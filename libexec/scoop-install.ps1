# Usage: scoop install <app> [options]
# Summary: Install apps
# Help: e.g. The usual way to install an app (uses your local 'buckets'):
#      scoop install git
#
# To install a different version of the app
# (note that this will auto-generate the manifest using current version):
#      scoop install gh@2.7.0
#
# To install an app from a manifest at a URL:
#      scoop install https://raw.githubusercontent.com/ScoopInstaller/Main/master/bucket/runat.json
#
# To install an app from a manifest on your computer
#      scoop install \path\to\app.json
#
# Options:
#   -g, --global                    Install the app globally
#   -i, --independent               Don't install dependencies automatically
#   -k, --no-cache                  Don't use the download cache
#   -u, --no-update-scoop           Don't update Scoop before installing if it's outdated
#   -s, --skip                      Skip hash validation (use with caution!)
#   -a, --arch <32bit|64bit|arm64>  Use the specified architecture, if the app supports it

. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\json.ps1" # 'autoupdate.ps1' 'manifest.ps1' (indirectly)
. "$PSScriptRoot\..\lib\autoupdate.ps1" # 'generate_user_manifest' (indirectly)
. "$PSScriptRoot\..\lib\manifest.ps1" # 'generate_user_manifest' 'Get-Manifest' 'Select-CurrentVersion' (indirectly)
. "$PSScriptRoot\..\lib\system.ps1"
. "$PSScriptRoot\..\lib\install.ps1"
. "$PSScriptRoot\..\lib\decompress.ps1"
. "$PSScriptRoot\..\lib\shortcuts.ps1"
. "$PSScriptRoot\..\lib\psmodules.ps1"
. "$PSScriptRoot\..\lib\versions.ps1"
. "$PSScriptRoot\..\lib\depends.ps1"

$opt, $apps, $err = getopt $args 'gikusa:' 'global', 'independent', 'no-cache', 'no-update-scoop', 'skip', 'arch='
if ($err) { "scoop install: $err"; exit 1 }

$global = $opt.g -or $opt.global
$check_hash = !($opt.s -or $opt.skip)
$independent = $opt.i -or $opt.independent
$use_cache = !($opt.k -or $opt.'no-cache')
$architecture = Get-DefaultArchitecture
try {
    $architecture = Format-ArchitectureString ($opt.a + $opt.arch)
} catch {
    abort "ERROR: $_"
}

if (!$apps) { error '<app> missing'; my_usage; exit 1 }

if ($global -and !(is_admin)) {
    abort 'ERROR: you need admin rights to install global apps'
}

if (is_scoop_outdated) {
    if ($opt.u -or $opt.'no-update-scoop') {
        warn "Scoop is out of date."
    } else {
        & "$PSScriptRoot\scoop-update.ps1"
    }
}

ensure_none_failed $apps

if ($apps.length -eq 1) {
    $app, $null, $version = parse_app $apps
    if ($app.EndsWith('.json')) {
        $app = [System.IO.Path]::GetFileNameWithoutExtension($app)
    }
    $curVersion = Select-CurrentVersion -AppName $app -Global:$global
    if ($null -eq $version -and $curVersion) {
        warn "'$app' ($curVersion) is already installed.`nUse 'scoop update $app$(if ($global) { ' --global' })' to install a new version."
        exit 0
    }
}

# get any specific versions that we need to handle first
$specific_versions = $apps | Where-Object {
    $null, $null, $version = parse_app $_
    return $null -ne $version
}

# compare object does not like nulls
if ($specific_versions.length -gt 0) {
    $difference = Compare-Object -ReferenceObject $apps -DifferenceObject $specific_versions -PassThru
} else {
    $difference = $apps
}

$specific_versions_paths = $specific_versions | ForEach-Object {
    $app, $bucket, $version = parse_app $_
    if (installed_manifest $app $version) {
        warn "'$app' ($version) is already installed.`nUse 'scoop update $app$(if ($global) { " --global" })' to install a new version."
        continue
    }

    generate_user_manifest $app $bucket $version
}
$apps = @(($specific_versions_paths + $difference) | Where-Object { $_ } | Sort-Object -Unique)

# remember which were explictly requested so that we can
# differentiate after dependencies are added
$explicit_apps = $apps

if (!$independent) {
    $apps = $apps | Get-Dependency -Architecture $architecture | Select-Object -Unique # adds dependencies
}
ensure_none_failed $apps

$apps, $skip = prune_installed $apps $global

$skip | Where-Object { $explicit_apps -contains $_ } | ForEach-Object {
    $app, $null, $null = parse_app $_
    $version = Select-CurrentVersion -AppName $app -Global:$global
    warn "'$app' ($version) is already installed. Skipping."
}

$suggested = @{ };
if ((Test-Aria2Enabled) -and (get_config 'aria2-warning-enabled' $true)) {
    warn "Scoop uses 'aria2c' for multi-connection downloads."
    warn "Should it cause issues, run 'scoop config aria2-enabled false' to disable it."
    warn "To disable this warning, run 'scoop config aria2-warning-enabled false'."
}
$apps | ForEach-Object { install_app $_ $architecture $global $suggested $use_cache $check_hash }

show_suggestions $suggested

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBmxmaAAMKoS3eL
# m0hay7SedFaL8g+AxkSXQ9IvRWGbTKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINzF8FYXwZKvRCFEsVr2
# yNvP9PGnjj/dQmTRysHhQHH5MA0GCSqGSIb3DQEBAQUABIIBAArlvXUjqm74mc/y
# 7xe1FBVwJXGDT8CAMaCdt7kkoFu8xmcJV4+lf0dlfkJEQM0i2dmC1z5HPF7z4E5T
# wkTNMPp6bI5JSdx8fGJ8Le1KU0Yg+D5QlafeneZlSQAmcQihh7fq6ZIH3ho0aKl0
# F0hpruFAb8quSMP+4YmyniicCCFR9DkOPVlP+m9so9Q/LRHQjsXEvKG4TGFKcVPH
# Q30UnqsNPa1Jb4lDODbX5ry2bEqWGFfKTliklAtpaGRgze98KTJcgP5NYfE0/DSH
# cnprpOJnIBDV3egFx5ByOS2DBsivEXJuwYzGi02pylUF+7BkVuSnKRGWNEyWwKQO
# oFQYhho=
# SIG # End signature block
