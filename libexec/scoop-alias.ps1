# Usage: scoop alias add|list|rm [<args>]
# Summary: Manage scoop aliases
# Help: Add, remove or list Scoop aliases
#
# Aliases are custom Scoop subcommands that can be created to make common tasks
# easier.
#
# To add an Alias:
#     scoop alias add <name> <command> <description>
#
# e.g.:
#     scoop alias add rm 'scoop uninstall $args[0]' 'Uninstalls an app'
#     scoop alias add upgrade 'scoop update *' 'Updates all apps, just like brew or apt'
#
# Options:
#   -v, --verbose   Show alias description and table headers (works only for 'list')

param(
    [String]$opt,
    [String]$name,
    [String]$command,
    [String]$description,
    [Switch]$verbose = $false
)

. "$PSScriptRoot\..\lib\install.ps1" # shim related

$script:config_alias = 'alias'

function init_alias_config {
    $aliases = get_config $script:config_alias
    if ($aliases) {
        $aliases
    } else {
        New-Object -TypeName PSObject
    }
}

function add_alias($name, $command) {
    if (!$command) {
        abort "Can't create an empty alias."
    }

    # get current aliases from config
    $aliases = init_alias_config
    if ($aliases.$name) {
        abort "Alias $name already exists."
    }

    $alias_file = "scoop-$name"

    # generate script
    $shimdir = shimdir $false
    $script =
    @(
        "# Summary: $description",
        "$command"
    ) -join "`r`n"
    $script | Out-UTF8File "$shimdir\$alias_file.ps1"

    # add alias to config
    $aliases | Add-Member -MemberType NoteProperty -Name $name -Value $alias_file

    set_config $script:config_alias $aliases | Out-Null
}

function rm_alias($name) {
    $aliases = init_alias_config
    if (!$name) {
        abort 'Which alias should be removed?'
    }

    if ($aliases.$name) {
        "Removing alias $name..."

        rm_shim $aliases.$name (shimdir $false)

        $aliases.PSObject.Properties.Remove($name)
        set_config $script:config_alias $aliases | Out-Null
    } else {
        abort "Alias $name doesn't exist."
    }
}

function list_aliases {
    $aliases = @()

    (init_alias_config).PSObject.Properties.GetEnumerator() | ForEach-Object {
        $content = Get-Content (command_path $_.Name)
        $command = ($content | Select-Object -Skip 1).Trim()
        $summary = (summary $content).Trim()

        $aliases += New-Object psobject -Property @{Name = $_.name; Summary = $summary; Command = $command }
    }

    if (!$aliases.count) {
        info "No alias found."
    }
    $aliases = $aliases.GetEnumerator() | Sort-Object Name
    if ($verbose) {
        return $aliases | Select-Object Name, Command, Summary
    } else {
        return $aliases | Select-Object Name, Command
    }
}

switch ($opt) {
    'add' { add_alias $name $command }
    'rm' { rm_alias $name }
    'list' { list_aliases }
    default { my_usage; exit 1 }
}

exit 0

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUm0J4pF7SMePBy/HPSxE45z/7
# X2WgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUwMWCZCYSXU0d38rKEfMhdeQEmMIwDQYJKoZIhvcNAQEBBQAEggEA
# gd/VTZcg8R9c27PW1zJkYkOetTLHAAfGTn7jJD0l0eoaecWkQU+z9TlJIw7FIldb
# hbb97qfRvQCLFHO8WzJzBdghi9eKYkzpAuECi0vfMFsSD4IrMERjheA9VeKitMR4
# gEuOeCaZFQ2gB/kAH6W0vRMNzw5nwIy/pnZFg0C25qOgmim4NmYOk25RBSQixtxN
# ASLJQ6fHIiKqvnWBpS/fGBoBZO8JFFJW9YdIRi/2akF1GabWVZ8+/LMe5Oa1S5XX
# HAmfqZCbKj7TCN+LtIZ+HPiscovgi1RS+pM5OjuhkuuujN/x/ZJPyvdClLyT4CHj
# m9z0U9Fq0Bi6/wImsOPA5w==
# SIG # End signature block
