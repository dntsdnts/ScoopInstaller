# Usage: scoop help <command>
# Summary: Show help for a command
param($cmd)

function print_help($cmd) {
    $file = Get-Content (command_path $cmd) -Raw

    $usage = usage $file
    $help = scoop_help $file

    if ($usage) { "$usage`n" }
    if ($help) { $help }
}

function print_summaries {
    $commands = @()

    command_files | ForEach-Object {
        $command = [ordered]@{}
        $command.Command = command_name $_
        $command.Summary = summary (Get-Content (command_path $command.Command))
        $commands += [PSCustomObject]$command
    }

    $commands
}

$commands = commands

if(!($cmd)) {
    Write-Host "Usage: scoop <command> [<args>]

Available commands are listed below.

Type 'scoop help <command>' to get more help for a specific command."
    print_summaries
} elseif($commands -contains $cmd) {
    print_help $cmd
} else {
    warn "scoop help: no such command '$cmd'"
    exit 1
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC9XFPASJm+jaQp
# vcGskvBmDAvm6qf2v7VCPfh7YbX4vaCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHhttJjLUuS11gxB30zB
# YNFNji2UD2tDmLy53f5bKFL0MA0GCSqGSIb3DQEBAQUABIIBAEZM5VU3wcm5lH45
# d78o/wJEXqm4CfuBlo6/H1uQBbCcIDAqThKmTbQdfqJMsM0tOcgsXXITn8wPzVg0
# EtZzDbazJ5qoQBEgVl3MiGt1Z4scC4dmM1Lod8m19BrooE1nYRb7rkrwe2BJyumi
# 0tY8UOv7o7ckNzAmTQMZe6fuPEqdjkHYXtCRwlcVEJuKOgZeMO2CzVxjs+oaFeaE
# snpHhAP0L+w/zjsaFuN5d27fPWkU4kIfXR47SzCVMub1MAdSJrZdEM3j/Xl8BS8N
# inl1aD+fX1BJ/kz3iubh92xvw9QzcKRgdCVqPUalrUralcSsO+ZX8CddjWtvCA2F
# kkQC7uc=
# SIG # End signature block
