<#
.SYNOPSIS
    Check if manifest contains checkver and autoupdate property.
.PARAMETER App
    Manifest name.
    Wirldcard is supported.
.PARAMETER Dir
    Location of manifests.
.PARAMETER SkipSupported
    Manifests with checkver and autoupdate will not be presented.
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
    [Switch] $SkipSupported
)

. "$PSScriptRoot\..\lib\core.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1"

$Dir = Convert-Path $Dir

Write-Host '[' -NoNewLine
Write-Host 'C' -NoNewLine -ForegroundColor Green
Write-Host ']heckver'
Write-Host ' | [' -NoNewLine
Write-Host 'A' -NoNewLine -ForegroundColor Cyan
Write-Host ']utoupdate'
Write-Host ' |  |'

Get-ChildItem $Dir -Filter "$App.json" -Recurse | ForEach-Object {
    $json = parse_json $_.FullName

    if ($SkipSupported -and $json.checkver -and $json.autoupdate) { return }

    Write-Host '[' -NoNewLine
    Write-Host $(if ($json.checkver) { 'C' } else { ' ' }) -NoNewLine -ForegroundColor Green
    Write-Host ']' -NoNewLine

    Write-Host '[' -NoNewLine
    Write-Host $(if ($json.autoupdate) { 'A' } else { ' ' }) -NoNewLine -ForegroundColor Cyan
    Write-Host '] ' -NoNewLine
    Write-Host $_.BaseName
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBAQ8l+m0GVp/ZO
# MeI3KeWLrXcwYdEDFVsbOM8szWrg3aCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHpHLX0Jd4toXjCg/s/X
# n6sDJWlfUMZ5jyEZYwCwpnfSMA0GCSqGSIb3DQEBAQUABIIBAHTmsWWQ4vKXoBR7
# I5+Yp16ogFWspDYdMuB92PZ3yesp+LWLOrCB9UqCYBb4PFmgHMGbGDOazH1qlCug
# 9c7WK79obz5XE8W/b/RyI+gKwM2vWRnw38FxAja4XbE7MaQXKcZtHfZbVZTG8pYS
# ZYzOCXwkhrPeMZYxvUsz5vgtiMJzEXmXoSG6ZgKpLR6hMa0bJWN4OWZcpj0oJ5+Q
# NDZ+wyYBJPIwqMQ51dOOYNOUVRlGv9f2tuInHHssqisWzyBW4NgSLzoaEqDW7ztP
# fzV/FnK39vev6dUCUjeaPMNFA8oXD3k2+7zT+Jt+44rE82Ropu1VJbXP2LDaO3zi
# Ex+KKqk=
# SIG # End signature block
