function install_psmodule($manifest, $dir, $global) {
    $psmodule = $manifest.psmodule
    if (!$psmodule) { return }

    $targetdir = ensure (modulesdir $global)

    ensure_in_psmodulepath $targetdir $global

    $module_name = $psmodule.name
    if (!$module_name) {
        abort "Invalid manifest: The 'name' property is missing from 'psmodule'."
    }

    $linkfrom = "$targetdir\$module_name"
    Write-Host "Installing PowerShell module '$module_name'"

    Write-Host "Linking $(friendly_path $linkfrom) => $(friendly_path $dir)"

    if (Test-Path $linkfrom) {
        warn "$(friendly_path $linkfrom) already exists. It will be replaced."
        Remove-Item -Path $linkfrom -Force -Recurse -ErrorAction SilentlyContinue
    }

    New-DirectoryJunction $linkfrom $dir | Out-Null
}

function uninstall_psmodule($manifest, $dir, $global) {
    $psmodule = $manifest.psmodule
    if (!$psmodule) { return }

    $module_name = $psmodule.name
    Write-Host "Uninstalling PowerShell module '$module_name'."

    $targetdir = modulesdir $global

    $linkfrom = "$targetdir\$module_name"
    if (Test-Path $linkfrom) {
        Write-Host "Removing $(friendly_path $linkfrom)"
        $linkfrom = Convert-Path $linkfrom
        Remove-Item -Path $linkfrom -Force -Recurse -ErrorAction SilentlyContinue
    }
}

function ensure_in_psmodulepath($dir, $global) {
    $path = Get-EnvVar -Name 'PSModulePath' -Global:$global
    if (!$global -and $null -eq $path) {
        $path = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
    }
    if ($path -notmatch [Regex]::Escape($dir)) {
        Write-Output "Adding $(friendly_path $dir) to $(if($global){'global'}else{'your'}) PowerShell module path."

        Set-EnvVar -Name 'PSModulePath' -Value "$dir;$path" -Global:$global
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDOpoVIXPbTsEAF
# S2t6hWTy6j4Rek12O/F2c/NMZ2P3c6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPGPDybt+X8E8+KtNL6T
# UFcf+2MgM6sr2aoFGutm922JMA0GCSqGSIb3DQEBAQUABIIBAJRe/h9dAInC0J2i
# 8ne02sqvA5Jz9L48l+PTxh+7VOVPuqq63b3QvsYg2jkfKUrsR4P5PWgx8pmSbixm
# 1FU7SjQVpba3x+RqwHliebD15ApqO4t5v9686dr2lZET4YoW0qKj5V5QUM7Ht4GL
# 0KgIvNVZ0qIbw4t4jv5Jjj3e6FGTDLAjQJB/sMAF+aGmAKLFLtvaVOSJKotEn/y5
# itgw48P7n1nRJeabvCXqvd8xezJ8Bp0WfpwT5SdlI9OcoEd3NgFqBKNwFRSZe2ig
# ki3TJoR88bh7trOtEbZkAwxt6bUDTj9o2GhAdVmMPHUCnfAJNI9buPpiAbclVLWr
# ec13k2E=
# SIG # End signature block
