function Get-CustomEvents {
<#
.SYNOPSIS
    Retrieves custom events from specified Windows event logs on local or remote computers.

.NOTES
    Author   : adil-o7
    Version  : 1.1.0
    Date     : 2025-12-24

.PARAMETER LogName
    Specifies the name of the event log to query. This parameter is mandatory.

.PARAMETER ComputerName
    Specifies one or more computer names to query. Accepts pipeline input.
    Default is the local computer.

.PARAMETER EventID
    Specifies the Event ID to filter on. This parameter is optional.

.PARAMETER ProviderName
    Specifies the provider name to filter on. This parameter is optional.

.PARAMETER MaxEvents
    Specifies the maximum number of events to retrieve per computer. Default is 100.

.PARAMETER StartTime
    Specifies the start time for the event query. This parameter is optional.

.PARAMETER EndTime
    Specifies the end time for the event query. This parameter is optional.

.PARAMETER Credential
    Specifies credentials to use when connecting to remote computers. This parameter is optional.

.EXAMPLE
    Get-CustomEvents -LogName "Application" -ProviderName "windows_exporter" -MaxEvents 10

.EXAMPLE
    Get-CustomEvents -LogName "System" -EventID 1074 -StartTime (Get-Date).AddDays(-1) -Verbose

.EXAMPLE
    Get-CustomEvents -LogName "Application" -ComputerName "Server01", "Server02" -EventID 1000

.EXAMPLE
    Get-Content C:\servers.txt | Get-CustomEvents -LogName "System" -EventID 1074 -MaxEvents 50

.EXAMPLE
    Get-CustomEvents -LogName "Application" -ComputerName "RemoteServer" -Credential (Get-Credential)
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogName,

        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('CN','MachineName','Host')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$false)]
        [int]$EventID,

        [Parameter(Mandatory=$false)]
        [string]$ProviderName,

        [Parameter(Mandatory=$false)]
        [int]$MaxEvents = 100,

        [Parameter(Mandatory=$false)]
        [datetime]$StartTime,

        [Parameter(Mandatory=$false)]
        [datetime]$EndTime,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    ) #End param

    begin {
        # Build the filter hashtable based on provided parameters
        $FilterHashtable = @{
            LogName = $LogName
        }

        if ($EventID) { $FilterHashtable.Add("ID", $EventID) }
        if ($ProviderName) { $FilterHashtable.Add("ProviderName", $ProviderName) }
        if ($StartTime) { $FilterHashtable.Add("StartTime", $StartTime) }
        if ($EndTime) { $FilterHashtable.Add("EndTime", $EndTime) }

        Write-Verbose "Querying events with the following filter:"
        Write-Verbose ($FilterHashtable | Out-String)

        # Prepare Get-WinEvent parameters
        $GetWinEventParams = @{
            FilterHashtable = $FilterHashtable
            MaxEvents = $MaxEvents
            ErrorAction = 'Stop'
        }

        if ($Credential) {
            $GetWinEventParams.Add('Credential', $Credential)
        } #End if
    } #End begin

    process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Processing computer: $Computer"

            # Test connectivity first
            if ($Computer -ne $env:COMPUTERNAME -and $Computer -ne 'localhost' -and $Computer -ne '.') {
                Write-Verbose "Testing connectivity to $Computer..."
                if (-not (Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
                    Write-Warning "Unable to reach computer: $Computer. Skipping..."
                    continue
                } #End if
            } #End if

            try {
                # Add ComputerName parameter for remote queries
                if ($Computer -ne $env:COMPUTERNAME -and $Computer -ne 'localhost' -and $Computer -ne '.') {
                    $GetWinEventParams['ComputerName'] = $Computer
                }
                else {
                    $GetWinEventParams.Remove('ComputerName')
                } #End if

                # Attempt to retrieve events
                Write-Verbose "Retrieving events from $Computer..."
                $Events = Get-WinEvent @GetWinEventParams

                if ($Events) {
                    Write-Verbose "Found $($Events.Count) events on $Computer."
                    $Events | ForEach-Object {
                        [PSCustomObject]@{
                            TimeCreated = $_.TimeCreated
                            ComputerName = $_.MachineName
                            ProviderName = $_.ProviderName
                            EventID = $_.Id
                            Level = $_.LevelDisplayName
                            Message = $_.Message
                        }
                    } #End ForEach-Object
                }
                else {
                    Write-Warning "No events were found on $Computer matching the specified criteria."
                } #End if
            }
            catch {
                if ($_.Exception.Message -like "*No events were found*") {
                    Write-Warning "No events were found on $Computer matching the specified criteria."
                }
                elseif ($_.Exception.Message -like "*network path was not found*") {
                    Write-Warning "Unable to connect to $Computer. Check network connectivity and firewall settings."
                }
                elseif ($_.Exception.Message -like "*Access is denied*") {
                    Write-Warning "Access denied when connecting to $Computer. Check credentials and permissions."
                }
                else {
                    Write-Error "An error occurred querying $Computer : $_"
                } #End if

                # Attempt to show recent events from the log for troubleshooting
                Write-Verbose "Attempting to retrieve recent events from $Computer for troubleshooting..."
                Write-Host "Available events in the $LogName log on $Computer :" -ForegroundColor Yellow
                try {
                    $TroubleshootParams = @{
                        LogName = $LogName
                        MaxEvents = 5
                        ErrorAction = 'Stop'
                    }

                    if ($Computer -ne $env:COMPUTERNAME -and $Computer -ne 'localhost' -and $Computer -ne '.') {
                        $TroubleshootParams['ComputerName'] = $Computer
                    } #End if

                    if ($Credential) {
                        $TroubleshootParams['Credential'] = $Credential
                    } #End if

                    Get-WinEvent @TroubleshootParams |
                        Format-Table TimeCreated, Id, ProviderName, LevelDisplayName, Message -AutoSize -Wrap
                }
                catch {
                    Write-Warning "Unable to retrieve events from the $LogName log on $Computer : $_"
                } #End try
            } #End try
        } #End foreach
    } #End process

    end {
        Write-Verbose "Event query completed."
    } #End end
} #End function Get-CustomEvents
