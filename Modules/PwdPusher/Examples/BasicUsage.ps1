# PwdPusher Module - Basic Usage Examples

# Import the module
Import-Module PwdPusher

# ====================================
# Example 1: Generate a basic password
# ====================================
Write-Host "`n--- Example 1: Generate a basic password ---" -ForegroundColor Green
$password = New-PusherPassword
Write-Host "Generated SecureString password (use Show-PusherPassword to view)"

# ====================================
# Example 2: View the generated password
# ====================================
Write-Host "`n--- Example 2: View the generated password ---" -ForegroundColor Green
$plainText = Show-PusherPassword -SecurePassword $password
Write-Host "Password: $plainText"

# ====================================
# Example 3: Generate custom length password
# ====================================
Write-Host "`n--- Example 3: Generate 16-character password ---" -ForegroundColor Green
$longPassword = New-PusherPassword -Length 16
Write-Host "Password: $(Show-PusherPassword $longPassword)"

# ====================================
# Example 4: Generate a simple password (lowercase only)
# ====================================
Write-Host "`n--- Example 4: Generate simple password (lowercase only) ---" -ForegroundColor Green
$simplePassword = New-PusherPassword -Simple -Length 12
Write-Host "Password: $(Show-PusherPassword $simplePassword)"

# ====================================
# Example 5: Generate a PIN (numbers only)
# ====================================
Write-Host "`n--- Example 5: Generate 6-digit PIN ---" -ForegroundColor Green
$pin = New-PusherPassword -Pin -Length 6
Write-Host "PIN: $(Show-PusherPassword $pin)"

# ====================================
# Example 6: Generate password with specific complexity
# ====================================
Write-Host "`n--- Example 6: Generate password with specific requirements ---" -ForegroundColor Green
$complexPassword = New-PusherPassword -Length 16 -Capitals 3 -Digits 3 -Symbols 2
Write-Host "Password: $(Show-PusherPassword $complexPassword)"

# ====================================
# Example 7: Generate password excluding ambiguous characters
# ====================================
Write-Host "`n--- Example 7: Generate password excluding hard-to-read characters ---" -ForegroundColor Green
$readablePassword = New-PusherPassword -Length 12 -ExcludeHard
Write-Host "Password: $(Show-PusherPassword $readablePassword)"

# ====================================
# Example 8: Generate password excluding specific characters
# ====================================
Write-Host "`n--- Example 8: Generate password without vowels ---" -ForegroundColor Green
$noVowelsPassword = New-PusherPassword -Length 12 -ExcludeChars "aeiouAEIOU"
Write-Host "Password: $(Show-PusherPassword $noVowelsPassword)"

# ====================================
# Example 9: Use aliases for shorter commands
# ====================================
Write-Host "`n--- Example 9: Using aliases ---" -ForegroundColor Green
$pwd1 = nppwd -n 10  # New-PusherPassword alias
Write-Host "Password: $(sppwd $pwd1)"  # Show-PusherPassword alias

# ====================================
# Example 10: Pipeline usage
# ====================================
Write-Host "`n--- Example 10: Pipeline usage ---" -ForegroundColor Green
$pipelinePassword = New-PusherPassword -Length 14 | Show-PusherPassword
Write-Host "Password: $pipelinePassword"
