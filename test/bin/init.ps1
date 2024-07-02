#Requires -Version 5.1
Write-Output "PowerShell: $($PSVersionTable.PSVersion)"
Write-Output 'Check and install testsuite dependencies ...'
if (Get-InstalledModule -Name Pester -MinimumVersion 5.2 -MaximumVersion 5.99 -ErrorAction SilentlyContinue) {
    Write-Output 'Pester 5 is already installed.'
} else {
    Write-Output 'Installing Pester 5 ...'
    Install-Module -Repository PSGallery -Scope CurrentUser -Force -Name Pester -MinimumVersion 5.2 -MaximumVersion 5.99 -SkipPublisherCheck
}
if (Get-InstalledModule -Name PSScriptAnalyzer -MinimumVersion 1.17 -ErrorAction SilentlyContinue) {
    Write-Output 'PSScriptAnalyzer is already installed.'
} else {
    Write-Output 'Installing PSScriptAnalyzer ...'
    Install-Module -Repository PSGallery -Scope CurrentUser -Force -Name PSScriptAnalyzer -SkipPublisherCheck
}
if (Get-InstalledModule -Name BuildHelpers -MinimumVersion 2.0 -ErrorAction SilentlyContinue) {
    Write-Output 'BuildHelpers is already installed.'
} else {
    Write-Output 'Installing BuildHelpers ...'
    Install-Module -Repository PSGallery -Scope CurrentUser -Force -Name BuildHelpers -SkipPublisherCheck
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBSuqCFKG8zVYHu
# HysSVVRmpmw3Sthcq29WFVf3m0v6gaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFE5pFYyRBF1XwEytZ0F
# SgQkHnVmuuarc2QtUxUnVHztMA0GCSqGSIb3DQEBAQUABIIBALNk3Xk2kY4uJNEh
# 54qR1JBV3tfqRalhK9ielyfCi6zixoVvqo++xtr38rCk3KIgSO6huGXTwnbghrpY
# lc+BsMz37VQ94t+WncA18adJo0c7xveY3qtwu/x3VJkAguPaV8z0gnEtA/mQO4GH
# 4VAHCiOZspwA3HoozQ2gKUl4XnQxSzKp5cKUIYP61zVGW874Y/iI8WUgatyxpILs
# RZXeyi5Dz35I276+c6yA94zpaEShqXmVch4ptAp7qu7lBuW9pl5v+h5lWGUhMc0C
# y/ALccfg+Emy0m6FytXf8oHGhYSgRSJPBVELTB3lFw1mM7+JHVF37aMGrH+hJSlX
# TBfFjHg=
# SIG # End signature block
