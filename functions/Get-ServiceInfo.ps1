<#
.SYNOPSIS
    Retrieves detailed information about Windows services specified in an input file.

.DESCRIPTION
    The Get-ServiceInfo function reads a list of service names from a text file and retrieves
    comprehensive information about each service using WMI (Windows Management Instrumentation).
    The function returns detailed service properties including name, display name, state, status,
    start mode, service account, process ID, and executable path.

    This function is useful for:
    - Service inventory and documentation
    - Auditing service configurations across multiple systems
    - Troubleshooting service-related issues
    - Generating service reports for compliance or operational purposes

.NOTES
    Author   : adil-o7
    Version  : 1.0.0
    Date     : 2025-12-18

.PARAMETER InputFile
    The full path to a text file containing service names (one service name per line).
    Empty lines in the file will be ignored.
    The file should contain the service name (not the display name).
    Example file content:
        Spooler
        wuauserv
        MSSQLSERVER
        W32Time

.EXAMPLE
    Get-ServiceInfo -InputFile "C:\Services\ServiceList.txt"
    Retrieves detailed information for all services listed in the specified file.

.EXAMPLE
    $ServiceData = Get-ServiceInfo -InputFile "C:\Temp\CriticalServices.txt"
    $ServiceData | Format-Table -AutoSize
    Retrieves service information and displays it in a formatted table.

.EXAMPLE
    Get-ServiceInfo -InputFile "C:\Services\List.txt" | Export-Csv -Path "C:\Reports\ServiceReport.csv" -NoTypeInformation
    Retrieves service information and exports it to a CSV file for reporting.

.EXAMPLE
    Get-ServiceInfo -InputFile "C:\Services\List.txt" | Where-Object { $_.State -eq "Running" }
    Retrieves service information and filters to show only running services.

.EXAMPLE
    $Services = Get-ServiceInfo -InputFile "C:\Services\List.txt"
    $Services | Where-Object { $_.StartMode -eq "Auto" -and $_.State -ne "Running" }
    Identifies services that are set to start automatically but are not currently running.

.OUTPUTS
    System.Management.Automation.PSCustomObject
    Returns custom objects with the following properties for each service:
    - Name: The service name (short name used in commands)
    - DisplayName: The friendly display name of the service
    - State: Current state (Running, Stopped, Paused, etc.)
    - Status: Service status (OK, Error, Degraded, etc.)
    - StartMode: How the service starts (Auto, Manual, Disabled, etc.)
    - StartName: The account under which the service runs (LocalSystem, NetworkService, domain\user, etc.)
    - ProcessId: The Process ID of the running service (0 if stopped)
    - Pathname: Full path to the service executable

.NOTES
    Requirements:
    - Administrative privileges may be required to query certain service properties
    - WMI must be accessible on the local system
    - The input file must exist and be readable

    Tips:
    - Service names are case-insensitive
    - Use Get-Service to find the correct service name if unsure
    - The function continues processing even if individual services fail
#>

function Get-ServiceInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            Mandatory=$true,
            Position=0,
            HelpMessage="Enter the full path to a text file containing service names (one per line)"
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            # Validate that the file exists before proceeding
            if (Test-Path $_ -PathType Leaf) {
                $true
            } #End if
            else {
                throw "The file '$_' does not exist. Please provide a valid file path."
            } #End else
        })]
        [string]$InputFile
    )

    begin {
        Write-Verbose "Starting Get-ServiceInfo function"
        Write-Verbose "Input file: $InputFile"
    } #End begin

    process {
        try {
            # Verify that the input file exists
            if (-not (Test-Path $InputFile)) {
                throw "Input file not found: $InputFile"
            } #End if

            # Read service names from the input file
            # Remove empty lines and whitespace using Where-Object filter
            Write-Verbose "Reading service names from input file..."
            $ServiceNames = Get-Content $InputFile | Where-Object { $_.Trim() -ne '' }

            # Log the number of services to process
            Write-Verbose "Found $($ServiceNames.Count) service(s) to query"

            # Initialize an array to store the service information objects
            $ServiceInfoCollection = @()

            # Process each service name from the input file
            foreach ($ServiceName in $ServiceNames) {
                try {
                    Write-Verbose "Querying service: $ServiceName"

                    # Query WMI for detailed service information
                    # Win32_Service class provides comprehensive service details
                    # Using -Filter instead of Where-Object for better performance with WMI queries
                    $WmiService = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" -ErrorAction Stop

                    # Check if the service was found
                    if ($WmiService) {
                        # Create an ordered hashtable with service properties
                        # Using [ordered] ensures properties appear in the specified order
                        $Array = [ordered]@{
                            'Name'         = $WmiService.Name          # Service name (short name)
                            'DisplayName'  = $WmiService.DisplayName   # Friendly display name
                            'State'        = $WmiService.State         # Current state (Running, Stopped, etc.)
                            'Status'       = $WmiService.Status        # Service status (OK, Error, etc.)
                            'StartMode'    = $WmiService.StartMode     # Startup type (Auto, Manual, Disabled)
                            'StartName'    = $WmiService.StartName     # Account the service runs under
                            'ProcessId'    = $WmiService.ProcessId     # Process ID (0 if stopped)
                            'Pathname'     = $WmiService.PathName      # Full path to service executable
                        }

                        # Convert the hashtable to a PSCustomObject for better formatting and pipeline support
                        $InfoSummary = New-Object -TypeName PSObject -Property $Array

                        # Add the service object to the collection
                        $ServiceInfoCollection += $InfoSummary

                        Write-Verbose "Successfully retrieved information for service: $ServiceName"
                    } #End if
                    else {
                        # If service is not found, log a warning
                        Write-Warning "Service '$ServiceName' not found on this system."
                    } #End else
                } #End try
                catch {
                    # If there's an error processing a specific service, log it and continue
                    Write-Error "Error processing service '$ServiceName': $_"
                    Write-Verbose "Continuing with next service..."
                } #End catch
            } #End foreach

            # Log summary of results
            Write-Verbose "Successfully processed $($ServiceInfoCollection.Count) out of $($ServiceNames.Count) service(s)"

            # Return the collection of service information objects
            return $ServiceInfoCollection
        } #End try
        catch {
            # Catch any unexpected errors during the main process
            Write-Error "An error occurred in Get-ServiceInfo: $_"
            throw
        } #End catch
    } #End process

    end {
        Write-Verbose "Get-ServiceInfo function completed"
    } #End end
} #End function Get-ServiceInfo