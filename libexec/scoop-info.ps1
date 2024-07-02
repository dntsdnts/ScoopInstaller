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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6SMkawAmnZAAO4todVvKzJY4
# 2BagggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUc6hRnlXn06Vg56HyEh6K9Xyvh5gwDQYJKoZIhvcNAQEBBQAEggEA
# bZilTv5aIEoGV4rzurzftscWjMMtG1q+2yu5fes00QPWrD60ua8ELcW2Cksm+UMG
# TQObKyLq8q0qmS8XclvNwUHPN5HQvuVX3tbeABtDEL+WGdXK7Pe0h9PHnZdmponm
# nLhruwS3MElVMTRaLW07wE6AVs5v4LrpZYdM3Y42gMVTPb/i5FaNQM8yIhI89pRe
# hRwyOJDNBHm7Ppp8WEboX0TkfetmvmdoTWdsJ9CF7iM6RV3dcbr+umRcd4FSocSp
# e9JX5BCKIwt0x9d3p9h+QLC6OaqkO/aKCiUmo1zCd3b4hSVEnPTMmpAcJ/k7PkSn
# 5Ydx8ydFU7GrtFsLauRZjQ==
# SIG # End signature block
