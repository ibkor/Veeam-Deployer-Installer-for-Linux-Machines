# This project is licensed under the MIT License - see the LICENSE file for details.
 $logDir = 'C:\logs'
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory
}

# Define the log file path
$logFile = Join-Path -Path $logDir -ChildPath 'PGAdjusterLog.txt'

# Function to log messages
function Write-Log {
    param (
        [string]$message
    )
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timeStamp - $message"
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "Script execution started."

$hostnames = Import-Csv -Path "C:\tmp\hostnames.csv"

$PGs = Get-VBRProtectionGroup

$changes = @{}
$notFoundHosts = @()
$duplicateHosts = @()

# Collect information about where each host appears
$hostToPGMap = @{}

foreach ($entry in $hostnames) {
    $Srv = $entry.HostName
    Write-Log "Checking host: $Srv"

    $found = $false

    # Find the protection group containing the host
    $pgsContainingHost = @()

    foreach ($PG in $PGs) {
        $comp = $PG.Container.CustomCredentials
        $existingHost = $comp | Where-Object { $_.HostName -eq $Srv }

        if ($existingHost) {
            $found = $true
            $pgsContainingHost += $PG

            if (-not $hostToPGMap.ContainsKey($Srv)) {
                $hostToPGMap[$Srv] = @()
            }
            $hostToPGMap[$Srv] += $PG.Name
        }

        if ($existingHost.UseTemporaryCertificate) {
            Write-Log "Host $Srv already uses temporary certificate. No changes required."
            continue
        }
    }

    if ($found) {
        # If the host is found in more than one protection group, mark it as a duplicate and do not do anything, manual edit is needed
        if ($pgsContainingHost.Count -gt 1) {
            $duplicateHosts += $Srv
            $pgNames = $pgsContainingHost | ForEach-Object { $_.Name } | Sort-Object | Get-Unique
            Write-Log "Duplicate found for host $Srv in groups: $($pgNames -join ', ')"
        }

        else {
            $PG = $pgsContainingHost[0]
            $comp = $PG.Container.CustomCredentials
            $existingHost = $comp | Where-Object { $_.HostName -eq $Srv }

            if ($existingHost -and -not $existingHost.UseTemporaryCertificate) {
                if (-not $changes.ContainsKey($PG.Id)) {
                    $changes[$PG.Id] = @{
                        'PG' = $PG
                        'ToRemove' = @()
                        'ToAdd' = @()
                    }
                }
                $changes[$PG.Id]['ToRemove'] += $existingHost
                $supervisor = New-VBRIndividualComputerCustomCredentials -HostName $Srv -UseTemporaryCertificate
                $changes[$PG.Id]['ToAdd'] += $supervisor
                Write-Log "Host $Srv will be updated to use temporary certificate."
            }
        }
    } else {
        $notFoundHosts += $Srv
    }
}

# Apply batch changes
foreach ($pgChange in $changes.Values) {
    $PG = $pgChange['PG']
    [System.Collections.ArrayList]$compList = @($PG.Container.CustomCredentials)

    $changesMade = $false

    if ($pgChange['ToRemove'].Count -gt 0) {
        foreach ($currentHost in $pgChange['ToRemove']) {
            $null = $compList.Remove($currentHost)
            Write-Log "Removed host: $($currentHost.HostName)"
        }
        $changesMade = $true
    }

    if ($pgChange['ToAdd'].Count -gt 0) {
        $compList.AddRange($pgChange['ToAdd'])
        $addedHosts = ($pgChange['ToAdd'] | ForEach-Object { $_.HostName }) -join ', '
        Write-Log "Added new hosts: $addedHosts"
        $changesMade = $true
    }

    if ($changesMade) {
        $newcomp = Set-VBRIndividualComputerContainer -Container $PG.Container -CustomCredentials $compList
        Set-VBRProtectionGroup -ProtectionGroup $PG -Container $newcomp
        Rescan-VBREntity -Entity $PG -Wait
        Write-Log "Completed rescan after updates for group $($PG.Name)"
    } else {
        Write-Log "No changes made for group $($PG.Name), skipping rescan."
        Write-Host "No changes made for group $($PG.Name), skipping rescan."
    }
}

if ($duplicateHosts.Count -gt 0) {
    Write-Log "The following hosts were found in multiple protection groups:"
    Write-Host "The following hosts were found in multiple protection groups:" -ForegroundColor Yellow
    foreach ($dupHost in $duplicateHosts | Sort-Object | Get-Unique) {
        $pgNames = $hostToPGMap[$dupHost] -join ', '
        Write-Log "$dupHost in groups: $pgNames"
        Write-Host "$dupHost in groups: $pgNames" -ForegroundColor Cyan
    }
}

if ($changes.Values.Count -eq 0) {
        Write-Log "No changes made for any Protection Group, skipping rescan."
        Write-Host "No changes made for any Protection Group, skipping rescan."
}

if ($notFoundHosts.Count -gt 0) {
    Write-Log "The following hosts were not found in any protection groups: $($notFoundHosts -join ', ')"
    Write-Host "The following hosts were not found in any protection groups:" -ForegroundColor Yellow
    $notFoundHosts | ForEach-Object { Write-Host $_ -ForegroundColor Red }
}

Write-Log "Script execution completed."
Read-Host -Prompt "Script execution completed. Press enter to exit..." 
