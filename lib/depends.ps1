function Get-Dependency {
    <#
    .SYNOPSIS
        Get app's dependencies (with apps attached at the end).
    .PARAMETER AppName
        App's name
    .PARAMETER Architecture
        App's architecture
    .PARAMETER Resolved
        List of resolved dependencies (internal use)
    .PARAMETER Unresolved
        List of unresolved dependencies (internal use)
    .OUTPUTS
        [Object[]]
        List of app's dependencies
    .NOTES
        When pipeline input is used, the output will have duplicate items, and should be filtered by 'Select-Object -Unique'.
        ALgorithm: http://www.electricmonk.nl/docs/dependency_resolving_algorithm/dependency_resolving_algorithm.html
    #>
    [CmdletBinding()]
    [OutputType([Object[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject]
        $AppName,
        [Parameter(Mandatory = $true, Position = 1)]
        [String]
        $Architecture,
        [String[]]
        $Resolved = @(),
        [String[]]
        $Unresolved = @()
    )
    process {
        $AppName, $manifest, $bucket, $url = Get-Manifest $AppName
        $Unresolved += $AppName

        if (!$manifest) {
            if (((Get-LocalBucket) -notcontains $bucket) -and $bucket) {
                warn "Bucket '$bucket' not added. Add it with $(if($bucket -in (known_buckets)) { "'scoop bucket add $bucket' or " })'scoop bucket add $bucket <repo>'."
            }
            abort "Couldn't find manifest for '$AppName'$(if($bucket) { " from '$bucket' bucket" } elseif($url) { " at '$url'" })."
        }

        $deps = @(Get-InstallationHelper $manifest $Architecture) + @($manifest.depends) | Select-Object -Unique

        foreach ($dep in $deps) {
            if ($Resolved -notcontains $dep) {
                if ($Unresolved -contains $dep) {
                    abort "Circular dependency detected: '$AppName' -> '$dep'."
                }
                $Resolved, $Unresolved = Get-Dependency $dep $Architecture -Resolved $Resolved -Unresolved $Unresolved
            }
        }

        $Unresolved = $Unresolved -ne $AppName
        if ($bucket) {
            $Resolved += "$bucket/$AppName"
        } else {
            if ($url) {
                $Resolved += $url
            } else {
                $Resolved += $AppName
            }
        }
        if ($Unresolved.Length -eq 0) {
            return $Resolved
        } else {
            return $Resolved, $Unresolved
        }
    }
}

function Get-InstallationHelper {
    <#
    .SYNOPSIS
        Get helpers that used in installation
    .PARAMETER Manifest
        App's manifest
    .PARAMETER Architecture
        Architecture of the app
    .PARAMETER All
        If true, return all helpers, otherwise return only helpers that are not already installed
    .OUTPUTS
        [Object[]]
        List of helpers
    #>
    [CmdletBinding()]
    [OutputType([Object[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject]
        $Manifest,
        [Parameter(Mandatory = $true, Position = 1)]
        [String]
        $Architecture,
        [Switch]
        $All
    )
    begin {
        $helper = @()
    }
    process {
        $url = arch_specific 'url' $Manifest $Architecture
        $pre_install = arch_specific 'pre_install' $Manifest $Architecture
        $installer = arch_specific 'installer' $Manifest $Architecture
        $post_install = arch_specific 'post_install' $Manifest $Architecture
        $script = $pre_install + $installer.script + $post_install
        if (((Test-7zipRequirement -Uri $url) -or ($script -like '*Expand-7zipArchive *')) -and !(get_config USE_EXTERNAL_7ZIP)) {
            $helper += '7zip'
        }
        if (((Test-LessmsiRequirement -Uri $url) -or ($script -like '*Expand-MsiArchive *')) -and (get_config USE_LESSMSI)) {
            $helper += 'lessmsi'
        }
        if ($Manifest.innosetup -or ($script -like '*Expand-InnoArchive *')) {
            $helper += 'innounp'
        }
        if ($script -like '*Expand-DarkArchive *') {
            $helper += 'dark'
        }
        if ((Test-ZstdRequirement -Uri $url) -or ($script -like '*Expand-ZstdArchive *')) {
            $helper += 'zstd'
        }
        if (!$All) {
            '7zip', 'lessmsi', 'innounp', 'dark', 'zstd' | ForEach-Object {
                if (Test-HelperInstalled -Helper $_) {
                    $helper = $helper -ne $_
                }
            }
        }
    }
    end {
        return $helper
    }
}

function Test-7zipRequirement {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [String[]]
        $Uri
    )
    return ($Uri | Where-Object {
            $_ -match '\.((gz)|(tar)|(t[abgpx]z2?)|(lzma)|(bz2?)|(7z)|(001)|(rar)|(iso)|(xz)|(lzh)|(nupkg))(\.[^\d.]+)?$'
        }).Count -gt 0
}

function Test-ZstdRequirement {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [String[]]
        $Uri
    )
    return ($Uri | Where-Object { $_ -match '\.zst$' }).Count -gt 0
}

function Test-LessmsiRequirement {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [String[]]
        $Uri
    )
    return ($Uri | Where-Object { $_ -match '\.msi$' }).Count -gt 0
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAVSuh5GGRJ1LDe
# gOzKJFY69luVzqMOCK9XDnG9D4bRRqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE963Te94tm191tsOSXY
# +TPELB11tt/AGiiDDXI6KGlZMA0GCSqGSIb3DQEBAQUABIIBADn9COnvtHKtJhJZ
# Z+xGZzbbvcBpjzAhZ2fJUXO1eMvta8/OI+DEzCAAPcrxiG7hPRiG7gVQPhLReN7o
# /CYGKTFTkhSamtZ1h9y07ytn51A9fpJgBFfZurOd0lUPUNEKvlcFoFXFa3j5Bz1s
# QGM7tD9XXhCcLt4zfxt9d+5iBhfcLHH/O12inqe5CIK1t66C4oi6nf0vPeSV+YdZ
# E/UPF6FJx9axXDmvz7UMOAqXZt0mawERYvuVM/SC4UMdE8ETLcjnLLfyOtKDFC+C
# aEetpO9p8H8A5SJFqDO+YGWydcS0A/0Rc6w8gknBTZYs58rHaXBPXckb1Fsi+Y6M
# zA5nVjg=
# SIG # End signature block
