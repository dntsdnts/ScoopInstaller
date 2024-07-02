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
                warn "Bucket '$bucket' not installed. Add it with 'scoop bucket add $bucket' or 'scoop bucket add $bucket <repo>'."
            }
            abort "Couldn't find manifest for '$AppName'$(if(!$bucket) { '.' } else { " from '$bucket' bucket." })"
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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpuPLZ8NGD9odqncl8T2gEPb4
# vMWgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQU/J0FZ7Da0kM8XQGaZPWmDNyzDIMwDQYJKoZIhvcNAQEBBQAEggEA
# qu7eGGpDAT+PcQQq5LaRQyBXfy/TZvMrmJcivvkw/o6lpRsfuUXje+LaDj362zOL
# qXb12au1KELrKqrEiJ819fWYT/O+M4fOssY9PAJ4kZkurk6b5tcDI0bFkpV22f/2
# m1M2MWxoTfkusTpCpLhKy7zgJ1W8JOiBBB+gr6yBK2DzIeMnl1xXUrVlnQuUbEeP
# QPggfj9bseuDgJCkESxww+Q8G3GYADp9sKw+EZwerHaP7H4M2obBUV0XPAKwICOG
# Bk9VVlnCwzxxfvP2fAySDD1tZk4ELza03sCBceADESoFi1ftTJieumoo+pa6qOya
# yhXS6N8lc4bMdb2Zopkq2w==
# SIG # End signature block
