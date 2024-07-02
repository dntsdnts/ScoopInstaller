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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyOVYYmBl+LOvxvO1qesTZ45z
# TMCgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUv8INaR9PCQPWRj8pDQ1R2jqfxIcwDQYJKoZIhvcNAQEBBQAEggEA
# Lqc7pxdDMJqc6MgcaLP6xZK1XcpO9BUBImD5nfEUBxmRUT4qY7c55acGTcjoRUDk
# 8uwqDm3ZTN+3usLPIuDNapIP9OPi3h1LY0TgltCLhF9+IvIGq3qBh+xIgktIhfGd
# YjX9mUY3AwtROXv8H4q0PWYlr1WDujDUsNj2wh3TLZtmWX7VFF4jLBCrJA9olXoZ
# 3gy4hVsfBoBBVIGqwwTov4H788P9Upbi8UIWCoMC08qb4PIjvDuoU8zpQd6VQIaa
# nixlyG4Tv6NbsHzFcbYsZRMswflNARkOWVeen26cnQlSB9fxWMeOWiBqDb4EPM39
# QbVqrgiL4pru/x2DSZ7kvw==
# SIG # End signature block
