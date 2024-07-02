# Usage: scoop hold <apps>
# Summary: Hold an app to disable updates
# Help: To hold a user-scoped app:
#      scoop hold <app>
#
# To hold a global app:
#      scoop hold -g <app>
#
# Options:
#   -g, --global  Hold globally installed apps

. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\json.ps1" # 'save_install_info' (indirectly)
. "$PSScriptRoot\..\lib\manifest.ps1" # 'install_info' 'Select-CurrentVersion' (indirectly)
. "$PSScriptRoot\..\lib\versions.ps1" # 'Select-CurrentVersion'

$opt, $apps, $err = getopt $args 'g' 'global'
if ($err) { "scoop hold: $err"; exit 1 }

$global = $opt.g -or $opt.global

if (!$apps) {
    my_usage
    exit 1
}

if ($global -and !(is_admin)) {
    error 'You need admin rights to hold a global app.'
    exit 1
}

$apps | ForEach-Object {
    $app = $_

    if ($app -eq 'scoop') {
        $hold_update_until = [System.DateTime]::Now.AddDays(1)
        set_config HOLD_UPDATE_UNTIL $hold_update_until.ToString('o') | Out-Null
        success "$app is now held and might not be updated until $($hold_update_until.ToLocalTime())."
        return
    }
    if (!(installed $app $global)) {
        if ($global) {
            error "'$app' is not installed globally."
        } else {
            error "'$app' is not installed."
        }
        return
    }

    if (get_config NO_JUNCTION) {
        $version = Select-CurrentVersion -App $app -Global:$global
    } else {
        $version = 'current'
    }
    $dir = versiondir $app $version $global
    $json = install_info $app $version $global
    if (!$json) {
        error "Failed to hold '$app'."
        continue
    }
    $install = @{}
    $json | Get-Member -MemberType Properties | ForEach-Object { $install.Add($_.Name, $json.($_.Name)) }
    if ($install.hold) {
        info "'$app' is already held."
        continue
    }
    $install.hold = $true
    save_install_info $install $dir
    success "$app is now held and can not be updated anymore."
}

exit $exitcode

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAHuqRBy4/NsNUA
# l7NDPM3mF5ujeOYIHjb9f+NiiV2hv6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPE8ZP5bbZIk8LZsr93k
# KK6VRXOGsUgA6ZIRyg+erlvVMA0GCSqGSIb3DQEBAQUABIIBABFAAhJGzTaGXLIi
# JslK8MYPLxw5eW+/eRO1irCtMLD9er7x0C2dFSTArk/080G/WTmi4CPg+cOzi1DO
# b8M+wWVQ2f/9Fdl4xnr4kRl/lFTAXSIFVnkteeOpx6ShLorCOQYk9TiJacGInSWx
# QI0vsRUSVAbiEjgsxU5dSYlT0MmBWlJgJjQrWbLbPmRNLZyXVqdgSJEiHpF0DS3h
# 54JtktWxIdj0oJNJMPeIbhnnFpc4jLie2pecNtaV08tuzVjZUXZhK762kT5CtWzW
# s5oyFmDIhkSox/sRJMNr8E81U/dB0cg9BQamEArIJwW5GjB9kVGGOKBZKWMVEYmx
# FOKuVYc=
# SIG # End signature block
