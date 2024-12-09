# Veeam Deployer Installer for Linux Machines

This repository contains a set of PowerShell scripts that facilitate the deployment of Veeam Deployment Kit for certificate based connections to multiple Linux machines simultaneously, configure the necessary certificates, and manage OpenSSH settings on a Windows server.

## Overview

With these scripts, you can:
- Automate the installation of Veeam Backup & Replication Deployment Kit on all specified Linux machines.
- Verify the success of deployments and log the results.
- Enable or disable OpenSSH on the Windows server as required.
  
## Prerequisites

- Veeam Backup & Replication Server installed
- PowerShell access to the Veeam Backup & Replication Server
- `OpenSSH` is enabled on VBR Server
- The `scp` and `ssh` commands available
- `yum` package manager on affected Linux machines
- Sudo Privileges: The user should have sufficient privileges to run the following commands with `sudo` without being prompted for a password:
  - `yum install -y veeamdeployment-12.2.0.334-1.x86_64.rpm`
  - `/opt/veeam/deployment/veeamdeploymentsvc --install-server-certificate server-cert.p12`
  - `/opt/veeam/deployment/veeamdeploymentsvc --install-certificate client-cert.pem`
  - `/opt/veeam/deployment/veeamdeploymentsvc --restart`
  - `rpm -q veeamdeployment-12.2.0.334-1.x86_64`

## Usage

1. **Verify OpenSSH availability on VBR Server**
   - If OpenSSH is not enabled on VBR Server, enable it by running enable-ssh.ps1.
     it can be verified with the command:     `Get-Service -Name sshd`

2. **Prepare Hostnames CSV**
   - Create a CSV file named `hostnames.csv` with the following format and save it on VBR Server:
     ```
     Hostname
     hostname1
     hostname2
     hostname3
     ```

3. **Set Script Variables**
   - Modify the variables in VeeamDeployer script to suit your environment:
     - `$ExportPath`: Location on the VBR server to save the deployment kit.
     - `$csvFilePath`: Path to the `hostnames.csv` file.
     - `$TargetPath`: Destination path on Linux machines where files will be copied.
     - `$LogFilePath`: Path where logs will be saved on VBR Server.
     - `$username`: Username for SSH connections.

4. **Run the Script**
   - Open PowerShell on your VBR server.
   - Execute the script to start the deployment process. The progress will be logged in the specified log file.
   - Enter the user password when prompted.
  
5. **Installation Verification**
   - Modify the variables in DeploymentVerification script to suit your environment:
      - `$csvFilePath = Path to the `hostnames.csv` file.
      - `$username` = Username for SSH connections.
      - `$LogFilePath` = Path where logs will be saved on VBR Server.

   - Run DeploymentVerification.ps1 to verify the installation on the linux servers.
     
6. **OpenSSH verification on VBR Server**
   - If OpenSSH is not needed on VBR Server, disable it by running disable-openssh.ps1 script.
   
7. **Review Logs**
   - Check the log file located at `$LogFilePath` for any errors or installation details.

## Issues

For any issues or bug reports, please open an issue in the repository.

