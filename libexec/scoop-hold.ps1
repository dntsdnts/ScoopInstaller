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

foreach ($app in $apps) {

    if ($app -eq 'scoop') {
        $hold_update_until = [System.DateTime]::Now.AddDays(1)
        set_config HOLD_UPDATE_UNTIL $hold_update_until.ToString('o') | Out-Null
        success "$app is now held and might not be updated until $($hold_update_until.ToLocalTime())."
        continue
    }
    if (!(installed $app $global)) {
        if ($global) {
            error "'$app' is not installed globally."
        } else {
            error "'$app' is not installed."
        }
        continue
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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhDlRwqOffWf9Nhhm6Smtv2Sw
# ffGgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUZbqjEmJqKbtcK7nC3P6Vfth3YAowDQYJKoZIhvcNAQEBBQAEggEA
# cGasOVVLxaTUyrYZVSukR45eobThSWdR8VSCfrt4KlfZBRkB5JWb7dRwQHiMTpL9
# ftd34/qngEqHrtCyeXkWqX3dWE1J++rH/2qH7DHj6BSyKoGUIpP8vkKqyv+TtPL0
# FL/Fe6K450TVFYY2WgsKQlCSUhhwDcgfQ6VC+JgsY/HY75pxTpO6emVZWa8KePv9
# SY7zufSG8XVFZd0X4U0GVEmJjiHENjpl8wcOvus3HmvzeCteR3NCyxuCZgu8OyxZ
# PkAIHQPgexJWcY2ysOiHok2DsvUGXAwnOlcBaumhxA7uTtuHs5vVgwaClsljfbYC
# uck/DDtumm4iR/I3zMBDTQ==
# SIG # End signature block
