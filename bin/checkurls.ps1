<#
.SYNOPSIS
    List manifests which do not have valid URLs.
.PARAMETER App
    Manifest name to search.
    Placeholder is supported.
.PARAMETER Dir
    Where to search for manifest(s).
.PARAMETER Timeout
    How long (seconds) the request can be pending before it times out.
.PARAMETER SkipValid
    Manifests will all valid URLs will not be shown.
#>
param(
    [String] $App = '*',
    [Parameter(Mandatory = $true)]
    [ValidateScript( {
        if (!(Test-Path $_ -Type Container)) {
            throw "$_ is not a directory!"
        } else {
            $true
        }
    })]
    [String] $Dir,
    [Int] $Timeout = 5,
    [Switch] $SkipValid
)

. "$PSScriptRoot\..\lib\core.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1"
. "$PSScriptRoot\..\lib\install.ps1"

$Dir = Convert-Path $Dir
$Queue = @()

Get-ChildItem $Dir -Filter "$App.json" -Recurse | ForEach-Object {
    $manifest = parse_json $_.FullName
    $Queue += , @($_.BaseName, $manifest)
}

Write-Host '[' -NoNewLine
Write-Host 'U' -NoNewLine -ForegroundColor Cyan
Write-Host ']RLs'
Write-Host ' | [' -NoNewLine
Write-Host 'O' -NoNewLine -ForegroundColor Green
Write-Host ']kay'
Write-Host ' |  | [' -NoNewLine
Write-Host 'F' -NoNewLine -ForegroundColor Red
Write-Host ']ailed'
Write-Host ' |  |  |'

function test_dl([String] $url, $cookies) {
    # Trim renaming suffix, prevent getting 40x response
    $url = ($url -split '#/')[0]

    $wreq = [Net.WebRequest]::Create($url)
    $wreq.Timeout = $Timeout * 1000
    if ($wreq -is [Net.HttpWebRequest]) {
        $wreq.UserAgent = Get-UserAgent
        $wreq.Referer = strip_filename $url
        if ($cookies) {
            $wreq.Headers.Add('Cookie', (cookie_header $cookies))
        }
    }

    get_config PRIVATE_HOSTS | Where-Object { $_ -ne $null -and $url -match $_.match } | ForEach-Object {
        (ConvertFrom-StringData -StringData $_.Headers).GetEnumerator() | ForEach-Object {
            $wreq.Headers[$_.Key] = $_.Value
        }
    }

    $wres = $null
    try {
        $wres = $wreq.GetResponse()

        return $url, $wres.StatusCode, $null
    } catch {
        $e = $_.Exception
        if ($e.InnerException) { $e = $e.InnerException }

        return $url, 'Error', $e.Message
    } finally {
        if ($null -ne $wres -and $wres -isnot [Net.FtpWebResponse]) {
            $wres.Close()
        }
    }
}

foreach ($man in $Queue) {
    $name, $manifest = $man
    $urls = @()
    $ok = 0
    $failed = 0
    $errors = @()

    if ($manifest.url) {
        $manifest.url | ForEach-Object { $urls += $_ }
    } else {
        script:url $manifest '64bit' | ForEach-Object { $urls += $_ }
        script:url $manifest '32bit' | ForEach-Object { $urls += $_ }
        script:url $manifest 'arm64' | ForEach-Object { $urls += $_ }
    }

    $urls | ForEach-Object {
        $url, $status, $msg = test_dl $_ $manifest.cookie
        if ($msg) { $errors += "$msg ($url)" }
        if ($status -eq 'OK' -or $status -eq 'OpeningData') { $ok += 1 } else { $failed += 1 }
    }

    if (($ok -eq $urls.Length) -and $SkipValid) { continue }

    # URLS
    Write-Host '[' -NoNewLine
    Write-Host $urls.Length -NoNewLine -ForegroundColor Cyan
    Write-Host ']' -NoNewLine

    # Okay
    Write-Host '[' -NoNewLine
    if ($ok -eq $urls.Length) {
        Write-Host $ok -NoNewLine -ForegroundColor Green
    } elseif ($ok -eq 0) {
        Write-Host $ok -NoNewLine -ForegroundColor Red
    } else {
        Write-Host $ok -NoNewLine -ForegroundColor Yellow
    }
    Write-Host ']' -NoNewLine

    # Failed
    Write-Host '[' -NoNewLine
    if ($failed -eq 0) {
        Write-Host $failed -NoNewLine -ForegroundColor Green
    } else {
        Write-Host $failed -NoNewLine -ForegroundColor Red
    }
    Write-Host '] ' -NoNewLine
    Write-Host $name

    $errors | ForEach-Object {
        Write-Host "       > $_" -ForegroundColor DarkRed
    }
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUO5f2Y+dJDj9brxD5gSeIfF8a
# vOagggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUn7IstKOFvvRTA9SqnYhv6YTEpBAwDQYJKoZIhvcNAQEBBQAEggEA
# twQPjZoA3Iy3STNHDo9ty30q+QSiZo6aM1eaZoC9gt+EC63jsQ2vC97pZE8gSfMU
# uYHluetXk7m3NCcazKeP8dHaETf6r4wp3PI12cKAowFV4FAT+gVL02hEMk8rLLz4
# 9rnVp9S+sCYNCLktvhbblXC2YV3xb5vo67gop8UIBgYSZqXT/PXRxhFKDaJccf4L
# QcuY0jX1mCL6cohsdUUU/1ZPRBA2qv/ODBmmS3CLbhKftULZAxfBhkUQDL5d5ymw
# p7katYdLxzqcqFbMlFB4IYMG0mGCqgRvN29rQnaoo3G3Q3FxzKwl5oZ0y0Qej/yZ
# Sb2QqxyBGxjEt20OGlrQ6Q==
# SIG # End signature block
