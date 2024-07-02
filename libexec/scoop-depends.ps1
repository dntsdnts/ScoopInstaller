# Usage: scoop depends <app>
# Summary: List dependencies for an app, in the order they'll be installed

. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\depends.ps1" # 'Get-Dependency'
. "$PSScriptRoot\..\lib\manifest.ps1" # 'Get-Manifest' (indirectly)

$opt, $apps, $err = getopt $args 'a:' 'arch='
$app = $apps[0]

if(!$app) { error '<app> missing'; my_usage; exit 1 }

$architecture = Get-DefaultArchitecture
try {
    $architecture = Format-ArchitectureString ($opt.a + $opt.arch)
} catch {
    abort "ERROR: $_"
}

$deps = @()
Get-Dependency $app $architecture | ForEach-Object {
    $dep = [ordered]@{}
    $dep.Source, $dep.Name = $_ -split '/'
    $deps += [PSCustomObject]$dep
}
$deps

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBwWAN+zQIQxZCw
# IzB+AjUH2czr5Jx733wr62ouL0n9uaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEhoolys9qEgsR/YWXnp
# nSvMijsRjDhLjyxamVBLP7N5MA0GCSqGSIb3DQEBAQUABIIBAKbIQyWNtmjPAOLS
# TWFQvN6BRN867mToqK4KjotpXEOwZ1tWq5IfT9Ii/wVFJnPXWANGvGOreR30u2GJ
# oU86HoeDu2wSomks0zkKV2F5L7pGH1jJDG67p+mGsRkZdIjDXop9ZV7HJcJBAnaV
# 5tUu/XsdDLpDohm+YqjhAPKW3DJrerihRbXt/CFVwL/cgjJyp9t/3yjEmmB0tNNW
# ihUeb7BgX0Hp6bvkuZANqOHR9vwW9lJzI5PB+EQYHQ61Bs4hzE0uXD2xnKrovPfI
# wL/Yamz/haBK46T7/6C+v8LY2SQ+GE0kDuuNj6oy8ppaF/SDz4qzIhuzXXebBqmZ
# UTg8ooI=
# SIG # End signature block
