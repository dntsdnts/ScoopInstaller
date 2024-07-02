Describe 'PSScriptAnalyzer' -Tag 'Linter' {
    BeforeDiscovery {
        $scriptDir = @('.', 'bin', 'lib', 'libexec', 'test')
    }

    BeforeAll {
        $lintSettings = "$PSScriptRoot\..\PSScriptAnalyzerSettings.psd1"
    }

    It 'PSScriptAnalyzerSettings.ps1 should exist' {
        $lintSettings | Should -Exist
    }

    Context 'Linting all *.psd1, *.psm1 and *.ps1 files' {
        BeforeEach {
            $analysis = Invoke-ScriptAnalyzer -Path "$PSScriptRoot\..\$_" -Settings $lintSettings
        }
        It 'Should pass: <_>' -TestCases $scriptDir {
            $analysis | Should -HaveCount 0
            if ($analysis) {
                foreach ($result in $analysis) {
                    switch -wildCard ($result.ScriptName) {
                        '*.psm1' { $type = 'Module' }
                        '*.ps1' { $type = 'Script' }
                        '*.psd1' { $type = 'Manifest' }
                    }
                    Write-Warning "     [*] $($result.Severity): $($result.Message)"
                    Write-Warning "         $($result.RuleName) in $type`: $directory\$($result.ScriptName):$($result.Line)"
                }
            }
        }
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB3ZRNK1xde0hh1
# 6oiUYQwtMU6CarAJJvbWQHBdR48un6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
# vkj4l+euvSLrMA0GCSqGSIb3DQEBDQUAMA8xDTALBgNVBAMMBHFycXIwHhcNMjQw
# NjI5MDczMTE4WhcNMjUwNjI5MDc1MTE4WjAPMQ0wCwYDVQQDDARxcnFyMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzGyCuR6iKpn8DX3kWN4b7mG9FwOf
# P+3w/qAPET+0ejsqwRfd3PbQBtCln8LP40sTe0Oy5tOFez63/tXshModzgfA+5cA
# iGG1I1YMVRHjpVPd24tZLr+6kkOR6az+VFS3zRCWhH/kN5oMxxkEt7vacZC1QRrh
# PQWcCVXYorPmZwPNHws5k7ZxtPHWT367HZrzrzHXW0VB+XX52a7EgRWFVzAaCziH
# DHUTAvnDwbnLGt1kfX43AxvcOPXpzFPtpEXh+DRgwKGjJaHKzuWYzK8lHs6TXbZF
# QbJI4SN4xgq4+i2ceZECPl4ROzG9HaO7s4Q4TmeXAcyziMxb55QHQDauwQIDAQAB
# o0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0O
# BBYEFFxJWt2yBxX0gUBoRDAcm4HuLs9LMA0GCSqGSIb3DQEBDQUAA4IBAQBIqYh9
# /0VLnlt0csz4RWJf6tpmdUrv39mlXfJXBQBgSjKrUNph1lyvEnXorTqCTyT5cjQ5
# 5GXaN4jQYpE2FISWUte/b+JY0WPl5xS3Ewl5c6HVIwDZ/54hXKezQu18NVVRvbAL
# 5blL+fn+NFMakRiP8Z/advmSN7qsF8H/HWSTRnkAAzfDe7folyzfgmej4Stk7XRX
# QabaUPeiYTiJGhY0FFknsXLIwk3F0azE5LRxUD7qhoK2nFP9yPjVXqfkmxOt2WPo
# 7FGDPJYS0iPB/oQO4/+3x0YHXgmE8BoicNRA9jQJ1s/gDQOX0qOWgbecdwNef1u/
# Tnv+D9lQdt4kF86zMYIB1TCCAdECAQEwIzAPMQ0wCwYDVQQDDARxcnFyAhBRXjN4
# 3tOevkj4l+euvSLrMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPB8z+YOfeGKmUhddMkQ
# sjypRt0t+ynRl+C/u3UXTaNBMA0GCSqGSIb3DQEBAQUABIIBAIYec17R5uuqBFug
# acKgj1QxawiqSbMQrDfwkkgBGUztf3YXfmnD/QtkSjR3o95gmC8aWtJxcmA70hjz
# XQLBNbBonpd+cm1dOIp8nkyVfFsDGhjJcE9jsjtRUd2tBaXG/vCEqLBwsFdsLvVK
# 7z4SVJdXQAulh1TbAFBQq7J17/5CvReSILwxNSG32YzaB0Gpubp1LdhnMwMEoefa
# owAyRY8ZRbzWlpIJspEurFT48dX0rGEdrZM3HAUWVulANYUHTwRaXvtLyWbecuKm
# EpGfASMHYRXfPmEWgliU0cCtSp6NUnWX++3R+JaTH9RwA/OLJxA7hBnZXD3zsSM+
# b4/tEgE=
# SIG # End signature block
