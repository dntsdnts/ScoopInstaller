# Usage: scoop info <app> [options]
# Summary: Display information about an app
# Help: Options:
#   -v, --verbose   Show full paths and URLs

. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1" # 'Get-Manifest'
. "$PSScriptRoot\..\lib\versions.ps1" # 'Get-InstalledVersion'

$opt, $app, $err = getopt $args 'v' 'verbose'
if ($err) { error "scoop info: $err"; exit 1 }
$verbose = $opt.v -or $opt.verbose

if (!$app) { my_usage; exit 1 }

$app, $manifest, $bucket, $url = Get-Manifest $app

if (!$manifest) {
    abort "Could not find manifest for '$(show_app $app)' in local buckets."
}

$global = installed $app $true
$status = app_status $app $global
$install = install_info $app $status.version $global
$status.installed = $bucket -and $install.bucket -eq $bucket
$version_output = $manifest.version
$manifest_file = if ($bucket) {
    manifest_path $app $bucket
} else {
    $url
}

if ($verbose) {
    $dir = currentdir $app $global
    $original_dir = versiondir $app $manifest.version $global
    $persist_dir = persistdir $app $global
} else {
    $dir, $original_dir, $persist_dir = "<root>", "<root>", "<root>"
}

if ($status.installed) {
    $manifest_file = manifest_path $app $install.bucket
    if ($install.url) {
        $manifest_file = $install.url
    }
    if ($status.version -eq $manifest.version) {
        $version_output = $status.version
    } else {
        $version_output = "$($status.version) (Update to $($manifest.version) available)"
    }
}

$item = [ordered]@{ Name = $app }
if ($manifest.description) {
    $item.Description = $manifest.description
}
$item.Version = $version_output
if ($bucket) {
    $item.Bucket = $bucket
}
if ($manifest.homepage) {
    $item.Website = $manifest.homepage.TrimEnd('/')
}
# Show license
if ($manifest.license) {
    $item.License = if ($manifest.license.identifier -and $manifest.license.url) {
        if ($verbose) { "$($manifest.license.identifier) ($($manifest.license.url))" } else { $manifest.license.identifier }
    } elseif ($manifest.license -match '^((ht)|f)tps?://') {
        $manifest.license
    } elseif ($manifest.license -match '[|,]') {
        if ($verbose) {
            "$($manifest.license) ($(($manifest.license -Split "\||," | ForEach-Object { "https://spdx.org/licenses/$_.html" }) -join ', '))"
        } else {
            $manifest.license
        }
    } else {
        if ($verbose) { "$($manifest.license) (https://spdx.org/licenses/$($manifest.license).html)" } else { $manifest.license }
    }
}

if ($manifest.depends) {
    $item.Dependencies = $manifest.depends -join ' | '
}

if (Test-Path $manifest_file) {
    if (Get-Command git -ErrorAction Ignore) {
        $gitinfo = (Invoke-Git -Path (Split-Path $manifest_file) -ArgumentList @('log', '-1', '-s', '--format=%aD#%an', $manifest_file) 2> $null) -Split '#'
    }
    if ($gitinfo) {
        $item.'Updated at' = $gitinfo[0] | Get-Date
        $item.'Updated by' = $gitinfo[1]
    } else {
        $item.'Updated at' = (Get-Item $manifest_file).LastWriteTime
        $item.'Updated by' = (Get-Acl $manifest_file).Owner.Split('\')[-1]
    }
}

# Manifest file
if ($verbose) { $item.Manifest = $manifest_file }

if ($status.installed) {
    # Show installed versions
    $installed_output = @()
    Get-InstalledVersion -AppName $app -Global:$global | ForEach-Object {
        $installed_output += if ($verbose) { versiondir $app $_ $global } else { "$_$(if ($global) { " *global*" })" }
    }
    $item.Installed = $installed_output -join "`n"

    if ($verbose) {
        # Show size of installation
        $appsdir = appsdir $global

        # Collect file list from each location
        $appFiles = Get-ChildItem $appsdir -Filter $app
        $currentFiles = Get-ChildItem $appFiles.FullName -Filter (Select-CurrentVersion $app $global)
        $persistFiles = Get-ChildItem $persist_dir -ErrorAction Ignore # Will fail if app does not persist data
        $cacheFiles = Get-ChildItem $cachedir -Filter "$app#*"

        # Get the sum of each file list
        $fileTotals = @()
        foreach ($fileType in ($appFiles, $currentFiles, $persistFiles, $cacheFiles)) {
            if ($null -ne $fileType) {
                $fileSum = (Get-ChildItem $fileType.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
                $fileTotals += coalesce $fileSum 0
            } else {
                $fileTotals += 0
            }
        }

        # Old versions = app total - current version size
        $fileTotals += $fileTotals[0] - $fileTotals[1]

        if ($fileTotals[2] + $fileTotals[3] + $fileTotals[4] -eq 0) {
            # Simple app size output if no old versions, persisted data, cached downloads
            $item.'Installed size' = filesize $fileTotals[1]
        } else {
            $fileSizes = [ordered] @{
                'Current version:  ' = $fileTotals[1]
                'Old versions:     ' = $fileTotals[4]
                'Persisted data:   ' = $fileTotals[2]
                'Cached downloads: ' = $fileTotals[3]
                'Total:            ' = $fileTotals[0] + $fileTotals[2] + $fileTotals[3]
            }

            $fileSizeOutput = @()

            # Don't output empty categories
            $fileSizes.GetEnumerator() | ForEach-Object {
                if ($_.Value -ne 0) {
                    $fileSizeOutput += $_.Key + (filesize $_.Value)
                }
            }

            $item.'Installed size' = $fileSizeOutput -join "`n"
        }
    }
} else {
    if ($verbose) {
        # Get download size if app not installed
        $totalPackage = 0
        foreach ($url in @(url $manifest (Get-DefaultArchitecture))) {
            try {
                if (Test-Path (cache_path $app $manifest.version $url)) {
                    $cached = " (latest version is cached)"
                } else {
                    $cached = $null
                }

                [int]$urlLength = (Invoke-WebRequest $url -Method Head).Headers.'Content-Length'[0]
                $totalPackage += $urlLength
            } catch [System.Management.Automation.RuntimeException] {
                $totalPackage = 0
                $packageError = "the server at $(([System.Uri]$url).Host) did not send a Content-Length header"
                break
            } catch {
                $totalPackage = 0
                $packageError = "the server at $(([System.Uri]$url).Host) is down"
                break
            }
        }
        if ($totalPackage -ne 0) {
            $item.'Download size' = "$(filesize $totalPackage)$cached"
        } else {
            $item.'Download size' = "Unknown ($packageError)$cached"
        }
    }
}

$binaries = @(arch_specific 'bin' $manifest $install.architecture)
if ($binaries) {
    $binary_output = @()
    $binaries | ForEach-Object {
        if ($_ -is [System.Array]) {
            $binary_output += "$($_[1]).$($_[0].Split('.')[-1])"
        } else {
            $binary_output += $_
        }
    }
    $item.Binaries = $binary_output -join " | "
}
$shortcuts = @(arch_specific 'shortcuts' $manifest $install.architecture)
if ($shortcuts) {
    $shortcut_output = @()
    $shortcuts | ForEach-Object {
        $shortcut_output += $_[1]
    }
    $item.Shortcuts = $shortcut_output -join " | "
}
$env_set = arch_specific 'env_set' $manifest $install.architecture
if ($env_set) {
    $env_vars = @()
    $env_set | Get-Member -member noteproperty | ForEach-Object {
        $env_vars += "$($_.name) = $(format $env_set.$($_.name) @{ "dir" = $dir })"
    }
    $item.Environment = $env_vars -join "`n"
}
$env_add_path = arch_specific 'env_add_path' $manifest $install.architecture
if ($env_add_path) {
    $env_path = @()
    $env_add_path | Where-Object { $_ } | ForEach-Object {
        $env_path += if ($_ -eq '.') {
            $dir
        } else {
            "$dir\$_"
        }
    }
    $item.'Path Added' = $env_path -join "`n"
}

if ($manifest.suggest) {
    $suggest_output = @()
    $manifest.suggest.PSObject.Properties | ForEach-Object {
        $suggest_output += $_.Value -join ' | '
    }
    $item.Suggestions = $suggest_output -join ' | '
}

if ($manifest.notes) {
    # Show notes
    $item.Notes = (substitute $manifest.notes @{ '$dir' = $dir; '$original_dir' = $original_dir; '$persist_dir' = $persist_dir }) -join "`n"
}

[PSCustomObject]$item

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBkKprIfWKMpwBT
# hGuK5LYvYBbQC9lArEYvcvHnR6oX5aCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMLTRUEJcRkDKCq0SzXZ
# XRVWT1351lcJHfzF3kbk7SHLMA0GCSqGSIb3DQEBAQUABIIBACrBShl3bPe0U2Dj
# zJc4qgVyDmM6hYSXRAmXWXAz/Y0aAwlcIo0pjLPsTYHvZrav0x63qHn3gG9VDJy6
# MfCS5yoeMKrGrchVdBnvguyz/eMXdUvEgZuqh8ShX6H+84Wi0gYStusAo+xjOxYm
# C2FLsFr4vlhjGsoU4KK4cmLUKlP5voyRYz3EbtR3kFgQ5Rk++vg3RXmBf8kex+ho
# pHllpSERakXaoLft2YtAGt9R6AJpjsD/MATT6OvnPGSwgDGEjcbgMNEd0DG6n1rP
# q2XMPTymbR75NLqFtRXerGy4XMBcednoKkipvykHHUF2v77drChEAHe/S5Aug/NG
# zfyrec4=
# SIG # End signature block
