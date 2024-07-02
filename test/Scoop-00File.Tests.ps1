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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBIqYKL7Hnvr6zd
# gx1sU9XYcGkhFdZ5OWZ8h72g1kHKHqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBmpSYHm5ouG3A711gaQ
# 4neC2celXwdfbGDXid4UtwWYMA0GCSqGSIb3DQEBAQUABIIBADNXPrGBXuz/WeHu
# nL6FnZCOlzzyLj/q6RiPoxdvNX8oeIT/1gCwBjFO7LIobKl7+HfMd6eoc3BaRuM2
# Ked5oSvT6ikqsvUt3M1O0Fcl932zTwHBr0pYq2BpOXjF7R1+asKLyfNCIKvhOX6z
# 4PfXrGdlHDXB+TF78bsb2KhKDoTQLBR+GV1O0WMrPpxnbYEpo/qlfzTAREwVQyXZ
# hNxjT9HXUXdKRw9GaXvRvh2QHHcSMHVtA05pcvKkSqWjvnrhr632E1tW1PqRROlp
# iNENJ4pk1kLmODaT4nAuYFp30ARkjahZeBoKNVhL30Y0xbmMCkoq9FN3ng7byADH
# 4Xkw2H8=
# SIG # End signature block
