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
        scoop update
    }
}

# we only want to show this warning once
if(!$use_cache) { warn "Cache is being ignored." }

foreach ($curr_app in $apps) {
    # Prevent leaking variables from previous iteration
    $bucket = $version = $app = $manifest = $url = $null

    $app, $bucket, $version = parse_app $curr_app
    $app, $manifest, $bucket, $url = Get-Manifest "$bucket/$app"

    info "Starting download for $app..."

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
        error "Couldn't find manifest for '$app'$(if($url) { " at the URL $url" })."
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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQxxlmSquRSUMRc1jdalocXlz
# DSegggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUUFZOiTSkczo9gfSpROWkFCXizqYwDQYJKoZIhvcNAQEBBQAEggEA
# DJz0WQ+TvvBHgdHQ/UBd3zgKhcDJHmKVSCx1q8Rood/0t7DAaViAD1+6rexANZ7+
# 7Gr9XQ6OBi5K9o8qRdvD+RpexZhZbhfWIwTnCtXI+FDGG4mst0lSZfV1O9OSW0W+
# JKnEsj4vDySzrbukY8Z0t3dB7WgYoh2csNsr2aRwQq/D/S7c71apZwhabTgb/uL6
# ewAiJhHXFM48+Pku/0g5vF1ZPti6RGAxr1DfZ55fCu5fWIzLueRN3AYDOlsNoqnc
# Vkc385OYnwnImDvyVEgket0T6dHQyNndZQ7xdDwymabQkPucJNRtt/ynRjiP3szw
# lF2cvtPu4zVQJUdihuFozg==
# SIG # End signature block
