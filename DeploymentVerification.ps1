$csvFilePath = "C:\csv\hostnames.csv"   # Where we keep linux hostnames, use the same hostnames csv file used in deployment
$username = "newuser" # Set backup user name here
$LogFilePath = "C:\logs\verification_log.txt" # Path to log file for verification

Clear-Content -Path $LogFilePath -ErrorAction SilentlyContinue

$csvData = Import-Csv -Path $csvFilePath | Select-Object -ExpandProperty Hostname

$successfulHosts = @()
$unsuccessfulHosts = @()

foreach ($hostname in $csvData) {
    $sshUser = "$username@$hostname"

    Write-Host "Checking installation of veeamdeployment on $hostname..."

    # Check if the Veeam Deployment package is installed
    $checkPackageCommand = "rpm -q veeamdeployment-12.2.0.334-1.x86_64"
    $packageStatus = ssh $sshUser "$checkPackageCommand" 2>&1

    $separatorLine = "=" * 50
    Add-Content -Path $LogFilePath -Value "$separatorLine"
    Add-Content -Path $LogFilePath -Value "Checking package installation for $hostname"

    if ($packageStatus -like "veeamdeployment-12.2.0.334-1.x86_64*") {
        $successfulHosts += $hostname
        $successMessage = "$hostname Package is successfully installed."
        Write-Host $successMessage
        Add-Content -Path $LogFilePath -Value $successMessage
    } else {
        $unsuccessfulHosts += $hostname
        $errorMessage = "$hostname Package is not installed, or password is incorrect. Status: $packageStatus"
        Write-Host $errorMessage
        Add-Content -Path $LogFilePath -Value $errorMessage
    }
}

Write-Host "-------------------------------------------------"
Write-Host "Verification Summary:"
Write-Host "Successful Installations: $($successfulHosts.Count)"
$successfulHosts | ForEach-Object { Write-Host $_ }

Write-Host "Unsuccessful Installations: $($unsuccessfulHosts.Count)"
$unsuccessfulHosts | ForEach-Object { Write-Host $_ }

Add-Content -Path $LogFilePath -Value "-------------------------------------------------"
Add-Content -Path $LogFilePath -Value "Verification Summary:"
Add-Content -Path $LogFilePath -Value "Successful Installations: $($successfulHosts.Count)"
$successfulHosts | ForEach-Object { Add-Content -Path $LogFilePath -Value $_ }

Add-Content -Path $LogFilePath -Value "Unsuccessful Installations: $($unsuccessfulHosts.Count)"
$unsuccessfulHosts | ForEach-Object { Add-Content -Path $LogFilePath -Value $_ }

Read-Host -Prompt "Press Enter to exit"