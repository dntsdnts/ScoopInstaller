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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAoGkB9fcFG9aYF
# cagoXtoXxZTw3zo65Vnb3Uov6tI3MaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF9r3uXyOkrvjhhlNRfU
# p6QrNxhpipKYg/CYV4w9QpPsMA0GCSqGSIb3DQEBAQUABIIBAJDPJD613+UY3SqS
# I2fak+/uwPDruSUXAVxmWz5x1hsGRj0bPJp/nGFPKFyZBl+llgfA92ot0X3J9uMI
# NJ7g8JNumHafWvE3bQ2NrAs8wmo4f3dzPTzKFg85Bb1Z6hIUgPcUclT16v5M2kQ6
# NOjIOvyl0Wx1iaBgMuNUVWLAFoyTYkzNdZ6e3EviniyoIthbilRrx2pnKZSiQXCT
# LKDF9XMKPGlgzMCpxi0t3uCXWZZ0IbA0KCTognbWU5UeKFzfCDXeVALh9dykWuNU
# xnkQ9fj9n6YpjiysC+1qC1CQgsgZHwntDgTHOqPyu8iaS7KVbPfEy9rKQl9H5UC8
# HUR9f/A=
# SIG # End signature block
