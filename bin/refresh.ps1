# for development, update the installed scripts to match local source
. "$PSScriptRoot\..\lib\core.ps1"

$src = "$PSScriptRoot\.."
$dest = ensure (versiondir 'scoop' 'current')

# make sure not running from the installed directory
if("$src" -eq "$dest") { abort "$(strip_ext $myinvocation.mycommand.name) is for development only" }

'copying files...'
$output = robocopy $src $dest /mir /njh /njs /nfl /ndl /xd .git tmp /xf .DS_Store last_updated

$output | Where-Object { $_ -ne "" }

Write-Output 'creating shim...'
shim "$dest\bin\scoop.ps1" $FALSE

Set-AuthenticodeSignature "$dest\bin\scoop.ps1" (ls Cert:\CurrentUser\My\ -CodeSigningCert)

success 'scoop was refreshed!'

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCmrpTEzoR2ZYFi
# tez4h+Eg7De+u9HKWKaEWMjLs7SuRqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOefqiOD3zAZci1U9TD7
# VkemRSGqqBa8CyzTVz58jTziMA0GCSqGSIb3DQEBAQUABIIBAEImTevBOCKLNIqk
# k+CF6JdYT1yrl9hBoR+I01Vb2eIazD4iXkyKRV6Ohr2xL9hxMHDGCxK2tG/Kj6LV
# oej9X8nJyQI04vW2EZRxSqUtt9A7SBbSGRE3HfFB6eDzIRexIz6qOblDJ7ZugZPj
# hcDNlXt7bs8c6vaOW6X+7NU24HWX/mqZ62SX90uX9QseWEof87GBGdedbVbNfOJy
# kLdkd9NsqB06JfoGaj1A88MbaLPyJV/mT9gfJwhKmvQk5T00ztlM2yq4yMcf3PoX
# uYks8T+vocILR8+Wu4BTqW3Ye5P7PVAItTjX5E96emH0spV7HHqs72HnE8S8seeU
# P/12L08=
# SIG # End signature block
