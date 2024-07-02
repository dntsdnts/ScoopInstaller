# Usage: scoop prefix <app>
# Summary: Returns the path to the specified app
param($app)

. "$PSScriptRoot\..\lib\versions.ps1" # 'currentdir' (indirectly)

if (!$app) {
    my_usage
    exit 1
}

$app_path = currentdir $app $false
if (!(Test-Path $app_path)) {
    $app_path = currentdir $app $true
}

if (Test-Path $app_path) {
    Write-Output $app_path
} else {
    abort "Could not find app path for '$app'."
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCzWyV5N2Az8Glz
# a+dDazufl9u6sYb+RxnbHCxLdk2MV6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGfY6Jhi7/cDpuiyCNin
# nqILLigS/G2lJF9+DfAeFmELMA0GCSqGSIb3DQEBAQUABIIBAI7LtWREc9ijdNJv
# +sL0YMXjoyfBJ7t1LQb1/CgDuTpiogaH+oHSkDzYSrtTTi7yePlGoqeq2HKVeOhu
# 9vKZ84CnqGvLNOQnlfXg+M5RGY99NlukwbsCuyDnVbWWs0PSz2QtD8CZmHkLCd5p
# ez4Zo0ARy+ZnNSuQJCYg6WXBI/quhQragPJvQckQYldfRwfpSp/2nk1pbPX7jnK3
# oZ5qV1zp1yZGVPp6RoLlT7ZsUkE5CspGERaw/fvCYYUXXDuXgnQdKA+xbR5WVPpp
# N9wGgKJxspbHwM8GkGGAug0KtcISkx4p4qcgM3yl2YcJjroSUml/cwHhUbCJAWY6
# 3ECGS7Y=
# SIG # End signature block
