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
    New-Object PSObject -Property @{ Name = $app; Version = $version; Length = $file.Length }
}

function cacheshow($app) {
    if (!$app -or $app -eq '*') {
        $app = '.*?'
    } else {
        $app = '(' + ($app -join '|') + ')'
    }
    $files = @(Get-ChildItem $cachedir | Where-Object -Property Name -Value "^$app#" -Match)
    $totalLength = ($files | Measure-Object -Property Length -Sum).Sum

    $files | ForEach-Object { cacheinfo $_ } | Select-Object Name, Version, Length

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
        Write-Host "Removing $($_.Name)..."
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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjFUzJYhIv0sStRsugOfPbT1O
# K1qgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQU6FR8XGz64dJACapmE4H9a+fE11EwDQYJKoZIhvcNAQEBBQAEggEA
# ZUHSEyCtgebar+QWDxz18biqm6gRl95O0NE4fluiOefAK/3KWf9/mvhEcFmxp9KJ
# 5QPaCXSkbeuPJzzzYCr8iU3fiYqPmuOhzGzyB7O6OQlidkxEfoS6I/QFb+CnJtGH
# Tvd/hM2iNux3OTEQ3PMPY0qIm3ZBCW2oJOgYAPDrToTVqR6ElOT8uzgPuzUvI+lz
# eOYXBt6VU2OAxPw23f2xLLqhxC8ZjxAx5FXBparPVhn3QH8W/IL4c7j81akzCgd4
# dWoVbx7NTMB83wgF3RliTcbPr2WhkY307DOv/oGGfcJ758ug+y3jJtgpCqJqutcQ
# 3ZeIgMVmFxMOIgurnnhKRQ==
# SIG # End signature block
