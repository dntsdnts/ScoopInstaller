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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBgMdynLTcZzV/b
# 1eDq8B5q5EkTBW05hjAWqpHHaEBldKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMIbgctlzgyjczE4aiY0
# 0/BaAnLgPjsjzW1o02+5TyddMA0GCSqGSIb3DQEBAQUABIIBAFDMAWAGb6VXwqDc
# yhYLI1kePaUFNB7e0s39tIJn9mt5z07JDer5rZl3C9vqoUuhTedUI4x4nGi5KSdz
# LuIBLa9/3S7QvEi2mwEuKZ20AN2KSx8XsGdLhS83QIHcjIkLANohKNdy+oimkr+v
# ipwMC+1l07/oRWWq72W6L0LFFnPxXxeP6Ts1x893bJp/3M3o6Mfubp0aYhiBK5Q9
# y0dUFzV/8oLStwJOwthtiuxUT0TrxsfpKWGyQ38WXYanLIsk8OILVSAyMPBByLaT
# Tegjzl0EkpX8uZ/wgH/mpfO0QtppeAONRrampj/zwDF2QdYj+9IG7zkGEtTLwf9C
# JRVWHtY=
# SIG # End signature block
