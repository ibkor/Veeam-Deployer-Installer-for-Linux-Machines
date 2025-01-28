## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

# Veeam Deployer Installer for Linux Machines

This repository contains a set of PowerShell scripts that facilitate the deployment of Veeam Deployment Kit for certificate based connections to multiple Linux machines simultaneously, configure the necessary certificates, and manage OpenSSH settings on a Windows server. With PGAdjuster Script, Protection Group connection types for each server can be changed to Cert-based Auth automatically. The script will remove the servers from the Protection Groups and add them to the same Protection Group with Certificate Based Auth. without changing any other settings. It will also install required components to the servers automatically during the final rescan.

Now, the script also detects Linux Distribution and uses either zypper, yum or dpkg to install. 

## Overview

With these scripts, you can:
- Automate the installation of Veeam Backup & Replication Deployment Kit on all specified Linux machines.
- Verify the success of deployments and log the results.
- Edit existing Protection Groups and change connection type to Certificate Based Authentication.
- Enable or disable OpenSSH on the Windows server as required.
  
## Prerequisites

- Veeam Backup & Replication Server installed
- PowerShell access to the Veeam Backup & Replication Server
- `OpenSSH` is enabled on VBR Server
- OS on VBR Server is Windows Server 2019 or later.
- For Windows Server 2016 or earlier, OpenSSH must be enabled manually.
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
   - Check the log files located at `$LogFilePath` for any errors or installation details.

8. **Post-Deployment Steps**
   - PGAdjuster script can be run to automatically edit existing Protection Groups and change the connection type to Cert-Based Auth. Or, a manual adjustment can be done as following:
   - SSH can be disabled on Linux machines if desired. Additionally, previously used Linux user accounts for backups can be removed from Linux machines.
   - On the Veeam Backup & Replication side, create a protection group with the following parameters:
     - At the Type step of the wizard, select Individuals computers.
     - At the Computers step of the wizard, add Linux Machines and select the Connect using certificate-based authentication method to connect to the computer.
     - After you create the protection group, Veeam Backup & Replication will rescan the protection group. During the rescan operation, Veeam Backup & Replication will replace the Veeam Deployer Service temporary certificate, connect to the Veeam Deployer Service and install Veeam Agent.
    
Disclaimer: The scripts in this repository are provided "as is" without any warranties, express or implied. The author is not liable for any damages resulting from the use or inability to use these scripts, including but not limited to direct, indirect, incidental, or consequential damages. Users accept full responsibility for any risks associated with using these scripts, including compliance with laws and regulations. By using these scripts, you agree to indemnify the author against any claims arising from your use.
