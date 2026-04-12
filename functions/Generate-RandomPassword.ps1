<#
.SYNOPSIS
    Generates a random password with customizable length and complexity.

.DESCRIPTION
    The Generate-RandomPassword function creates a cryptographically strong random password
    using the .NET Framework's System.Web.Security.Membership class. The password can be
    customized by specifying the total length and the number of non-alphanumeric characters.
    This is useful for creating secure passwords for user accounts, service accounts, or
    automated password rotation scenarios.

.NOTES
    Author   : adil-o7
    Version  : 1.1.0
    Date     : 2025-12-18

.PARAMETER Length
    Specifies the total length of the generated password.
    Default value is 14 characters.
    The password length should be at least equal to the number of non-alphanumeric characters.

.PARAMETER NumberOfNonAlphaCharacters
    Specifies how many non-alphanumeric characters (special characters) to include in the password.
    Default value is 3 characters.
    Non-alphanumeric characters include symbols like: !@#$%^&*()_+-=[]{}|;:,.<>?

.EXAMPLE
    Generate-RandomPassword
    Generates a 14-character password with 3 non-alphanumeric characters (default settings).
    Output example: "aB3$cD9#eF2@gH"

.EXAMPLE
    Generate-RandomPassword -Length 20
    Generates a 20-character password with 3 non-alphanumeric characters.
    Output example: "aB3$cD9#eF2@gH5!jK7&"

.EXAMPLE
    Generate-RandomPassword -Length 16 -NumberOfNonAlphaCharacters 5
    Generates a 16-character password with 5 non-alphanumeric characters for increased complexity.
    Output example: "aB3$cD9#eF2@gH5!"

.EXAMPLE
    genpwd -Length 15
    Uses the alias 'genpwd' to generate a 15-character password with default special character count.

.OUTPUTS
    System.String
    Returns a randomly generated password as a string.

.NOTES
    Requirements:
    - Requires .NET Framework System.Web assembly
    - The password is generated using cryptographically secure random methods
    - The non-alphanumeric characters are distributed throughout the password, not just at specific positions
#>

function Generate-RandomPassword {
    [CmdletBinding()]
    [Alias("genpwd")]
    [OutputType([string])]

    param(
        [Parameter(Mandatory=$false, Position=0)]
        [ValidateRange(1, 128)]
        [int32]$Length = 14,

        [Parameter(Mandatory=$false, Position=1)]
        [ValidateRange(0, 128)]
        [ValidateScript({
            # Validate that the number of non-alpha characters doesn't exceed the total length
            if ($_ -gt $Length) {
                throw "NumberOfNonAlphaCharacters ($($_)) cannot be greater than Length ($Length)"
            } #End if
            $true
        })]
        [int32]$NumberOfNonAlphaCharacters = 3
    )

    begin {
        Write-Verbose "Starting password generation with Length=$Length and NonAlphaChars=$NumberOfNonAlphaCharacters"
    } #End begin

    process {
        try {
            # Load the System.Web assembly which contains the Membership class
            # This assembly provides the GeneratePassword method for secure password generation
            Add-Type -AssemblyName System.Web

            # Generate the password using the .NET Framework's Membership class
            # This method uses cryptographically strong random number generation
            # Parameters:
            #   1. $Length - Total length of the password to generate
            #   2. $NumberOfNonAlphaCharacters - Minimum number of special characters to include
            $Password = [System.Web.Security.Membership]::GeneratePassword($Length, $NumberOfNonAlphaCharacters)

            # Log verbose information about the generated password (without revealing the actual password)
            Write-Verbose "Password generated successfully with $Length total characters"

            # Return the generated password
            return $Password
        } #End try
        catch {
            # If password generation fails, display an error with details
            Write-Error "Failed to generate password: $_"
            throw
        } #End catch
    } #End process

    end {
        Write-Verbose "Password generation completed"
    } #End end
} #End function Generate-RandomPassword