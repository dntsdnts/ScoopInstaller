function Get-LatestVersion {
    <#
    .SYNOPSIS
        Get latest version of app from manifest
    .PARAMETER AppName
        App's name
    .PARAMETER Bucket
        Bucket which the app belongs to
    .PARAMETER Uri
        Remote app manifest's URI
    #>
    [OutputType([String])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('App')]
        [String]
        $AppName,
        [Parameter(Position = 1)]
        [String]
        $Bucket,
        [Parameter(Position = 2)]
        [String]
        $Uri
    )
    process {
        return (manifest $AppName $Bucket $Uri).version
    }
}

function Select-CurrentVersion { # 'manifest.ps1'
    <#
    .SYNOPSIS
        Select current version of installed app, from 'current\manifest.json' or modified time of version directory
    .PARAMETER AppName
        App's name
    .PARAMETER Global
        Globally installed application
    #>
    [OutputType([String])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('App')]
        [String]
        $AppName,
        [Parameter(Position = 1)]
        [Switch]
        $Global
    )
    process {
        $currentPath = "$(appdir $AppName $Global)\current"
        if (!(get_config NO_JUNCTION)) {
            $currentVersion = (parse_json "$currentPath\manifest.json").version
            if ($currentVersion -eq 'nightly') {
                $currentVersion = (Get-Item $currentPath).Target | Split-Path -Leaf
            }
        }
        if ($null -eq $currentVersion) {
            $installedVersion = Get-InstalledVersion -AppName $AppName -Global:$Global
            if ($installedVersion) {
                $currentVersion = @($installedVersion)[-1]
            } else {
                $currentVersion = $null
            }
        }
        return $currentVersion
    }
}

function Get-InstalledVersion {
    <#
    .SYNOPSIS
        Get all installed version of app, by checking version directories' 'install.json'
    .PARAMETER AppName
        App's name
    .PARAMETER Global
        Globally installed application
    .NOTES
        Versions are sorted from oldest to newest, i.e., latest installed version is the last one in the output array.
        If no installed version found, empty array will be returned.
    #>
    [OutputType([Object[]])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('App')]
        [String]
        $AppName,
        [Parameter(Position = 1)]
        [Switch]
        $Global
    )
    process {
        $appPath = appdir $AppName $Global
        if (Test-Path $appPath) {
            $versions = @((Get-ChildItem "$appPath\*\install.json" | Sort-Object -Property LastWriteTimeUtc).Directory.Name)
            return $versions | Where-Object { ($_ -ne 'current') -and ($_ -notlike '_*.old*') }
        } else {
            return @()
        }
    }
    # Deprecated
    # sort_versions (Get-ChildItem $appPath -dir -attr !reparsePoint | Where-Object { $null -ne $(Get-ChildItem $_.FullName) } | ForEach-Object { $_.Name })
}

function Compare-Version {
    <#
    .SYNOPSIS
        Compare versions, mainly according to SemVer's rules
    .PARAMETER ReferenceVersion
        Specifies a version used as a reference for comparison
    .PARAMETER DifferenceVersion
        Specifies the version that are compared to the reference version
    .PARAMETER Delimiter
        Specifies the delimiter of versions
    .OUTPUTS
        System.Int32
            '0' if DifferenceVersion is equal to ReferenceVersion,
            '1' if DifferenceVersion is greater then ReferenceVersion,
            '-1' if DifferenceVersion is less then ReferenceVersion
    #>
    [OutputType([Int32])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [String]
        $ReferenceVersion,
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String]
        $DifferenceVersion,
        [String]
        $Delimiter = '-'
    )
    process {
        # Use '+' sign as post-release, see https://github.com/ScoopInstaller/Scoop/pull/3721#issuecomment-553718093
        $ReferenceVersion, $DifferenceVersion = @($ReferenceVersion, $DifferenceVersion) -replace '\+', '-'

        # Return 0 if versions are equal
        if ($DifferenceVersion -eq $ReferenceVersion) {
            return 0
        }

        # Preprocess versions (split, convert and separate)
        $splitReferenceVersion = @(SplitVersion -Version $ReferenceVersion -Delimiter $Delimiter)
        $splitDifferenceVersion = @(SplitVersion -Version $DifferenceVersion -Delimiter $Delimiter)

        # Nightly versions are always equal unless UPDATE_NIGHTLY is $true
        if ($splitReferenceVersion[0] -eq 'nightly' -and $splitDifferenceVersion[0] -eq 'nightly') {
            if (get_config UPDATE_NIGHTLY) {
                # nightly versions will be compared by date if UPDATE_NIGHTLY is $true
                if ($null -eq $splitReferenceVersion[1]) {
                    $splitReferenceVersion += Get-Date -Format 'yyyyMMdd'
                }
                if ($null -eq $splitDifferenceVersion[1]) {
                    $splitDifferenceVersion += Get-Date -Format 'yyyyMMdd'
                }
                return [Math]::Sign($splitDifferenceVersion[1] - $splitReferenceVersion[1])
            } else {
                return 0
            }
        }

        for ($i = 0; $i -lt [Math]::Max($splitReferenceVersion.Length, $splitDifferenceVersion.Length); $i++) {
            # '1.1-alpha' is less then '1.1'
            if ($i -ge $splitReferenceVersion.Length) {
                if ($splitDifferenceVersion[$i] -match 'alpha|beta|rc|pre') {
                    return -1
                } else {
                    return 1
                }
            }
            # '1.1' is greater then '1.1-beta'
            if ($i -ge $splitDifferenceVersion.Length) {
                if ($splitReferenceVersion[$i] -match 'alpha|beta|rc|pre') {
                    return 1
                } else {
                    return -1
                }
            }

            # If some parts of versions have '.', compare them with delimiter '.'
            if (($splitReferenceVersion[$i] -match '\.') -or ($splitDifferenceVersion[$i] -match '\.')) {
                $Result = Compare-Version -ReferenceVersion $splitReferenceVersion[$i] -DifferenceVersion $splitDifferenceVersion[$i] -Delimiter '.'
                # If the parts are equal, continue to next part, otherwise return
                if ($Result -ne 0) {
                    return $Result
                } else {
                    continue
                }
            }

            # If some parts of versions have '_', compare them with delimiter '_'
            if (($splitReferenceVersion[$i] -match '_') -or ($splitDifferenceVersion[$i] -match '_')) {
                $Result = Compare-Version -ReferenceVersion $splitReferenceVersion[$i] -DifferenceVersion $splitDifferenceVersion[$i] -Delimiter '_'
                # If the parts are equal, continue to next part, otherwise return
                if ($Result -ne 0) {
                    return $Result
                } else {
                    continue
                }
            }

            # Don't try to compare [Long] to [String]
            if ($null -ne $splitReferenceVersion[$i] -and $null -ne $splitDifferenceVersion[$i]) {
                if ($splitReferenceVersion[$i] -is [String] -and $splitDifferenceVersion[$i] -isnot [String]) {
                    $splitDifferenceVersion[$i] = "$($splitDifferenceVersion[$i])"
                }
                if ($splitDifferenceVersion[$i] -is [String] -and $splitReferenceVersion[$i] -isnot [String]) {
                    $splitReferenceVersion[$i] = "$($splitReferenceVersion[$i])"
                }
            }

            # Compare [String] or [Long]
            if ($splitDifferenceVersion[$i] -gt $splitReferenceVersion[$i]) {
                return 1
            }
            if ($splitDifferenceVersion[$i] -lt $splitReferenceVersion[$i]) {
                return -1
            }
        }
    }
}

# Helper function
function SplitVersion {
    <#
    .SYNOPSIS
        Split version by Delimiter, convert number string to number, and separate letters from numbers
    .PARAMETER Version
        Specifies a version
    .PARAMETER Delimiter
        Specifies the delimiter of version (Literal)
    #>
    [OutputType([Object[]])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String]
        $Version,
        [String]
        $Delimiter = '-'
    )
    process {
        $Version = $Version -replace '[a-zA-Z]+', "$Delimiter$&$Delimiter"
        return ($Version -split [Regex]::Escape($Delimiter) -ne '' | ForEach-Object { if ($_ -match '^\d+$') { [Long]$_ } else { $_ } })
    }
}

# Deprecated
# Not used anymore in scoop core
function qsort($ary, $fn) {
    warn '"qsort" is deprecated. Please avoid using it anymore.'
    if ($null -eq $ary) { return @() }
    if (!($ary -is [array])) { return @($ary) }

    $pivot = $ary[0]
    $rem = $ary[1..($ary.length - 1)]

    $lesser = qsort ($rem | Where-Object { (& $fn $pivot $_) -lt 0 }) $fn

    $greater = qsort ($rem | Where-Object { (& $fn $pivot $_) -ge 0 }) $fn

    return @() + $lesser + @($pivot) + $greater
}

# Deprecated
# Not used anymore in scoop core
function sort_versions($versions) {
    warn '"sort_versions" is deprecated. Please avoid using it anymore.'
    qsort $versions Compare-Version
}

function compare_versions($a, $b) {
    Show-DeprecatedWarning $MyInvocation 'Compare-Version'
    # Please note the parameters' sequence
    return Compare-Version -ReferenceVersion $b -DifferenceVersion $a
}

function latest_version($app, $bucket, $url) {
    Show-DeprecatedWarning $MyInvocation 'Get-LatestVersion'
    return Get-LatestVersion -AppName $app -Bucket $bucket -Uri $url
}

function current_version($app, $global) {
    Show-DeprecatedWarning $MyInvocation 'Select-CurrentVersion'
    return Select-CurrentVersion -AppName $app -Global:$global
}

function versions($app, $global) {
    Show-DeprecatedWarning $MyInvocation 'Get-InstalledVersion'
    return Get-InstalledVersion -AppName $app -Global:$global
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAEoNj0xf5WVzrJ
# rmWgsE8G2NugyBlBVnv9d4fYw7FbbqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA/4ZU9HGfh1Ax8+QPUm
# mGhhtoHqZg/puZdRApAUs7MSMA0GCSqGSIb3DQEBAQUABIIBABCCPbQHXuEQ4zGK
# SflrcNFbfMqxeOKSMn4kkWF9fGIdAlzO4dQCWkqTd+Yy9fdrBIf2lX8DYDGpg5hq
# F1J+1bjmGXNdXs8ACTkrXT4DQF/OuAPi4MxrQDmqBl0nYTwWV4RMTcCUobyMAVOZ
# G5ZXz+46bgTtFC9CvE8Y+5CdiZ1edupxEOssZ3zfS+xr5Af1uMPwIICNmquw2Vy5
# Imevx7+XYjxNTJsn8Kcfw9hV+tPoCRmPnUmyGudmitPgRjKuuycnB1uiCi7syGG/
# 0bDcNFBb54guq6jbWG1IWG8CsisikZdfi5Jb/2m+/9dcE+m4MsZA1ePxsgE6iNNI
# l2n6DxA=
# SIG # End signature block
