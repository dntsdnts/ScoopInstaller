BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\core.ps1"
    . "$PSScriptRoot\..\lib\depends.ps1"
    . "$PSScriptRoot\..\lib\buckets.ps1"
    . "$PSScriptRoot\..\lib\install.ps1"
    . "$PSScriptRoot\..\lib\manifest.ps1"
}

Describe 'Package Dependencies' -Tag 'Scoop' {
    Context 'Requirement function' {
        It 'Test 7zip requirement' {
            Test-7zipRequirement -Uri 'test.xz' | Should -BeTrue
            Test-7zipRequirement -Uri 'test.bin' | Should -BeFalse
            Test-7zipRequirement -Uri @('test.xz', 'test.bin') | Should -BeTrue
        }
        It 'Test lessmsi requirement' {
            Mock get_config { $true }
            Test-LessmsiRequirement -Uri 'test.msi' | Should -BeTrue
            Test-LessmsiRequirement -Uri 'test.bin' | Should -BeFalse
            Test-LessmsiRequirement -Uri @('test.msi', 'test.bin') | Should -BeTrue
        }
        It 'Allow $Uri be $null' {
            Test-7zipRequirement -Uri $null | Should -BeFalse
            Test-LessmsiRequirement -Uri $null | Should -BeFalse
        }
    }

    Context 'InstallationHelper function' {
        BeforeAll {
            $working_dir = setup_working 'format/formatted'
            $manifest1 = parse_json (Join-Path $working_dir '3-array-with-single-and-multi.json')
            $manifest2 = parse_json (Join-Path $working_dir '4-script-block.json')
            Mock Test-HelperInstalled { $false }
        }
        It 'Get helpers from URL' {
            Mock get_config { $true }
            Get-InstallationHelper -Manifest $manifest1 -Architecture '32bit' | Should -Be @('lessmsi')
        }
        It 'Get helpers from script' {
            Mock get_config { $false }
            Get-InstallationHelper -Manifest $manifest2 -Architecture '32bit' | Should -Be @('7zip')
        }
        It 'Helpers reflect config changes' {
            Mock get_config { $false } -ParameterFilter { $name -eq 'USE_LESSMSI' }
            Mock get_config { $true } -ParameterFilter { $name -eq 'USE_EXTERNAL_7ZIP' }
            Get-InstallationHelper -Manifest $manifest1 -Architecture '32bit' | Should -BeNullOrEmpty
            Get-InstallationHelper -Manifest $manifest2 -Architecture '32bit' | Should -BeNullOrEmpty
        }
        It 'Not return installed helpers' {
            Mock get_config { $true } -ParameterFilter { $name -eq 'USE_LESSMSI' }
            Mock get_config { $false } -ParameterFilter { $name -eq 'USE_EXTERNAL_7ZIP' }
            Mock Test-HelperInstalled { $true }-ParameterFilter { $Helper -eq '7zip' }
            Mock Test-HelperInstalled { $false }-ParameterFilter { $Helper -eq 'Lessmsi' }
            Get-InstallationHelper -Manifest $manifest1 -Architecture '32bit' | Should -Be @('lessmsi')
            Get-InstallationHelper -Manifest $manifest2 -Architecture '32bit' | Should -BeNullOrEmpty
            Mock Test-HelperInstalled { $false }-ParameterFilter { $Helper -eq '7zip' }
            Mock Test-HelperInstalled { $true }-ParameterFilter { $Helper -eq 'Lessmsi' }
            Get-InstallationHelper -Manifest $manifest1 -Architecture '32bit' | Should -BeNullOrEmpty
            Get-InstallationHelper -Manifest $manifest2 -Architecture '32bit' | Should -Be @('7zip')
        }
    }

    Context 'Dependencies resolution' {
        BeforeAll {
            Mock Test-HelperInstalled { $false }
            Mock get_config { $true } -ParameterFilter { $name -eq 'USE_LESSMSI' }
            Mock Get-Manifest { 'lessmsi', @{}, $null, $null } -ParameterFilter { $app -eq 'lessmsi' }
            Mock Get-Manifest { '7zip', @{ url = 'test.msi' }, $null, $null } -ParameterFilter { $app -eq '7zip' }
            Mock Get-Manifest { 'innounp', @{}, $null, $null } -ParameterFilter { $app -eq 'innounp' }
        }

        It 'Resolve install dependencies' {
            Mock Get-Manifest { 'test', @{ url = 'test.7z' }, $null, $null }
            Get-Dependency -AppName 'test' -Architecture '32bit' | Should -Be @('lessmsi', '7zip', 'test')
            Mock Get-Manifest { 'test', @{ innosetup = $true }, $null, $null }
            Get-Dependency -AppName 'test' -Architecture '32bit' | Should -Be @('innounp', 'test')
        }
        It 'Resolve script dependencies' {
            Mock Get-Manifest { 'test', @{ pre_install = 'Expand-7zipArchive ' }, $null, $null }
            Get-Dependency -AppName 'test' -Architecture '32bit' | Should -Be @('lessmsi', '7zip', 'test')
        }
        It 'Resolve runtime dependencies' {
            Mock Get-Manifest { 'depends', @{}, $null, $null } -ParameterFilter { $app -eq 'depends' }
            Mock Get-Manifest { 'test', @{ depends = 'depends' }, $null, $null }
            Get-Dependency -AppName 'test' -Architecture '32bit' | Should -Be @('depends', 'test')
        }
        It 'Keep bucket name of app' {
            Mock Get-Manifest { 'depends', @{}, 'anotherbucket', $null } -ParameterFilter { $app -eq 'anotherbucket/depends' }
            Mock Get-Manifest { 'test', @{ depends = 'anotherbucket/depends' }, 'bucket', $null }
            Get-Dependency -AppName 'bucket/test' -Architecture '32bit' | Should -Be @('anotherbucket/depends', 'bucket/test')
        }
    }
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoplSkOMwcdBtsNFc6rUX1hLY
# wc+gggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUALAgk9ADNGq5KWTy75q85+H5asEwDQYJKoZIhvcNAQEBBQAEggEA
# FLhDC8tGxkhbZdL4njwqKIIFDOEXA8UqgRbfGelqcSuJifi3hZ1ghN3ZfRA7I7tt
# 7Khkz0lsEUGjxJakfwmFBvOqTGaiKkHKjt00uenWui0L2BgkCgQDxR38t7llPpPW
# jppPKAWDT5PIMEj563h8NgIr6An6z2oRuMaZueOy5kYkUeyIYvOP613JmwkSrhtP
# OhhGW+buulOE0SIFgXGTkH2yMt8yIND9XkOBGdd/oVk+9QdNLdfNlIc6G8TCdb9N
# LUOy5cLSzoKPWMVe10iNibNyO7WGd7ye27aOhJf0+veH5iNptZ/CCywdgzFCn5z4
# fxYJe+FV/VhufGGRRx0ccg==
# SIG # End signature block
