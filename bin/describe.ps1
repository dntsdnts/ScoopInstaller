<#
.SYNOPSIS
    Search for application description on homepage.
.PARAMETER App
    Manifest name to search.
    Placeholders are supported.
.PARAMETER Dir
    Where to search for manifest(s).
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
    [String] $Dir
)

. "$PSScriptRoot\..\lib\core.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1"
. "$PSScriptRoot\..\lib\description.ps1"

$Dir = Convert-Path $Dir
$Queue = @()

Get-ChildItem $Dir -Filter "$App.json" -Recurse | ForEach-Object {
    $manifest = parse_json $_.FullName
    $Queue += , @($_.BaseName, $manifest)
}

$Queue | ForEach-Object {
    $name, $manifest = $_
    Write-Host "$name`: " -NoNewline

    if (!$manifest.homepage) {
        Write-Host "`nNo homepage set." -ForegroundColor Red
        return
    }
    # get description from homepage
    try {
        $wc = New-Object Net.Webclient
        $wc.Headers.Add('User-Agent', (Get-UserAgent))
        $homepage = $wc.DownloadData($manifest.homepage)
        $home_html = (Get-Encoding($wc)).GetString($homepage)
    } catch {
        Write-Host "`n$($_.Exception.Message)" -ForegroundColor Red
        return
    }

    $description, $descr_method = find_description $manifest.homepage $home_html
    if (!$description) {
        Write-Host "`nDescription not found ($($manifest.homepage))" -ForegroundColor Red
        return
    }

    $description = clean_description $description

    Write-Host "(found by $descr_method)"
    Write-Host "  ""$description""" -ForegroundColor Green
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCAGqJ3WR2yAm1K
# 0grZO3Br8wXADU9NvAW+0aEV9k0QK6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAlp29zjFESgLRYUYoYR
# EvMegl9QIngoxxJ4y8GwpjtJMA0GCSqGSIb3DQEBAQUABIIBABQYax1YDuMvx+F1
# YZ/GH0bAOUiksOBl9fwXbua0NWeamORufQ9o21Wugt8qGQuy0mG77ku4Ui79SvKY
# Ej5jS8Mb7Qn+l6mVfXyOLJsNUPyKnJxPheiQGwjhHWgXFThsxkW897hX554xHsGu
# nLG8SSMRT4YN/RUzE1/DuUq7kzQKLMt2JHlymaS1gYSipopdwSMlsdalsKFYnNST
# W/+EedU7/Pt6Zr5Q2TNNeSImBk741RlSoectq/gb0w2rH41njpplXtTuJWKikjIt
# uzDXf93S/yHz//f1QGHXExflFDTwLASBatKo+uEciEBx823brTmjQ/OYtP51P1WZ
# +83Mee0=
# SIG # End signature block
