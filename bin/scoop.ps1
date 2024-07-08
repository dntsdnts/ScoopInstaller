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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUELyevwsFFZ7swVNmnKKL5odV
# N2WgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUrvo6OFunluS9+KvzGuxp8PKI3nkwDQYJKoZIhvcNAQEBBQAEggEA
# nFKQ6Cj8VO+AFZzhsmstc37rrAn+U3dGDfR+MObaccT1HyQDw6aYEpthPvUWJf+S
# +GlRSvC+TZMtJFRku+gBiFBf4Re0faUqTq0aORQ6XWDjC8/yLcVLvceO2RaJ+Jwl
# 06OQvQkRFKKn7AWLpxzmIYcPT1PbnEd6xnjmhSLrG4CviNUyQEiV6sWXR//EPCvj
# Ec8Ein4fZaEhFn4bHBfEE6fcOR8CS9hXbZNoZJZROoOnVRxT4SJwP575PdY2TbQe
# BhIXpVu+SzQ/0SEs3gM0VDPQlZkm6gbYzks4P6SctDHJlVhhSj+HfdlCweXMCZeI
# PGdympnNRLZWAqIVvJsHzg==
# SIG # End signature block
