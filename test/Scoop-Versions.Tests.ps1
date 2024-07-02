BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\versions.ps1"
}

Describe 'versions comparison' -Tag 'Scoop' {
    Context 'semver compliant versions' {
        It 'handles major.minor.patch progressing' {
            Compare-Version '0.1.0' '0.1.1' | Should -Be 1
            Compare-Version '0.1.1' '0.2.0' | Should -Be 1
            Compare-Version '0.2.0' '1.0.0' | Should -Be 1
        }

        It 'handles pre-release versioning progression' {
            Compare-Version '0.4.0' '0.5.0-alpha.1' | Should -Be 1
            Compare-Version '0.5.0-alpha.1' '0.5.0-alpha.2' | Should -Be 1
            Compare-Version '0.5.0-alpha.2' '0.5.0-alpha.10' | Should -Be 1
            Compare-Version '0.5.0-alpha.10' '0.5.0-beta' | Should -Be 1
            Compare-Version '0.5.0-beta' '0.5.0-alpha.10' | Should -Be -1
            Compare-Version '0.5.0-beta' '0.5.0-beta.0' | Should -Be 1
        }

        It 'handles the pre-release tags in an alphabetic order' {
            Compare-Version '0.5.0-rc.1' '0.5.0-z' | Should -Be 1
            Compare-Version '0.5.0-rc.1' '0.5.0-howdy' | Should -Be -1
            Compare-Version '0.5.0-howdy' '0.5.0-rc.1' | Should -Be 1
        }
    }

    Context 'semver semi-compliant versions' {
        It 'handles Windows-styled major.minor.patch.build progression' {
            Compare-Version '0.0.0.0' '0.0.0.1' | Should -Be 1
            Compare-Version '0.0.0.1' '0.0.0.2' | Should -Be 1
            Compare-Version '0.0.0.2' '0.0.1.0' | Should -Be 1
            Compare-Version '0.0.1.0' '0.0.1.1' | Should -Be 1
            Compare-Version '0.0.1.1' '0.0.1.2' | Should -Be 1
            Compare-Version '0.0.1.2' '0.0.2.0' | Should -Be 1
            Compare-Version '0.0.2.0' '0.1.0.0' | Should -Be 1
            Compare-Version '0.1.0.0' '0.1.0.1' | Should -Be 1
            Compare-Version '0.1.0.1' '0.1.0.2' | Should -Be 1
            Compare-Version '0.1.0.2' '0.1.1.0' | Should -Be 1
            Compare-Version '0.1.1.0' '0.1.1.1' | Should -Be 1
            Compare-Version '0.1.1.1' '0.1.1.2' | Should -Be 1
            Compare-Version '0.1.1.2' '0.2.0.0' | Should -Be 1
            Compare-Version '0.2.0.0' '1.0.0.0' | Should -Be 1
        }

        It 'handles partial semver version differences' {
            Compare-Version '1' '1.1' | Should -Be 1
            Compare-Version '1' '1.0' | Should -Be 1
            Compare-Version '1.1.0.0' '1.1' | Should -Be -1
            Compare-Version '1.4' '1.3.0' | Should -Be -1
            Compare-Version '1.4' '1.3.255.255' | Should -Be -1
            Compare-Version '1.4' '1.4.4' | Should -Be 1
            Compare-Version '1.1.1_8' '1.1.1' | Should -Be -1
            Compare-Version '1.1.1_8' '1.1.1_9' | Should -Be 1
            Compare-Version '1.1.1_10' '1.1.1_9' | Should -Be -1
            Compare-Version '1.1.1b' '1.1.1a' | Should -Be -1
            Compare-Version '1.1.1a' '1.1.1b' | Should -Be 1
            Compare-Version '1.1a2' '1.1a3' | Should -Be 1
            Compare-Version '1.1.1a10' '1.1.1b1' | Should -Be 1
        }

        It 'handles dash-style versions' {
            Compare-Version '1.8.9' '1.8.5-1' | Should -Be -1
            Compare-Version '7.0.4-9' '7.0.4-10' | Should -Be 1
            Compare-Version '7.0.4-9' '7.0.4-8' | Should -Be -1
            Compare-Version '2019-01-01' '2019-01-02' | Should -Be 1
            Compare-Version '2019-01-02' '2019-01-01' | Should -Be -1
            Compare-Version '2018-01-01' '2019-01-01' | Should -Be 1
            Compare-Version '2019-01-01' '2018-01-01' | Should -Be -1
        }
        It 'handles post-release tagging ("+")' {
            Compare-Version '1' '1+hotfix.0' | Should -Be 1
            Compare-Version '1.0.0' '1.0.0+hotfix.0' | Should -Be 1
            Compare-Version '1.0.0+hotfix.0' '1.0.0+hotfix.1' | Should -Be 1
            Compare-Version '1.0.0+hotfix.1' '1.0.1' | Should -Be 1
            Compare-Version '1.0.0+1.1' '1.0.0+1' | Should -Be -1
        }
    }

    Context 'other misc versions' {
        It 'handles plain text string' {
            Compare-Version 'latest' '20150405' | Should -Be -1
            Compare-Version '0.5alpha' '0.5' | Should -Be 1
            Compare-Version '0.5' '0.5Beta' | Should -Be -1
            Compare-Version '0.4' '0.5Beta' | Should -Be 1
        }

        It 'handles empty string' {
            Compare-Version '7.0.4-9' '' | Should -Be -1
        }

        It 'handles equal versions' {
            function get_config { $null }
            Compare-Version '12.0' '12.0' | Should -Be 0
            Compare-Version '7.0.4-9' '7.0.4-9' | Should -Be 0
            Compare-Version 'nightly-20190801' 'nightly' | Should -Be 0
            Compare-Version 'nightly-20190801' 'nightly-20200801' | Should -Be 0
        }

        It "handles nightly versions with 'update_nightly'" {
            function get_config { $true }
            Mock Get-Date { '20200801' }
            Compare-Version 'nightly-20200801' 'nightly' | Should -Be 0
            Compare-Version 'nightly-20200730' 'nightly' | Should -Be 1
            Compare-Version 'nightly-20200730' 'nightly-20200801' | Should -Be 1
            Compare-Version 'nightly-20200802' 'nightly' | Should -Be -1
            Compare-Version 'nightly-20200802' 'nightly-20200801' | Should -Be -1
        }
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAa75Csi2tNUTkO
# Hb9HxZDNYCH0lKFZ60bhIstKHMWOB6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP3AjYymsGivNyt4/9bK
# scPDTCvFoMSA5TDw88QwXbLUMA0GCSqGSIb3DQEBAQUABIIBAG9Dsjs/Ty7FSZq5
# qHgFLBAPhm9/oh2YJ4WfCKz80PbR8XvN761qwH9ah3cL5WWYtQtpUmrOwUV5duFz
# LDqcrX7tG8voPN7+pFUmQZlKg6Pw96Ov1pvaVqBBESAgI3NETgTHGWOYqHDehhdx
# SLijHaoCCcMOlO9zxRscpExVKc+psKflLzQUPJXMA6W9xC8xsKzSNrNsmDo6RNAw
# DVrHyckUTqNLYzQgXKd2cRiaEXEdXfr6gQj9RuG00J/uI0UUVYv+ZrTJE9yToqlT
# bjbZgImLcc7gLVxbqWrg+F4bQCaVmM6/+flPLkvAOPAeKIuLNZG+/tk0XtShwmRS
# 55RatDU=
# SIG # End signature block
