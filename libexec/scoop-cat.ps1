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
    abort "Couldn't find manifest for '$app'$(if($bucket) { " from '$bucket' bucket" } elseif($url) { " at '$url'" })."
}

exit $exitCode

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBjNQKDPId1x0ZV
# DlpT/Pwrme8f+pIrh8z6aJ+DQG8vqaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGUY2Z4Lscrs/OHPfMV6
# f55hGt37RwFC3MwxzYTp9H63MA0GCSqGSIb3DQEBAQUABIIBAKJtvqJGLZWi6T/p
# 6OF5eC62OG2BX2GseLXvdPSn+zI9ac7N80UFEpj/fSIjYp7b1CH1t/lAdHtJv6kF
# xVW56XWeyQSfd4QX1qUAWYXntSAbAL/ZWcbWFq5nTPM+EzJU/pO1yO4tPZYRsrD3
# UIfAZQAuzxsi+lBGLB5m0dypZ0SN1Cjd/+oiRNHdf2A0+Hrh1V06ulWyCKPMiSlw
# mfxY+JQUF6Qefuccmue6O1BKBzI++YUSg5m/jtKokQ+ypo1DeNFvs3v+bgYRf3zO
# T4grBIoKX6jDl8TOE4ctLRwq+JGZg7rmEbO6yFcyiN6ScmwJcawN2ygDpKMpSUy3
# nIe/5rU=
# SIG # End signature block
