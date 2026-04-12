<#
.SYNOPSIS
    Queries and retrieves a list of open files on a remote or local computer.

.DESCRIPTION
    The Get-OpenFile function uses the Windows 'openfiles' command-line utility to query
    and retrieve information about files that are currently open on a specified computer.
    This is useful for troubleshooting file locks, identifying which users have files open,
    or auditing file access on remote systems.

    The function returns structured PowerShell objects containing details about each open file,
    including the hostname, file ID, accessed by (username), file type, number of locks, and
    the open mode.

.NOTES
    Author   : adil-o7
    Version  : 1.0.0
    Date     : 2025-12-18

.PARAMETER ComputerName
    The name or IP address of the computer to query for open files.
    This parameter is mandatory and can accept input from the pipeline.
    Examples: "SERVER01", "192.168.1.100", "FILESERVER.domain.com"

.EXAMPLE
    Get-OpenFile -ComputerName "SERVER01"
    Retrieves all open files on the computer named SERVER01.

.EXAMPLE
    "SERVER01", "SERVER02", "SERVER03" | Get-OpenFile
    Uses pipeline input to query open files on multiple servers.
    Useful for auditing multiple servers in a batch operation.

.EXAMPLE
    Get-OpenFile -ComputerName "FILESERVER" | Where-Object { $_.'Accessed By' -like "*jdoe*" }
    Retrieves open files on FILESERVER and filters to show only files accessed by user 'jdoe'.

.EXAMPLE
    Get-OpenFile -ComputerName "SERVER01" | Export-Csv -Path "C:\Reports\OpenFiles.csv" -NoTypeInformation
    Queries open files and exports the results to a CSV file for reporting purposes.

.EXAMPLE
    $OpenFiles = Get-OpenFile -ComputerName "FILESERVER"
    $OpenFiles | Format-Table -AutoSize
    Retrieves open files and displays them in a formatted table.

.OUTPUTS
    System.Management.Automation.PSCustomObject
    Returns custom objects with properties for each open file including:
    - Hostname: The computer name
    - ID: Unique identifier for the open file
    - Accessed By: Username accessing the file
    - Type: Type of file access
    - # Locks: Number of locks on the file
    - Open Mode: The mode in which the file is opened

.NOTES
    Requirements:
    - Administrative privileges may be required depending on the target computer's configuration
    - Remote computer must be accessible over the network
    - Windows 'openfiles' utility must be available (included in Windows by default)
    - WMI/RPC ports must be open if querying remote computers
    - The openfiles service must be running on the target computer

    Known Limitations:
    - Some systems may require the "Maintain Objects List" policy to be enabled
    - Results may vary depending on the Windows version and security settings
#>

function Get-OpenFile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = "Enter the computer name or IP address to query for open files"
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("CN", "Computer", "Server")]
        [string]$ComputerName
    )

    begin {
        # Log the start of the function execution
        Write-Verbose "Starting Get-OpenFile function"
    } #End begin

    process {
        try {
            # Log which computer is being queried
            Write-Verbose "Querying open files on computer: $ComputerName"

            # Execute the 'openfiles' command-line utility to query open files
            # Parameters explained:
            #   /query      - Query mode to retrieve open files
            #   /s          - Specifies the remote computer name or IP address
            #   /fo csv     - Format output as CSV (Comma-Separated Values) for easy parsing
            #   /V          - Verbose mode, provides additional details about open files
            $OpenFiles = openfiles.exe /query /s $ComputerName /fo csv /V |
                # Filter the output to include only lines containing CSV data
                # The -match operator with '","' pattern excludes header/footer text and keeps only valid CSV rows
                Where-Object { $_ -match '","' } |
                # Convert the filtered CSV text data into PowerShell objects
                # This makes the data easy to work with using PowerShell cmdlets and pipeline operations
                ConvertFrom-Csv

            # Check if any open files were found
            if ($OpenFiles) {
                Write-Verbose "Successfully retrieved $($OpenFiles.Count) open file(s) from $ComputerName"
            } #End if
            else {
                Write-Verbose "No open files found on $ComputerName"
            } #End else

            # Return the structured open files data
            return $OpenFiles
        } #End try
        catch {
            # If the query fails, display a detailed error message
            # Common causes: Computer not reachable, access denied, or openfiles service not enabled
            Write-Error "Failed to query open files on $ComputerName. Error: $_"

            # Additional verbose error information for troubleshooting
            Write-Verbose "Possible causes: Network connectivity issues, insufficient permissions, or openfiles tracking not enabled on target"
        } #End catch
    } #End process

    end {
        Write-Verbose "Get-OpenFile function completed"
    } #End end
} #End function Get-OpenFile