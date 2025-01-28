$ExportPath = "C:\temp"   #Path to save deployment kit on VBR Server
$csvFilePath = "C:\csv\hostnames.csv" #Where we keep linux hostnames, Prepare CSV content with hostnames only. First line: Hostname, other lines: 1 hostname on each line
$TargetPath = "/tmp/VeeamUpload"  #Path on Linux Machines, where the files will be copied
$LogFilePath = "C:\logs\installation_log.txt" # Path to log file on VBR Server
$username = "root" # Set backup user name here

Clear-Content -Path $LogFilePath -ErrorAction SilentlyContinue

$csvData = Import-Csv -Path $csvFilePath | Select-Object -ExpandProperty Hostname

Generate-VBRBackupServerDeployerKit -ExportPath $ExportPath

$detectDistro = 'source /etc/os-release && echo $ID'

foreach ($hostname in $csvData) {
    $sshUser = "$username@$hostname"
    $Destination = "$username@$hostname"":$TargetPath"
    $initialmessage = "Deployment Kit is being transferred to $hostname at $TargetPath`n"

    Add-Content -Path $LogFilePath -Value "$separatorLine"
    Add-Content -Path $LogFilePath -Value "$separatorLine"
    Write-Host $initialmessage
    Add-Content -Path $LogFilePath -Value $initialmessage

    try {
        cd "C:\Users\Administrator\Desktop\OpenSSH-Win64"

        $scpOutput = (& { ./scp -r -v -o Ciphers=aes256-ctr -o MACs=hmac-sha2-256 "$ExportPath/*" $Destination 2>&1 }) | Tee-Object -Variable scpLog
        
        if ($scpOutput -like "*failed to upload file*" -or $scpOutput -like "*Permission denied*") {
        Write-Host "Transfer failed. Check installation_logs for more information."
        Add-Content -Path $LogFilePath -Value $scpOutput
        Read-Host -Prompt "Press Enter to continue working on the next machine"
        Continue
        }

        $successMessage = "Transfer to $hostname succeeded`n"

        Write-Host $successMessage
        Add-Content -Path $LogFilePath -Value $successMessage

        # Detect the distribution and choose package manager command
        $distroOutput = ./ssh -q -o Ciphers=aes256-ctr -o MACs=hmac-sha2-256 $sshUser "$detectDistro" 2>&1 
        $distroType = $distroOutput.Trim()

        Write-Host "Detected distro: $distroOutput"
        Add-Content -Path $LogFilePath -Value "Detected distro on $hostname is $distroOutput"

        # Prepare commands for installation
        $installCommand = if ($distroType -eq "suse" -or $distroType -eq "sles") {
            "sudo zypper install -y $TargetPath/veeamdeployment-12.2.0.334-1.x86_64.rpm"
        } elseif ($distroType -eq "centos" -or $distroType -eq "rhel" -or $distroType -eq "fedora" -or $distroType -eq "amazon") {
            "sudo yum install -y $TargetPath/veeamdeployment-12.2.0.334-1.x86_64.rpm"
        } elseif ($distroType -eq "debian" -or $distroType -eq "ubuntu") {
            "sudo dpkg -i $TargetPath/veeamdeployment-12.2.0.334-1.amd64.deb && sudo apt-get install -f -y"
        } else {
            "echo 'Unsupported Linux distribution'; exit 1"
        }

        $commands = "cd $TargetPath; $installCommand; " +
            "sudo /opt/veeam/deployment/veeamdeploymentsvc --install-server-certificate server-cert.p12; " +
            "sudo /opt/veeam/deployment/veeamdeploymentsvc --install-certificate client-cert.pem; " +
            "sudo /opt/veeam/deployment/veeamdeploymentsvc --restart"

        $output = ./ssh -q -o Ciphers=aes256-ctr -o MACs=hmac-sha2-256 $sshUser "bash -c '$commands'" 2>&1 

        $separatorLine = "=" * 50 
        Add-Content -Path $LogFilePath -Value "$separatorLine"
        Add-Content -Path $LogFilePath -Value "Installation output for $hostname"

        foreach ($line in $output) {
            Add-Content -Path $LogFilePath -Value $line
        }

        Add-Content -Path $LogFilePath -Value "$separatorLine"

        # Check for errors in the output before deciding on success
        if ($output -like "*Permission denied*" -or $output -like "*a terminal is required*" -or $output -like "*error*") {
            $errorMessage = "Installation on $hostname failed due to permission issues or sudo configuration`n"
            Write-Host $errorMessage  
            Add-Content -Path $LogFilePath -Value $errorMessage
            Read-Host -Prompt "Press Enter to continue working on the next machine"
            Continue
        } 
          
        $installSuccessMessage = "Installation on $hostname succeeded`n"
        Write-Host $installSuccessMessage 
        Add-Content -Path $LogFilePath -Value $installSuccessMessage

    } catch {
        $errorMessage = "Error encountered on $hostname"
        Write-Host $errorMessage
        Add-Content -Path $LogFilePath -Value $errorMessage
    }

    Read-Host -Prompt "Press Enter to continue working on the next machine"
}

Read-Host -Prompt "Press Enter to exit"