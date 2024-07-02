BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\getopt.ps1"
}

Describe 'getopt' -Tag 'Scoop' {
    It 'handle short option with required argument missing' {
        $null, $null, $err = getopt '-x' 'x:' ''
        $err | Should -Be 'Option -x requires an argument.'

        $null, $null, $err = getopt '-xy' 'x:y' ''
        $err | Should -Be 'Option -x requires an argument.'
    }

    It 'handle long option with required argument missing' {
        $null, $null, $err = getopt '--arb' '' 'arb='
        $err | Should -Be 'Option --arb requires an argument.'
    }

    It 'handle space in quote' {
        $opt, $rem, $err = getopt '-x', 'space arg' 'x:' ''
        $err | Should -BeNullOrEmpty
        $opt.x | Should -Be 'space arg'
    }

    It 'handle unrecognized short option' {
        $null, $null, $err = getopt '-az' 'a' ''
        $err | Should -Be 'Option -z not recognized.'
    }

    It 'handle unrecognized long option' {
        $null, $null, $err = getopt '--non-exist' '' ''
        $err | Should -Be 'Option --non-exist not recognized.'

        $null, $null, $err = getopt '--global', '--another' 'abc:de:' 'global', 'one'
        $err | Should -Be 'Option --another not recognized.'
    }

    It 'remaining args returned' {
        $opt, $rem, $err = getopt '-g', 'rem' 'g' ''
        $err | Should -BeNullOrEmpty
        $opt.g | Should -BeTrue
        $rem | Should -Not -BeNullOrEmpty
        $rem.length | Should -Be 1
        $rem[0] | Should -Be 'rem'
    }

    It 'get a long flag and a short option with argument' {
        $a = '--global -a 32bit test' -split ' '
        $opt, $rem, $err = getopt $a 'ga:' 'global', 'arch='

        $err | Should -BeNullOrEmpty
        $opt.global | Should -BeTrue
        $opt.a | Should -Be '32bit'
    }

    It 'handles regex characters' {
        $a = '-?'
        { $opt, $rem, $err = getopt $a 'ga:' 'global' 'arch=' } | Should -Not -Throw
        { $null, $null, $null = getopt $a '?:' 'help' | Should -Not -Throw }
    }

    It 'handles short option without required argument' {
        $null, $null, $err = getopt '-x' 'x' ''
        $err | Should -BeNullOrEmpty
    }

    It 'handles long option without required argument' {
        $opt, $null, $err = getopt '--long-arg' '' 'long-arg'
        $err | Should -BeNullOrEmpty
        $opt.'long-arg' | Should -BeTrue
    }

    It 'handles long option with required argument' {
        $opt, $null, $err = getopt '--long-arg', 'test' '' 'long-arg='
        $err | Should -BeNullOrEmpty
        $opt.'long-arg' | Should -Be 'test'
    }

    It 'handles the option terminator' {
        $opt, $rem, $err = getopt '--long-arg', '--' '' 'long-arg'
        $err | Should -BeNullOrEmpty
        $opt.'long-arg' | Should -BeTrue
        $rem[0] | Should -BeNullOrEmpty
        $opt, $rem, $err = getopt '--long-arg', '--', '-x', '-y' 'xy' 'long-arg'
        $err | Should -BeNullOrEmpty
        $opt.'long-arg' | Should -BeTrue
        $opt.'x' | Should -BeNullOrEmpty
        $opt.'y' | Should -BeNullOrEmpty
        $rem[0] | Should -Be '-x'
        $rem[1] | Should -Be '-y'
    }
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjsCiXN1UlNR+KDPb+53pFxGc
# 9FGgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQU9sB2wwU5a+pONytVKECWhcgDQLcwDQYJKoZIhvcNAQEBBQAEggEA
# rakwE/fvLAuU+w9HC8dOUiz26YCntpuMld5OiUzZfmmG1p+vNuF1Z5bKON3LN/4e
# HTOfGpYsDf08ccPsqKUFV0rcObhX1rNoPZFIJRUl926rmy37VbGicpiuMixbMZU2
# n+8l9OATmztAhNGWgtbksYSnEhhirjAzmc2oEhLdMdNqb8fCAwSo3W0WolJD6iEQ
# CwjD6VvP/ABhzW1l0TJYn3zd+c5ZYJO0CEWuYbAsoOnqx2b2wT5EV4sxyx1MIVuj
# wc/QeTP6PDkdLzv9EBFHMb5gdIhQMAjvITVEwUrKJGNX2IYmUfg9Ffya3zQu6ASz
# I93Gn7+24A4Kn2eEgiNxEw==
# SIG # End signature block
