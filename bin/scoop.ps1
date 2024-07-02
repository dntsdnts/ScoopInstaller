#Requires -Version 5
Set-StrictMode -Off

. "$PSScriptRoot\..\lib\core.ps1"
. "$PSScriptRoot\..\lib\buckets.ps1"
. "$PSScriptRoot\..\lib\commands.ps1"
. "$PSScriptRoot\..\lib\help.ps1"

$subCommand = $Args[0]

# for aliases where there's a local function, re-alias so the function takes precedence
$aliases = Get-Alias | Where-Object { $_.Options -notmatch 'ReadOnly|AllScope' } | ForEach-Object { $_.Name }
Get-ChildItem Function: | Where-Object -Property Name -In -Value $aliases | ForEach-Object {
    Set-Alias -Name $_.Name -Value Local:$($_.Name) -Scope Script
}

switch ($subCommand) {
    ({ $subCommand -in @($null, '-h', '--help', '/?') }) {
        exec 'help'
    }
    ({ $subCommand -in @('-v', '--version') }) {
        Write-Host 'Current Scoop version:'
        if (Test-GitAvailable -and (Test-Path "$PSScriptRoot\..\.git") -and (get_config SCOOP_BRANCH 'master') -ne 'master') {
            Invoke-Git -Path "$PSScriptRoot\.." -ArgumentList @('log', 'HEAD', '-1', '--oneline')
        } else {
            $version = Select-String -Pattern '^## \[(v[\d.]+)\].*?([\d-]+)$' -Path "$PSScriptRoot\..\CHANGELOG.md"
            Write-Host $version.Matches.Groups[1].Value -ForegroundColor Cyan -NoNewline
            Write-Host " - Released at $($version.Matches.Groups[2].Value)"
        }
        Write-Host ''

        Get-LocalBucket | ForEach-Object {
            $bucketLoc = Find-BucketDirectory $_ -Root
            if (Test-GitAvailable -and (Test-Path "$bucketLoc\.git")) {
                Write-Host "'$_' bucket:"
                Invoke-Git -Path $bucketLoc -ArgumentList @('log', 'HEAD', '-1', '--oneline')
                Write-Host ''
            }
        }
    }
    ({ $subCommand -in (commands) }) {
        [string[]]$arguments = $Args | Select-Object -Skip 1
        if ($null -ne $arguments -and $arguments[0] -in @('-h', '--help', '/?')) {
            exec 'help' @($subCommand)
        } else {
            exec $subCommand $arguments
        }
    }
    default {
        warn "scoop: '$subCommand' isn't a scoop command. See 'scoop help'."
        exit 1
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1Kb8DLUcfF1Ud
# Q9qL+BIL+a83V9h7ZS0tai4ugVkp5qCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII48Dmy61eIAHy8pg5gW
# qelrHNl5Kbbdcei+a6sAJ5pXMA0GCSqGSIb3DQEBAQUABIIBAB4GVESBU7VJDQDa
# xZkOZ/Hv0/EvrHdY+xD0LraUWSHR6ZJuINtsf4orzmJz/fj51ERzkzeY8NE7kJB4
# sywPxqzZlU6Ns/vpq9OFPhAn6SsxqKlf9NwXNE+H1UKMgBFGcmEPVINzc+J5tc3f
# d1g66Z2bQpygt66H+4u3H4WlSZGA61ZLlh96rjRU8uop8bZBK2URKIueVETnMCQD
# l2dwWDIBmJF6+c6la8s3GXMp5KPkNWZXCec01cjv50+gNWAiDQ5z50RPQg8AdvG5
# YCEknxQhVAW6V4EKiutxoomheGxzYs0UctRgLvNxCr6uzKd8u8bpYyvgqz06tPm4
# BDSXeqU=
# SIG # End signature block
