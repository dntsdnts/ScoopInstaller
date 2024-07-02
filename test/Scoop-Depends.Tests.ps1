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
        It 'Test Zstd requirement' {
            Test-ZstdRequirement -Uri 'test.zst' | Should -BeTrue
            Test-ZstdRequirement -Uri 'test.bin' | Should -BeFalse
            Test-ZstdRequirement -Uri @('test.zst', 'test.bin') | Should -BeTrue
        }
        It 'Test lessmsi requirement' {
            Mock get_config { $true }
            Test-LessmsiRequirement -Uri 'test.msi' | Should -BeTrue
            Test-LessmsiRequirement -Uri 'test.bin' | Should -BeFalse
            Test-LessmsiRequirement -Uri @('test.msi', 'test.bin') | Should -BeTrue
        }
        It 'Allow $Uri be $null' {
            Test-7zipRequirement -Uri $null | Should -BeFalse
            Test-ZstdRequirement -Uri $null | Should -BeFalse
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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC9avaSL6xZB5p5
# 4e8fYH2OOuzHxQJ2SINKJTHoW1iQfqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG7CSKs+4ZTMpie+BmE0
# ELGcbpaW6O3r1yWIoeYPGjKoMA0GCSqGSIb3DQEBAQUABIIBAKTveFqKlIMNS6P+
# hM1I7Z2J81kuGfJVLCKHgYE2LUXp9Gz5e0o4BB5L/emRy2GKO4QtNJsus6UCAYFd
# N+YF4+Tmeh4+b6G7iBb5UiXbYzk9gXIs+32kODg3f5mEWVgsrMw10HBAmGZOuPkv
# vA++cM8n55emtZPjQ85c+JGDxQlIbfEtnV7tWVnDL9uYkZHU0IWMl1sr+mCy4Q2/
# ckPIN1vf5UEFLmNwvt/YhQtwrgck6tp4tkJMT7l/MkCe7VH3P1c0IoAzBWKhy8ZL
# DKAV1GSzPnOlH9fuCfLUvVP9gF57HXHXzOdX06XYyyjfJk05Bo3jaFnd2sw8uklx
# KOi78po=
# SIG # End signature block
