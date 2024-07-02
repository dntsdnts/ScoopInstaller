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

        It 'handles nightly versions with `update_nightly`' {
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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5KCbrGedwhDumnx2gc6HrzAC
# H/KgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUGlDYSZpC0de51Xjhs+XDB77FRTkwDQYJKoZIhvcNAQEBBQAEggEA
# apCuj5bsITHA88Gl4aKDBlc3tthIk0zVZG1n0j6yTMbZ5S6fRQGuB2QLxge1LViw
# 877i84Ig40kei4+SmdUTMkCgRH/62B/Qr4e52inDJaI1p9OFvjYIjO7tlLFmiqUl
# I2bT6jWEtccBPkNa4bTqg/fmHuRIDORVQOeeYDWnf7QtJ/hAmZZ1CYE/UE6RMfTE
# o+w4INVIpNJginvBG1onXtEdGwqj5juvVmzt1k29DZgWQ0DCOZkgXVusU7c4lw6C
# M+xfm6hMb254B8cvHoWYYpvnWF4Wamb4m/tmiYB/rBntOOsJCjSfW5dQKxVNCGKm
# sQrvE18VXCwhjZECsC4y8w==
# SIG # End signature block
