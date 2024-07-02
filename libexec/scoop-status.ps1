# Usage: scoop status
# Summary: Show status and check for new app versions
# Help: Options:
#   -l, --local         Checks the status for only the locally installed apps,
#                       and disables remote fetching/checking for Scoop and buckets

. "$PSScriptRoot\..\lib\manifest.ps1" # 'manifest' 'parse_json' "install_info"
. "$PSScriptRoot\..\lib\versions.ps1" # 'Select-CurrentVersion'

# check if scoop needs updating
$currentdir = versiondir 'scoop' 'current'
$needs_update = $false
$bucket_needs_update = $false
$script:network_failure = $false
$no_remotes = $args[0] -eq '-l' -or $args[0] -eq '--local'
if (!(Get-Command git -ErrorAction SilentlyContinue)) { $no_remotes = $true }
$list = @()
if (!(Get-FormatData ScoopStatus)) {
    Update-FormatData "$PSScriptRoot\..\supporting\formats\ScoopTypes.Format.ps1xml"
}

function Test-UpdateStatus($repopath) {
    if (Test-Path "$repopath\.git") {
        Invoke-Git -Path $repopath -ArgumentList @('fetch', '-q', 'origin')
        $script:network_failure = 128 -eq $LASTEXITCODE
        $branch  = Invoke-Git -Path $repopath -ArgumentList @('branch', '--show-current')
        $commits = Invoke-Git -Path $repopath -ArgumentList @('log', "HEAD..origin/$branch", '--oneline')
        if ($commits) { return $true }
        else { return $false }
    } else {
        return $true
    }
}

if (!$no_remotes) {
    $needs_update = Test-UpdateStatus $currentdir
    foreach ($bucket in Get-LocalBucket) {
        if (Test-UpdateStatus (Find-BucketDirectory $bucket -Root)) {
            $bucket_needs_update = $true
            break
        }
    }
}

if ($needs_update) {
    warn "Scoop out of date. Run 'scoop update' to get the latest changes."
} elseif ($bucket_needs_update) {
    warn "Scoop bucket(s) out of date. Run 'scoop update' to get the latest changes."
} elseif (!$script:network_failure -and !$no_remotes) {
    success 'Scoop is up to date.'
}

$true, $false | ForEach-Object { # local and global apps
    $global = $_
    $dir = appsdir $global
    if (!(Test-Path $dir)) { return }

    Get-ChildItem $dir | Where-Object name -NE 'scoop' | ForEach-Object {
        $app = $_.name
        $status = app_status $app $global
        if (!$status.outdated -and !$status.failed -and !$status.removed -and !$status.missing_deps) { return }

        $item = [ordered]@{}
        $item.Name = $app
        $item.'Installed Version' = $status.version
        $item.'Latest Version' = if ($status.outdated) { $status.latest_version } else { "" }
        $item.'Missing Dependencies' = $status.missing_deps -Split ' ' -Join ' | '
        $info = @()
        if ($status.failed)  { $info += 'Install failed' }
        if ($status.hold)    { $info += 'Held package' }
        if ($status.removed) { $info += 'Manifest removed' }
        $item.Info = $info -join ', '
        $list += [PSCustomObject]$item
    }
}

if ($list.Length -eq 0 -and !$needs_update -and !$bucket_needs_update -and !$script:network_failure) {
    success 'Everything is ok!'
}

$list | Add-Member -TypeName ScoopStatus -PassThru

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCArdpbvN5kzGuNT
# 43dUlSfLc1L34lHIfM9gvUsUxXtqs6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOVAuhSi6BDeSzk4vBiY
# qqe7vz1aUVpxaMv1rCuTk0Z7MA0GCSqGSIb3DQEBAQUABIIBAEqiuyf/sXYLcpyk
# +xRDqcQfsZwnP+eydc7XvTK0s2+tD54ebjJwI9NZwc9H1CA9VJEmbd+Z7y5QEsZP
# UhgJmD4lZ7xGq0RkcIQN+9mZ0gl556Yb5WjS+5jXuJr/uSiiGs20IPUb9azhiJvN
# xPDsM2VypoGojIombGtuEgxXOgCGwa4fdpZUD7dmIrG0YTBSeMJJBv3RUptBnwld
# 9BD6xompW9lsWWJWDCbFx977NaBlRBR9wQe3KnEnPGzsPAh1WiMlOfmNqXwJwyKI
# s3rOiBDiqHtyrvaPX2COgKsOY31BWugQc/bhdRkS0bwVNBr1ozcm2StebQDGgQ5w
# vwJT4Vo=
# SIG # End signature block
