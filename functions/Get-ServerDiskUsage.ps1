function Get-ServerDiskUsage {
    <#
    .SYNOPSIS
        Gets disk usage summary for Windows Server(s)

    .DESCRIPTION
        Returns total disk capacity and used space across all fixed drives
        as PowerShell objects. Can provide detailed per-disk information.

    .NOTES
        Author   : adil-o7
        Version  : 1.0.0
        Date     : 2025-12-24

    .PARAMETER ComputerName
        Server name(s) to query. Defaults to local computer.

    .PARAMETER Detailed
        Returns detailed information for each disk drive

    .EXAMPLE
        Get-ServerDiskUsage
        Returns summary disk usage for local server as PSObject

    .EXAMPLE
        Get-ServerDiskUsage -ComputerName "SRV1","SRV2","SRV3"
        Returns summary disk usage for multiple servers

    .EXAMPLE
        Get-ServerDiskUsage -ComputerName "SRV1" -Detailed
        Returns detailed per-disk information

    .EXAMPLE
        Get-ServerDiskUsage -Detailed | Format-Table -AutoSize
        Display detailed results in formatted table
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [switch]$Detailed
    )
    #End param

    process {
        foreach ($Server in $ComputerName) {
            try {
                # Use Invoke-Command for remote servers, direct WMI for local
                if ($Server -eq $env:COMPUTERNAME -or $Server -eq "localhost" -or $Server -eq ".") {
                    # Local execution
                    $Disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
                    $ServerName = $env:COMPUTERNAME
                } else {
                    # Remote execution
                    $Result = Invoke-Command -ComputerName $Server -ScriptBlock {
                        $Disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
                        return @{
                            ServerName = $env:COMPUTERNAME
                            Disks = $Disks
                        }
                    } -ErrorAction Stop

                    $Disks = $Result.Disks
                    $ServerName = $Result.ServerName
                }
                #End if

                if ($Detailed) {
                    # Return detailed information for each disk
                    foreach ($Disk in $Disks) {
                        $CapacityGB = [Math]::Round($Disk.Size / 1GB, 2)
                        $FreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
                        $UsedGB = [Math]::Round(($Disk.Size - $Disk.FreeSpace) / 1GB, 2)
                        $UsedPercent = if ($Disk.Size -gt 0) { [Math]::Round((($Disk.Size - $Disk.FreeSpace) / $Disk.Size) * 100, 1) } else { 0 }
                        $FreePercent = if ($Disk.Size -gt 0) { [Math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 1) } else { 0 }

                        [PSCustomObject]@{
                            ServerName = $ServerName
                            DriveLetter = $Disk.DeviceID
                            Label = $Disk.VolumeName
                            CapacityGB = $CapacityGB
                            UsedGB = $UsedGB
                            FreeGB = $FreeGB
                            UsedPercent = $UsedPercent
                            FreePercent = $FreePercent
                        }
                    }
                    #End foreach
                } else {
                    # Return summary information
                    $TotalCapacityBytes = ($Disks | Measure-Object -Property Size -Sum).Sum
                    $TotalFreeBytes = ($Disks | Measure-Object -Property FreeSpace -Sum).Sum
                    $TotalUsedBytes = $TotalCapacityBytes - $TotalFreeBytes

                    # Convert to GB and round
                    $TotalCapacityGB = [Math]::Round($TotalCapacityBytes / 1GB)
                    $TotalUsedGB = [Math]::Round($TotalUsedBytes / 1GB)

                    [PSCustomObject]@{
                        ServerName = $ServerName
                        TotalCapacityGB = $TotalCapacityGB
                        TotalUsedGB = $TotalUsedGB
                    }
                }
                #End if

            } catch {
                Write-Warning "Failed to query $Server : $($_.Exception.Message)"
            }
            #End try
        }
        #End foreach
    }
    #End process
}
#End function Get-ServerDiskUsage
