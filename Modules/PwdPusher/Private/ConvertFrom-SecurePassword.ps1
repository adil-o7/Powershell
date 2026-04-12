function ConvertFrom-SecurePassword {
    <#
    .SYNOPSIS
        Converts a SecureString to plain text string.
    .DESCRIPTION
        Safely converts a SecureString to plain text for use in API calls.
        Uses modern .NET methods with proper memory cleanup.
    .PARAMETER SecurePassword
        The SecureString to convert to plain text.
    .EXAMPLE
        $plainText = ConvertFrom-SecurePassword -SecurePassword $secureString
    .NOTES
        This function should only be used when absolutely necessary (e.g., API calls).
        The plain text password should be handled carefully and cleared from memory as soon as possible.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Security.SecureString]$SecurePassword
    )

    process {
        try {
            # Modern approach using NetworkCredential (more secure than BSTR)
            $credential = New-Object System.Net.NetworkCredential("", $SecurePassword)
            return $credential.Password
        }
        catch {
            Write-Error "Failed to convert SecureString: $_"
            throw
        }
    }
}
