function Get-Timestamp {
    <#
    .SYNOPSIS
        Generates timestamps in various formats.

    .DESCRIPTION
        The Get-Timestamp function returns the current date and time in various formats.
        Supports custom formatting, UTC conversion, Unix timestamps, and different standard formats.

    .NOTES
        Author: adil-o7
        Version: 1.0.2
        Date: 2026-01-01

    .PARAMETER Format
        Specifies the format of the timestamp. Valid options:
        - Default: yyyy-MM-dd HH:mm:ss (standard readable format)
        - ISO8601: ISO 8601 format (yyyy-MM-ddTHH:mm:ss)
        - Unix: Unix epoch timestamp (seconds since 1970-01-01)
        - UnixMs: Unix epoch in milliseconds
        - Short: Short date and time (MM/dd/yyyy HH:mm)
        - Long: Long date and time format (dddd, MMMM dd, yyyy h:mm:ss tt)
        - Log: Log-friendly format with timestamp (yyyyMMdd_HHmmss)
        - File: File-friendly date-only format (yyyyMMdd)
        - Custom: Use with -CustomFormat parameter

    .PARAMETER CustomFormat
        Custom DateTime format string. Used when -Format is set to 'Custom'.
        See https://docs.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings

    .PARAMETER UTC
        Returns the timestamp in UTC instead of local time.

    .PARAMETER AddSeconds
        Add specified number of seconds to the current time.

    .PARAMETER AddMinutes
        Add specified number of minutes to the current time.

    .PARAMETER AddHours
        Add specified number of hours to the current time.

    .PARAMETER AddDays
        Add specified number of days to the current time.

    .PARAMETER DateTime
        Use a specific DateTime object instead of the current time.

    .EXAMPLE
        Get-Timestamp
        Returns: 2025-11-22 10:30:45

    .EXAMPLE
        Get-Timestamp -Format ISO8601
        Returns: 2025-11-22T10:30:45

    .EXAMPLE
        Get-Timestamp -Format Unix
        Returns: 1732273845

    .EXAMPLE
        Get-Timestamp -Format Log
        Returns: 20251122_103045
        Description: Perfect for log filenames or timestamped entries.

    .EXAMPLE
        Get-Timestamp -Format File
        Returns: 20251122
        Description: Date-only format suitable for file naming.

    .EXAMPLE
        Get-Timestamp -UTC
        Returns the current UTC timestamp in default format.

    .EXAMPLE
        Get-Timestamp -Format Custom -CustomFormat "yyyy-MM-dd"
        Returns: 2025-11-22

    .EXAMPLE
        Get-Timestamp -AddDays 7 -Format ISO8601
        Returns the timestamp for 7 days from now.

    .EXAMPLE
        Get-Date | Get-Timestamp -Format Unix
        Converts a DateTime object to Unix timestamp via pipeline.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Standard')]
    [OutputType([string], [int64])]
    param (
        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'Custom')]
        [ValidateSet('Default', 'ISO8601', 'Unix', 'UnixMs', 'Short', 'Long', 'Log', 'File', 'Custom')]
        [string]$Format = 'Default',

        [Parameter(ParameterSetName = 'Custom', Mandatory = $false)]
        [string]$CustomFormat,

        [Parameter()]
        [switch]$UTC,

        [Parameter()]
        [int]$AddSeconds = 0,

        [Parameter()]
        [int]$AddMinutes = 0,

        [Parameter()]
        [int]$AddHours = 0,

        [Parameter()]
        [int]$AddDays = 0,

        [Parameter(ValueFromPipeline = $true)]
        [datetime]$DateTime
    )

    begin {
        Write-Verbose "Get-Timestamp: Starting timestamp generation"
    } #End begin

    process {
        try {
            # Determine the base time source (provided DateTime, UTC, or local time)
            if ($PSBoundParameters.ContainsKey('DateTime')) {
                # Use the DateTime object passed via pipeline or parameter
                $BaseTime = $DateTime
                Write-Verbose "Using provided DateTime: $BaseTime"
            } #End if
            elseif ($UTC) {
                # Get current UTC time
                $BaseTime = [datetime]::UtcNow
                Write-Verbose "Using UTC time: $BaseTime"
            } #End elseif
            else {
                # Default to local system time
                $BaseTime = Get-Date
                Write-Verbose "Using local time: $BaseTime"
            } #End else

            # Apply time offset adjustments (supports negative values for past times)
            if ($AddSeconds -ne 0) {
                $BaseTime = $BaseTime.AddSeconds($AddSeconds)
                Write-Verbose "Added $AddSeconds seconds"
            } #End if
            if ($AddMinutes -ne 0) {
                $BaseTime = $BaseTime.AddMinutes($AddMinutes)
                Write-Verbose "Added $AddMinutes minutes"
            } #End if
            if ($AddHours -ne 0) {
                $BaseTime = $BaseTime.AddHours($AddHours)
                Write-Verbose "Added $AddHours hours"
            } #End if
            if ($AddDays -ne 0) {
                $BaseTime = $BaseTime.AddDays($AddDays)
                Write-Verbose "Added $AddDays days"
            } #End if

            # Convert the timestamp to the requested format
            $result = switch ($Format) {
                'Default' {
                    # Standard readable format: 2025-11-22 10:30:45
                    $BaseTime.ToString('yyyy-MM-dd HH:mm:ss')
                }
                'ISO8601' {
                    # ISO 8601 standard format: 2025-11-22T10:30:45
                    $BaseTime.ToString('yyyy-MM-ddTHH:mm:ss')
                }
                'Unix' {
                    # Unix epoch timestamp (seconds since Jan 1, 1970)
                    [int64]([datetime]$BaseTime - [datetime]'1970-01-01').TotalSeconds
                }
                'UnixMs' {
                    # Unix epoch in milliseconds for high-precision timestamps
                    [int64]([datetime]$BaseTime - [datetime]'1970-01-01').TotalMilliseconds
                }
                'Short' {
                    # Compact format: 11/22/2025 10:30
                    $BaseTime.ToString('MM/dd/yyyy HH:mm')
                }
                'Long' {
                    # Fully spelled out format: Friday, November 22, 2025 10:30:45 AM
                    $BaseTime.ToString('dddd, MMMM dd, yyyy h:mm:ss tt')
                }
                'Log' {
                    # Log-friendly format with no special characters: 20251122_103045
                    $BaseTime.ToString('yyyyMMdd_HHmmss')
                }
                'File' {
                    # Simple date format for file naming: 20251122
                    $BaseTime.ToString('yyyyMMdd')
                }
                'Custom' {
                    # User-defined custom format using .NET format strings
                    if ([string]::IsNullOrWhiteSpace($CustomFormat)) {
                        Write-Error "CustomFormat parameter is required when Format is 'Custom'"
                        return
                    } #End if
                    $BaseTime.ToString($CustomFormat)
                }
            } #End switch

            Write-Verbose "Generated timestamp: $result (Format: $Format)"
            return $result
        } #End try
        catch {
            Write-Error "Failed to generate timestamp: $_"
            throw
        } #End catch
    } #End process

    end {
        Write-Verbose "Get-Timestamp: Completed"
    } #End end
} #End function Get-Timestamp
