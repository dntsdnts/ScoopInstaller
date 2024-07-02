# Usage: scoop checkup
# Summary: Check for potential problems
# Help: Performs a series of diagnostic tests to try to identify things that may
# cause problems with Scoop.

. "$PSScriptRoot\..\lib\diagnostic.ps1"

$issues = 0
$defenderIssues = 0

$adminPrivileges = ([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if ($adminPrivileges -and $env:USERNAME -ne 'WDAGUtilityAccount') {
    $defenderIssues += !(check_windows_defender $false)
    $defenderIssues += !(check_windows_defender $true)
}

$issues += !(check_main_bucket)
$issues += !(check_long_paths)
$issues += !(Get-WindowsDeveloperModeStatus)

if (!(Test-HelperInstalled -Helper 7zip) -and !(get_config USE_EXTERNAL_7ZIP)) {
    warn "'7-Zip' is not installed! It's required for unpacking most programs. Please Run 'scoop install 7zip'."
    $issues++
}

if (!(Test-HelperInstalled -Helper Innounp)) {
    warn "'Inno Setup Unpacker' is not installed! It's required for unpacking InnoSetup files. Please run 'scoop install innounp'."
    $issues++
}

if (!(Test-HelperInstalled -Helper Dark)) {
    warn "'dark' is not installed! It's required for unpacking installers created with the WiX Toolset. Please run 'scoop install dark' or 'scoop install wixtoolset'."
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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCgVb6srIe+OCAi
# 4swvAabo+Y5h1trGhQYVSvhTprtNVaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPUc4nKnkJrtdf04V3HT
# dTEAUeawQu3Qa7py4QC8f1lzMA0GCSqGSIb3DQEBAQUABIIBALcmSDFisDO3UxNj
# pTg1zN5QBNETn2F7bsTH1PPxN2/aZV6m5yckOjoxfQ8Rhkl90ASybFgp5qRhsijo
# DBVm2pDbsZpkUCsUpvWqX/qKN1eur/OeutE9ddyJZGbw1qZ9yctIuV3KamFgbyc2
# jMGDqTNmfrIJqgygGRh5uOYBG7CTFjBR8Kqhk0aqE0TTERmnRdMZNqeb7baJpeoM
# t3rQAupL6EGAxZPpnqRATcOA5xquuDpT8ITOn33fv4x6otDTmrw0t3iJ/r+Jr423
# q50TnE2TajX0DXH1vaQ+8JQfx4JcN2MqqsE27W1CF3Qa9L57mMx8MIKSss2r/0Ni
# 3cotDws=
# SIG # End signature block
