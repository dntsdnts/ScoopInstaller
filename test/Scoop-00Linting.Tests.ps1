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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwGpogK1DmLvIcallcVL1BA0C
# /kygggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUdcWaeWa4t19TS0FMH8duLNguVjYwDQYJKoZIhvcNAQEBBQAEggEA
# RS+u7lC/bdN/cYSqrenXWX2676Ou26GpS2IxRCC7Y2T9foLLhl48ytU8cPKObF4l
# 1mV2FcGxROfVSC3wGBomkE/1pSPHcaQjMcfhi8PSk9Hdje6pSJ5eFnwCGHc25qNk
# HViVoTRlUse7UZNDCvsG/jRJRPS0EMyqdEdE3eOj2CbMZrHdtxhlBadOafH5uO/U
# Po6ty/Mo3m+AHx6RFbXwBMyHXViLEcYZsofr6a6YwZjMJJHU0hyMfZMjeA06w4Xz
# YpxElWwsq/WH7qTjh6TUR9CrWcc7nmpttPyl/IlUbFI+myAxbeyoHlv2kqLp4Xd9
# dzWBmfZPZxrKmyo1tS4ZzA==
# SIG # End signature block
