# Usage: scoop alias <subcommand> [options] [<args>]
# Summary: Manage scoop aliases
# Help: Available subcommands: add, rm, list.
#
# Aliases are custom Scoop subcommands that can be created to make common tasks easier.
#
# To add an alias:
#
#     scoop alias add <name> <command> [<description>]
#
# e.g.,
#
#     scoop alias add rm 'scoop uninstall $args[0]' 'Uninstall an app'
#     scoop alias add upgrade 'scoop update *' 'Update all apps, just like "brew" or "apt"'
#
# To remove an alias:
#
#     scoop alias rm <name>
#
# To list all aliases:
#
#     scoop alias list [-v|--verbose]
#
# Options:
#   -v, --verbose  Show alias description and table headers (works only for "list")

param($SubCommand)

. "$PSScriptRoot\..\lib\getopt.ps1"

$SubCommands = @('add', 'rm', 'list')
if ($SubCommand -notin $SubCommands) {
    if (!$SubCommand) {
        error '<subcommand> missing'
    } else {
        error "'$SubCommand' is not one of available subcommands: $($SubCommands -join ', ')"
    }
    my_usage
    exit 1
}

$opt, $other, $err = getopt $Args 'v' 'verbose'
if ($err) { "scoop alias: $err"; exit 1 }

$name, $command, $description = $other
$verbose = $opt.v -or $opt.verbose

switch ($SubCommand) {
    'add' {
        if (!$name -or !$command) {
            error "<name> and <command> must be specified for subcommand 'add'"
            exit 1
        }
        add_alias $name $command $description
    }
    'rm' {
        if (!$name) {
            error "<name> must be specified for subcommand 'rm'"
            exit 1
        }
        rm_alias $name
    }
    'list' {
        list_aliases $verbose
    }
}

exit 0

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPvhIAgRQNi8QjZc+MsKiVG4Q
# TY2gggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQU5bF9SmrnOyLaBcbodzPk2k4We98wDQYJKoZIhvcNAQEBBQAEggEA
# VUA7y156XU9xKlhpNSaj4aMpi2NJHMY5Pq9O9UUg+zXCEYaeRRnpCJGQ20Cjndnh
# rYxvWPYmetlnAxhWfS472QkgNbXk/+Jk9S/Bv31+AFD5j7jp03nRMwqXvOmKVvhg
# Kqi7jI+nU2Lz2POvNkMncyB6gEE2B5rNWuX2x6iu1BUit1+KhA7m98DM20/8uvRg
# A0G6SCEiULS/+BVVEo6W2VnnoX0abKsrT9126ATHE18AK7/2114zDhs3XzGKaOiM
# anNOhjT6vDKTvgd9QvD4uuM2k0L+jbxU7hWhfYf57ghZMlGtyW9C+HMrJo0hSUJr
# lHmP2D2knjAfROysGBygIA==
# SIG # End signature block
