# Check for OpenSSH Client
$sshClient = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

function Install-OpenSSH {
    param (
        [string]$Capability
    )
    Add-WindowsCapability -Online -Name $Capability
    Write-Host "$Capability installed successfully."
}

if ($sshClient.State -ne 'Installed') {
    Write-Host "OpenSSH Client is not installed. Installing it now..."
    Install-OpenSSH 'OpenSSH.Client~~~~0.0.1.0'
} else {
    Write-Host "OpenSSH Client is already installed."
}

if ($sshServer.State -ne 'Installed') {
    Write-Host "OpenSSH Server is not installed. Installing it now..."
    Install-OpenSSH 'OpenSSH.Server~~~~0.0.1.0'
} else {
    Write-Host "OpenSSH Server is already installed."
}

if ($sshServer.State -eq 'Installed') {
    
    $sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
    if ($sshdService -and $sshdService.Status -ne 'Running') {
        Start-Service sshd
        Write-Host "OpenSSH Server service started."
    } elseif ($sshdService) {
        Write-Host "OpenSSH Server service is already running."
    } else {
        Write-Host "OpenSSH Server service not found."
    }

    Set-Service -Name sshd -StartupType Automatic
    Write-Host "OpenSSH Server service set to start automatically."
}

Read-Host -Prompt "Press Enter to exit"