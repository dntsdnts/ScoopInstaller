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
function getopt([String[]]$argv, [String]$shortopts, [String[]]$longopts) {
    $opts = @{}; $rem = @()

    function err($msg) {
        $opts, $rem, $msg
    }

    function regex_escape($str) {
        return [Regex]::Escape($str)
    }

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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCnD6aCmAqTXd+0
# o1hrvBOi61L8YSKYaKVMo5aza+MgwqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFxCsnIZOzCocSqMq+4Z
# JyOT8dMvkvG0reQ15ieu9wJBMA0GCSqGSIb3DQEBAQUABIIBAJ/5AOvC2O0uihWp
# UDTb/OD4IGrkWp6ybgsrPoxFdIYSBTFW0SJgPXmv7GM5PdNfn9pSgy06BRj6TsTp
# cbeEDtrgPt3/U9iMBYSAms+Ti2DWiG/xGiD1Zc9tIhhZGTAbgz6M/5iHNNcj64LG
# ixdDWMJ9D0lUci84uX8hZnxFc6myFjCXkJHkG8+3L1cTwMyRrK9vNBpEUaxTHzRc
# DZkZZR/29S51XF9cx6Zu4Y+qVX95PUiuVDzqjDFrG+69fdhDF3iljuly6VZKl906
# cgc0uCnQBbyziG8z0kJPn1YvCr8wdZlj5wcFlpPV5uXcEAICZSK8nvqRS2lamVQr
# PtLa+eo=
# SIG # End signature block
