#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'BuildHelpers'; ModuleVersion = '2.0.1' }
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
param(
    [String] $BucketPath = $MyInvocation.PSScriptRoot
)

. "$PSScriptRoot\Scoop-00File.Tests.ps1" -TestPath $BucketPath

Describe 'Manifest validates against the schema' {
    BeforeDiscovery {
        $bucketDir = if (Test-Path "$BucketPath\bucket") {
            "$BucketPath\bucket"
        } else {
            $BucketPath
        }
        if ($env:CI -eq $true) {
            Set-BuildEnvironment -Force
            $manifestFiles = @(Get-GitChangedFile -Path $bucketDir -Include '*.json' -Commit $env:BHCommitHash)
        } else {
            $manifestFiles = (Get-ChildItem $bucketDir -Filter '*.json' -Recurse).FullName
        }
    }
    BeforeAll {
        Add-Type -Path "$PSScriptRoot\..\supporting\validator\bin\Scoop.Validator.dll"
        # Could not use backslash '\' in Linux/macOS for .NET object 'Scoop.Validator'
        $validator = New-Object Scoop.Validator("$PSScriptRoot/../schema.json", $true)
        $global:quotaExceeded = $false
    }
    It '<_>' -TestCases $manifestFiles {
        if ($global:quotaExceeded) {
            Set-ItResult -Skipped -Because 'Schema validation limit exceeded.'
        } else {
            $file = $_ # exception handling may overwrite $_
            try {
                $validator.Validate($file)
                if ($validator.Errors.Count -gt 0) {
                    Write-Host "  [-] $_ has $($validator.Errors.Count) Error$(If($validator.Errors.Count -gt 1) { 's' })!" -ForegroundColor Red
                    Write-Host $validator.ErrorsAsString -ForegroundColor Yellow
                }
                $validator.Errors.Count | Should -Be 0
            } catch {
                if ($_.Exception.Message -like '*The free-quota limit of 1000 schema validations per hour has been reached.*') {
                    $global:quotaExceeded = $true
                    Set-ItResult -Skipped -Because 'Schema validation limit exceeded.'
                } else {
                    throw
                }
            }
        }
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB8i/DXSCTlbYaK
# TCuOqpKdRCtDz/jFzGIHFwZOg3C+JKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHrl0OcjVtGKwfLbmnrW
# PgT8vmp747pZDAC/hfu4/l7RMA0GCSqGSIb3DQEBAQUABIIBAH1arr3sp9s6CMot
# /ret4usW6tfXoTaJ0YM/t8rRTbUIFLZGdAd3z7z6kD0NUcGFxiPpp8nCV4YwAo3g
# NbbTSVahnR64+0HEcyj19ADgNNedILmC1u/sR3pr4QZqETlLKUxRpiCcGUQ2SU35
# BbCbaH3cOTMV8vEXEjef4q9wvsS2J8YbbdXarmbuLjzGlvHOgmcKAhFqNNGixUR7
# tm6sRzjql2oMM+slwDeylh0S+8o45uJI8ZjIpK8803F4seIoRWsq14U2BfVyDz0a
# AHYnM3edmI9epSNliorNx0dQiWyZtU0rRlxmMvbR1QWxpLmrFdOPkFacVWEvcgle
# 9B/vtaQ=
# SIG # End signature block
