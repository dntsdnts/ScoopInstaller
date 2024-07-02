function manifest_path($app, $bucket) {
    (Get-ChildItem (Find-BucketDirectory $bucket) -Filter "$(sanitary_path $app).json" -Recurse).FullName
}

function parse_json($path) {
    if ($null -eq $path -or !(Test-Path $path)) { return $null }
    try {
        Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    } catch {
        warn "Error parsing JSON at '$path'."
    }
}

function url_manifest($url) {
    $str = $null
    try {
        $wc = New-Object Net.Webclient
        $wc.Headers.Add('User-Agent', (Get-UserAgent))
        $data = $wc.DownloadData($url)
        $str = (Get-Encoding($wc)).GetString($data)
    } catch [system.management.automation.methodinvocationexception] {
        warn "error: $($_.exception.innerexception.message)"
    } catch {
        throw
    }
    if(!$str) { return $null }
    try {
        $str | ConvertFrom-Json -ErrorAction Stop
    } catch {
        warn "Error parsing JSON at '$url'."
    }
}

function Get-Manifest($app) {
    $bucket, $manifest, $url = $null
    $app = $app.TrimStart('/')
    # check if app is a URL or UNC path
    if ($app -match '^(ht|f)tps?://|\\\\') {
        $url = $app
        $app = appname_from_url $url
        $manifest = url_manifest $url
    } else {
        $app, $bucket, $version = parse_app $app
        if ($bucket) {
            $manifest = manifest $app $bucket
        } else {
            foreach ($tekcub in Get-LocalBucket) {
                $manifest = manifest $app $tekcub
                if ($manifest) {
                    $bucket = $tekcub
                    break
                }
            }
        }
        if (!$manifest) {
            # couldn't find app in buckets: check if it's a local path
            if (Test-Path $app) {
                $url = Convert-Path $app
                $app = appname_from_url $url
                $manifest = url_manifest $url
            } else {
                if (($app -match '\\/') -or $app.EndsWith('.json')) { $url = $app }
                $app = appname_from_url $app
            }
        }
    }
    return $app, $manifest, $bucket, $url
}

function manifest($app, $bucket, $url) {
    if ($url) { return url_manifest $url }
    parse_json (manifest_path $app $bucket)
}

function save_installed_manifest($app, $bucket, $dir, $url) {
    if ($url) {
        $wc = New-Object Net.Webclient
        $wc.Headers.Add('User-Agent', (Get-UserAgent))
        $data = $wc.DownloadData($url)
        (Get-Encoding($wc)).GetString($data) | Out-UTF8File "$dir\manifest.json"
    } else {
        Copy-Item (manifest_path $app $bucket) "$dir\manifest.json"
    }
}

function installed_manifest($app, $version, $global) {
    parse_json "$(versiondir $app $version $global)\manifest.json"
}

function save_install_info($info, $dir) {
    $nulls = $info.keys | Where-Object { $null -eq $info[$_] }
    $nulls | ForEach-Object { $info.remove($_) } # strip null-valued

    $file_content = $info | ConvertToPrettyJson # in 'json.ps1'
    [System.IO.File]::WriteAllLines("$dir\install.json", $file_content)
}

function install_info($app, $version, $global) {
    $path = "$(versiondir $app $version $global)\install.json"
    if (!(Test-Path $path)) { return $null }
    parse_json $path
}

function arch_specific($prop, $manifest, $architecture) {
    if ($manifest.architecture) {
        $val = $manifest.architecture.$architecture.$prop
        if ($val) { return $val } # else fallback to generic prop
    }

    if ($manifest.$prop) { return $manifest.$prop }
}

function Get-SupportedArchitecture($manifest, $architecture) {
    if ($architecture -eq 'arm64' -and ($manifest | ConvertToPrettyJson) -notmatch '[''"]arm64["'']') {
        # Windows 10 enables existing unmodified x86 apps to run on Arm devices.
        # Windows 11 adds the ability to run unmodified x64 Windows apps on Arm devices!
        # Ref: https://learn.microsoft.com/en-us/windows/arm/overview
        if ($WindowsBuild -ge 22000) {
            # Windows 11
            $architecture = '64bit'
        } else {
            # Windows 10
            $architecture = '32bit'
        }
    }
    if (![String]::IsNullOrEmpty((arch_specific 'url' $manifest $architecture))) {
        return $architecture
    }
}

function generate_user_manifest($app, $bucket, $version) {
    # 'autoupdate.ps1' 'buckets.ps1' 'manifest.ps1'
    $app, $manifest, $bucket, $null = Get-Manifest "$bucket/$app"
    if ("$($manifest.version)" -eq "$version") {
        return manifest_path $app $bucket
    }
    warn "Given version ($version) does not match manifest ($($manifest.version))"
    warn "Attempting to generate manifest for '$app' ($version)"

    if (!($manifest.autoupdate)) {
        abort "'$app' does not have autoupdate capability`r`ncouldn't find manifest for '$app@$version'"
    }

    ensure (usermanifestsdir) | out-null
    try {
        Invoke-AutoUpdate $app "$(Convert-Path (usermanifestsdir))\$app.json" $manifest $version $(@{ })
        return Convert-Path (usermanifest $app)
    } catch {
        write-host -f darkred "Could not install $app@$version"
    }

    return $null
}

function url($manifest, $arch) { arch_specific 'url' $manifest $arch }
function installer($manifest, $arch) { arch_specific 'installer' $manifest $arch }
function uninstaller($manifest, $arch) { arch_specific 'uninstaller' $manifest $arch }
function hash($manifest, $arch) { arch_specific 'hash' $manifest $arch }
function extract_dir($manifest, $arch) { arch_specific 'extract_dir' $manifest $arch}
function extract_to($manifest, $arch) { arch_specific 'extract_to' $manifest $arch}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBoYYDNuJlvnVEL
# 14/JCyOLx7zHESfCzdom43bl+7J8Z6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGZBA2u4KXH3TZfCXLxr
# roMwkQb4JUFyQtZdqANBcQokMA0GCSqGSIb3DQEBAQUABIIBAKw4wGB/dBxzSsi8
# JmQSPbAqp0i1yjAMv0xw7dmn1na9lFrR3e2gO5p9hAavqBgCLE1ldEc2hpYY7Syk
# joX99VyesUVQbnMORV6iFxujoNi5uW3AnTStwNUeDPC5pUgfajBm7Q0iMAd33ZE1
# B89QuGVGDKPh/YmsvPHGT3x6uuVC7DanTYDcAAgIvSSmXmYKo9vE35awf7dFDE0M
# 63sTcOz4ukoJko9uCTPbwu24zeUMJ20EZwmqZ1KPAL1H0/sF17jkRqLTD1j6X7CQ
# cx6WbERtv1dmUrVhfFCpkUame6T5dknAQlzvdCdtDMmc/gmSt9/eTLHUMIFRjDkZ
# 8ImoRlc=
# SIG # End signature block
