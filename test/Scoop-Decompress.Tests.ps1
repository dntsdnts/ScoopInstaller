BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\core.ps1"
    . "$PSScriptRoot\..\lib\decompress.ps1"
    . "$PSScriptRoot\..\lib\install.ps1"
    . "$PSScriptRoot\..\lib\manifest.ps1"
    . "$PSScriptRoot\..\lib\versions.ps1"
}

Describe 'Decompression function' -Tag 'Scoop', 'Windows', 'Decompress' {

    BeforeAll {
        $working_dir = setup_working 'decompress'

        function test_extract($extract_fn, $from, $removal) {
            $to = (strip_ext $from) -replace '\.tar$', ''
            & $extract_fn ($from -replace '/', '\') ($to -replace '/', '\') -Removal:$removal -ExtractDir $args[0]
            return $to
        }

    }
    Context 'Decompression test cases should exist' {
        BeforeAll {
            $testcases = "$working_dir\TestCases.zip"
        }
        It 'Test cases should exist and hash should match' {
            $testcases | Should -Exist
            (Get-FileHash -Path $testcases -Algorithm SHA256).Hash.ToLower() | Should -Be 'afb86b0552187b8d630ce25d02835fb809af81c584f07e54cb049fb74ca134b6'
        }
        It 'Test cases should be extracted correctly' {
            { Microsoft.PowerShell.Archive\Expand-Archive -Path $testcases -DestinationPath $working_dir } | Should -Not -Throw
        }
    }

    Context '7zip extraction' {

        BeforeAll {
            if ($env:CI) {
                Mock Get-AppFilePath { (Get-Command 7z.exe).Path }
            } elseif (!(installed 7zip)) {
                scoop install 7zip
            }
            $test1 = "$working_dir\7ZipTest1.7z"
            $test2 = "$working_dir\7ZipTest2.tgz"
            $test3 = "$working_dir\7ZipTest3.tar.bz2"
            $test4 = "$working_dir\7ZipTest4.tar.gz"
            $test5_1 = "$working_dir\7ZipTest5.7z.001"
            $test5_2 = "$working_dir\7ZipTest5.7z.002"
            $test5_3 = "$working_dir\7ZipTest5.7z.003"
            $test6_1 = "$working_dir\7ZipTest6.part01.rar"
            $test6_2 = "$working_dir\7ZipTest6.part02.rar"
            $test6_3 = "$working_dir\7ZipTest6.part03.rar"
            $test7 = "$working_dir\NSISTest.exe"
        }

        AfterEach {
            Remove-Item -Path $to -Recurse -Force
        }

        It 'extract normal compressed file' {
            $to = test_extract 'Expand-7zipArchive' $test1
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 3
        }

        It 'extract "extract_dir" correctly' {
            $to = test_extract 'Expand-7zipArchive' $test1 $false 'tmp'
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'extract "extract_dir" with spaces correctly' {
            $to = test_extract 'Expand-7zipArchive' $test1 $false 'tmp 2'
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'extract nested compressed file' {
            # file ext: tgz
            $to = test_extract 'Expand-7zipArchive' $test2
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1

            # file ext: tar.bz2
            $to = test_extract 'Expand-7zipArchive' $test3
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'extract nested compressed file with different inner name' {
            $to = test_extract 'Expand-7zipArchive' $test4
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'extract splited 7z archives (.001, .002, ...)' {
            $to = test_extract 'Expand-7zipArchive' $test5_1
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'extract splited RAR archives (.part01.rar, .part02.rar, ...)' {
            $to = test_extract 'Expand-7zipArchive' $test6_1
            $to | Should -Exist
            "$to\dummy" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'extract NSIS installer' {
            $to = test_extract 'Expand-7zipArchive' $test7
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'self-extract NSIS installer' {
            $to = "$working_dir\NSIS Test"
            $null = Invoke-ExternalCommand -FilePath $test7 -ArgumentList @('/S', '/NCRC', "/D=$to")
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'works with "-Removal" switch ($removal param)' {
            $test1 | Should -Exist
            $to = test_extract 'Expand-7zipArchive' $test1 $true
            $to | Should -Exist
            $test1 | Should -Not -Exist
            $test5_1 | Should -Exist
            $test5_2 | Should -Exist
            $test5_3 | Should -Exist
            $to = test_extract 'Expand-7zipArchive' $test5_1 $true
            $to | Should -Exist
            $test5_1 | Should -Not -Exist
            $test5_2 | Should -Not -Exist
            $test5_3 | Should -Not -Exist
            $test6_1 | Should -Exist
            $test6_2 | Should -Exist
            $test6_3 | Should -Exist
            $to = test_extract 'Expand-7zipArchive' $test6_1 $true
            $to | Should -Exist
            $test6_1 | Should -Not -Exist
            $test6_2 | Should -Not -Exist
            $test6_3 | Should -Not -Exist
        }
    }

    Context 'msi extraction' {

        BeforeAll {
            if ($env:CI) {
                Mock Get-AppFilePath { $env:SCOOP_LESSMSI_PATH }
            } elseif (!(installed lessmsi)) {
                scoop install lessmsi
            }
            Copy-Item "$working_dir\MSITest.msi" "$working_dir\MSI Test.msi"
            $test1 = "$working_dir\MSITest.msi"
            $test2 = "$working_dir\MSI Test.msi"
            $test3 = "$working_dir\MSITestNull.msi"
        }

        It 'extract normal MSI file using msiexec' {
            Mock get_config { $false }
            $to = test_extract 'Expand-MsiArchive' $test1
            $to | Should -Exist
            "$to\MSITest\empty" | Should -Exist
            (Get-ChildItem "$to\MSITest").Count | Should -Be 1
        }

        It 'extract normal MSI file with whitespace in path using msiexec' {
            Mock get_config { $false }
            $to = test_extract 'Expand-MsiArchive' $test2
            $to | Should -Exist
            "$to\MSITest\empty" | Should -Exist
            (Get-ChildItem "$to\MSITest").Count | Should -Be 1
        }

        It 'extract normal MSI file using lessmsi' {
            Mock get_config { $true }
            $to = test_extract 'Expand-MsiArchive' $test1
            $to | Should -Exist
        }

        It 'extract normal MSI file with whitespace in path using lessmsi' {
            Mock get_config { $true }
            $to = test_extract 'Expand-MsiArchive' $test2
            $to | Should -Exist
        }

        It 'extract empty MSI file using lessmsi' {
            Mock get_config { $true }
            $to = test_extract 'Expand-MsiArchive' $test3
            $to | Should -Exist
        }

        It 'works with "-Removal" switch ($removal param)' {
            Mock get_config { $false }
            $test1 | Should -Exist
            test_extract 'Expand-MsiArchive' $test1 $true
            $test1 | Should -Not -Exist
        }
    }

    Context 'inno extraction' {

        BeforeAll {
            if ($env:CI) {
                Mock Get-AppFilePath { $env:SCOOP_INNOUNP_PATH }
            } elseif (!(installed innounp)) {
                scoop install innounp
            }
            $test = "$working_dir\InnoTest.exe"
        }

        It 'extract Inno Setup file' {
            $to = test_extract 'Expand-InnoArchive' $test
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'works with "-Removal" switch ($removal param)' {
            $test | Should -Exist
            test_extract 'Expand-InnoArchive' $test $true
            $test | Should -Not -Exist
        }
    }

    Context 'zip extraction' {

        BeforeAll {
            $test = "$working_dir\ZipTest.zip"
        }

        It 'extract compressed file' {
            $to = test_extract 'Expand-ZipArchive' $test
            $to | Should -Exist
            "$to\empty" | Should -Exist
            (Get-ChildItem $to).Count | Should -Be 1
        }

        It 'works with "-Removal" switch ($removal param)' {
            $test | Should -Exist
            test_extract 'Expand-ZipArchive' $test $true
            $test | Should -Not -Exist
        }
    }
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPd9GAloRSo35+rEIL/y2W61m
# IZCgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUJgosVvEm91Db7b6YK/U8AYkUnhMwDQYJKoZIhvcNAQEBBQAEggEA
# Q8G9J07r/p03p5o3HYHWjlZ4aZYEXkj004nms+IqZzyGkQMkCa6sOTPymUSpcWV5
# uPi9AQVDhY2yPPfsM2/E8+F5qx0flL0vktXIsGPYw9ohcnZKkAdM6IvXJPfo6u4D
# Tawz2wE2EnvnTae93wMSo1k8ZhRsZpv5jExrIM+4pRpXJU63OLztGxwoXWIoUo1z
# 6hFg9+iyb1k1veIy9jsclQHxhiNMt8BcfbbAMeAaHlj8eeCc4G7XvmmxMfnBCPKO
# Y+0q+FQOuepWVFCQbhOO7UWz/MgfNuhgwyz4K6t7fpaXrjWKZN2yUmOSjHZ7D1zS
# GVV5MO/dZVm9Y81ISeY+Xg==
# SIG # End signature block
