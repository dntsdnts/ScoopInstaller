BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\core.ps1"
    . "$PSScriptRoot\..\lib\commands.ps1"
}

Describe 'Manipulate Alias' -Tag 'Scoop' {
    BeforeAll {
        Mock shimdir { "$TestDrive\shims" }
        Mock set_config {}
        Mock get_config { @{} }

        $shimdir = shimdir
        ensure $shimdir
    }

    It 'Creates a new alias if it does not exist' {
        $alias_script = "$shimdir\scoop-rm.ps1"
        $alias_script | Should -Not -Exist

        add_alias 'rm' '"hello, world!"'
        & $alias_script | Should -Be 'hello, world!'
    }

    It 'Skips an existing alias' {
        $alias_script = "$shimdir\scoop-rm.ps1"
        Mock abort {}
        New-Item $alias_script -Type File -Force
        $alias_script | Should -Exist

        add_alias 'rm' '"test"'
        Should -Invoke -CommandName abort -Times 1 -ParameterFilter { $msg -eq "File 'scoop-rm.ps1' already exists in shims directory." }
    }

    It 'Removes an existing alias' {
        $alias_script = "$shimdir\scoop-rm.ps1"
        $alias_script | Should -Exist
        Mock get_config { @(@{'rm' = 'scoop-rm' }) }
        Mock info {}

        rm_alias 'rm'
        $alias_script | Should -Not -Exist
        Should -Invoke -CommandName info -Times 1 -ParameterFilter { $msg -eq "Removing alias 'rm'..." }
    }
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoZVkuN33Rm1D3ZdfWYBP5bIB
# VlqgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUceAtymq0ikSHrzoYlZqFpGV9S/swDQYJKoZIhvcNAQEBBQAEggEA
# Cr7OEGqBiiF5mJl5rGJLkmG9xRRMaHHmOc1WwNHhfQPBi+LtLbQZJXcyidqKZNzE
# peZg+9IY3fuy10J1245MjQZ4k9Sw6urAJ3JPHr9pwKoiU7shAx/B3Uz3SvyEV1lr
# z7hkRC034LjjimOMjBcP03FuNHfCudzFSKtwDrdxiMnEhS76U/eApe/eMIW3P7/l
# KrOBlpY9la+HXNfPiiehdeRfKIG1vSwwlVqXW8lJSaetr9vO7jGAp2uejAzTuDBW
# IMzUvaWsd+CZhak+uPMW3VhlLdb4m6mcSQPw4qiDjbC4MWkI3IsUcjAmtsBm/BIm
# DLi1bVBTRUDBx5446q27Sw==
# SIG # End signature block
