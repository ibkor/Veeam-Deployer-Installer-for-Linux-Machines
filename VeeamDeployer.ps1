$ExportPath = "C:\temp"   #Path to save deployment kit on VBR Server
$csvFilePath = "C:\csv\hostnames.csv" #Where we keep linux hostnames, Prepare CSV content with hostnames only. First line: Hostname, other lines: 1 hostname on each line
$TargetPath = "/files"  #Path on Linux Machines, where the files will be copied
$LogFilePath = "C:\logs\installation_log.txt" # Path to log file on VBR Server
$username = "root" # Set backup user name here

# Ensure the log file is cleared at the start
Clear-Content -Path $LogFilePath -ErrorAction SilentlyContinue

$csvData = Import-Csv -Path $csvFilePath | Select-Object -ExpandProperty Hostname

Generate-VBRBackupServerDeployerKit -ExportPath $ExportPath

foreach ($hostname in $csvData) {
    $sshUser = "$username@$hostname"
    $Destination = "$username@$hostname"":$TargetPath"
    $initialmessage = "Deployment Kit is being transferred to $hostname at $TargetPath`n"

    Add-Content -Path $LogFilePath -Value "$separatorLine"
    Add-Content -Path $LogFilePath -Value "$separatorLine"
    Write-Host $initialmessage
    Add-Content -Path $LogFilePath -Value $initialmessage

    try {
         
        scp -r "$ExportPath/*" $Destination

        $successMessage = "Transfer to $hostname succeeded`n"
        Write-Host $successMessage
        Add-Content -Path $LogFilePath -Value $successMessage
       
        $commands = "cd $TargetPath; " +
                    "sudo yum install -y veeamdeployment-12.2.0.334-1.x86_64.rpm; " +
                    "sudo /opt/veeam/deployment/veeamdeploymentsvc --install-server-certificate server-cert.p12; " +
                    "sudo /opt/veeam/deployment/veeamdeploymentsvc --install-certificate client-cert.pem; " +
                    "sudo /opt/veeam/deployment/veeamdeploymentsvc --restart"
        
        $output = ssh $sshUser "bash -c '$commands'" 2>&1 
                
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
