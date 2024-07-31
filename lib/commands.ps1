# Description: Functions for managing commands and aliases.

## Functions for commands

function command_files {
    (Get-ChildItem "$PSScriptRoot\..\libexec") + (Get-ChildItem "$scoopdir\shims") |
        Where-Object 'scoop-.*?\.ps1$' -Property Name -Match
}

function commands {
    command_files | ForEach-Object { command_name $_ }
}

function command_name($filename) {
    $filename.name | Select-String 'scoop-(.*?)\.ps1$' | ForEach-Object { $_.matches[0].groups[1].value }
}

function command_path($cmd) {
    $cmd_path = "$PSScriptRoot\..\libexec\scoop-$cmd.ps1"

    # built in commands
    if (!(Test-Path $cmd_path)) {
        # get path from shim
        $shim_path = "$scoopdir\shims\scoop-$cmd.ps1"
        $line = ((Get-Content $shim_path) | Where-Object { $_.startswith('$path') })
        if ($line) {
            Invoke-Command ([scriptblock]::Create($line)) -NoNewScope
            $cmd_path = $path
        } else { $cmd_path = $shim_path }
    }

    $cmd_path
}

function exec($cmd, $arguments) {
    $cmd_path = command_path $cmd

    & $cmd_path @arguments
}

## Functions for aliases

function add_alias {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$name,
        [ValidateNotNullOrEmpty()]
        [string]$command,
        [string]$description
    )

    $aliases = get_config ALIAS ([PSCustomObject]@{})
    if ($aliases.$name) {
        abort "Alias '$name' already exists."
    }

    $alias_script_name = "scoop-$name"
    $shimdir = shimdir $false
    if (Test-Path "$shimdir\$alias_script_name.ps1") {
        abort "File '$alias_script_name.ps1' already exists in shims directory."
    }
    $script = @(
        "# Summary: $description",
        "$command"
    ) -join "`n"
    try {
        $script | Out-UTF8File "$shimdir\$alias_script_name.ps1"
    } catch {
        abort $_.Exception
    }

    # Add the new alias to the config.
    $aliases | Add-Member -MemberType NoteProperty -Name $name -Value $alias_script_name
    set_config ALIAS $aliases | Out-Null
}

function rm_alias {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$name
    )

    $aliases = get_config ALIAS ([PSCustomObject]@{})
    if (!$aliases.$name) {
        abort "Alias '$name' doesn't exist."
    }

    info "Removing alias '$name'..."
    Remove-Item "$(shimdir $false)\scoop-$name.ps1"
    $aliases.PSObject.Properties.Remove($name)
    set_config ALIAS $aliases | Out-Null
}

function list_aliases {
    param(
        [bool]$verbose
    )

    $aliases = get_config ALIAS ([PSCustomObject]@{})
    $alias_info = $aliases.PSObject.Properties.Name | Where-Object { $_ } | ForEach-Object {
        $content = Get-Content (command_path $_)
        [PSCustomObject]@{
            Name    = $_
            Summary = (summary $content).Trim()
            Command = ($content | Select-Object -Skip 1).Trim()
        }
    }
    if (!$alias_info) {
        info 'No alias found.'
        return
    }
    $alias_info = $alias_info | Sort-Object Name
    $properties = @('Name', 'Command')
    if ($verbose) {
        $properties += 'Summary'
    }
    $alias_info | Select-Object $properties
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxrie+V4j0mdvspLKtxD88XOR
# LUWgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQULRmIV3aQStl8gAW84euHnM3JprkwDQYJKoZIhvcNAQEBBQAEggEA
# ZgJdfJ6D+Z8HIAv37vpM8GOv+FlPkGmvD+SnGKwJbkBD7oTLLDEgiStSXlJ/4wk3
# 1GIaFEUxmhZ9yXdO6aLsrHZ6dslX4RNN3MpJdPvl5dSxkXvqXZtlY+zkOAiheSW5
# yP7V6XbYn1DHOWGD0/pf7BYUamQhGu0xJCRYUHWF850qLnnxWpRNU4+ap3xFgDfm
# /kOSxAnMMcE1/k8HDrBXbvlrDKWXihQHXhIFYOOtstP+lQjkYuBqsCw0XJrqKW9P
# tj50cwWOunA1ZWiDyN5vXTPqvIN88LzZIOaWSYB3p8YzpuHyyD9W5DOaPcuTLQzS
# aumfxtj4aMVN1L8QoCpb6Q==
# SIG # End signature block
