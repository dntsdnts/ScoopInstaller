BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\core.ps1"
    . "$PSScriptRoot\..\lib\help.ps1"
    . "$PSScriptRoot\..\libexec\scoop-alias.ps1" | Out-Null
}

Describe 'Manipulate Alias' -Tag 'Scoop' {
    BeforeAll {
        Mock shimdir { "$TestDrive\shims" }
        Mock set_config { }
        Mock get_config { @{} }

        $shimdir = shimdir
        ensure $shimdir
    }

    It 'Creates a new alias if alias doesn''t exist' {
        $alias_file = "$shimdir\scoop-rm.ps1"
        $alias_file | Should -Not -Exist

        add_alias 'rm' '"hello, world!"'
        & $alias_file | Should -Be 'hello, world!'
    }

    It 'Does not change existing alias if alias exists' {
        $alias_file = "$shimdir\scoop-rm.ps1"
        New-Item $alias_file -Type File -Force
        $alias_file | Should -Exist

        add_alias 'rm' 'test'
        & $alias_file | Should -Not -Be 'test'
    }

    It 'Removes an existing alias' {
        $alias_file = "$shimdir\scoop-rm.ps1"
        add_alias 'rm' '"hello, world!"'

        $alias_file | Should -Exist
        Mock get_config { @(@{'rm' = 'scoop-rm' }) }

        rm_alias 'rm'
        $alias_file | Should -Not -Exist
    }
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNN2Qlr+Q92GXKt1+j/mx92vI
# 6migggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUkXPH+wPk6Vy9GBJkDM7LhFVZJvEwDQYJKoZIhvcNAQEBBQAEggEA
# gyvme/rGfj0pEXfrJDje/5To08J5mKoMtWoqVfVivIT4jvmHTrCY/BrygpV3iijV
# lY4jida9tM7iyOf2OI9sa3GNxb5CQDVfyUp+I9BGqwnLkToeUR8O5353Ynhb5ggZ
# gQ9A4qB32i5HkDsDtPTPjZYQNL7SJcqpsUgZvp/hPnnsV4tueDXWwfTqZkVrJmt+
# CgmB9+EaId7jKmw+nBNvqv2XxRqfkW5NtVM0/+SClhCcx4t6Qlq1XjoeYbGl2dza
# jJB1BOM3VR7fhcCN5BEuNRJ2V1mYlS2H5euQxVQ6vDaa8Gf6DJfo8cXeXXwZAOwy
# hcZLoGNVB8bDpBipuBTMYQ==
# SIG # End signature block
