# Usage: scoop create <url>
# Summary: Create a custom app manifest
# Help: Create your own custom app manifest
param($url)

function create_manifest($url) {
    $manifest = new_manifest

    $manifest.url = $url

    $url_parts = $null
    try {
        $url_parts = parse_url $url
    } catch {
        abort "Error: $url is not a valid URL"
    }

    $name = choose_item $url_parts 'App name'
    $name = if ($name.Length -gt 0) {
        $name
    } else {
        file_name ($url_parts | Select-Object -Last 1)
    }

    $manifest.version = choose_item $url_parts 'Version'

    $manifest | ConvertTo-Json | Out-File -FilePath "$name.json" -Encoding ASCII
    $manifest_path = Join-Path $pwd "$name.json"
    Write-Host "Created '$manifest_path'."
}

function new_manifest() {
    @{ 'homepage' = ''; 'license' = ''; 'version' = ''; 'url' = '';
        'hash' = ''; 'extract_dir' = ''; 'bin' = ''; 'depends' = ''
    }
}

function file_name($segment) {
    $segment.substring(0, $segment.lastindexof('.'))
}

function parse_url($url) {
    $uri = New-Object Uri $url
    $uri.pathandquery.substring(1).split('/')
}

function choose_item($list, $query) {
    for ($i = 0; $i -lt $list.count; $i++) {
        $item = $list[$i]
        Write-Host "$($i + 1)) $item"
    }
    $sel = Read-Host $query

    if ($sel.trim() -match '^[0-9+]$') {
        return $list[$sel - 1]
    }

    $sel
}

if (!$url) {
    & "$PSScriptRoot\scoop-help.ps1" create
} else {
    create_manifest $url
}

exit 0

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUi9FXQ6SbnV7rsT2B4q0BxOOV
# hzSgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQU73mPbstkNQgTDzsmS0fjG1+drPQwDQYJKoZIhvcNAQEBBQAEggEA
# BOLYJPd5mYjeXWIywbiUyavW38aIQxypwb3ejliQPuGuub9WyNTEovcnuFTXXVca
# Lrv74WxZ4HhFqrs8iEzmbwrQCyVFsGV3EW7sExjXDP+isszLV90mQq8wMnWzUuYk
# f/BNlgfg3eAM6E4L6NeZE+Eg2gVTOBURo1qsmrXQk+CsS+YbHD1BhUrc+lBS7Jz7
# lx4ugWElxF2lLwWg2yDURccGaMdwMg6zcN/n5lC7Lp6ISZ2c+TnrFLfvrnY8K0aC
# reVU3d0mBOGWWRZft2r53HVOFyWTq3pnjoG7VJie1Y2Z8ICH/QqVSxZ++JS5sW+V
# 6Rjlr7oqlsCUsxucsap1Uw==
# SIG # End signature block
