# PwdPusher Module - Publishing Passwords Examples

# Import the module
Import-Module PwdPusher

# ====================================
# Example 1: Generate and publish a password to pwpush.com
# ====================================
Write-Host "`n--- Example 1: Generate and publish to pwpush.com ---" -ForegroundColor Green
$password = New-PusherPassword -Length 16
try {
    $url = Publish-PusherPassword -Password $password
    Write-Host "Password URL: $url"
    Write-Host "Share this URL to securely transmit the password"
} catch {
    Write-Host "Note: Publishing requires internet connection to pwpush.com" -ForegroundColor Yellow
}

# ====================================
# Example 2: Publish with custom expiration
# ====================================
Write-Host "`n--- Example 2: Publish with custom expiration (3 days, 5 views) ---" -ForegroundColor Green
$password = New-PusherPassword
try {
    $url = Publish-PusherPassword -Password $password -Days 3 -Views 5
    Write-Host "Password URL (expires in 3 days or 5 views): $url"
} catch {
    Write-Host "Note: Publishing requires internet connection" -ForegroundColor Yellow
}

# ====================================
# Example 3: Publish with KillSwitch enabled
# ====================================
Write-Host "`n--- Example 3: Publish with delete capability ---" -ForegroundColor Green
$password = New-PusherPassword
try {
    $url = Publish-PusherPassword -Password $password -KillSwitch
    Write-Host "Password URL (can be deleted by viewer): $url"
} catch {
    Write-Host "Note: Publishing requires internet connection" -ForegroundColor Yellow
}

# ====================================
# Example 4: Publish to private instance (HTTP)
# ====================================
Write-Host "`n--- Example 4: Publish to local/private instance ---" -ForegroundColor Green
$password = New-PusherPassword
try {
    # For local development/testing instances
    $url = Publish-PusherPassword -Password $password -Server "localhost:5100" -UseHttp
    Write-Host "Password URL (local instance): $url"
} catch {
    Write-Host "Note: Requires local Password Pusher instance running" -ForegroundColor Yellow
}

# ====================================
# Example 5: Publish with memory cleanup
# ====================================
Write-Host "`n--- Example 5: Publish and wipe password from memory ---" -ForegroundColor Green
$password = New-PusherPassword
Write-Host "Before: Password object exists"
try {
    $url = Publish-PusherPassword -Password $password -Wipe -Verbose
    Write-Host "After: Password has been disposed from memory"
} catch {
    Write-Host "Note: Publishing requires internet connection" -ForegroundColor Yellow
}

# ====================================
# Example 6: Complete workflow with pipeline
# ====================================
Write-Host "`n--- Example 6: Complete workflow using pipeline ---" -ForegroundColor Green
try {
    $url = New-PusherPassword -Length 20 | Publish-PusherPassword -Days 1 -Views 1
    Write-Host "One-time password URL: $url"
} catch {
    Write-Host "Note: Publishing requires internet connection" -ForegroundColor Yellow
}

# ====================================
# Example 7: Using aliases
# ====================================
Write-Host "`n--- Example 7: Using aliases for quick commands ---" -ForegroundColor Green
try {
    $url = nppwd -n 16 | pppwd -d 2 -v 3
    Write-Host "Quick password URL: $url"
} catch {
    Write-Host "Note: Publishing requires internet connection" -ForegroundColor Yellow
}

# ====================================
# Example 8: Publish with verbose output
# ====================================
Write-Host "`n--- Example 8: Publish with verbose logging ---" -ForegroundColor Green
$password = New-PusherPassword
try {
    $url = Publish-PusherPassword -Password $password -Verbose
    Write-Host "Password published successfully"
} catch {
    Write-Host "Note: Publishing requires internet connection" -ForegroundColor Yellow
}

# ====================================
# Example 9: Secure workflow for team password sharing
# ====================================
Write-Host "`n--- Example 9: Team password sharing workflow ---" -ForegroundColor Green
Write-Host "Use case: Share a temporary password with a colleague"
$teamPassword = New-PusherPassword -Length 16 -ExcludeHard
Write-Host "Generated password: $(Show-PusherPassword $teamPassword)"
try {
    $shareUrl = Publish-PusherPassword -Password $teamPassword -Days 1 -Views 2 -KillSwitch
    Write-Host "Share this URL: $shareUrl"
    Write-Host "Expires: 24 hours or 2 views (whichever comes first)"
    Write-Host "Recipient can delete after viewing"
} catch {
    Write-Host "Note: Publishing requires internet connection" -ForegroundColor Yellow
}
