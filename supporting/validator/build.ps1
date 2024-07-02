Param([Switch]$Fast)
Push-Location $PSScriptRoot
. "$PSScriptRoot\..\..\lib\core.ps1"
. "$PSScriptRoot\..\..\lib\install.ps1"

if (!$Fast) {
    Write-Host "Install dependencies ..."
    & "$PSScriptRoot\install.ps1"
}

$output = "$PSScriptRoot\bin"
if (!$Fast) {
    Get-ChildItem "$PSScriptRoot\packages\Newtonsoft.*\lib\net45\*.dll" -File | ForEach-Object { Copy-Item $_ $output }
}
Write-Output 'Compiling Scoop.Validator.cs ...'
& "$PSScriptRoot\packages\Microsoft.Net.Compilers.Toolset\tasks\net472\csc.exe" -deterministic -platform:anycpu -nologo -optimize -target:library -reference:"$output\Newtonsoft.Json.dll" -reference:"$output\Newtonsoft.Json.Schema.dll" -out:"$output\Scoop.Validator.dll" Scoop.Validator.cs
Write-Output 'Compiling validator.cs ...'
& "$PSScriptRoot\packages\Microsoft.Net.Compilers.Toolset\tasks\net472\csc.exe" -deterministic -platform:anycpu -nologo -optimize -target:exe -reference:"$output\Scoop.Validator.dll" -reference:"$output\Newtonsoft.Json.dll" -reference:"$output\Newtonsoft.Json.Schema.dll" -out:"$output\validator.exe" validator.cs

Write-Output 'Computing checksums ...'
Remove-Item "$PSScriptRoot\bin\checksum.sha256" -ErrorAction Ignore
Remove-Item "$PSScriptRoot\bin\checksum.sha512" -ErrorAction Ignore
Get-ChildItem "$PSScriptRoot\bin\*" -Include *.exe, *.dll | ForEach-Object {
    "$((Get-FileHash -Path $_ -Algorithm SHA256).Hash.ToLower()) *$($_.Name)" | Out-File "$PSScriptRoot\bin\checksum.sha256" -Append -Encoding oem
    "$((Get-FileHash -Path $_ -Algorithm SHA512).Hash.ToLower()) *$($_.Name)" | Out-File "$PSScriptRoot\bin\checksum.sha512" -Append -Encoding oem
}
Pop-Location

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGQ2TblG0D1Gq7OkQEXdxueN7
# b/SgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUBOs2bevNXGBZXrGS7Bg5vJwdAyEwDQYJKoZIhvcNAQEBBQAEggEA
# xpr1lpDKh/9k3qWJ+1Q/JhO2Oy4cLdYJaeOdjlVQ3MK6Pc2EoqXLM6TD8pcS13wi
# AFS4SbVI4OipurfNP7P+Rec9k+Sl0yaCne2a8t5qpt6qvF8lsHbTcuNQKlEpxyBd
# yXSD67uLZ+Y88ZJrj5AlN0EjzmizQXOnOIcd4Psj9IcuR0u83oAaZmhQEpAU0HDY
# +6qDi3eTIiCp+HtROz/0nX/WTTT4BR8S87rYWM+k3omJv6vdw1Md+1irgZNAVz+2
# oPWEsqkyuIMEn6t58N4oEQYY/9UCCTzP/kWn9xQZk/XajV9xxQSxX74OnDsgtod8
# 9sWysINqfIpbFAk3L9bWmA==
# SIG # End signature block
