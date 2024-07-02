<#
Diagnostic tests.
Return $true if the test passed, otherwise $false.
Use 'warn' to highlight the issue, and follow up with the recommended actions to rectify.
#>
function check_windows_defender($global) {
    $defender = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if (Test-CommandAvailable Get-MpPreference) {
        if ((Get-MpPreference).DisableRealtimeMonitoring) { return $true }
        if ($defender -and $defender.Status) {
            if ($defender.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) {
                $installPath = $scoopdir;
                if ($global) { $installPath = $globaldir; }

                $exclusionPath = (Get-MpPreference).ExclusionPath
                if (!($exclusionPath -contains $installPath)) {
                    info "Windows Defender may slow down or disrupt installs with realtime scanning."
                    Write-Host "  Consider running:"
                    Write-Host "    sudo Add-MpPreference -ExclusionPath '$installPath'"
                    Write-Host "  (Requires 'sudo' command. Run 'scoop install sudo' if you don't have it.)"
                    return $false
                }
            }
        }
    }
    return $true
}

function check_main_bucket {
    if ((Get-LocalBucket) -notcontains 'main') {
        warn 'Main bucket is not added.'
        Write-Host "  run 'scoop bucket add main'"

        return $false
    }

    return $true
}

function check_long_paths {
    if ([System.Environment]::OSVersion.Version.Major -lt 10 -or [System.Environment]::OSVersion.Version.Build -lt 1607) {
        warn 'This version of Windows does not support configuration of LongPaths.'
        return $false
    }
    $key = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -ErrorAction SilentlyContinue -Name 'LongPathsEnabled'
    if (!$key -or ($key.LongPathsEnabled -eq 0)) {
        warn 'LongPaths support is not enabled.'
        Write-Host "  You can enable it by running:"
        Write-Host "    sudo Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1"
        Write-Host "  (Requires 'sudo' command. Run 'scoop install sudo' if you don't have it.)"
        return $false
    }

    return $true
}

function Get-WindowsDeveloperModeStatus {
    $DevModRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (!(Test-Path -Path $DevModRegistryPath) -or (Get-ItemProperty -Path `
        $DevModRegistryPath -Name AllowDevelopmentWithoutDevLicense -ErrorAction `
        SilentlyContinue).AllowDevelopmentWithoutDevLicense -ne 1) {
        warn "Windows Developer Mode is not enabled. Operations relevant to symlinks may fail without proper rights."
        Write-Host "  You may read more about the symlinks support here:"
        Write-Host "  https://blogs.windows.com/windowsdeveloper/2016/12/02/symlinks-windows-10/"
        return $false
    }

    return $true
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzLKsgm5OGH5JHfWlvwItc6KT
# HDOgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUgen6D7NQ74kxeKyowFo8tw8x/wEwDQYJKoZIhvcNAQEBBQAEggEA
# t92bWJn6Ipj51UTw83AaaOu96CXUK9n0f3JlEIGv8dQawimfk3F60RHJVe/uYuWv
# sS9/hxj500PCYjbB69v5F2F9BM9AJWqv9SGV3Q2MowsaREKFKew5xNjtdoHBWJq8
# vCTlcc29cdS0q2ag2YzaI/QDauh0RY9Ok5fRBsyYi1GDo97+G5eIPBmY6eMuuKXa
# D/19Y4L4qCoWUXSsuUhXrzL2etXw1oJ88g10v5Y2WOyZZ5+rJNMtKNfCtOH4cbNn
# WhqE0Gud40cfbv9fVPnqREHMZwcHhgFoz6irj4yFhmm39rK8rnlfYwNmOIcZjpKN
# 0hGoZ3j0794K+RVsP8jvQg==
# SIG # End signature block
