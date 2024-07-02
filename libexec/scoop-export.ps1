# Usage: scoop export > scoopfile.json
# Summary: Exports installed apps, buckets (and optionally configs) in JSON format
# Help: Options:
#   -c, --config       Export the Scoop configuration file too

. "$PSScriptRoot\..\lib\json.ps1" # 'ConvertToPrettyJson'

$export = @{}

if ($args[0] -eq '-c' -or $args[0] -eq '--config') {
    $export.config = $scoopConfig
    # Remove machine-specific properties
    foreach ($prop in 'last_update', 'root_path', 'global_path', 'cache_path', 'alias') {
        $export.config.PSObject.Properties.Remove($prop)
    }
}

$export.buckets = list_buckets
$export.apps = @(& "$PSScriptRoot\scoop-list.ps1" 6>$null)

$export | ConvertToPrettyJSON

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBA8jdjks4BBfuC
# dsFJ2LfY3G3SLyUjZH6hWcsbVa5JLaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEN67fezLXovFAUeHdHU
# ImWZ8+CP+g2FmcQy0WKXbkIFMA0GCSqGSIb3DQEBAQUABIIBAK0ehhkhkIo2b1dL
# D2pTcIocGuNscPoYp73fgAytoZfvz2gmY8vhXqZat6MYaIgLf6qSlPAApEoNSKcs
# RvJgfKjuDz4KT0CqCV8haoAnmjhuS4onOqjuTuGZ2ZGrwdkzdPriFvBR9lL9XLFR
# uCMn11MFSvmQ3DfmXF/OIC4T3nUMDaIHVy2FUx1rfmzfrWi8yFRdIkClvFCPoluN
# 6foa1+mRD9dzu2qjxaikJnAJ08ZJK4/p/Kfk3Mz+Fbb1pnsqikElpNAbquflX25j
# Pv/LjrZQotSuac/gi33t34eDamGLrTfLykc48g+NF0DaPAMKQxxV8OywYssLuMDs
# 9oP1Z2g=
# SIG # End signature block
