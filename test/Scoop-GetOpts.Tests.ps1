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
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAJTqEWM57Fe69y
# 8Fch5oFxevu9uMRknQBCAoBxRVo/TqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPQD9/WyW4haG2seKOY9
# F1a5A4supc8GKxlu4loP7QaiMA0GCSqGSIb3DQEBAQUABIIBAKc6nZKtLWX443Nk
# JtfBTi7WuPz+FvuHQU10YKTMZ3n25mpLaxn1wibRkvueYIOqt+fWXwnZ3V1V4HJG
# mrhlwiYraafXazR0EYbjIBljdSs+7ENoSJdxc17wGs7gs2UaL6FQFYOehR/7MOH0
# V1m6zsFa2yKKtH/MhXc1FyPffePkkvrLHuzlJmzFUJB+CSLYK0Plomi/3XT7vmha
# hS9hPZSsscDXoz9OpBS68TMA+R92xmheFbsD7h+RlAcVoW9oNCTF4TpPC6zUVF90
# TyDSBqm97+KUDGrWt+Rhv22f8DlxNDw/2rVwL8Va3zozz2BUOEW1h1Zueuka1qi+
# GSq7Po4=
# SIG # End signature block
