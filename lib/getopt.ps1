# adapted from http://hg.python.org/cpython/file/2.7/Lib/getopt.py
# argv:
#    array of arguments
# shortopts:
#    string of single-letter options. options that take a parameter
#    should be follow by ':'
# longopts:
#    array of strings that are long-form options. options that take
#    a parameter should end with '='
# returns @(opts hash, remaining_args array, error string)
# NOTES:
#    The first "--" in $argv, if any, will terminate all options; any
# following arguments are treated as non-option arguments, even if
# they begin with a hyphen. The "--" itself will not be included in
# the returned $opts. (POSIX-compatible)
function getopt($argv, $shortopts, $longopts) {
    $opts = @{}; $rem = @()

    function err($msg) {
        $opts, $rem, $msg
    }

    function regex_escape($str) {
        return [Regex]::Escape($str)
    }

    # ensure these are arrays
    $argv = @($argv -split ' ')
    $longopts = @($longopts)

    for ($i = 0; $i -lt $argv.Length; $i++) {
        $arg = $argv[$i]
        if ($null -eq $arg) { continue }
        # don't try to parse array arguments
        if ($arg -is [Array]) { $rem += , $arg; continue }
        if ($arg -is [Int]) { $rem += $arg; continue }
        if ($arg -is [Decimal]) { $rem += $arg; continue }

        if ($arg -eq '--') {
            if ($i -lt $argv.Length - 1) {
                $rem += $argv[($i + 1)..($argv.Length - 1)]
            }
            break
        } elseif ($arg.StartsWith('--')) {
            $name = $arg.Substring(2)

            $longopt = $longopts | Where-Object { $_ -match "^$name=?$" }

            if ($longopt) {
                if ($longopt.EndsWith('=')) {
                    # requires arg
                    if ($i -eq $argv.Length - 1) {
                        return err "Option --$name requires an argument."
                    }
                    $opts.$name = $argv[++$i]
                } else {
                    $opts.$name = $true
                }
            } else {
                return err "Option --$name not recognized."
            }
        } elseif ($arg.StartsWith('-') -and $arg -ne '-') {
            for ($j = 1; $j -lt $arg.Length; $j++) {
                $letter = $arg[$j].ToString()

                if ($shortopts -match "$(regex_escape $letter)`:?") {
                    $shortopt = $Matches[0]
                    if ($shortopt[1] -eq ':') {
                        if ($j -ne $arg.Length - 1 -or $i -eq $argv.Length - 1) {
                            return err "Option -$letter requires an argument."
                        }
                        $opts.$letter = $argv[++$i]
                    } else {
                        $opts.$letter = $true
                    }
                } else {
                    return err "Option -$letter not recognized."
                }
            }
        } else {
            $rem += $arg
        }
    }

    $opts, $rem
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5emGprSZID/t1Xat/449GK7l
# J1SgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUC3hOLFHb1DrDAXW65FwGwbrcnywwDQYJKoZIhvcNAQEBBQAEggEA
# BlADHYR9CP1jCoG7Z1JMev19Ss1PAMvSMJL5kcTKAFrrr5cZu/hVoFdt3lbqk0UY
# lZvoe7Xz++RHqHfe4lMTlLQKU+qEcQCYkn996BmtLA+ezOaVG3+Ge7jFWa+EyAWQ
# hnFggLpm4dC4rAheQCTnocWvSjqDN4iZZXQNSRkGGFHUWTHABeGHhbCK7TaDLQX7
# fSnKyPr4+6+2K0ip4fUB7pvfv0GqYComRbuSRRvXe76bRrJEZ9f4fv5ZBKdoSI4E
# 0mIUgENYGyL91GhXBJTqa9fTlgquzulkFkH95u2Q47lor1V/hG56TgMzVNKUGtTh
# CN6OIPybjrcwx8Sr5DJiAA==
# SIG # End signature block
