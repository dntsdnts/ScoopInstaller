# Usage: scoop help <command>
# Summary: Show help for a command
param($cmd)

function print_help($cmd) {
    $file = Get-Content (command_path $cmd) -Raw

    $usage = usage $file
    $help = scoop_help $file

    if ($usage) { "$usage`n" }
    if ($help) { $help }
}

function print_summaries {
    $commands = @()

    command_files | ForEach-Object {
        $command = [ordered]@{}
        $command.Command = command_name $_
        $command.Summary = summary (Get-Content (command_path $command.Command))
        $commands += [PSCustomObject]$command
    }

    $commands
}

$commands = commands

if(!($cmd)) {
    Write-Host "Usage: scoop <command> [<args>]

Available commands are listed below.

Type 'scoop help <command>' to get more help for a specific command."
    print_summaries
} elseif($commands -contains $cmd) {
    print_help $cmd
} else {
    warn "scoop help: no such command '$cmd'"
    exit 1
}

exit 0

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUd+kUKwf76G/dSl2joxJR8/wD
# qPKgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUAVMDknHlqeUBBISx8kza+2ZZuNcwDQYJKoZIhvcNAQEBBQAEggEA
# x22QprPFuIqNwOKpbVCCJ18Oa+IFQH8/G9hV2ScEU/WJX8wDe3LHE4AbsjbV2HYh
# AEl+6ixty2N+82xPmLAEU+ZjaU2t2kyX/SWN6z2xJepZZUZwJO+6DcvDbukThJ+i
# fizHI8vXmpOJxksC8pwKsPPehRXJnu6Y0ve1UGivc8VuowcFZnFhpBCOUnil1S7q
# VfRttnkpUiZwNCH+51dmJbKK8Zq4pRvIIRis1zASZpkOAY/9RjJG3su7fnt/8uhU
# 5BKwH5ywRaMGYTN3vhBn3nzvZuTclTZ5pJnHOb3VNmpQkd/Waq/ZB8kaOUdo8YN7
# 7KnZDgDP09Blj8Q+5hIW0g==
# SIG # End signature block
