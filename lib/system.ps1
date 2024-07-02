# System-related functions

## Environment Variables

function Publish-EnvVar {
    if (-not ('Win32.NativeMethods' -as [Type])) {
        Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult
);
'@
    }

    $HWND_BROADCAST = [IntPtr] 0xffff
    $WM_SETTINGCHANGE = 0x1a
    $result = [UIntPtr]::Zero

    [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST,
        $WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        'Environment',
        2,
        5000,
        [ref] $result
    ) | Out-Null
}

function Get-EnvVar {
    param(
        [string]$Name,
        [switch]$Global
    )

    $registerKey = if ($Global) {
        Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    } else {
        Get-Item -Path 'HKCU:'
    }
    $envRegisterKey = $registerKey.OpenSubKey('Environment')
    $registryValueOption = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
    $envRegisterKey.GetValue($Name, $null, $registryValueOption)
}

function Set-EnvVar {
    param(
        [string]$Name,
        [string]$Value,
        [switch]$Global
    )

    $registerKey = if ($Global) {
        Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    } else {
        Get-Item -Path 'HKCU:'
    }
    $envRegisterKey = $registerKey.OpenSubKey('Environment', $true)
    if ($null -eq $Value -or $Value -eq '') {
        if ($envRegisterKey.GetValue($Name)) {
            $envRegisterKey.DeleteValue($Name)
        }
    } else {
        $registryValueKind = if ($Value.Contains('%')) {
            [Microsoft.Win32.RegistryValueKind]::ExpandString
        } elseif ($envRegisterKey.GetValue($Name)) {
            $envRegisterKey.GetValueKind($Name)
        } else {
            [Microsoft.Win32.RegistryValueKind]::String
        }
        $envRegisterKey.SetValue($Name, $Value, $registryValueKind)
    }
    Publish-EnvVar
}

function Split-PathLikeEnvVar {
    param(
        [string[]]$Pattern,
        [string]$Path
    )

    if ($null -eq $Path -and $Path -eq '') {
        return $null, $null
    } else {
        $splitPattern = $Pattern.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
        $splitPath = $Path.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
        $inPath = @()
        foreach ($p in $splitPattern) {
            $inPath += $splitPath.Where({ $_ -like $p })
            $splitPath = $splitPath.Where({ $_ -notlike $p })
        }
        return ($inPath -join ';'), ($splitPath -join ';')
    }
}

function Add-Path {
    param(
        [string[]]$Path,
        [string]$TargetEnvVar = 'PATH',
        [switch]$Global,
        [switch]$Force,
        [switch]$Quiet
    )

    # future sessions
    $inPath, $strippedPath = Split-PathLikeEnvVar $Path (Get-EnvVar -Name $TargetEnvVar -Global:$Global)
    if (!$inPath -or $Force) {
        if (!$Quiet) {
            $Path | ForEach-Object {
                Write-Host "Adding $(friendly_path $_) to $(if ($Global) {'global'} else {'your'}) path."
            }
        }
        Set-EnvVar -Name $TargetEnvVar -Value ((@($Path) + $strippedPath) -join ';') -Global:$Global
    }
    # current session
    $inPath, $strippedPath = Split-PathLikeEnvVar $Path $env:PATH
    if (!$inPath -or $Force) {
        $env:PATH = (@($Path) + $strippedPath) -join ';'
    }
}

function Remove-Path {
    param(
        [string[]]$Path,
        [string]$TargetEnvVar = 'PATH',
        [switch]$Global,
        [switch]$Quiet,
        [switch]$PassThru
    )

    # future sessions
    $inPath, $strippedPath = Split-PathLikeEnvVar $Path (Get-EnvVar -Name $TargetEnvVar -Global:$Global)
    if ($inPath) {
        if (!$Quiet) {
            $Path | ForEach-Object {
                Write-Host "Removing $(friendly_path $_) from $(if ($Global) {'global'} else {'your'}) path."
            }
        }
        Set-EnvVar -Name $TargetEnvVar -Value $strippedPath -Global:$Global
    }
    # current session
    $inSessionPath, $strippedPath = Split-PathLikeEnvVar $Path $env:PATH
    if ($inSessionPath) {
        $env:PATH = $strippedPath
    }
    if ($PassThru) {
        return $inPath
    }
}

## Deprecated functions

function env($name, $global, $val) {
    if ($PSBoundParameters.ContainsKey('val')) {
        Show-DeprecatedWarning $MyInvocation 'Set-EnvVar'
        Set-EnvVar -Name $name -Value $val -Global:$global
    } else {
        Show-DeprecatedWarning $MyInvocation 'Get-EnvVar'
        Get-EnvVar -Name $name -Global:$global
    }
}

function strip_path($orig_path, $dir) {
    Show-DeprecatedWarning $MyInvocation 'Split-PathLikeEnvVar'
    Split-PathLikeEnvVar -Pattern @($dir) -Path $orig_path
}

function add_first_in_path($dir, $global) {
    Show-DeprecatedWarning $MyInvocation 'Add-Path'
    Add-Path -Path $dir -Global:$global -Force
}

function remove_from_path($dir, $global) {
    Show-DeprecatedWarning $MyInvocation 'Remove-Path'
    Remove-Path -Path $dir -Global:$global
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCLm3I9wLk3EhsF
# XoI7V3vruTKKhzJQqRQcAng66/iBOaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJHuZd/atbyQn7Lds2/2
# YndgIm/JqZ/NNfw9Rk2BYYDyMA0GCSqGSIb3DQEBAQUABIIBAGkNvKwONWzMdAhy
# Jwqsmb9uormS+PGbfck872p8naUvfGCm2NkxAJkLh0ILsvE1LRRSAEe6l0pIPO61
# d62Mlz2ZDAaXj6nz3EH/J49c1EOinxUaE3q322ulDmncQTWAUns/0Dn2b6sYeZ5m
# D5Xi97u/FzVpE7bllb7QfmejTVbwg59UvMwlpKAo1gQ7hr71h7lZQ1Xi4UsUen8T
# tNAtnQI7s4XI5uTBOQKZTrhISWMMmQy+xudlj91/7d9xXSQv6K1v8fYRu92uvHaY
# 43j6DrvSkSMB393SbY06JWgoiLXpvhIEFZhmN2agIESICUHEy6CAH+POlwtUDziI
# KA/yq/4=
# SIG # End signature block
