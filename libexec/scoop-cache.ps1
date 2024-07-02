# Usage: scoop cache show|rm [app(s)]
# Summary: Show or clear the download cache
# Help: Scoop caches downloads so you don't need to download the same files
# when you uninstall and re-install the same version of an app.
#
# You can use
#     scoop cache show
# to see what's in the cache, and
#     scoop cache rm <app> to remove downloads for a specific app.
#
# To clear everything in your cache, use:
#     scoop cache rm *
# You can also use the `-a/--all` switch in place of `*` here

param($cmd)

function cacheinfo($file) {
    $app, $version, $url = $file.Name -split '#'
    New-Object PSObject -Property @{ Name = $app; Version = $version; Length = $file.Length; URL = $url }
}

function cacheshow($app) {
    if (!$app -or $app -eq '*') {
        $app = '.*?'
    } else {
        $app = '(' + ($app -join '|') + ')'
    }
    $files = @(Get-ChildItem $cachedir | Where-Object -Property Name -Value "^$app#" -Match)
    $totalLength = ($files | Measure-Object -Property Length -Sum).Sum

    $files | ForEach-Object { cacheinfo $_ } | Select-Object Name, Version, Length, URL

    Write-Host "Total: $($files.Length) $(pluralize $files.Length 'file' 'files'), $(filesize $totalLength)" -ForegroundColor Yellow
}

function cacheremove($app) {
    if (!$app) {
        'ERROR: <app(s)> missing'
        my_usage
        exit 1
    } elseif ($app -eq '*' -or $app -eq '-a' -or $app -eq '--all') {
        $files = @(Get-ChildItem $cachedir)
    } else {
        $app = '(' + ($app -join '|') + ')'
        $files = @(Get-ChildItem $cachedir | Where-Object -Property Name -Value "^$app#" -Match)
    }
    $totalLength = ($files | Measure-Object -Property Length -Sum).Sum

    $files | ForEach-Object {
        $curr = cacheinfo $_
        Write-Host "Removing $($curr.URL)..."
        Remove-Item $_.FullName
        if(Test-Path "$cachedir\$($curr.Name).txt") {
            Remove-Item "$cachedir\$($curr.Name).txt"
        }
    }

    Write-Host "Deleted: $($files.Length) $(pluralize $files.Length 'file' 'files'), $(filesize $totalLength)" -ForegroundColor Yellow
}

switch($cmd) {
    'rm' {
        cacheremove $Args
    }
    'show' {
        cacheshow $Args
    }
    default {
        cacheshow (@($cmd) + $Args)
    }
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDU0NzsmZXrtQNE
# 6dlFsIhx+fpf4xTXJ8W7NxHZgadesKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDAsrqX0xOykqMMnwgZR
# oLmoaVkwN8nQLYW8Gix33zUvMA0GCSqGSIb3DQEBAQUABIIBAKLCil9A+Z6VbrCE
# Uc/smUWPfJLzLNDZ+crDVKwMA+YWHVv0rYPePnvFsHWXeTPlnpxKXFmDDAbqvYBR
# rxGY7SbrufwaQMJxRhEO45qM75qhE/nlaJsisdU/K8H88NcUd71yZwy25fAlbTfV
# GgqGark+vrh5vZm/ex7Ucr/kPScv/go1uOuuzVrkMajP6+KPmV11RnCqXJ2eZwQD
# X7r2ysiR6R/23og4igZJua3raBVPDUB6j64hBOb8YMlib1tE4QIDOKQqUi2/6pKC
# ciQA1TQPIDM4TweqRfLXjsIMbGYrfT+F1lbA1mX8jJ3UU4ZUuZcjTHJRcnDAd3wu
# 7VZ7l2o=
# SIG # End signature block
