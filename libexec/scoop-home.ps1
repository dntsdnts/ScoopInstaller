# Usage: scoop home <app>
# Summary: Opens the app homepage
param($app)

. "$PSScriptRoot\..\lib\manifest.ps1" # 'Get-Manifest'

if ($app) {
    $null, $manifest, $bucket, $null = Get-Manifest $app
    if ($manifest) {
        if ($manifest.homepage) {
            Start-Process $manifest.homepage
        } else {
            abort "Could not find homepage in manifest for '$app'."
        }
    } else {
        abort "Could not find manifest for '$app'."
    }
} else {
    my_usage
    exit 1
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAnXM+R7HQybLmQ
# hScKKL1rHwyebX9bw8j8WbM5TnPlQKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP6j4Zm+9F12VHdh81z2
# AOUi5Grn6a0Pw2+Y9Bz1CGuFMA0GCSqGSIb3DQEBAQUABIIBAKPO6Kcgc2Lmd1vd
# YRV/rLSNUM/NNVQhISJqo4IXfSWojdts9IslkIxoOUmJIP/AnOAov/NimCBfIp3E
# J35T1CpEf9t1bYifrEVAAy4EaACA3X+7f7a9K8X4Ycaugy2uaqxYYVgtis6GwJIB
# 2xJZlZKPWzf3SbJOOxStfq6rHQqpGA51rAL91GF7RULoLM+vk3Vv3pYHJaeVL2PQ
# gLuZiLxc9zcWKAA7/5MBMN//5HMNTPOWa2TG2V0ZIrmFROvAMNJMya8VbU1KOS2z
# m1xy9wf3lMpO51AKE+72zw0vWdoR1B0Y5YlpyinQSollyyCgwuQJ0tsDUyIT9OL6
# clrnDb4=
# SIG # End signature block
