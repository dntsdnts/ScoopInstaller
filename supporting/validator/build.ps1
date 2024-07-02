Param([Switch]$Fast)
Push-Location $PSScriptRoot
. "$PSScriptRoot\..\..\lib\core.ps1"
. "$PSScriptRoot\..\..\lib\install.ps1"

if (!$Fast) {
    Write-Host 'Install dependencies ...'
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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBkWwi9mZzgpV4f
# 54ZQmlShy57UI9ZfmDjoeTCFbT75raCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICMzPFszZ5hH8T6nfRwh
# vEGrJy0b2JATT7a/RsiVWD6nMA0GCSqGSIb3DQEBAQUABIIBACwZgPY3n7nGCFyw
# oMGJ+iT6R9JvWk+qQCxVChegseXjok9OzCOMIJ/qgxbWeaAWXdCPwW7yoKmotXiI
# INoyurhNgM4vPGuCirPPiFQc1Ldir/QkIJawaQfp55MBPX69WADTBFoC5Ir5e+9G
# 4x9KPueKgJSYWbnMnGv7cG27/WFOktHrdiu/TtmyUSjfRM7uKzUU4IOgnqOqJqsJ
# 6gWyVGzsA9Vfcp/1OxPyFIDXWrn+j2BoT5/Hc2p7Dppksd6rlngH1/VSJg+havpJ
# BpxBrOy64zzG06Wkf25DnhryDEB52mF5SmXQdVXj5zc5lAJ7edAXAeFUkfXA9QHb
# d/iv6SU=
# SIG # End signature block
