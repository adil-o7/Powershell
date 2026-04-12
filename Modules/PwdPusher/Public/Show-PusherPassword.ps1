function Show-PusherPassword {
    <#
    .SYNOPSIS
        Show generated password from New-PusherPassword.
    .DESCRIPTION
        Converts a SecureString password to plain text for display.
        Use with caution as this exposes the password in clear text.
    .PARAMETER SecurePassword
        The SecureString password to display
    .EXAMPLE
        Show-PusherPassword -SecurePassword $SecPwd
        Display the password from the SecureString
    .EXAMPLE
        Show-PusherPassword $SecPwd
        Display using positional parameter
    .EXAMPLE
        sppwd $SecPwd
        Display using alias
    .NOTES
        This function should only be used when you need to view or copy the password.
        The password will be visible in plain text.
    #>

    [CmdletBinding()]
    [Alias("sppwd")]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Security.SecureString]$SecurePassword
    )

    process {
        try {
            # Use the modern NetworkCredential method instead of deprecated BSTR
            $credential = New-Object System.Net.NetworkCredential("", $SecurePassword)
            return $credential.Password
        }
        catch {
            Write-Error "Failed to convert SecureString to plain text: $_"
            throw
        }
    }
} #End function 