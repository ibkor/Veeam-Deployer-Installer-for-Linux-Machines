$ExportPath = "C:\temp"   #Path to save deployment kit on VBR Server
$csvFilePath = "C:\csv\hostnames.csv" #Where we keep linux hostnames, Prepare CSV content with hostnames only. First line: Hostname, other lines: 1 hostname on each line
$TargetPath = "/tmp/VeeamUpload"  #Path on Linux Machines, where the files will be copied
$LogFilePath = "C:\logs\installation_log.txt" # Path to log file on VBR Server
$username = "root" # Set backup user name here

# Ensure the log file is cleared at the start
Clear-Content -Path $LogFilePath -ErrorAction SilentlyContinue

$csvData = Import-Csv -Path $csvFilePath | Select-Object -ExpandProperty Hostname

Generate-VBRBackupServerDeployerKit -ExportPath $ExportPath

# Command to determine the package manager
$detectDistro = "source /etc/os-release && echo $ID"

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
        ./scp -r -o Ciphers=aes256-ctr -o MACs=hmac-sha2-256 "$ExportPath/*" $Destination

        $successMessage = "Transfer to $hostname succeeded`n"
        Write-Host $successMessage
        Add-Content -Path $LogFilePath -Value $successMessage

        # Detect the distribution and choose package manager command
        $distroOutput = ./ssh -o Ciphers=aes256-ctr -o MACs=hmac-sha2-256 $sshUser "$detectDistro" 2>&1 
        $distroType = $distroOutput.Trim()

        # Prepare commands for installation
        $installCommand = if ($distroType -eq "suse") {
            "sudo zypper install -y /tmp/VeeamUpload/veeamdeployment-12.2.0.334-1.x86_64.rpm"
        } elseif ($distroType -eq "centos" -or $distroType -eq "rhel" -or $distroType -eq "fedora" -or $distroType -eq "amazon") {
            "sudo yum install -y /tmp/VeeamUpload/veeamdeployment-12.2.0.334-1.x86_64.rpm"
        } else {
            "echo 'Unsupported Linux distribution'; exit 1"
        }

        $commands = "cd $TargetPath; $installCommand; " +
                    "sudo /opt/veeam/deployment/veeamdeploymentsvc --install-server-certificate server-cert.p12; " +
                    "sudo /opt/veeam/deployment/veeamdeploymentsvc --install-certificate client-cert.pem; " +
                    "sudo /opt/veeam/deployment/veeamdeploymentsvc --restart"

        $output = ./ssh -o Ciphers=aes256-ctr -o MACs=hmac-sha2-256 $sshUser "bash -c '$commands'" 2>&1 

        $separatorLine = "=" * 50 
        Add-Content -Path $LogFilePath -Value "$separatorLine"
        Add-Content -Path $LogFilePath -Value "Installation output for $hostname"

        foreach ($line in $output) {
            Add-Content -Path $LogFilePath -Value $line
        }

        Add-Content -Path $LogFilePath -Value "$separatorLine"

        $installSuccessMessage = "Installation on $hostname succeeded`n"
        Add-Content -Path $LogFilePath -Value $installSuccessMessage
        Write-Host $installSuccessMessage 
       
    } catch {
        $errorMessage = "Error encountered on $hostname"
        Write-Host $errorMessage
        Add-Content -Path $LogFilePath -Value $errorMessage
    }

    Read-Host -Prompt "Press Enter to continue working on the next machine"
}

Read-Host -Prompt "Press Enter to exit"