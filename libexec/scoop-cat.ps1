# Usage: scoop cat <app>
# Summary: Show content of specified manifest.
# Help: Show content of specified manifest.
# If configured, `bat` will be used to pretty-print the JSON.
# See `cat_style` in `scoop help config` for further information.

param($app)

. "$PSScriptRoot\..\lib\json.ps1" # 'ConvertToPrettyJson'
. "$PSScriptRoot\..\lib\manifest.ps1" # 'Get-Manifest'

if (!$app) { error '<app> missing'; my_usage; exit 1 }

$null, $manifest, $bucket, $url = Get-Manifest $app

if ($manifest) {
        $style = get_config CAT_STYLE
        if ($style) {
                $manifest | ConvertToPrettyJson | bat --no-paging --style $style --language json
        } else {
                $manifest | ConvertToPrettyJson
        }
} else {
        abort "Couldn't find manifest for '$app'$(if($url) { " at the URL $url" })."
}

exit $exitCode

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4N+lbw9goX3Nnaa5sbguKmEx
# efugggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUnUMsmKY0cnFSzp+cnLRIwW7tM/MwDQYJKoZIhvcNAQEBBQAEggEA
# coaajkfrtwn510Dy5eOnLDbVfYTwdG76lICQuyipULL7hP6VZEphiz+Rl+R2aOvS
# HqWDNIOcj83WSd1ArVgHv90/f7daZdWhE5FlG4g4tqVK5090/uJIeCtM14z+JwVS
# 6rt1q3SaqiMy3YTMYcO4s3bf6TGIIMb/q2V+H0x3aczHy9wDNcZ42NNtceDKet5L
# azR01T6XXExsS1ucpPp381krFdxXA/HqWhIFakSMbEWsAMDP3iojbQCqB2egdsVs
# Q+w5ryClxputG9FoJD3V0Ek9B+3L03Ge8wu2Zzg77cO9JIy6j+M+5YJjlEUEcyk3
# 9qabOOLH9WYlUzThZ4xNog==
# SIG # End signature block
