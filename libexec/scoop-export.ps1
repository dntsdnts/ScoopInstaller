# Usage: scoop export > scoopfile.json
# Summary: Exports installed apps, buckets (and optionally configs) in JSON format
# Help: Options:
#   -c, --config       Export the Scoop configuration file too

. "$PSScriptRoot\..\lib\json.ps1" # 'ConvertToPrettyJson'

$export = @{}

if ($args[0] -eq '-c' -or $args[0] -eq '--config') {
    $export.config = $scoopConfig
    # Remove machine-specific properties
    foreach ($prop in 'last_update', 'root_path', 'global_path', 'cache_path', 'alias') {
        $export.config.PSObject.Properties.Remove($prop)
    }
}

$export.buckets = list_buckets
$export.apps = @(& "$PSScriptRoot\scoop-list.ps1" 6>$null)

$export | ConvertToPrettyJSON

exit 0

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwCst1V4+TuEASpr2al46e/ZG
# yPOgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUDJBQGHaKC9ITWSsiriBUIHs5WTIwDQYJKoZIhvcNAQEBBQAEggEA
# LaUhchNh6wDesIw+yaWZ7j0hXzXOe6TRBN/d+mcbXNrAhsQ4tEoB2qAwM6JV9zqo
# ZHqW26gGT0G5VOnyxps5JGkGyCA9kLlAsqMij25IP8f2a49fh6dkVvn3goQ+geD8
# td+Uh/d09M6msA48Pqecl3rqptCXg80V2NOE+83c5rSU4+9iqZDZ1t6xbMQvWq48
# AwuiKzC1qmmp8lOOpe8JM36NvDwNKfs/x6qkwccWcCpMsHE9cFZ1iTNPBwoeb0ME
# hfR06r/vkFDU7jgESz5TrBZtT4F2mf1AYkB5EZJNzlI1yCpEjE/cHXVDNeVjiDXA
# 5QUqzXbvzKd21JNBGQScpA==
# SIG # End signature block
