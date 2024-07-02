# Usage: scoop status
# Summary: Show status and check for new app versions
# Help: Options:
#   -l, --local         Checks the status for only the locally installed apps,
#                       and disables remote fetching/checking for Scoop and buckets

. "$PSScriptRoot\..\lib\manifest.ps1" # 'manifest' 'parse_json' "install_info"
. "$PSScriptRoot\..\lib\versions.ps1" # 'Select-CurrentVersion'

# check if scoop needs updating
$currentdir = fullpath $(versiondir 'scoop' 'current')
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
        git_cmd -C "`"$repopath`"" fetch -q origin
        $script:network_failure = 128 -eq $LASTEXITCODE
        $branch  = git -C $repopath branch --show-current
        $commits = git -C $repopath log "HEAD..origin/$branch" --oneline
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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsl+O00qtmNp0iYvu9ffEiAv0
# r82gggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUc8jwbG/SEu3QfeWk6SjO/w9tRzIwDQYJKoZIhvcNAQEBBQAEggEA
# EhgWsXG+vxiwNMgrbhBZOSOkXJuxuUKXqY6KMCvuNH3HTo43Lp9Kz7wUgJ1KBJB8
# 7YrYoW+0+NAWfCUoUCLJPxZqQHnMEisZIwy3o2p5b35ckONfMEIrkyGZckMB5byo
# no8tNdDPtG636vQ4cH+vzH9m0TK/EXfYXYjKB0K686WppRIgDcDZsk5Cx33kvdvu
# l7e5OK/v6UBFcls07o8AVCVWaEe1AjG9j93wcYgbkpB6sGurnZ/EhIbvwDJTzZdZ
# r+9DrR+Qw7dRu6ERVTTsyadKIYKy1A3a9B6Jd7mIQJnRNKCn2xMPSZKYpNlW2wuf
# Mv/d+iwouT3D5kbHnNkMvQ==
# SIG # End signature block
