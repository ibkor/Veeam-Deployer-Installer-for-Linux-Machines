# Function to remove OpenSSH capabilities
function Remove-OpenSSH {
    param (
        [string]$Capability
    )
    Remove-WindowsCapability -Online -Name $Capability
    Write-Host "$Capability removed successfully."
}

# Check for OpenSSH Client
$sshClient = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

# Check and remove OpenSSH Client
if ($sshClient.State -eq 'Installed') {
    Write-Host "OpenSSH Client is installed. Removing it now..."
    Remove-OpenSSH 'OpenSSH.Client~~~~0.0.1.0'
} else {
    Write-Host "OpenSSH Client is not installed."
}

# Check and remove OpenSSH Server
if ($sshServer.State -eq 'Installed') {
    Write-Host "OpenSSH Server is installed. Stopping and removing it now..."
    
    # Stop the sshd service if it is running
    $sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
    if ($sshdService -and $sshdService.Status -eq 'Running') {
        Stop-Service sshd
        Write-Host "OpenSSH Server service stopped."
    }
    
    # Remove the OpenSSH Server feature
    Remove-OpenSSH 'OpenSSH.Server~~~~0.0.1.0'
} else {
    Write-Host "OpenSSH Server is not installed."
}

Read-Host -Prompt "Press Enter to exit"