# copies fixtures to a working directory
function setup_working($name) {
    $fixtures = "$PSScriptRoot\fixtures\$name"
    if (!(Test-Path $fixtures)) {
        Write-Host "couldn't find fixtures for $name at $fixtures" -f red
        exit 1
    }

    # reset working dir
    $working_dir = "$([IO.Path]::GetTempPath())ScoopTestFixtures\$name"

    if (Test-Path $working_dir) {
        Remove-Item -Recurse -Force $working_dir
    }

    # set up
    Copy-Item $fixtures -Destination $working_dir -Recurse

    return $working_dir
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTMYDboZsOjH1IFmjYAj+YH6T
# UX+gggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQU3F1c7EzkHQ9ZJWsYUFcq5Uzs2mQwDQYJKoZIhvcNAQEBBQAEggEA
# Rp50bLCeT5tI1ECaKJj6vTUNpl/CxH+K7X2+nI27c0vpP1CQpZ1x7m2SAwwyqlmC
# DqswCaPo9qZiS4maOuggNq/0UEmkPpd2Z+IJbTDR88W1qmXH7IRcze3t8ubnTo4/
# yhK0lV04wWdpI6mQJMZTIUaYArrkfF/z3N+fKcZxeFO29/1YCEaecaKCyLEe9GFl
# gz4mO96ekIDjKD+lEPMguh/ShZvYQMVwnzONIgg/83p+8YbgzDChzVb5jvuIZ84k
# AUssGtVKmu49fZgzEOfQVoZGM9UNARPP7c6nB6hbXW5XIZA2GQ4H5G8HF5041umx
# anqHTCGvfUFbUmtNO/9+7A==
# SIG # End signature block
