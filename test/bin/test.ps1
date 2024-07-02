#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'BuildHelpers'; ModuleVersion = '2.0.1' }
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
#Requires -Modules @{ ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.17.1' }
param(
    [String] $TestPath = (Convert-Path "$PSScriptRoot\..")
)

$pesterConfig = New-PesterConfiguration -Hashtable @{
    Run    = @{
        Path     = $TestPath
        PassThru = $true
    }
    Output = @{
        Verbosity = 'Detailed'
    }
}
$excludes = @()

if ($IsLinux -or $IsMacOS) {
    Write-Warning 'Skipping Windows-only tests on Linux/macOS'
    $excludes += 'Windows'
}

if ($env:CI -eq $true) {
    Write-Host "Load 'BuildHelpers' environment variables ..."
    Set-BuildEnvironment -Force

    # Check if tests are called from the Core itself, if so, adding excludes
    if ($TestPath -eq (Convert-Path "$PSScriptRoot\..")) {
        if ($env:BHCommitMessage -match '!linter') {
            Write-Warning "Skipping code linting per commit flag '!linter'"
            $excludes += 'Linter'
        }

        $changedScripts = (Get-GitChangedFile -Include '*.ps1', '*.psd1', '*.psm1' -Commit $env:BHCommitHash)
        if (!$changedScripts) {
            Write-Warning "Skipping tests and code linting for PowerShell scripts because they didn't change"
            $excludes += 'Linter'
            $excludes += 'Scoop'
        }

        if (!($changedScripts -like '*decompress.ps1') -and !($changedScripts -like '*Decompress.Tests.ps1')) {
            Write-Warning "Skipping tests and code linting for decompress.ps1 files because it didn't change"
            $excludes += 'Decompress'
        }

        if ('Decompress' -notin $excludes -and 'Windows' -notin $excludes) {
            Write-Host 'Install decompress dependencies ...'

            Write-Host (7z.exe | Select-String -Pattern '7-Zip').ToString()

            $env:SCOOP_HELPERS_PATH = 'C:\projects\helpers'
            if (!(Test-Path $env:SCOOP_HELPERS_PATH)) {
                New-Item -ItemType Directory -Path $env:SCOOP_HELPERS_PATH | Out-Null
            }

            $env:SCOOP_LESSMSI_PATH = "$env:SCOOP_HELPERS_PATH\lessmsi\lessmsi.exe"
            if (!(Test-Path $env:SCOOP_LESSMSI_PATH)) {
                $source = 'https://github.com/activescott/lessmsi/releases/download/v1.10.0/lessmsi-v1.10.0.zip'
                $destination = "$env:SCOOP_HELPERS_PATH\lessmsi.zip"
                Invoke-WebRequest -Uri $source -OutFile $destination
                & 7z.exe x "$env:SCOOP_HELPERS_PATH\lessmsi.zip" -o"$env:SCOOP_HELPERS_PATH\lessmsi" -y | Out-Null
            }

            $env:SCOOP_INNOUNP_PATH = "$env:SCOOP_HELPERS_PATH\innounp\innounp.exe"
            if (!(Test-Path $env:SCOOP_INNOUNP_PATH)) {
                $source = 'https://raw.githubusercontent.com/ScoopInstaller/Binary/master/innounp/innounp050.rar'
                $destination = "$env:SCOOP_HELPERS_PATH\innounp.rar"
                Invoke-WebRequest -Uri $source -OutFile $destination
                & 7z.exe x "$env:SCOOP_HELPERS_PATH\innounp.rar" -o"$env:SCOOP_HELPERS_PATH\innounp" -y | Out-Null
            }

            # Only download zstd for AppVeyor, GitHub Actions has zstd installed by default
            if ($env:BHBuildSystem -eq 'AppVeyor') {
                $env:SCOOP_ZSTD_PATH = "$env:SCOOP_HELPERS_PATH\zstd\zstd.exe"
                if (!(Test-Path $env:SCOOP_ZSTD_PATH)) {
                    $source = 'https://github.com/facebook/zstd/releases/download/v1.5.1/zstd-v1.5.1-win32.zip'
                    $destination = "$env:SCOOP_HELPERS_PATH\zstd.zip"
                    Invoke-WebRequest -Uri $source -OutFile $destination
                    & 7z.exe x "$env:SCOOP_HELPERS_PATH\zstd.zip" -o"$env:SCOOP_HELPERS_PATH\zstd" -y | Out-Null
                }
            } else {
                $env:SCOOP_ZSTD_PATH = (Get-Command zstd.exe).Path
            }
        }
    }

    # Display CI environment variables
    $buildVariables = (Get-ChildItem -Path 'Env:').Where({ $_.Name -match '^(?:BH|CI(?:_|$)|APPVEYOR|GITHUB_|RUNNER_|SCOOP_)' })
    $details = $buildVariables |
        Where-Object -FilterScript { $_.Name -notmatch 'EMAIL' } |
        Sort-Object -Property 'Name' |
        Format-Table -AutoSize -Property 'Name', 'Value' |
        Out-String
    Write-Host 'CI variables:'
    Write-Host $details -ForegroundColor DarkGray
}

if ($excludes.Length -gt 0) {
    $pesterConfig.Filter.ExcludeTag = $excludes
}

if ($env:BHBuildSystem -eq 'AppVeyor') {
    # AppVeyor
    $resultsXml = "$PSScriptRoot\TestResults.xml"
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $resultsXml
    $result = Invoke-Pester -Configuration $pesterConfig
    Add-TestResultToAppveyor -TestFile $resultsXml
} else {
    # GitHub Actions / Local
    $result = Invoke-Pester -Configuration $pesterConfig
}

exit $result.FailedCount

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDGJYciZ7iVIm8K
# euN66pIPwD80RLQlHFuwbbDZiXSNn6CCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIB6jo5Y94bKYDOSa76Sh
# Rd0IO0uqP/pW6Qo1S4Gs5aB+MA0GCSqGSIb3DQEBAQUABIIBAGGbHDZpK6iumXN/
# X8wS71sd1iKilaXYUy3J7PGFr9YBrQqQ+6PrGt5bcyueg+HS8rI9twG554G3dbLt
# GQ8yX3VTnJj/kXpolXjEyr7LQTt3zLypM0OG7RjcnpDvszkf6ZbzfHF3wiaN57SM
# Fu4yNzmOQdx/2yNiwG2+yDXY6wwe8q+nYDh/p1tLAnB+R7n4IrGduAFbFkJnwrnW
# lf4EeoUz6jnCWhckrMY/i18UVBHivqJWOXibnyjSOR8wFQVQyWRlj1FanMfV4F33
# x2FcmvdbvvNYGFr4a7wBRX3Ga89qDQs5VvcrSz8bOMHZWzGBtUaweYCeF0ePX0EB
# tPmhgG8=
# SIG # End signature block
