# Creates shortcut for the app in the start menu
function create_startmenu_shortcuts($manifest, $dir, $global, $arch) {
    $shortcuts = @(arch_specific 'shortcuts' $manifest $arch)
    $shortcuts | Where-Object { $_ -ne $null } | ForEach-Object {
        $target = [System.IO.Path]::Combine($dir, $_.item(0))
        $target = New-Object System.IO.FileInfo($target)
        $name = $_.item(1)
        $arguments = ''
        $icon = $null
        if ($_.length -ge 3) {
            $arguments = $_.item(2)
        }
        if ($_.length -ge 4) {
            $icon = [System.IO.Path]::Combine($dir, $_.item(3))
            $icon = New-Object System.IO.FileInfo($icon)
        }
        $arguments = (substitute $arguments @{ '$dir' = $dir; '$original_dir' = $original_dir; '$persist_dir' = $persist_dir })
        startmenu_shortcut $target $name $arguments $icon $global
    }
}

function shortcut_folder($global) {
    if ($global) {
        $startmenu = 'CommonStartMenu'
    } else {
        $startmenu = 'StartMenu'
    }
    return Convert-Path (ensure ([System.IO.Path]::Combine([Environment]::GetFolderPath($startmenu), 'Programs', 'Scoop Apps')))
}

function startmenu_shortcut([System.IO.FileInfo] $target, $shortcutName, $arguments, [System.IO.FileInfo]$icon, $global) {
    if (!$target.Exists) {
        Write-Host -f DarkRed "Creating shortcut for $shortcutName ($(fname $target)) failed: Couldn't find $target"
        return
    }
    if ($icon -and !$icon.Exists) {
        Write-Host -f DarkRed "Creating shortcut for $shortcutName ($(fname $target)) failed: Couldn't find icon $icon"
        return
    }

    $scoop_startmenu_folder = shortcut_folder $global
    $subdirectory = [System.IO.Path]::GetDirectoryName($shortcutName)
    if ($subdirectory) {
        $subdirectory = ensure $([System.IO.Path]::Combine($scoop_startmenu_folder, $subdirectory))
    }

    $wsShell = New-Object -ComObject WScript.Shell
    $wsShell = $wsShell.CreateShortcut("$scoop_startmenu_folder\$shortcutName.lnk")
    $wsShell.TargetPath = $target.FullName
    $wsShell.WorkingDirectory = $target.DirectoryName
    if ($arguments) {
        $wsShell.Arguments = $arguments
    }
    if ($icon -and $icon.Exists) {
        $wsShell.IconLocation = $icon.FullName
    }
    $wsShell.Save()
    Write-Host "Creating shortcut for $shortcutName ($(fname $target))"
}

# Removes the Startmenu shortcut if it exists
function rm_startmenu_shortcuts($manifest, $global, $arch) {
    $shortcuts = @(arch_specific 'shortcuts' $manifest $arch)
    $shortcuts | Where-Object { $_ -ne $null } | ForEach-Object {
        $name = $_.item(1)
        $shortcut = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$(shortcut_folder $global)\$name.lnk")
        Write-Host "Removing shortcut $(friendly_path $shortcut)"
        if (Test-Path -Path $shortcut) {
            Remove-Item $shortcut
        }
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAwqAGsa69BySEB
# +3XRhP47e4CfSjC/vnRYNl/trperiqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG+8jcIQ9Cl0TB1PXBNZ
# DHSMG0CKd+9SfhBl1tV6lZbNMA0GCSqGSIb3DQEBAQUABIIBAGdfBoUQ2G9W9K1v
# 7VhR4MVfLUN8qEe9KPww6izOdfDbRHNT1A8633epqe+mz9v6c0R+8eUDDvop8Suo
# 9QA+eZPY3MLZqjSfbpu+vewSNMDPRAI76B9P2TNs3Zl+NIFqF08IdjbWPw7+qAoX
# Mi+MFVNKIZJjD5tYptu3kZczbBjb8Zwjaxe71YbXbPgGUnrKFPqnARDPl+vESEfn
# CL/pA0Ghr/WDBX/jW6IGPFY2i4vosbMHbvm/OWTSyLaRhvviN01Dst2CimRCXEX9
# eioM98DOhzNXkUmYOYT+5twW36haaivW+RSxurGKOCVT9iukG/+92cg4Ls2jJUIw
# YuyDIpA=
# SIG # End signature block
