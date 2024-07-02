# copies fixtures to a working directory
function setup_working($name) {
    $fixtures = "$PSScriptRoot/fixtures/$name"
    if (!(Test-Path $fixtures)) {
        Write-Host "couldn't find fixtures for $name at $fixtures" -f red
        exit 1
    }

    # reset working dir
    $working_dir = "$([IO.Path]::GetTempPath())ScoopTestFixtures/$name"

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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZXHo63cLLJKBPyU8GBIPpukJ
# mA6gggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUZV0FBUndTNdVXAyeFZYgf895msgwDQYJKoZIhvcNAQEBBQAEggEA
# iWxftOfbaV3AvMaOUFZVpNSwHxpbaRq2bov2IKXEkePPLkt2ozyFu6xIPcwMIN+K
# 8Ql/Bqs8kXhav8sog2fzf/oMPDYvwrEDXr3vEahE4/t8S584mDR5sonXLwUkNyTP
# UcfAFFK8NgAhEPfTHJrKvWiQYDY14q4/NoiwaA84VU7xeE8/G4cRLrayVxkj8bDq
# GrfaBRWZ2GqnHc5bqaQ1Zj8PG5V82+NRGa+ruBo8FjPVKxc/DNzBA4Z0Ksrzhkd/
# CM5ghWYlIq3ENAlgl1liE/6wNgUFi3Jatuxjxn+zePI9QwnZbIUr4oPFQ5poDrBY
# qazgWqSTMZm2mVqQMfAzGQ==
# SIG # End signature block
