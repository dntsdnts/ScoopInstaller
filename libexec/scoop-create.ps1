# Usage: scoop create <url>
# Summary: Create a custom app manifest
# Help: Create your own custom app manifest
param($url)

function create_manifest($url) {
    $manifest = new_manifest

    $manifest.url = $url

    $url_parts = $null
    try {
        $url_parts = parse_url $url
    } catch {
        abort "Error: $url is not a valid URL"
    }

    $name = choose_item $url_parts 'App name'
    $name = if ($name.Length -gt 0) {
        $name
    } else {
        file_name ($url_parts | Select-Object -Last 1)
    }

    $manifest.version = choose_item $url_parts 'Version'

    $manifest | ConvertTo-Json | Out-File -FilePath "$name.json" -Encoding ASCII
    $manifest_path = Join-Path $pwd "$name.json"
    Write-Host "Created '$manifest_path'."
}

function new_manifest() {
    @{ 'homepage' = ''; 'license' = ''; 'version' = ''; 'url' = '';
        'hash' = ''; 'extract_dir' = ''; 'bin' = ''; 'depends' = ''
    }
}

function file_name($segment) {
    $segment.substring(0, $segment.lastindexof('.'))
}

function parse_url($url) {
    $uri = New-Object Uri $url
    $uri.pathandquery.substring(1).split('/')
}

function choose_item($list, $query) {
    for ($i = 0; $i -lt $list.count; $i++) {
        $item = $list[$i]
        Write-Host "$($i + 1)) $item"
    }
    $sel = Read-Host $query

    if ($sel.trim() -match '^[0-9+]$') {
        return $list[$sel - 1]
    }

    $sel
}

if (!$url) {
    & "$PSScriptRoot\scoop-help.ps1" create
} else {
    create_manifest $url
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD/bKGPGTF1Gq2I
# gbzycSkAziXMP4QSMEqReMNPCGXO2qCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII8QDL4JF1nqFefMdIQW
# 7xPYETgKi6/nVWpnTJ61Xse1MA0GCSqGSIb3DQEBAQUABIIBABdAQwc7pdOWwDsy
# AtPgRbMuuRSYakvjYMlyKhUNUZiMo8yaoKSbw0P3IzFTM5DiZEkyynA102lDCU5z
# HwvRbmofAvyXxAyb1KQqbVsEC0GOTRtQ1mGsvsD3GEbxCRH/irB9eWXoAmE9xefi
# rKoSdXihcOnvGjIPv+N5hdURsK2B99pWDf1EzNlUcvgb8IKODcFujktkmWQIwQDw
# khO933xWRjMlvegYyhthidZyz6w/bKIzWerK6UzaAOcZfVg2ssY1Zh9txtLq/OQC
# ZFMHmWj0pBM188IXXSjnCnKShEvMvaEhkhQ5hbdfXrfXY8sbzqHQKxjm+Lm0XAQm
# yA3QptM=
# SIG # End signature block
