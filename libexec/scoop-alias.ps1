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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC5u1UqTED9ZmCn
# nTfE0m0uN1uEL+Hhgh5mW1rKSvXnyKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILNEzLDQ26V9cm/Ehviw
# mJ6xTKrLOLcOGrIvrWF3+GvMMA0GCSqGSIb3DQEBAQUABIIBALshKvG8rlvbuUAS
# wegJYRS2SaRRGjZn+J1piYdLUvab7DqDzBoeXO95+WpHmdkQHlFsBB3B2HK6Ae3O
# hXiST4QlB7mKRmYFQO2MCnDa3La9zUdyJ+qsonG+TSqJUfVQ/g95gJPqFSVU0itc
# wBnT3mkEON0uFngsGDQwIjZwhVHCz51vqeotyJX3Qvqk+v9uiQyIU1no0vh9HIa+
# 5flTd3Jz2I9MsixghBZ7uBs3wlXxtWcFhmmcY0XQvfoC5QCJgwwo7rYSy/2sdB8J
# VLuU6K9q3wFoRdPUv3rva23qf8I4jSCoII3pebEq64gwFLi3DpVBazSolH/L3zTF
# N8ZfHqQ=
# SIG # End signature block
