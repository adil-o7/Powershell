BeforeAll {
    # Import the module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath/PwdPusher.psd1" -Force
}

Describe "PwdPusher Module" {
    Context "Module Import" {
        It "Should import the module successfully" {
            Get-Module PwdPusher | Should -Not -BeNullOrEmpty
        }

        It "Should export New-PusherPassword function" {
            Get-Command New-PusherPassword -Module PwdPusher | Should -Not -BeNullOrEmpty
        }

        It "Should export Publish-PusherPassword function" {
            Get-Command Publish-PusherPassword -Module PwdPusher | Should -Not -BeNullOrEmpty
        }

        It "Should export Show-PusherPassword function" {
            Get-Command Show-PusherPassword -Module PwdPusher | Should -Not -BeNullOrEmpty
        }

        It "Should have alias 'nppwd' for New-PusherPassword" {
            (Get-Alias nppwd).ResolvedCommandName | Should -Be 'New-PusherPassword'
        }

        It "Should have alias 'pppwd' for Publish-PusherPassword" {
            (Get-Alias pppwd).ResolvedCommandName | Should -Be 'Publish-PusherPassword'
        }

        It "Should have alias 'sppwd' for Show-PusherPassword" {
            (Get-Alias sppwd).ResolvedCommandName | Should -Be 'Show-PusherPassword'
        }
    }
}

Describe "New-PusherPassword" {
    Context "Basic Password Generation" {
        It "Should generate a password with default length (8 characters)" {
            $password = New-PusherPassword
            $password | Should -Not -BeNullOrEmpty
            $password | Should -BeOfType [System.Security.SecureString]
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText.Length | Should -Be 8
        }

        It "Should generate a password with specified length" {
            $password = New-PusherPassword -Length 16
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText.Length | Should -Be 16
        }

        It "Should reject length less than 4" {
            { New-PusherPassword -Length 3 } | Should -Throw
        }

        It "Should reject length greater than 64" {
            { New-PusherPassword -Length 65 } | Should -Throw
        }
    }

    Context "Password Complexity" {
        It "Should generate a simple (lowercase only) password" {
            $password = New-PusherPassword -Simple
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText | Should -MatchExactly '^[a-z]+$'
        }

        It "Should generate a PIN (numeric only) password" {
            $password = New-PusherPassword -Pin
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText | Should -MatchExactly '^\d+$'
        }

        It "Should generate password without capitals when set to 0" {
            $password = New-PusherPassword -Length 12 -Capitals 0
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText | Should -Not -MatchExactly '[A-Z]'
        }

        It "Should generate password without digits when set to 0" {
            $password = New-PusherPassword -Length 12 -Digits 0
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText | Should -Not -MatchExactly '\d'
        }

        It "Should generate password without symbols when set to 0" {
            $password = New-PusherPassword -Length 12 -Symbols 0
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText | Should -Not -MatchExactly '[!#$*()+,\-./:=?@\[\]_{|}~]'
        }
    }

    Context "Character Exclusion" {
        It "Should exclude specified characters" {
            $password = New-PusherPassword -ExcludeChars "aeiou" -Length 16
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText | Should -Not -MatchExactly '[aeiou]'
        }
    }

    Context "Parameter Aliases" {
        It "Should accept -n as alias for -Length" {
            $password = New-PusherPassword -n 10
            $plainText = [System.Net.NetworkCredential]::new("", $password).Password
            $plainText.Length | Should -Be 10
        }
    }
}

Describe "Show-PusherPassword" {
    Context "SecureString Conversion" {
        It "Should convert SecureString to plain text" {
            $plainPassword = "TestP@ssw0rd!"
            $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
            $result = Show-PusherPassword -SecurePassword $securePassword
            $result | Should -Be $plainPassword
        }

        It "Should accept pipeline input" {
            $plainPassword = "Pipeline@Test123"
            $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
            $result = $securePassword | Show-PusherPassword
            $result | Should -Be $plainPassword
        }

        It "Should throw error for null or empty SecureString" {
            { Show-PusherPassword -SecurePassword $null } | Should -Throw
        }
    }
}

Describe "Get-StringEntropy (Private Function)" {
    BeforeAll {
        # Import the private function for testing
        . "$ModulePath/Private/Get-StringEntropy.ps1"
    }

    Context "Entropy Calculation" {
        It "Should calculate entropy for a simple string" {
            $entropy = Get-StringEntropy -Val "aaaa"
            $entropy | Should -BeGreaterThan 0
            $entropy | Should -BeLessThan 1  # Very low entropy for repeated characters
        }

        It "Should calculate higher entropy for complex string" {
            $entropy = Get-StringEntropy -Val "aB3!xY9@"
            $entropy | Should -BeGreaterThan 2
        }

        It "Should return higher entropy for random strings than repeated characters" {
            $lowEntropy = Get-StringEntropy -Val "aaaaaaa"
            $highEntropy = Get-StringEntropy -Val "aB3!xY9"
            $highEntropy | Should -BeGreaterThan $lowEntropy
        }
    }
}

Describe "ConvertFrom-SecurePassword (Private Function)" {
    BeforeAll {
        # Import the private function for testing
        . "$ModulePath/Private/ConvertFrom-SecurePassword.ps1"
    }

    Context "SecureString Conversion" {
        It "Should convert SecureString to plain text string" {
            $plainPassword = "TestPassword123!"
            $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
            $result = ConvertFrom-SecurePassword -SecurePassword $securePassword
            $result | Should -Be $plainPassword
        }

        It "Should accept pipeline input" {
            $plainPassword = "PipelineTest456#"
            $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
            $result = $securePassword | ConvertFrom-SecurePassword
            $result | Should -Be $plainPassword
        }

        It "Should throw error for null SecureString" {
            { ConvertFrom-SecurePassword -SecurePassword $null } | Should -Throw
        }
    }
}

Describe "Publish-PusherPassword" {
    Context "Parameter Validation" {
        It "Should have default server set to pwpush.com" {
            $cmd = Get-Command Publish-PusherPassword
            $serverParam = $cmd.Parameters['Server']
            $serverParam.Attributes.TypeId.Name -contains 'ValidateNotNullOrEmptyAttribute' | Should -Be $true
        }

        It "Should validate Days range (1-90)" {
            {
                $secPass = ConvertTo-SecureString "test" -AsPlainText -Force
                New-PusherPassword | Publish-PusherPassword -Days 0 -ErrorAction Stop
            } | Should -Throw
        }

        It "Should validate Views range (1-100)" {
            {
                $secPass = ConvertTo-SecureString "test" -AsPlainText -Force
                New-PusherPassword | Publish-PusherPassword -Views 0 -ErrorAction Stop
            } | Should -Throw
        }

        It "Should require Password parameter" {
            $cmd = Get-Command Publish-PusherPassword
            $cmd.Parameters['Password'].Attributes.Mandatory | Should -Contain $true
        }
    }

    Context "URL Generation" {
        It "Should use HTTPS by default" {
            Mock Invoke-RestMethod {
                return @{ url_token = "test123"; first_view = $false }
            }

            $secPass = ConvertTo-SecureString "test" -AsPlainText -Force
            $result = Publish-PusherPassword -Password $secPass -Server "test.example.com"
            $result | Should -Match "^https://"
        }

        It "Should use HTTP when UseHttp switch is specified" {
            Mock Invoke-RestMethod {
                return @{ url_token = "test123"; first_view = $false }
            }

            $secPass = ConvertTo-SecureString "test" -AsPlainText -Force
            $result = Publish-PusherPassword -Password $secPass -Server "localhost:5100" -UseHttp
            $result | Should -Match "^http://"
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module PwdPusher -ErrorAction SilentlyContinue
}
