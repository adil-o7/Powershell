<#
.SYNOPSIS
    Compares Windows services between two servers and identifies differences.

.DESCRIPTION
    The Compare-ServerServices function queries and compares Windows services running on two different servers.
    It can filter by service status (Running/Stopped) and export results to CSV format.
    The comparison highlights services that exist only on Server1, only on Server2, or on both servers.

.NOTES
    Author   : adil-o7
    Version  : 1.0.0
    Date     : 2025-12-18

.PARAMETER Server1
    The name or IP address of the first server to compare.
    This parameter is mandatory.

.PARAMETER Server2
    The name or IP address of the second server to compare.
    This parameter is mandatory.

.PARAMETER OutputCSV
    Optional. The full path to export comparison results to a CSV file.
    If specified, results will be saved to this location.

.PARAMETER Status
    Optional. Filter services by their status. Valid values are "Running" or "Stopped".
    If not specified, all services regardless of status will be compared.

.EXAMPLE
    Compare-ServerServices -Server1 "PROD-WEB01" -Server2 "PROD-WEB02" -Verbose
    Compares all services between two web servers with verbose output.

.EXAMPLE
    Compare-ServerServices -Server1 "APP-SERVER1" -Server2 "APP-SERVER2" -Status "Running" -OutputCSV "C:\Reports\ServiceComparison.csv"
    Compares only running services and exports the results to a CSV file.

.EXAMPLE
    Compare-ServerServices -Server1 "DB-PRIMARY" -Server2 "DB-SECONDARY" -Status "Stopped"
    Compares only stopped services between two database servers.

.OUTPUTS
    System.Object
    Returns a comparison object containing the differences between the two servers' services.
#>

function Compare-ServerServices {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Server1,

        [Parameter(Mandatory=$true)]
        [string]$Server2,

        [Parameter(Mandatory=$false)]
        [string]$OutputCSV,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Running", "Stopped")]
        [string]$Status
    )

    # Output verbose message indicating the start of comparison
    Write-Verbose "Comparing services between $Server1 and $Server2"

    # ===========================
    # Nested Helper Function
    # ===========================
    <#
    .SYNOPSIS
        Internal helper function to retrieve services from a remote server.

    .DESCRIPTION
        Queries Windows services from the specified server using PowerShell remoting (Invoke-Command).
        Optionally filters services by their status if the $Status parameter is provided.

    .PARAMETER ServerName
        The name or IP address of the server to query.

    .RETURNS
        Array of service objects with Name and Status properties, or $null if an error occurs.
    #>
    function Get-ServerServices($ServerName) {
        try {
            # Build a hashtable of parameters for Invoke-Command to improve readability
            $Params = @{
                ComputerName = $ServerName              # Target server for remote execution
                ScriptBlock = {                         # Script to execute on remote server
                    param($StatusFilter)                # Accept status filter as parameter

                    # Retrieve all services from the remote server
                    $Services = Get-Service

                    # If a status filter was provided, apply it
                    if ($StatusFilter) {
                        $Services = $Services | Where-Object Status -eq $StatusFilter
                    } #End if

                    # Return only the Name and Status properties
                    $Services | Select-Object Name, Status
                }
                ArgumentList = $Status                  # Pass the status filter to the script block
                ErrorAction = 'Stop'                    # Stop execution if an error occurs
            }

            # Execute the remote command using splatting for better readability
            Invoke-Command @Params
        } #End try
        catch {
            # If service retrieval fails, display an error and return null
            Write-Error "Failed to retrieve services from $ServerName. Error: $_"
            return $null
        } #End catch
    }

    # ===========================
    # Main Execution Logic
    # ===========================

    # Retrieve services from both servers
    $Services1 = Get-ServerServices $Server1
    $Services2 = Get-ServerServices $Server2

    # Check if service retrieval was successful for both servers
    if (-not $Services1 -or -not $Services2) {
        Write-Error "Comparison aborted due to failure in retrieving services."
        return
    } #End if

    # Compare the service lists from both servers
    # -Property specifies which properties to compare (Name and Status)
    # -IncludeEqual includes services that exist on both servers
    $Comparison = Compare-Object $Services1 $Services2 -Property Name, Status -IncludeEqual

    # ===========================
    # Process and Display Results
    # ===========================

    # Process each comparison result and format for display
    $Results = foreach ($Item in $Comparison) {
        # Determine which server the service belongs to based on the side indicator
        # "<=" means the service exists on Server1 (or different on Server1)
        # "=>" means the service exists on Server2 (or different on Server2)
        # "==" means the service exists on both servers with the same status
        $ServerLocation = switch ($Item.SideIndicator) {
            "<=" { $Server1 }
            "=>" { $Server2 }
            "==" { "Both" }
        } #End switch

        # Assign color coding for console output to make differences easy to spot
        # Red = Only on Server1, Green = Only on Server2, White = On both servers
        $Color = switch ($Item.SideIndicator) {
            "<=" { "Red" }
            "=>" { "Green" }
            "==" { "White" }
        } #End switch

        # Display the result in the console with color coding
        Write-Host "$ServerLocation : $($Item.Name) ($($Item.Status))" -ForegroundColor $Color

        # Create a custom object for each result to enable CSV export
        [PSCustomObject]@{
            Name = $Item.Name           # Service name
            Status = $Item.Status       # Service status (Running, Stopped, etc.)
            Server = $ServerLocation    # Which server(s) the service exists on
        }
    } #End foreach

    # ===========================
    # Export Results to CSV
    # ===========================

    # If OutputCSV parameter was provided, export the results to a CSV file
    if ($OutputCSV) {
        $Results | Export-Csv -Path $OutputCSV -NoTypeInformation -UseCulture
        Write-Host "Results exported to $OutputCSV" -ForegroundColor Cyan
    } #End if

    # Return the raw comparison object for further processing if needed
    return $Comparison
} #End function Compare-ServerServices