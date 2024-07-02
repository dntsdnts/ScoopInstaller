BeforeAll {
    . "$PSScriptRoot\Scoop-TestLib.ps1"
    . "$PSScriptRoot\..\lib\core.ps1"
}

Describe 'config' -Tag 'Scoop' {
    BeforeAll {
        $configFile = [IO.Path]::GetTempFileName()
        $unicode = [Regex]::Unescape('\u4f60\u597d\u3053\u3093\u306b\u3061\u306f') # 你好こんにちは
    }

    AfterAll {
        Remove-Item -Path $configFile -Force
    }

    It 'load_cfg should return null if config file does not exist' {
        load_cfg $configFile | Should -Be $null
    }

    It 'set_config should be able to save typed values correctly' {
        # number
        $scoopConfig = set_config 'one' 1
        $scoopConfig.one | Should -BeExactly 1

        # boolean
        $scoopConfig = set_config 'two' $true
        $scoopConfig.two | Should -BeTrue
        $scoopConfig = set_config 'three' $false
        $scoopConfig.three | Should -BeFalse

        # underline key
        $scoopConfig = set_config 'under_line' 'four'
        $scoopConfig.under_line | Should -BeExactly 'four'

        # string
        $scoopConfig = set_config 'five' 'not null'

        # datetime
        $scoopConfig = set_config 'time' ([System.DateTime]::Parse('2019-03-18T15:22:09.3930000+00:00', $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal))
        $scoopConfig.time | Should -BeOfType [System.DateTime]

        # non-ASCII
        $scoopConfig = set_config 'unicode' $unicode
        $scoopConfig.unicode | Should -Be $unicode
    }

    It 'load_cfg should return PSObject if config file exist' {
        $scoopConfig = load_cfg $configFile
        $scoopConfig | Should -Not -BeNullOrEmpty
        $scoopConfig | Should -BeOfType [System.Management.Automation.PSObject]
        $scoopConfig.one | Should -BeExactly 1
        $scoopConfig.two | Should -BeTrue
        $scoopConfig.three | Should -BeFalse
        $scoopConfig.under_line | Should -BeExactly 'four'
        $scoopConfig.five | Should -Be 'not null'
        $scoopConfig.time | Should -BeOfType [System.DateTime]
        $scoopConfig.time | Should -Be ([System.DateTime]::Parse('2019-03-18T15:22:09.3930000+00:00', $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal))
        $scoopConfig.unicode | Should -Be $unicode
    }

    It 'get_config should return exactly the same values' {
        $scoopConfig = load_cfg $configFile
        (get_config 'one') | Should -BeExactly 1
        (get_config 'two') | Should -BeTrue
        (get_config 'three') | Should -BeFalse
        (get_config 'under_line') | Should -BeExactly 'four'
        (get_config 'five') | Should -Be 'not null'
        (get_config 'time') | Should -BeOfType [System.DateTime]
        (get_config 'time') | Should -Be ([System.DateTime]::Parse('2019-03-18T15:22:09.3930000+00:00', $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal))
        (get_config 'unicode') | Should -Be $unicode
    }

    It 'set_config should remove a value if being set to $null' {
        $scoopConfig = load_cfg $configFile
        $scoopConfig = set_config 'five' $null
        $scoopConfig.five | Should -BeNullOrEmpty
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBjb9Wz6MBDr8Zy
# zgSRUkG2GjC2RFHTZeaFRPBN23jFAaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIC37rqAXsOuA5L1CsZF
# lbXNrz2XjqPBMwgM1fTkDEAjMA0GCSqGSIb3DQEBAQUABIIBAAyZfTLi2sZYHhux
# 7Rl5oOX7R6yU0P8LZBiIK1wVDUnb1o+lVZJpSyVQEZKOvU2DfjrjQpLm+5yVOy/N
# mIDuSjs0ktEKzrO12IJA67wDfusY/UVTxAA3UNi1+6GSFfDIpTezXIvWPNXZjEnd
# PlEG60q07ZD9JwUNBUGQkeerBpftREZobdncmDYqUPXWPkeAl+4AuA4GehMw367x
# WV0s/mRqd8Ky9RDl5GsM+1VfAGxZ2jnpMz5E9XrIdotigQMgnwDFnxqUDFYkjHU+
# FonrtjTO5gvR1eaDx5jd0iWqcf7V/wQtIX2ufHTFOcPRFQtKvqeRPYwP0kgkp5BM
# UpXHalo=
# SIG # End signature block
