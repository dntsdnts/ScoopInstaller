function find_description($url, $html, $redir = $false) {
    $meta = meta_tags $html

    # check <meta property="og:description">
    $og_description = meta_content $meta 'property' 'og:description'
    if($og_description) {
        return $og_description, '<meta property="og:description">'
    }

    # check <meta name="description">
    $description = meta_content $meta 'name' 'description'
    if($description) {
        return $description, '<meta name="description">'
    }

    # check <meta http-equiv="refresh"> redirect
    $refresh = meta_refresh $meta $url
    if($refresh -and !$redir) {
        $wc = New-Object Net.Webclient
        $wc.Headers.Add('User-Agent', (Get-UserAgent))
        $data = $wc.DownloadData($refresh)
        $html = (Get-Encoding($wc)).GetString($data)
        return find_description $refresh $html $true
    }

    # check text for 'x is ...'
    $text = html_text $html $meta
    $text_desc = find_is $text
    if($text_desc) {
        return $text_desc, 'text'
    }

    # first paragraph
    $first_para = first_para $html
    if($first_para) {
        return $first_para, 'first <p>'
    }

    return $null, $null
}

function clean_description($description) {
    if(!$description) { return $description }
    $description = $description -replace '\n', ' '
    $description = $description -replace '\s{2,}', ' '
    return $description.trim()
}

# Collects meta tags from $html into hashtables.
function meta_tags($html) {
    $tags = @()
    $meta = ([regex]'<meta [^>]+>').matches($html)
    $meta | ForEach-Object {
        $attrs = ([regex]'([\w-]+)="([^"]+)"').matches($_.value)
        $hash = @{}
        $attrs | ForEach-Object {
            $hash[$_.groups[1].value] = $_.groups[2].value
        }
        $tags += $hash
    }
    $tags
}

function meta_content($tags, $attribute, $search) {
    if(!$tags) { return }
    return $tags | Where-Object { $_[$attribute] -eq $search } | ForEach-Object { $_['content'] }
}

# Looks for a redirect URL in a <meta> refresh tag.
function meta_refresh($tags, $url) {
    $refresh = meta_content $tags 'http-equiv' 'refresh'
    if($refresh) {
        if($refresh -match '\d+;\s*url\s*=\s*(.*)') {
            $refresh_url = $matches[1].trim("'", '"')
            if($refresh_url -notmatch '^https?://') {
                $refresh_url = "$url$refresh_url"
            }
            return $refresh_url
        }
    }
}

function html_body($html) {
    if($html -match '(?s)<body[^>]*>(.*?)</body>') {
        $body = $matches[1]
        $body = $body -replace '(?s)<script[^>]*>.*?</script>', ' '
        $body = $body -replace '(?s)<!--.*?-->', ' '
        return $body
    }
}

function html_text($body, $meta_tags) {
    $body = html_body $html
    if($body) {
        return strip_html $body
    }
}

function strip_html($html) {
    $html = $html -replace '(?s)<[^>]*>', ' '
    $html = $html -replace '\t', ' '
    $html = $html -replace '&nbsp;?', ' '
    $html = $html -replace '&gt;?', '>'
    $html = $html -replace '&lt;?', '<'
    $html = $html -replace '&quot;?', '"'

    $encoding_meta = meta_content $meta_tags 'http-equiv' 'Content-Type'
    if($encoding_meta) {
        if($encoding_meta -match 'charset\s*=\s*(.*)') {
            $charset = $matches[1]
            try {
                $encoding = [text.encoding]::getencoding($charset)
            } catch {
                Write-Warning "Unknown charset"
            }
            if($encoding) {
                $html = ([regex]'&#(\d+);?').replace($html, {
                    param($m)
                    try {
                        return $encoding.getstring($m.Groups[1].Value)
                    } catch {
                        return $m.value
                    }
                })
            }
        }
    }

    $html = $html -replace '\n +', "`r`n"
    $html = $html -replace '\n{2,}', "`r`n"
    $html = $html -replace ' {2,}', ' '
    $html = $html -replace ' (\.|,)', '$1'
    return $html.trim()
}

function find_is($text) {
    if($text -match '(?s)[\n\.]((?:[^\n\.])+? is .+?[\.!])') {
        return $matches[1].trim()
    }
}

function first_para($html) {
    $body = html_body $html
    if($body -match '(?s)<p[^>]*>(.*?)</p>') {
        return strip_html $matches[1]
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBr8IAyKH5V2cnQ
# SuNvlCV0fQkvPIJVaGIClfU24kdMe6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOV1uW7vjeak8WfeDzh6
# 2hx/+Ft0wHjYVpEHSX84VFHVMA0GCSqGSIb3DQEBAQUABIIBAFFnoquRhE9Gn00J
# 1IhqfH4ZxmXEECT/uhJ8vD1u79ZYuu208caSX8tssvEa216L2C6/4igb6eANKMf/
# hhtCCM8ejzHg9BDgNmvhqvULB98BHLSPK++KOvHoZXvLvVhDAybAyBTrJXBIABaL
# 9y4sR468XymvD6NuyZJtn0o0lZ38rB71stornRWwiQKul+cVG4sJEXo+g+MJLRrr
# ORqugMt6DyphXqvbO1gC5v8ZLxTMTvBvILb1dnRRzB+K3F6d7mzkTVA9MIKUiWHT
# pignjBMP6CiUYDGPAvzNo9PJePYcx39Zg3cZR2zA4HamZCCaaf6Zp/mkEVQZIp84
# SLXQ6ME=
# SIG # End signature block
