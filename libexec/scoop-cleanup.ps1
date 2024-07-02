# Usage: scoop cleanup <app> [options]
# Summary: Cleanup apps by removing old versions
# Help: 'scoop cleanup' cleans Scoop apps by removing old versions.
# 'scoop cleanup <app>' cleans up the old versions of that app if said versions exist.
#
# You can use '*' in place of <app> or `-a`/`--all` switch to cleanup all apps.
#
# Options:
#   -a, --all          Cleanup all apps (alternative to '*')
#   -g, --global       Cleanup a globally installed app
#   -k, --cache        Remove outdated download cache

. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1" # 'Select-CurrentVersion' (indirectly)
. "$PSScriptRoot\..\lib\versions.ps1" # 'Select-CurrentVersion'
. "$PSScriptRoot\..\lib\install.ps1" # persist related

$opt, $apps, $err = getopt $args 'agk' 'all', 'global', 'cache'
if ($err) { "scoop cleanup: $err"; exit 1 }
$global = $opt.g -or $opt.global
$cache = $opt.k -or $opt.cache
$all = $opt.a -or $opt.all

if (!$apps -and !$all) { 'ERROR: <app> missing'; my_usage; exit 1 }

if ($global -and !(is_admin)) {
    'ERROR: you need admin rights to cleanup global apps'; exit 1
}

function cleanup($app, $global, $verbose, $cache) {
    $current_version = Select-CurrentVersion -AppName $app -Global:$global
    if ($cache) {
        Remove-Item "$cachedir\$app#*" -Exclude "$app#$current_version#*"
    }
    $appDir = appdir $app $global
    $versions = Get-ChildItem $appDir -Name
    $versions = $versions | Where-Object { $current_version -ne $_ -and $_ -ne 'current' }
    if (!$versions) {
        if ($verbose) { success "$app is already clean" }
        return
    }

    Write-Host -f yellow "Removing $app`:" -NoNewline
    $versions | ForEach-Object {
        $version = $_
        Write-Host " $version" -NoNewline
        $dir = versiondir $app $version $global
        # unlink all potential old link before doing recursive Remove-Item
        unlink_persist_data (installed_manifest $app $version $global) $dir
        Remove-Item $dir -ErrorAction Stop -Recurse -Force
    }
    $leftVersions = Get-ChildItem $appDir
    if ($leftVersions.Length -eq 1 -and $leftVersions.Name -eq 'current' -and $leftVersions.LinkType) {
        attrib $leftVersions.FullName -R /L
        Remove-Item $leftVersions.FullName -ErrorAction Stop -Force
        $leftVersions = $null
    }
    if (!$leftVersions) {
        Remove-Item $appDir -ErrorAction Stop -Force
    }
    Write-Host ''
}

if ($apps -or $all) {
    if ($apps -eq '*' -or $all) {
        $verbose = $false
        $apps = applist (installed_apps $false) $false
        if ($global) {
            $apps += applist (installed_apps $true) $true
        }
    } else {
        $verbose = $true
        $apps = Confirm-InstallationStatus $apps -Global:$global
    }

    # $apps is now a list of ($app, $global) tuples
    $apps | ForEach-Object { cleanup @_ $verbose $cache }

    if ($cache) {
        Remove-Item "$cachedir\*.download" -ErrorAction Ignore
    }

    if (!$verbose) {
        success 'Everything is shiny now!'
    }
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC2qELcYSKcCOxa
# m8LXjQYdeSZ0MX7w/wwjYwrvETHGgqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIN4l31SfKScuZB8E2fV
# jXk+jN+55JV4hFJIw5fAfqBFMA0GCSqGSIb3DQEBAQUABIIBAD20VnlRZq7gb0nt
# poofDOTUfjZ7QL//lQQkxNsnnUDTniaSF2N3wa1Bn5UO8N494v2pkKmcebgMeYWA
# dv4CuhwpDQe2GRhabaz4vB0k2eaYGX7YY1tzwvLVr5RxoOKo+iro4DT8KB5JU9BA
# 3SRM0rlIndne5hOcEh+qppJYf+kbC8OhROo7bm5hKpCD/yMT16UR1lmZpVRbFPw9
# dzCIeBeIRM8AdFPD9tTqkZzmMj3XyiA2m3skwu6VmkdmdGc4D6SyQnzNTNj1LLfL
# +L4ndTDw1QC61kHuoBCsYKq1P1VkbnBse0OQx0KHRHFWYlLy/zx+ALUiH02GSCcn
# Pf99Yio=
# SIG # End signature block
