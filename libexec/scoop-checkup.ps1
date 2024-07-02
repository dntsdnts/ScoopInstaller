# Usage: scoop checkup
# Summary: Check for potential problems
# Help: Performs a series of diagnostic tests to try to identify things that may
# cause problems with Scoop.

. "$PSScriptRoot\..\lib\diagnostic.ps1"

$issues = 0
$defenderIssues = 0

$adminPrivileges = ([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if ($adminPrivileges) {
    $defenderIssues += !(check_windows_defender $false)
    $defenderIssues += !(check_windows_defender $true)
}

$issues += !(check_main_bucket)
$issues += !(check_long_paths)
$issues += !(Get-WindowsDeveloperModeStatus)

if (!(Test-HelperInstalled -Helper 7zip)) {
    error "'7-Zip' is not installed! It's required for unpacking most programs. Please Run 'scoop install 7zip' or 'scoop install 7zip-zstd'."
    $issues++
}

if (!(Test-HelperInstalled -Helper Innounp)) {
    error "'Inno Setup Unpacker' is not installed! It's required for unpacking InnoSetup files. Please run 'scoop install innounp'."
    $issues++
}

if (!(Test-HelperInstalled -Helper Dark)) {
    error "'dark' is not installed! It's required for unpacking installers created with the WiX Toolset. Please run 'scoop install dark' or 'scoop install wixtoolset'."
    $issues++
}

$globaldir = New-Object System.IO.DriveInfo($globaldir)
if ($globaldir.DriveFormat -ne 'NTFS') {
    error "Scoop requires an NTFS volume to work! Please point `$env:SCOOP_GLOBAL or 'global_path' variable in '~/.config/scoop/config.json' to another Drive."
    $issues++
}

$scoopdir = New-Object System.IO.DriveInfo($scoopdir)
if ($scoopdir.DriveFormat -ne 'NTFS') {
    error "Scoop requires an NTFS volume to work! Please point `$env:SCOOP or 'root_path' variable in '~/.config/scoop/config.json' to another Drive."
    $issues++
}

if ($issues) {
    warn "Found $issues potential $(pluralize $issues problem problems)."
} elseif ($defenderIssues) {
    info "Found $defenderIssues performance $(pluralize $defenderIssues problem problems)."
    warn "Security is more important than performance, in most cases."
} else {
    success "No problems identified!"
}

exit 0

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnBfAjI6sU8MPdqHHiro6Isnx
# W9OgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUDWqbL2tzrY6Hd0WpD9+8GhpoUGIwDQYJKoZIhvcNAQEBBQAEggEA
# iPmJ+j8x7KskvRnkrL9WA9qz4UkTsTW+l9Q1oPsHEafKus07z71DCeWUh2G7tL5p
# Beh1qk2LrJ7Cr+vanB1JP7VO5fCsBQvL7YovSwzWR4XweUjJ2bCNNYmdLlrEHH8y
# SyG/pN5WrE6Db6+Js1Kau/nmt+dJdUlse1immvgvi0768k252PPBDkb6b+4GYEsV
# M2JkyC3kAz+Q5q5/CQIQlG8hMkLeMSMJNZ1VA/F71x4/GfnCcXqHjpQNatT0NUvk
# 5WixuoX0bb2QKs+dgSRDXkbE13YbesLKSaofnnJrfEMySF0uaRJlI24XQPh10trT
# KtyhgQtrpZ+xtx/7/mVxoA==
# SIG # End signature block
