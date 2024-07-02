BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\core.ps1"
}

Describe 'config' -Tag 'Scoop' {
    BeforeAll {
        $configFile = [IO.Path]::GetTempFileName()
        $unicode = [Regex]::Unescape('\u4f60\u597d\u3053\u3093\u306b\u3061\u306f') # 你好こんにちは
    }

    AfterAll {
        Remove-Item -Path $configFile -Force
    }

    It 'load_cfg should return null if config file does not exist' {
        load_cfg $configFile | Should -Be $null
    }

    It 'set_config should be able to save typed values correctly' {
        # number
        $scoopConfig = set_config 'one' 1
        $scoopConfig.one | Should -BeExactly 1

        # boolean
        $scoopConfig = set_config 'two' $true
        $scoopConfig.two | Should -BeTrue
        $scoopConfig = set_config 'three' $false
        $scoopConfig.three | Should -BeFalse

        # underline key
        $scoopConfig = set_config 'under_line' 'four'
        $scoopConfig.under_line | Should -BeExactly 'four'

        # string
        $scoopConfig = set_config 'five' 'not null'

        # datetime
        $scoopConfig = set_config 'time' ([System.DateTime]::Parse('2019-03-18T15:22:09.3930000+00:00', $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal))
        $scoopConfig.time | Should -BeOfType [System.DateTime]

        # non-ASCII
        $scoopConfig = set_config 'unicode' $unicode
        $scoopConfig.unicode | Should -Be $unicode
    }

    It 'load_cfg should return PSObject if config file exist' {
        $scoopConfig = load_cfg $configFile
        $scoopConfig | Should -Not -BeNullOrEmpty
        $scoopConfig | Should -BeOfType [System.Management.Automation.PSObject]
        $scoopConfig.one | Should -BeExactly 1
        $scoopConfig.two | Should -BeTrue
        $scoopConfig.three | Should -BeFalse
        $scoopConfig.under_line | Should -BeExactly 'four'
        $scoopConfig.five | Should -Be 'not null'
        $scoopConfig.time | Should -BeOfType [System.DateTime]
        $scoopConfig.time | Should -Be ([System.DateTime]::Parse('2019-03-18T15:22:09.3930000+00:00', $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal))
        $scoopConfig.unicode | Should -Be $unicode
    }

    It 'get_config should return exactly the same values' {
        $scoopConfig = load_cfg $configFile
        (get_config 'one') | Should -BeExactly 1
        (get_config 'two') | Should -BeTrue
        (get_config 'three') | Should -BeFalse
        (get_config 'under_line') | Should -BeExactly 'four'
        (get_config 'five') | Should -Be 'not null'
        (get_config 'time') | Should -BeOfType [System.DateTime]
        (get_config 'time') | Should -Be ([System.DateTime]::Parse('2019-03-18T15:22:09.3930000+00:00', $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal))
        (get_config 'unicode') | Should -Be $unicode
    }

    It 'set_config should remove a value if being set to $null' {
        $scoopConfig = load_cfg $configFile
        $scoopConfig = set_config 'five' $null
        $scoopConfig.five | Should -BeNullOrEmpty
    }
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAL+HV3Hu25GFCXgjMPkqPCQn
# LiqgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
# AQ0FADAPMQ0wCwYDVQQDDARxcnFyMB4XDTI0MDYyOTA3MzExOFoXDTI1MDYyOTA3
# NTExOFowDzENMAsGA1UEAwwEcXJxcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAMxsgrkeoiqZ/A195FjeG+5hvRcDnz/t8P6gDxE/tHo7KsEX3dz20AbQ
# pZ/Cz+NLE3tDsubThXs+t/7V7ITKHc4HwPuXAIhhtSNWDFUR46VT3duLWS6/upJD
# kems/lRUt80QloR/5DeaDMcZBLe72nGQtUEa4T0FnAlV2KKz5mcDzR8LOZO2cbTx
# 1k9+ux2a868x11tFQfl1+dmuxIEVhVcwGgs4hwx1EwL5w8G5yxrdZH1+NwMb3Dj1
# 6cxT7aRF4fg0YMChoyWhys7lmMyvJR7Ok122RUGySOEjeMYKuPotnHmRAj5eETsx
# vR2ju7OEOE5nlwHMs4jMW+eUB0A2rsECAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeA
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRcSVrdsgcV9IFAaEQwHJuB
# 7i7PSzANBgkqhkiG9w0BAQ0FAAOCAQEASKmIff9FS55bdHLM+EViX+raZnVK79/Z
# pV3yVwUAYEoyq1DaYdZcrxJ16K06gk8k+XI0OeRl2jeI0GKRNhSEllLXv2/iWNFj
# 5ecUtxMJeXOh1SMA2f+eIVyns0LtfDVVUb2wC+W5S/n5/jRTGpEYj/Gf2nb5kje6
# rBfB/x1kk0Z5AAM3w3u36Jcs34Jno+ErZO10V0Gm2lD3omE4iRoWNBRZJ7FyyMJN
# xdGsxOS0cVA+6oaCtpxT/cj41V6n5JsTrdlj6OxRgzyWEtIjwf6EDuP/t8dGB14J
# hPAaInDUQPY0CdbP4A0Dl9KjloG3nHcDXn9bv057/g/ZUHbeJBfOszGCAcQwggHA
# AgEBMCMwDzENMAsGA1UEAwwEcXJxcgIQUV4zeN7Tnr5I+Jfnrr0i6zAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQU1vUOhYe1fXAnM9CqiTp3VtY9B4QwDQYJKoZIhvcNAQEBBQAEggEA
# ZpaOXbzVT7LBRPvjfsv2mX8PYX5Wh7Ku6ksYa3R0cXIeZl+6BL87u9qms7GROywG
# Xat9rBiqxRQjo+bi9Bt9moHPxIBaE4kTgFywW1PZwupU4TtzfqsoWCApE1RKOHy0
# eC11xPBwnSV1H3LCwVjwhIzmUPe00CXhc+EybZ3dnyirvnagzgvSgewRn/AH6Qn1
# Rmbo7uwxSMKbSROBXg3XgUGfs3EYuAO0hIQstxpYuunE4jVDknjEGUYLvM20dYwJ
# 6GVMVR333FsJGUQqi4Ap4FKIYLm31qhqQcYJiJz81GgE4Gw3j2WkBV6v6Z/45tIT
# gnyIsyREfrbpxDnf/AmmEQ==
# SIG # End signature block
