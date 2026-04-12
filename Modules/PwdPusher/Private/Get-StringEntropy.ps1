function Get-StringEntropy {
    <#
    .SYNOPSIS
        Calculates the Shannon entropy of a string.
    .DESCRIPTION
        Computes the information entropy (Shannon entropy) of a string to measure its randomness.
        Higher entropy values indicate more randomness/unpredictability.
        The maximum entropy for ASCII is ~8 bits per byte.
    .PARAMETER Val
        The string to calculate entropy for.
    .EXAMPLE
        Get-StringEntropy -Val "password123"
        Returns the entropy value for the string "password123"
    .EXAMPLE
        "MyP@ssw0rd!" | Get-StringEntropy
        Calculates entropy using pipeline input
    .OUTPUTS
        System.Double - The calculated entropy value in bits per byte
    .NOTES
        Used internally to validate password strength in New-PusherPassword.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)][ValidateNotNullOrEmpty()][string]$Val
    )
 
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Val)

    $FrequencyTable = @{}
    foreach ($Byte in $Bytes){
        $FrequencyTable[$Byte]++
    }
    $Entropy = 0.0
 
    foreach ($Byte in 0..255){
        $ByteProbability = ([Double]$FrequencyTable[[Byte]$Byte])/$Bytes.Length
        if ($ByteProbability -gt 0){
            $Entropy += -$ByteProbability * [Math]::Log($ByteProbability, 2)
        }
    }
    return $Entropy
}