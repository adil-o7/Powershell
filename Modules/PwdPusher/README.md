# PwdPusher [![awesome](https://github.com/sindresorhus/awesome/blob/main/media/badge-flat.svg)](https://github.com/sindresorhus/awesome/blob/main/media/)

PowerShell module for [Password Pusher](https://github.com/pglombardo/PasswordPusher) - an open-source application to securely communicate passwords over the web.

Fork from [pwposh](https://github.com/pgarm/pwposh) with significant enhancements.

## Overview

PwdPusher provides a secure way to generate strong passwords and share them via time-limited, view-limited URLs. Links automatically expire after a certain number of views and/or time has passed, ensuring your sensitive data doesn't persist indefinitely.

## Features

- **Secure Password Generation**: Generate cryptographically strong passwords with customizable complexity
- **SecureString Support**: All passwords are handled as SecureStrings for enhanced security
- **Flexible Expiration**: Set expiration by days (1-90) and/or views (1-100)
- **HTTPS by Default**: Secure transmission to Password Pusher services
- **Custom Instances**: Support for public pwpush.com or private instances
- **Memory Protection**: Optional password disposal after publishing
- **Pipeline Support**: Full PowerShell pipeline integration
- **Comprehensive Testing**: Pester tests included

## Installation

### From PowerShell Gallery (Recommended)
```powershell
Install-Module -Name PwdPusher -Scope CurrentUser
```

### Manual Installation
```powershell
# Clone or download this repository
git clone https://github.com/SupraOva/Powershell.git
cd Powershell/PwdPusher
Import-Module .\PwdPusher.psd1
```

## Functions

### New-PusherPassword
Generates a random password as a SecureString with extensive configuration options.

**Parameters:**
- `-Length`: Password length (4-64 characters, default: 8)
- `-Capitals`: Minimum number of uppercase letters
- `-Digits`: Minimum number of digits
- `-Symbols`: Minimum number of symbols
- `-Lowers`: Minimum number of lowercase letters
- `-Simple`: Generate lowercase-only password
- `-Pin`: Generate numeric-only PIN
- `-ExcludeHard`: Exclude hard-to-read characters
- `-ExcludeSoft`: Exclude commonly problematic characters
- `-ExcludeChars`: Exclude custom characters
- `-Entropy`: Minimum entropy value (2-6, default: 3)

**Examples:**
```powershell
# Basic 8-character password
$pwd = New-PusherPassword

# 16-character complex password
$pwd = New-PusherPassword -Length 16

# Simple lowercase password
$pwd = New-PusherPassword -Simple -Length 12

# 6-digit PIN
$pin = New-PusherPassword -Pin -Length 6

# Password excluding ambiguous characters
$pwd = New-PusherPassword -ExcludeHard -Length 16
```

### Publish-PusherPassword
Pushes a password to pwpush.com or a private Password Pusher instance and returns a shareable URL.

**Parameters:**
- `-Password`: SecureString password to publish (required)
- `-Days`: Days until expiration (1-90, default: 7)
- `-Views`: Views until expiration (1-100, default: 7)
- `-Server`: Server FQDN (default: "pwpush.com")
- `-KillSwitch`: Allow viewers to delete the link
- `-FirstView`: Enable first-view experience
- `-Wipe`: Dispose password from memory after publishing
- `-UseHttp`: Use HTTP instead of HTTPS (for local dev only)

**Examples:**
```powershell
# Publish to pwpush.com with defaults
$url = Publish-PusherPassword -Password $pwd

# Custom expiration
$url = Publish-PusherPassword -Password $pwd -Days 3 -Views 5

# Publish to private instance
$url = Publish-PusherPassword -Password $pwd -Server "localhost:5100" -UseHttp

# One-time link with pipeline
$url = New-PusherPassword | Publish-PusherPassword -Days 1 -Views 1
```

### Show-PusherPassword
Displays a SecureString password in plain text.

**Parameters:**
- `-SecurePassword`: The SecureString to display (required)

**Examples:**
```powershell
# Display password
Show-PusherPassword -SecurePassword $pwd

# Using pipeline
$pwd | Show-PusherPassword
```

## Aliases

- `nppwd` → `New-PusherPassword`
- `pppwd` → `Publish-PusherPassword`
- `sppwd` → `Show-PusherPassword`

## Quick Start

```powershell
# Generate and publish a password in one line
$url = New-PusherPassword -Length 16 | Publish-PusherPassword -Days 1 -Views 1
Write-Host "Share this URL: $url"

# Or using aliases
$url = nppwd -n 16 | pppwd -d 1 -v 1
```

## Examples

See the `Examples/` directory for comprehensive usage examples:
- `BasicUsage.ps1` - Password generation examples
- `PublishingPasswords.ps1` - Publishing and sharing examples

## Testing

Run Pester tests to validate functionality:

```powershell
# Install Pester if needed
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run tests
Invoke-Pester -Path .\Tests\PwdPusher.Tests.ps1
```

## Security Considerations

1. **SecureString Usage**: Always use SecureString for password handling
2. **HTTPS Default**: Module uses HTTPS by default for secure transmission
3. **Memory Management**: Use `-Wipe` parameter to dispose passwords from memory
4. **Expiration**: Always set appropriate expiration limits
5. **Private Instances**: Use private instances for sensitive organizational passwords

## Requirements

- PowerShell 5.1 or higher
- Internet connection (for publishing to pwpush.com)
- Password Pusher instance (public or private)

## Version History

### v0.4.0 (Current)
- Added missing `ConvertFrom-SecurePassword` helper function
- Fixed manifest description syntax error
- Improved SecureString handling (deprecated BSTR methods)
- Fixed HTTP/HTTPS protocol consistency
- Added comprehensive parameter validation
- Enhanced error handling for network failures
- Improved manifest configuration with proper exports
- Added PowerShell Gallery tags
- Created Pester test suite
- Added usage examples
- Fixed typos and improved documentation
- Added `-UseHttp` parameter for local development
- Default server now set to "pwpush.com"

### v0.3.0
- Previous release (see git history)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

See [LICENSE](LICENSE) file for details.

## Credits

- Original author: Adil OSMAN
- Forked from: [pwposh](https://github.com/pgarm/pwposh)
- Password Pusher: [https://github.com/pglombardo/PasswordPusher](https://github.com/pglombardo/PasswordPusher)

## Links

- **Project Repository**: [https://github.com/SupraOva/Powershell/tree/master/PwdPusher](https://github.com/SupraOva/Powershell/tree/master/PwdPusher)
- **Password Pusher**: [https://pwpush.com](https://pwpush.com)
- **Issues**: [https://github.com/SupraOva/Powershell/issues](https://github.com/SupraOva/Powershell/issues)
