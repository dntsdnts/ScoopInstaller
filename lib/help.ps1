function usage($text) {
    $text | Select-String '(?m)^# Usage: ([^\n]*)$' | ForEach-Object { "Usage: " + $_.matches[0].groups[1].value }
}

function summary($text) {
    $text | Select-String '(?m)^# Summary: ([^\n]*)$' | ForEach-Object { $_.matches[0].groups[1].value }
}

function scoop_help($text) {
    $help_lines = $text | Select-String '(?ms)^# Help:(.(?!^[^#]))*' | ForEach-Object { $_.matches[0].value; }
    $help_lines -replace '(?ms)^#\s?(Help: )?', ''
}

function my_usage { # gets usage for the calling script
    usage (Get-Content $myInvocation.PSCommandPath -raw)
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+L4ePsl04aqQN
# ohbxKfP3mzU7HDAOIkI0uoGBs8NPV6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKOwe/J78IIi3XEvsBh3
# Ge7FRtUZfnw9gOwCkIq+9+thMA0GCSqGSIb3DQEBAQUABIIBALUmdH/7efplgOZh
# uYSAW+phYM3zuAuHy5bDsB0JDUOfTkkRXHUTmttY6DSnGWWfHmi0ZarbFdC3TrBt
# P8ljxXTClibgSxVhRkKIVI5KV+3nYC/B6rkyXjmJ03eZTHEEqSaxcZggwhwHp2bE
# +Ed9/zaYe9ymofxae5n6rI+C/Gj5139Ao9moGDr0xQFmpRGDB4RS/Iux5T5eGPGE
# adF0hyQSQIupRM9XRIXmgXKGIV5r7ANIKJgznRc7F9betlln0qrHFdTbA5s1ehMn
# VwhmkLtb3GzmTGWmVTPjgo58/nE0SJCz2rA4ShSpIYzix5ZYdLe8K8/iQLQaGNBU
# xJmlH/A=
# SIG # End signature block
