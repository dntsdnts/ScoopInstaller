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
            $changedManifests = @(Get-GitChangedFile -Path $bucketDir -Include '*.json' -Commit $env:BHCommitHash)
        }
        $manifestFiles = (Get-ChildItem $bucketDir -Filter '*.json' -Recurse).FullName
        if ($changedManifests) {
            $manifestFiles = $manifestFiles | Where-Object { $_ -in $changedManifests }
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
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdmVRTBLKM8sJrghnLcTVBW2w
# ce+gggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUVRzqjgSx7gBdL0941i65Vnb5lcUwDQYJKoZIhvcNAQEBBQAEggEA
# VaPySQ7yHSBMbYgKS7gqdHysP9e6ItEU7OwjCimL/dUyOTb5/A4CUJFAPOM/ygR7
# qXmORcSInuQMFITx+8RVYqfq7y+YKSS56pFA6w08lhVL/BKpz5y7Cw6T2jeKIAR+
# YSE+QVeYf2AIE2PstJ8eyVRhvj6AeJOHIYJENt8RLu1MWq2w8rEtewRwOnt6Af9v
# OHekUG//eQOEMDc3cpZLcHZX7b/NbQF19Zfr7a1W0lMB647sKXJLN1hm0Rw9GMnT
# QdTraYrV9PQnU7Y0RLThuNTbttSEhtJ9GEhtK5a+Z3ZhfznhQidPLaSkxQhKOuuI
# HBVBFCGiWzTYyHO9mju6nw==
# SIG # End signature block
