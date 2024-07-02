# Usage: scoop download <app> [options]
# Summary: Download apps in the cache folder and verify hashes
# Help: e.g. The usual way to download an app, without installing it (uses your local 'buckets'):
#      scoop download git
#
# To download a different version of the app
# (note that this will auto-generate the manifest using current version):
#      scoop download gh@2.7.0
#
# To download an app from a manifest at a URL:
#      scoop download https://raw.githubusercontent.com/ScoopInstaller/Main/master/bucket/runat.json
#
# To download an app from a manifest on your computer
#      scoop download path\to\app.json
#
# Options:
#   -f, --force                     Force download (overwrite cache)
#   -h, --no-hash-check             Skip hash verification (use with caution!)
#   -u, --no-update-scoop           Don't update Scoop before downloading if it's outdated
#   -a, --arch <32bit|64bit|arm64>  Use the specified architecture, if the app supports it

. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\json.ps1" # 'autoupdate.ps1' (indirectly)
. "$PSScriptRoot\..\lib\autoupdate.ps1" # 'generate_user_manifest' (indirectly)
. "$PSScriptRoot\..\lib\manifest.ps1" # 'generate_user_manifest' 'Get-Manifest'
. "$PSScriptRoot\..\lib\install.ps1"

$opt, $apps, $err = getopt $args 'fhua:' 'force', 'no-hash-check', 'no-update-scoop', 'arch='
if ($err) { error "scoop download: $err"; exit 1 }

$check_hash = !($opt.h -or $opt.'no-hash-check')
$use_cache = !($opt.f -or $opt.force)
$architecture = Get-DefaultArchitecture
try {
    $architecture = Format-ArchitectureString ($opt.a + $opt.arch)
} catch {
    abort "ERROR: $_"
}

if (!$apps) { error '<app> missing'; my_usage; exit 1 }

if (is_scoop_outdated) {
    if ($opt.u -or $opt.'no-update-scoop') {
        warn "Scoop is out of date."
    } else {
        & "$PSScriptRoot\scoop-update.ps1"
    }
}

# we only want to show this warning once
if(!$use_cache) { warn "Cache is being ignored." }

foreach ($curr_app in $apps) {
    # Prevent leaking variables from previous iteration
    $bucket = $version = $app = $manifest = $url = $null

    $app, $bucket, $version = parse_app $curr_app
    $app, $manifest, $bucket, $url = Get-Manifest "$bucket/$app"

    info "Downloading '$app'$(if ($version) { " ($version)" }) [$architecture]$(if ($bucket) { " from $bucket bucket" })"

    # Generate manifest if there is different version in manifest
    if (($null -ne $version) -and ($manifest.version -ne $version)) {
        $generated = generate_user_manifest $app $bucket $version
        if ($null -eq $generated) {
            error 'Manifest cannot be generated with provided version'
            continue
        }
        $manifest = parse_json($generated)
    }

    if(!$manifest) {
        error "Couldn't find manifest for '$app'$(if($bucket) { " from '$bucket' bucket" } elseif($url) { " at '$url'" })."
        continue
    }
    $version = $manifest.version
    if(!$version) {
        error "Manifest doesn't specify a version."
        continue
    }
    if($version -match '[^\w\.\-\+_]') {
        error "Manifest version has unsupported character '$($matches[0])'."
        continue
    }

    $curr_check_hash = $check_hash
    if ($version -eq 'nightly') {
        $version = nightly_version
        $curr_check_hash = $false
    }

    $architecture = Get-SupportedArchitecture $manifest $architecture
    if ($null -eq $architecture) {
        error "'$app' doesn't support current architecture!"
        continue
    }

    if(Test-Aria2Enabled) {
        Invoke-CachedAria2Download $app $version $manifest $architecture $cachedir $manifest.cookie $use_cache $curr_check_hash
    } else {
        foreach($url in script:url $manifest $architecture) {
            try {
                Invoke-CachedDownload $app $version $url $null $manifest.cookie $use_cache
            } catch {
                write-host -f darkred $_
                error "URL $url is not valid"
                $dl_failure = $true
                continue
            }

            if($curr_check_hash) {
                $manifest_hash = hash_for_url $manifest $url $architecture
                $cached = cache_path $app $version $url
                $ok, $err = check_hash $cached $manifest_hash (show_app $app $bucket)

                if(!$ok) {
                    error $err
                    if(test-path $cached) {
                        # rm cached file
                        Remove-Item -force $cached
                    }
                    if ($url -like '*sourceforge.net*') {
                        warn 'SourceForge.net is known for causing hash validation fails. Please try again before opening a ticket.'
                    }
                    error (new_issue_msg $app $bucket "hash check failed")
                    continue
                }
            } else {
                info "Skipping hash verification."
            }
        }
    }

    if (!$dl_failure) {
        success "'$app' ($version) was downloaded successfully!"
    }
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBauuCmibTG+Yen
# 1SEtDb5z4cZwmtatbY2FNqnnqX3a0qCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDE8+ePu7rfs+LyZM2Az
# 9it229yUAziJCsCc1CNxCgQDMA0GCSqGSIb3DQEBAQUABIIBAJNAirEQ4O9HgifL
# NFag8JpHpfPaKM2TLnmsOZLTshFIy6xlORit+7XVv3SN3AFPDf2OYOoppzamPnQN
# byv7KjX03W2wQao+oHdUefA5NtP9k1zr8tA5+BXZ6wsxf/p8n7M35CQAeKf1HnD+
# mxS1p9/smwBcGGgfA1ub1bgeiKqbcML2UCViQF5rGhIxRxOcFgoLdKOPlcKhe8Vi
# OzDApXyiveoqyODpNxF9+J4CgGhmXbrIVT18V31a2bJR1N2K6OO8Lo6bNnJUEojw
# xjuSK63FA7UQDGPTAzF6Gy8KL7O5jOd+l4/BTWz6Knv/cVERmqYhanhHNflRE5SX
# KjIAjRw=
# SIG # End signature block
