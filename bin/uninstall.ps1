<#
.SYNOPSIS
    Uninstall ALL scoop applications and scoop itself.
.PARAMETER global
    Global applications will be uninstalled.
.PARAMETER purge
    Persisted data will be deleted.
#>
param(
    [bool] $global,
    [bool] $purge
)

. "$PSScriptRoot\..\lib\core.ps1"
. "$PSScriptRoot\..\lib\system.ps1"
. "$PSScriptRoot\..\lib\install.ps1"
. "$PSScriptRoot\..\lib\shortcuts.ps1"
. "$PSScriptRoot\..\lib\versions.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1"

if ($global -and !(is_admin)) {
    error 'You need admin rights to uninstall globally.'
    exit 1
}

if ($purge) {
    warn 'This will uninstall Scoop, all the programs that have been installed with Scoop and all persisted data!'
} else {
    warn 'This will uninstall Scoop and all the programs that have been installed with Scoop!'
}
$yn = Read-Host 'Are you sure? (yN)'
if ($yn -notlike 'y*') { exit }

$errors = $false

# Uninstall given app
function do_uninstall($app, $global) {
    $version = Select-CurrentVersion -AppName $app -Global:$global
    $dir = versiondir $app $version $global
    $manifest = installed_manifest $app $version $global
    $install = install_info $app $version $global
    $architecture = $install.architecture

    Write-Output "Uninstalling '$app'"
    run_uninstaller $manifest $architecture $dir
    rm_shims $app $manifest $global $architecture

    # If a junction was used during install, that will have been used
    # as the reference directory. Othewise it will just be the version
    # directory.
    $refdir = unlink_current (appdir $app $global)

    env_rm_path $manifest $refdir $global $architecture
    env_rm $manifest $global $architecture

    $appdir = appdir $app $global
    try {
        Remove-Item $appdir -Recurse -Force -ErrorAction Stop
    } catch {
        $errors = $true
        warn "Couldn't remove $(friendly_path $appdir): $_.Exception"
    }
}

function rm_dir($dir) {
    try {
        Remove-Item $dir -Recurse -Force -ErrorAction Stop
    } catch {
        abort "Couldn't remove $(friendly_path $dir): $_"
    }
}

# Remove all folders (except persist) inside given scoop directory.
function keep_onlypersist($directory) {
    Get-ChildItem $directory -Exclude 'persist' | ForEach-Object { rm_dir $_ }
}

# Run uninstallation for each app if necessary, continuing if there's
# a problem deleting a directory (which is quite likely)
if ($global) {
    installed_apps $true | ForEach-Object { # global apps
        do_uninstall $_ $true
    }
}

installed_apps $false | ForEach-Object { # local apps
    do_uninstall $_ $false
}

if ($errors) {
    abort 'Not all apps could be deleted. Try again or restart.'
}

if ($purge) {
    rm_dir $scoopdir
    if ($global) { rm_dir $globaldir }
} else {
    keep_onlypersist $scoopdir
    if ($global) { keep_onlypersist $globaldir }
}

Remove-Path -Path (shimdir $global) -Global:$global
if (get_config USE_ISOLATED_PATH) {
    Remove-Path -Path ('%' + $scoopPathEnvVar + '%') -Global:$global
}

success 'Scoop has been uninstalled.'

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHqQChYEkVNhbT
# sEl0rFdLy1+GJ9lFAF698PVxVjtprKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK4ds2TrFsMQYOWW+/LA
# 05IDPhUDNvyWlUmkbR3c+6IwMA0GCSqGSIb3DQEBAQUABIIBAF4lDPgl0GHuNZMk
# j8z4/mZaoYwAQiLFlKqUVeUMAkorMmGywV2Gq4Vcp6CBTacmiHxihbTzx6hfvYIn
# ll/jnBvMseL0tGYnBGDSDD/Io0RMJLqA7NjVRD7jGJIOFjvJ8dqcUNfP2up2wINf
# R50YJg2LFBma0RPFlQZ/zK+aQYvc0TmrEJzQGhw+CoGrgPz2n+5h7XSNghwINAy4
# YJVIkiH7WzPynf8MuW3d2PhlbMLa+lLEBSAwxmQJhYoO2eJDOC4uQCPv3iZ16IND
# lj0gL/O0q7mTpBtc6CDgUwuuh2MZ4UBWi+J2fUSNXxLJtz7QjPO5hkRbwkODBGRY
# g8CoTfQ=
# SIG # End signature block
