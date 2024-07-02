# Usage: scoop uninstall <app> [options]
# Summary: Uninstall an app
# Help: e.g. scoop uninstall git
#
# Options:
#   -g, --global   Uninstall a globally installed app
#   -p, --purge    Remove all persistent data

. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1" # 'Get-Manifest' 'Select-CurrentVersion' (indirectly)
. "$PSScriptRoot\..\lib\system.ps1"
. "$PSScriptRoot\..\lib\install.ps1"
. "$PSScriptRoot\..\lib\shortcuts.ps1"
. "$PSScriptRoot\..\lib\psmodules.ps1"
. "$PSScriptRoot\..\lib\versions.ps1" # 'Select-CurrentVersion'

# options
$opt, $apps, $err = getopt $args 'gp' 'global', 'purge'

if ($err) {
    error "scoop uninstall: $err"
    exit 1
}

$global = $opt.g -or $opt.global
$purge = $opt.p -or $opt.purge

if (!$apps) {
    error '<app> missing'
    my_usage
    exit 1
}

if ($global -and !(is_admin)) {
    error 'You need admin rights to uninstall global apps.'
    exit 1
}

if ($apps -eq 'scoop') {
    & "$PSScriptRoot\..\bin\uninstall.ps1" $global $purge
    exit
}

$apps = Confirm-InstallationStatus $apps -Global:$global
if (!$apps) { exit 0 }

:app_loop foreach ($_ in $apps) {
    ($app, $global) = $_

    $version = Select-CurrentVersion -AppName $app -Global:$global
    $appDir = appdir $app $global
    if ($version) {
        Write-Host "Uninstalling '$app' ($version)."

        $dir = versiondir $app $version $global
        $persist_dir = persistdir $app $global

        $manifest = installed_manifest $app $version $global
        $install = install_info $app $version $global
        $architecture = $install.architecture

        Invoke-HookScript -HookType 'pre_uninstall' -Manifest $manifest -Arch $architecture

        #region Workaround for #2952
        if (test_running_process $app $global) {
            continue
        }
        #endregion Workaround for #2952

        try {
            Test-Path $dir -ErrorAction Stop | Out-Null
        } catch [UnauthorizedAccessException] {
            error "Access denied: $dir. You might need to restart."
            continue
        }

        run_uninstaller $manifest $architecture $dir
        rm_shims $app $manifest $global $architecture
        rm_startmenu_shortcuts $manifest $global $architecture

        # If a junction was used during install, that will have been used
        # as the reference directory. Otherwise it will just be the version
        # directory.
        $refdir = unlink_current $dir

        uninstall_psmodule $manifest $refdir $global

        env_rm_path $manifest $refdir $global $architecture
        env_rm $manifest $global $architecture

        try {
            # unlink all potential old link before doing recursive Remove-Item
            unlink_persist_data $manifest $dir
            Remove-Item $dir -Recurse -Force -ErrorAction Stop
        } catch {
            if (Test-Path $dir) {
                error "Couldn't remove '$(friendly_path $dir)'; it may be in use."
                continue
            }
        }

        Invoke-HookScript -HookType 'post_uninstall' -Manifest $manifest -Arch $architecture
    }
    # remove older versions
    $oldVersions = @(Get-ChildItem $appDir -Name -Exclude 'current')
    foreach ($version in $oldVersions) {
        Write-Host "Removing older version ($version)."
        $dir = versiondir $app $version $global
        try {
            # unlink all potential old link before doing recursive Remove-Item
            unlink_persist_data $manifest $dir
            Remove-Item $dir -Recurse -Force -ErrorAction Stop
        } catch {
            error "Couldn't remove '$(friendly_path $dir)'; it may be in use."
            continue app_loop
        }
    }
    if (Test-Path ($currentDir = Join-Path $appDir 'current')) {
        attrib $currentDir -R /L
        Remove-Item $currentDir -ErrorAction Stop -Force
    }
    if (!(Get-ChildItem $appDir)) {
        try {
            # if last install failed, the directory seems to be locked and this
            # will throw an error about the directory not existing
            Remove-Item $appdir -Recurse -Force -ErrorAction Stop
        } catch {
            if ((Test-Path $appdir)) { throw } # only throw if the dir still exists
        }
    }

    # purge persistant data
    if ($purge) {
        Write-Host 'Removing persisted data.'
        $persist_dir = persistdir $app $global

        if (Test-Path $persist_dir) {
            try {
                Remove-Item $persist_dir -Recurse -Force -ErrorAction Stop
            } catch {
                error "Couldn't remove '$(friendly_path $persist_dir)'; it may be in use."
                continue
            }
        }
    }

    success "'$app' was uninstalled."
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB2AWzJCowwH8Nx
# kJGmLkDiy6kCAdO/cdrcBbfewwnDdKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJEPlxin4Dzw2Y1pTRDG
# c92j5rPvYLLAUvG7svAGxj++MA0GCSqGSIb3DQEBAQUABIIBAJJbEXjiu6fsf+T2
# ivRlJaPNM6OVivRYpW20rZoXjOwmQPyTmFiYjy6zLqWa74rTg1BKrM60Lnsqiy0W
# qYK4Sm0NnYXSN9w1T40rv91UtDAVAnP2I3i/3vsDXJHLGgsRiUSu0W4ku9XfVoS2
# RfShz9Ij5zxK0rxTM10+dqEfPDgPiJtQHhE2zemrExBplf5akH0R2q4iS1ThkzZW
# qy1fpyd+7udAHG6ydgiC0BZzFpRnbxqf1ZTlDSscZCPKdM4Ot8MQkPzjfdGzHs7y
# e4RjWtVUjHKTRvi62LtI+vLOGPI4eiQGHlvi19fgmRRzOJYE2PlhzmKpGT65Fgzs
# oiRukXs=
# SIG # End signature block
