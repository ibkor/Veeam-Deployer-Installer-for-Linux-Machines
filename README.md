# Veeam Deployer Installer for Linux Machines

This repository contains a PowerShell script that facilitates the deployment of Veeam Deployment Kit to multiple Linux machines simultaneously, as well as configuring the necessary certificates for proper operation.

## Overview

With this script, you can automate the installation of Veeam Backup & Replication Deployment Kit on all specified Linux machines. The script takes a list of hostnames from a CSV file, transfers the deployment kit to each machine, installs it, and configures the server and client certificates.

## Prerequisites

- Veeam Backup & Replication Server installed
- OpenSSH enabled on all target Linux machines
- PowerShell access to the Veeam Backup & Replication Server
- The `scp` and `ssh` commands available
- `yum` package manager on affected Linux machines
- To successfully run the commands included in this script on the Linux machines, ensure that the user has enough permissions.


## Usage

2. **Prepare Hostnames CSV**
   - Create a CSV file named `hostnames.csv` with the following format:
     ```
     Hostname
     hostname1
     hostname2
     hostname3
     ```

3. **Set Script Variables**
   - Modify the variables in the script to suit your environment:
     - `$ExportPath`: Location on the VBR server to save the deployment kit.
     - `$csvFilePath`: Path to the `hostnames.csv` file.
     - `$TargetPath`: Destination path on Linux machines where files will be copied.
     - `$LogFilePath`: Path where logs will be saved on VBR Server.
     - `$username`: Username for SSH connections.

4. **Run the Script**
   - Open PowerShell on your VBR server.
   - Execute the script to start the deployment process. The progress will be logged in the specified log file. 

5. **Review Logs**
   - Check the log file located at `$LogFilePath` for any errors or installation details.

## Issues

For any issues or bug reports, please open an issue in the repository.

