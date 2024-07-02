BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\core.ps1"
    . "$PSScriptRoot\..\lib\help.ps1"
    . "$PSScriptRoot\..\libexec\scoop-alias.ps1" | Out-Null
}

Describe 'Manipulate Alias' -Tag 'Scoop' {
    BeforeAll {
        Mock shimdir { "$TestDrive\shims" }
        Mock set_config {}
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

    It 'Does not change existing file if its filename same as alias name' {
        $alias_file = "$shimdir\scoop-rm.ps1"
        Mock abort {}
        New-Item $alias_file -Type File -Force
        $alias_file | Should -Exist

        add_alias 'rm' '"test"'
        Should -Invoke -CommandName abort -Times 1 -ParameterFilter { $msg -eq "File 'scoop-rm.ps1' already exists in shims directory." }
    }

    It 'Removes an existing alias' {
        $alias_file = "$shimdir\scoop-rm.ps1"
        $alias_file | Should -Exist
        Mock get_config { @(@{'rm' = 'scoop-rm' }) }
        Mock info {}

        rm_alias 'rm'
        $alias_file | Should -Not -Exist
        Should -Invoke -CommandName info -Times 1 -ParameterFilter { $msg -eq "Removing alias 'rm'..." }
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCJuESTa6Fa1BvG
# anY0kGGWR6vdKJRrK9A4kWBk8P3VlaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDuYTLGs0f/LzaVKFy/s
# MIdEWkTvQN+EsCQpHOduX0bcMA0GCSqGSIb3DQEBAQUABIIBAGIAxIeRK7zRYKAb
# rLkrfBbONinn0W3K6Xa7e1opv7SekF2JQTcX1jnA1Swkd67iEnAk5DQyPLH6Fq/J
# fPK68eVLAQrwErMDv8TZXZa0VrvcBUAUas5/Hh6APy7LgjZsSaeW/UbqdQpNpFgZ
# aFRXmQuyla0vpMFVr6i3hH7aWfMG5L7VRF36uSH/aiU4EADkWz4z//JFxVv5Mt+L
# IwsdXcKU5YOMDC1L8x8Jo8YU4munfvAcGSmHjs1Y6FmVvPAvDn9dNw+qL1kSwubQ
# jJaJ/1Uys2oveN0qBX2WgdUAjJ91sdpaaFoIwb82VYVp2VfAGYvpJkx9RLal4i4e
# yM0AG88=
# SIG # End signature block
