param(
    [String] $TestPath = "$PSScriptRoot\.."
)

BeforeDiscovery {
    $project_file_exclusions = @(
        '[\\/]\.git[\\/]',
        '\.sublime-workspace$',
        '\.DS_Store$',
        'supporting(\\|/)validator(\\|/)packages(\\|/)*'
    )
    $repo_files = (Get-ChildItem $TestPath -File -Recurse).FullName |
        Where-Object { $_ -inotmatch $($project_file_exclusions -join '|') }
}

Describe 'Code Syntax' -ForEach @(, $repo_files) -Tag 'File' {
    BeforeAll {
        $files = @(
            $_ | Where-Object { $_ -imatch '.(ps1|psm1)$' }
        )
        function Test-PowerShellSyntax {
            # ref: http://powershell.org/wp/forums/topic/how-to-check-syntax-of-scripts-automatically @@ https://archive.is/xtSv6
            # originally created by Alexander Petrovskiy & Dave Wyatt
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [string[]]
                $Path
            )

            process {
                foreach ($scriptPath in $Path) {
                    $contents = Get-Content -Path $scriptPath

                    if ($null -eq $contents) {
                        continue
                    }

                    $errors = $null
                    $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)

                    New-Object psobject -Property @{
                        Path              = $scriptPath
                        SyntaxErrorsFound = ($errors.Count -gt 0)
                    }
                }
            }
        }

    }

    It 'PowerShell code files do not contain syntax errors' {
        $badFiles = @(
            foreach ($file in $files) {
                if ( (Test-PowerShellSyntax $file).SyntaxErrorsFound ) {
                    $file
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files have syntax errors: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }

}

Describe 'Style constraints for non-binary project files' -ForEach @(, $repo_files) -Tag 'File' {
    BeforeAll {
        $files = @(
            # gather all files except '*.exe', '*.zip', or any .git repository files
            $_ |
                Where-Object { $_ -inotmatch '(.exe|.zip|.dll)$' } |
                Where-Object { $_ -inotmatch '(unformatted)' }
        )
    }

    It 'files do not contain leading UTF-8 BOM' {
        # UTF-8 BOM == 0xEF 0xBB 0xBF
        # see http://www.powershellmagazine.com/2012/12/17/pscxtip-how-to-determine-the-byte-order-mark-of-a-text-file @@ https://archive.is/RgT42
        # ref: http://poshcode.org/2153 @@ https://archive.is/sGnnu
        $badFiles = @(
            foreach ($file in $files) {
                if ((Get-Command Get-Content).parameters.ContainsKey('AsByteStream')) {
                    # PowerShell Core (6.0+) '-Encoding byte' is replaced by '-AsByteStream'
                    $content = ([char[]](Get-Content $file -AsByteStream -TotalCount 3) -join '')
                } else {
                    $content = ([char[]](Get-Content $file -Encoding byte -TotalCount 3) -join '')
                }
                if ([regex]::match($content, '(?ms)^\xEF\xBB\xBF').success) {
                    $file
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files have utf-8 BOM: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }

    It 'files end with a newline' {
        $badFiles = @(
            foreach ($file in $files) {
                # Ignore previous TestResults.xml
                if ($file -match 'TestResults.xml') {
                    continue
                }
                $string = [System.IO.File]::ReadAllText($file)
                if ($string.Length -gt 0 -and $string[-1] -ne "`n") {
                    $file
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files do not end with a newline: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }

    It 'file newlines are CRLF' {
        $badFiles = @(
            foreach ($file in $files) {
                $content = [System.IO.File]::ReadAllText($file)
                if (!$content) {
                    throw "File contents are null: $($file)"
                }
                $lines = [regex]::split($content, '\r\n')
                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++) {
                    if ( [regex]::match($lines[$i], '\r|\n').success ) {
                        $file
                        break
                    }
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files have non-CRLF line endings: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }

    It 'files have no lines containing trailing whitespace' {
        $badLines = @(
            foreach ($file in $files) {
                # Ignore previous TestResults.xml
                if ($file -match 'TestResults.xml') {
                    continue
                }
                $lines = [System.IO.File]::ReadAllLines($file)
                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++) {
                    if ($lines[$i] -match '\s+$') {
                        'File: {0}, Line: {1}' -f $file, ($i + 1)
                    }
                }
            }
        )

        if ($badLines.Count -gt 0) {
            throw "The following $($badLines.Count) lines contain trailing whitespace: `r`n`r`n$($badLines -join "`r`n")"
        }
    }

    It 'any leading whitespace consists only of spaces (excepting makefiles)' {
        $badLines = @(
            foreach ($file in $files) {
                if ($file -inotmatch '(^|.)makefile$') {
                    $lines = [System.IO.File]::ReadAllLines($file)
                    $lineCount = $lines.Count

                    for ($i = 0; $i -lt $lineCount; $i++) {
                        if ($lines[$i] -notmatch '^[ ]*(\S|$)') {
                            'File: {0}, Line: {1}' -f $file, ($i + 1)
                        }
                    }
                }
            }
        )

        if ($badLines.Count -gt 0) {
            throw "The following $($badLines.Count) lines contain TABs within leading whitespace: `r`n`r`n$($badLines -join "`r`n")"
        }
    }

}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdOQp3B/5taWIKlwd40RoUNEO
# k9WgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUB/Q/Wtjw1aevmW23/Q6f7lRv5UowDQYJKoZIhvcNAQEBBQAEggEA
# jnRu+tV21b3KZklgvofZcmvGi4oNOXJw3RiKKUx7ejpVYfcdOlh55nCRDdkg5a42
# tx5tehor63KgkUHyfA/oqg2SyOuO2s5GT2ERc6KbhSmilBteVwtV3yotmrcEwwqs
# mC4LERe652r5hQ90NiExuU0tkqSRwMRiupHBP4cvc4p3H+bpiNnpcy8Xi69OL7XU
# u+jD5AnUttIYHbvWjYyyaE5zkMOFoyQa0JF+ZQROfVmyycSVpxu4Fs3NMiXnvoRG
# e9pMeZyKOhnwrDTAn8PDTfte+gYijamtyWbeJ/4+Tgf+KWgrnwi05fXQIJNBvoAl
# C+5EWwI3nfw3HzCdNAzzVg==
# SIG # End signature block
