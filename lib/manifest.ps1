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
    if (!$str) { return $null }
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

    ensure (usermanifestsdir) | Out-Null
    $manifest_path = "$(usermanifestsdir)\$app.json"

    if (get_config USE_SQLITE_CACHE) {
        $cached_manifest = (Get-ScoopDBItem -Name $app -Bucket $bucket -Version $version).manifest
        if ($cached_manifest) {
            $cached_manifest | Out-UTF8File $manifest_path
            return $manifest_path
        }
    }

    if (!($manifest.autoupdate)) {
        abort "'$app' does not have autoupdate capability`r`ncouldn't find manifest for '$app@$version'"
    }

    try {
        Invoke-AutoUpdate $app $manifest_path $manifest $version $(@{ })
        return $manifest_path
    } catch {
        Write-Host -ForegroundColor DarkRed "Could not install $app@$version"
    }

    return $null
}

function url($manifest, $arch) { arch_specific 'url' $manifest $arch }
function installer($manifest, $arch) { arch_specific 'installer' $manifest $arch }
function uninstaller($manifest, $arch) { arch_specific 'uninstaller' $manifest $arch }
function hash($manifest, $arch) { arch_specific 'hash' $manifest $arch }
function extract_dir($manifest, $arch) { arch_specific 'extract_dir' $manifest $arch }
function extract_to($manifest, $arch) { arch_specific 'extract_to' $manifest $arch }

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUofK+jYSA0RfjktdUmfnIUNKv
# nvegggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
# AQ0FADAPMQ0wCwYDVQQDDARxcnFyMB4XDTI0MDYyOTA3MzExOFoXDTI1MDYyOTA3
# NTExOFowDzENMAsGA1UEAwwEcXJxcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAMxsgrkeoiqZ/A195FjeG+5hvRcDnz/t8P6gDxE/tHo7KsEX3dz20AbQ
# pZ/Cz+NLE3tDsubThXs+t/7V7ITKHc4HwPuXAIhhtSNWDFUR46VT3duLWS6/upJD
# kems/lRUt80QloR/5DeaDMcZBLe72nGQtUEa4T0FnAlV2KKz5mcDzR8LOZO2cbTx
# 1k9+ux2a868x11tFQfl1+dmuxIEVhVcwGgs4hwx1EwL5w8G5yxrdZH1+NwMb3Dj1
# 6cxT7aRF4fg0YMChoyWhys7lmMyvJR7Ok122RUGySOEjeMYKuPotnHmRAj5eETsx
# vR2ju7OEOE5nlwHMs4jMW+eUB0A2rsECAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeA
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRcSVrdsgcV9IFAaEQwHJuB
# 7i7PSzANBgkqhkiG9w0BAQ0FAAOCAQEASKmIff9FS55bdHLM+EViX+raZnVK79/Z
# pV3yVwUAYEoyq1DaYdZcrxJ16K06gk8k+XI0OeRl2jeI0GKRNhSEllLXv2/iWNFj
# 5ecUtxMJeXOh1SMA2f+eIVyns0LtfDVVUb2wC+W5S/n5/jRTGpEYj/Gf2nb5kje6
# rBfB/x1kk0Z5AAM3w3u36Jcs34Jno+ErZO10V0Gm2lD3omE4iRoWNBRZJ7FyyMJN
# xdGsxOS0cVA+6oaCtpxT/cj41V6n5JsTrdlj6OxRgzyWEtIjwf6EDuP/t8dGB14J
# hPAaInDUQPY0CdbP4A0Dl9KjloG3nHcDXn9bv057/g/ZUHbeJBfOszGCAcQwggHA
# AgEBMCMwDzENMAsGA1UEAwwEcXJxcgIQUV4zeN7Tnr5I+Jfnrr0i6zAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUeeVEnD8L8SoOxnN2xry9Zjs3oiwwDQYJKoZIhvcNAQEBBQAEggEA
# qONoElWg2UQGt70GcGMvQgioyazBjG+CJC5bH+xv3O/XMJZ9tlDQPrPJI8EJyWck
# +0icp4kbAaujywiA11Pd55yz2XeRiAKEdEg+JnnAfnhXRV4SeLEUUAYahKsYv43R
# HzOc8FZeMJvunjjcG0xuTDeARgKuHYZB/od0tjRgYdEJLhSK3AtuVDmTfcLPSWOM
# U3lqk/iJOX8TDqIC+AEnoVe7Hoa8HxkU+Ev86sAHldjjkQX5apckMc4V+6lEjVsj
# 1FEVCaTB5U4uVrfYhWfZEicpQhk4p4TP/bs1bhafG3CWXhymjHGLQpZdKP7yqfRv
# i+WBSIGDwz1gRAGEP4N5qA==
# SIG # End signature block
