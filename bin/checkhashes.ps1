<#
.SYNOPSIS
    Check if ALL urls inside manifest have correct hashes.
.PARAMETER App
    Manifest to be checked.
    Wildcard is supported.
.PARAMETER Dir
    Where to search for manifest(s).
.PARAMETER Update
    When there are mismatched hashes, manifest will be updated.
.PARAMETER ForceUpdate
    Manifest will be updated all the time. Not only when there are mismatched hashes.
.PARAMETER SkipCorrect
    Manifests without mismatch will not be shown.
.PARAMETER UseCache
    Downloaded files will not be deleted after script finish.
    Should not be used, because check should be used for downloading actual version of file (as normal user, not finding in some document from vendors, which could be damaged / wrong (Example: Slack@3.3.1 ScoopInstaller/Extras#1192)), not some previously downloaded.
.EXAMPLE
    PS BUCKETROOT> .\bin\checkhashes.ps1
    Check all manifests for hash mismatch.
.EXAMPLE
    PS BUCKETROOT> .\bin\checkhashes.ps1 MANIFEST -Update
    Check MANIFEST and Update if there are some wrong hashes.
#>
param(
    [String] $App = '*',
    [Parameter(Mandatory = $true)]
    [ValidateScript( {
        if (!(Test-Path $_ -Type Container)) {
            throw "$_ is not a directory!"
        } else {
            $true
        }
    })]
    [String] $Dir,
    [Switch] $Update,
    [Switch] $ForceUpdate,
    [Switch] $SkipCorrect,
    [Alias('k')]
    [Switch] $UseCache
)

. "$PSScriptRoot\..\lib\core.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1"
. "$PSScriptRoot\..\lib\buckets.ps1"
. "$PSScriptRoot\..\lib\autoupdate.ps1"
. "$PSScriptRoot\..\lib\json.ps1"
. "$PSScriptRoot\..\lib\versions.ps1"
. "$PSScriptRoot\..\lib\install.ps1"

$Dir = Convert-Path $Dir
if ($ForceUpdate) { $Update = $true }
# Cleanup
if (!$UseCache) { Remove-Item "$cachedir\*HASH_CHECK*" -Force }

function err ([String] $name, [String[]] $message) {
    Write-Host "$name`: " -ForegroundColor Red -NoNewline
    Write-Host ($message -join "`r`n") -ForegroundColor Red
}

$MANIFESTS = @()
foreach ($single in Get-ChildItem $Dir -Filter "$App.json" -Recurse) {
    $name = $single.BaseName
    $file = $single.FullName
    $manifest = parse_json $file

    # Skip nighly manifests, since their hash validation is skipped
    if ($manifest.version -eq 'nightly') { continue }

    $urls = @()
    $hashes = @()

    if ($manifest.url) {
        $manifest.url | ForEach-Object { $urls += $_ }
        $manifest.hash | ForEach-Object { $hashes += $_ }
    } elseif ($manifest.architecture) {
        # First handle 64bit
        script:url $manifest '64bit' | ForEach-Object { $urls += $_ }
        hash $manifest '64bit' | ForEach-Object { $hashes += $_ }
        script:url $manifest '32bit' | ForEach-Object { $urls += $_ }
        hash $manifest '32bit' | ForEach-Object { $hashes += $_ }
        script:url $manifest 'arm64' | ForEach-Object { $urls += $_ }
        hash $manifest 'arm64' | ForEach-Object { $hashes += $_ }
    } else {
        err $name 'Manifest does not contain URL property.'
        continue
    }

    # Number of URLS and Hashes is different
    if ($urls.Length -ne $hashes.Length) {
        err $name 'URLS and hashes count mismatch.'
        continue
    }

    $MANIFESTS += @{
        app      = $name
        file     = $file
        manifest = $manifest
        urls     = $urls
        hashes   = $hashes
    }
}

# clear any existing events
Get-Event | ForEach-Object { Remove-Event $_.SourceIdentifier }

foreach ($current in $MANIFESTS) {
    $count = 0
    # Array of indexes mismatched hashes.
    $mismatched = @()
    # Array of computed hashes
    $actuals = @()

    $current.urls | ForEach-Object {
        $algorithm, $expected = get_hash $current.hashes[$count]
        if ($UseCache) {
            $version = $current.manifest.version
        } else {
            $version = 'HASH_CHECK'
        }

        Invoke-CachedDownload $current.app $version $_ $null $null -use_cache:$UseCache

        $to_check = cache_path $current.app $version $_
        $actual_hash = (Get-FileHash -Path $to_check -Algorithm $algorithm).Hash.ToLower()

        # Append type of algorithm to both expected and actual if it's not sha256
        if ($algorithm -ne 'sha256') {
            $actual_hash = "$algorithm`:$actual_hash"
            $expected = "$algorithm`:$expected"
        }

        $actuals += $actual_hash
        if ($actual_hash -ne $expected) {
            $mismatched += $count
        }
        $count++
    }

    if ($mismatched.Length -eq 0 ) {
        if (!$SkipCorrect) {
            Write-Host "$($current.app): " -NoNewline
            Write-Host 'OK' -ForegroundColor Green
        }
    } else {
        Write-Host "$($current.app): " -NoNewline
        Write-Host 'Mismatch found ' -ForegroundColor Red
        $mismatched | ForEach-Object {
            $file = cache_path $current.app $version $current.urls[$_]
            Write-Host "`tURL:`t`t$($current.urls[$_])"
            if (Test-Path $file) {
                Write-Host "`tFirst bytes:`t$((get_magic_bytes_pretty $file ' ').ToUpper())"
            }
            Write-Host "`tExpected:`t$($current.hashes[$_])" -ForegroundColor Green
            Write-Host "`tActual:`t`t$($actuals[$_])" -ForegroundColor Red
        }
    }

    if ($Update) {
        if ($current.manifest.url -and $current.manifest.hash) {
            $current.manifest.hash = $actuals
        } else {
            $platforms = ($current.manifest.architecture | Get-Member -MemberType NoteProperty).Name
            # Defaults to zero, don't know, which architecture is available
            $64bit_count = 0
            $32bit_count = 0
            $arm64_count = 0

            # 64bit is get, donwloaded and added first
            if ($platforms.Contains('64bit')) {
                $64bit_count = $current.manifest.architecture.'64bit'.hash.Count
                $current.manifest.architecture.'64bit'.hash = $actuals[0..($64bit_count - 1)]
            }
            if ($platforms.Contains('32bit')) {
                $32bit_count = $current.manifest.architecture.'32bit'.hash.Count
                $current.manifest.architecture.'32bit'.hash = $actuals[($64bit_count)..($64bit_count + $32bit_count - 1)]
            }
            if ($platforms.Contains('arm64')) {
                $arm64_count = $current.manifest.architecture.'arm64'.hash.Count
                $current.manifest.architecture.'arm64'.hash = $actuals[($64bit_count + $32bit_count)..($64bit_count + $32bit_count + $arm64_count - 1)]
            }
        }

        Write-Host "Writing updated $($current.app) manifest" -ForegroundColor DarkGreen

        $current.manifest = $current.manifest | ConvertToPrettyJson
        $path = Convert-Path $current.file
        [System.IO.File]::WriteAllLines($path, $current.manifest)
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBIP3KH1/g52NTP
# eYnnet0PlzV8ZRIldt14Fb3/YkOmjqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPhMZvCwDSU6NyQGJU5d
# ZWRfdc6jERuY3WmP9XBftUZwMA0GCSqGSIb3DQEBAQUABIIBALPOx9ftEkVoE+n0
# ZI5bmzOEVF7QundGp100pjeMjiY+67ySzdUC2/7roCgzeDteNoBD+Acn3ZSk2BHG
# Frdqz6F7ly1kUKMCNLLwKojgGLv7aehylY5FfNFAE9GNLWNzp+AjjRAINQj6RfkR
# nv3XlMdUWoFn7bvh7Flvq5/SwTVlQdFjhpi39sQOw+dhA35XMgZAIXS0GEojeG+v
# OTl1n597Mtwaml51PyYxtWKZVN/+V6D280WYnGYc8lEy/RO6sewLDmzKjBReMR+V
# 2fzy0UT6/kFHkPKTyjssp5VD8iYDndVDQR1dualMYf3/WXP8Hy2M9VZgbF49Yk+E
# 8+mMqOQ=
# SIG # End signature block
