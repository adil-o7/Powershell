function Get-DnsParseLog
{
    <#
    .SYNOPSIS
    Parses a Windows DNS Debug log file into structured PowerShell objects.

    .DESCRIPTION
    The Get-DnsParseLog cmdlet parses Windows DNS Debug log files and converts them into
    structured PowerShell objects for easier analysis and manipulation. The cmdlet supports
    both file paths and piped DNS log data, making it flexible for various scenarios.

    The parsed output includes:
    - DateTime of the DNS query/response
    - Query or Response indication
    - Client IP address
    - Send/Receive direction
    - Protocol (UDP/TCP)
    - DNS record type
    - Query details

    .PARAMETER LogFile
    Specifies the path to the DNS debug log file to parse. This parameter is mandatory.
    The parameter accepts pipeline input and supports both file paths and raw log data.

    .EXAMPLE
    Get-DnsParseLog -LogFile "C:\Logs\dns.log" | Format-Table

    Parses the DNS debug log file and displays the results in a table format.

    .EXAMPLE
    Get-DnsParseLog -LogFile "C:\Logs\dns.log" | Export-Csv "C:\Reports\ParsedDns.csv" -NoTypeInformation

    Parses the DNS debug log file and exports the results to a CSV file.

    .EXAMPLE
    Get-ChildItem "C:\Logs\*.log" | ForEach-Object { Get-DnsParseLog -LogFile $_.FullName }

    Parses multiple DNS log files from a directory.

    .EXAMPLE
    Get-DnsParseLog -LogFile "C:\Logs\dns.log" | Where-Object RecordType -eq "A"

    Parses the log and filters only A record queries.

    .NOTES
    Author: adil-o7
    Version: 1.1.0
    Date: 2025-12-24

    The cmdlet expects DNS debug logs from Windows Server DNS with the standard format.
    Lines that don't match the expected pattern are discarded.
    Use -Debug parameter to see detailed processing statistics.

    .LINK
    https://github.com/SupraOva/Powershell
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to the DNS debug log file or raw log data"
        )]
        [ValidateNotNullOrEmpty()]
        [String]$LogFile
    )

    BEGIN
    {
        Write-Debug "BEGIN: Initializing settings"

        # Statistics counters
        $nTotalSuccess = 0      # Number of lines successfully parsed and saved
        $nTotalFailed = 0       # Number of lines that matched pattern but failed to parse
        $nTotalDiscarded = 0    # Number of lines that didn't match the pattern
        $nTotalEvaluated = 0    # Total number of lines evaluated

        # Data sample from Windows Server 2012 R2, used for dnspattern below
        # 05/03/2019 16:05:31 0F9C PACKET  000000082A8141F0 UDP Snd 10.202.168.232  c1f8 R Q [8081   DR  NOERROR] A      (3)api(11)blahblah(3)com(0)

        $dnspattern = "^(?<log_date>([0-9]{1,2}.[0-9]{1,2}.[0-9]{2,4}|[0-9]{2,4}-[0-9]{2}-[0-9]{2})\s*[0-9: ]{7,8}\s*(PM|AM)?) ([0-9A-Z]{3,4} PACKET\s*[0-9A-Za-z]{8,16}) (?<protocol>UDP|TCP) (?<way>Snd|Rcv) (?<ip>[0-9.]{7,15}|[0-9a-f:]{3,50})\s*([0-9a-z]{4}) (?<QR>.) (?<OpCode>.) \[.*\] (?<QueryType>.*) (?<query>\(.*)"

        $returnselect = @{label = "DateTime"; expression = { [datetime]::ParseExact($match.Groups['log_date'].value.trim(), "dd/MM/yyyy HH:mm:ss", $null) } },
        @{label = "Query/Response"; expression = { switch ($match.Groups['QR'].value.trim()) { "" { 'Query' }; "R" { 'Response' } } } },
        @{label = "Client"; expression = { [ipaddress] ($match.Groups['ip'].value.trim()).trim() } },
        @{label = "SendReceive"; expression = { $match.Groups['way'].value.trim() } },
        @{label = "Protocol"; expression = { $match.Groups['protocol'].value.trim() } },
        @{label = "RecordType"; expression = { $match.Groups['QueryType'].value.trim() } },
        @{label = "Query"; expression = { $match.Groups['query'].value.trim() -replace "(`\(.*)", "`$1" -replace "`\(.*?`\)", "." -replace "^.", "" } }

        Write-Debug "BEGIN: Initializing Settings - DONE"
    } # End BEGIN

    PROCESS
    {
        Write-Debug "PROCESS: Starting to process file: $LogFile"

        try
        {
            Get-DnsLogLines -LogFile $LogFile | ForEach-Object {

                # Increment overall total
                $nTotalEvaluated++

                $match = [regex]::match($_, $dnspattern)

                if ($match.Success)
                {
                    try
                    {
                        $true | Select-Object $returnselect
                        $nTotalSuccess++
                    } # End try
                    catch
                    {
                        Write-Debug "Failed to process row: $_"
                        Write-Warning "Failed to parse matching line: $($_.Exception.Message)"
                        $nTotalFailed++
                    } # End catch
                } # End if
                else
                {
                    $nTotalDiscarded++
                } # End else

            } # End ForEach-Object
        } # End try
        catch
        {
            Write-Error "Error processing DNS log: $($_.Exception.Message)"
            throw
        } # End catch

        Write-Debug "PROCESS: Finished processing file: $LogFile"

    } # End PROCESS

    END
    {
        # Print summary statistics
        Write-Debug "=== Summary ==="
        Write-Debug "Total lines in the file ($LogFile): $nTotalEvaluated"
        Write-Debug "Records processed successfully: $nTotalSuccess"
        Write-Debug "Records processed with failure: $nTotalFailed"
        Write-Debug "Records discarded as not relevant: $nTotalDiscarded"
    } # End END

} # End function Get-DnsParseLog

function Get-DnsLogLines
{
    <#
    .SYNOPSIS
    Helper function to retrieve DNS log lines from a file or raw input.

    .DESCRIPTION
    The Get-DnsLogLines function is a helper function that retrieves DNS log lines
    from either a file path or raw log data. It validates the input and returns
    the log lines for processing.

    .PARAMETER LogFile
    Specifies the path to the DNS log file or raw log data.

    .OUTPUTS
    System.String
    Returns individual log lines as strings.

    .NOTES
    This is a private helper function for Get-DnsParseLog.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$LogFile
    )

    # Test if the parameter is a valid file path
    $PathCorrect = try
    {
        Test-Path $LogFile -ErrorAction Stop
    } # End try
    catch
    {
        $false
    } # End catch

    # If input looks like raw log data (starts with digits) and is not an EVENT line
    if ($LogFile -match "^\d\d" -and $LogFile -notlike "*EVENT*" -and $PathCorrect -ne $true)
    {
        Write-Output $LogFile
    } # End if
    elseif ($PathCorrect -eq $true)
    {
        try
        {
            Get-Content $LogFile -ErrorAction Stop | ForEach-Object { $_ }
        } # End try
        catch
        {
            Write-Error "Failed to read DNS log file '$LogFile': $($_.Exception.Message)"
            throw
        } # End catch
    } # End elseif
    else
    {
        Write-Warning "Invalid DNS log path or data: $LogFile"
    } # End else

} # End function Get-DnsLogLines
