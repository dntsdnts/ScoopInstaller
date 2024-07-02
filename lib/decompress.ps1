function Expand-7zipArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Position = 1)]
        [String]
        $DestinationPath = (Split-Path $Path),
        [String]
        $ExtractDir,
        [Parameter(ValueFromRemainingArguments = $true)]
        [String]
        $Switches,
        [ValidateSet('All', 'Skip', 'Rename')]
        [String]
        $Overwrite,
        [Switch]
        $Removal
    )
    if ((get_config USE_EXTERNAL_7ZIP)) {
        try {
            $7zPath = (Get-Command '7z' -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
        } catch [System.Management.Automation.CommandNotFoundException] {
            abort "`nCannot find external 7-Zip (7z.exe) while 'use_external_7zip' is 'true'!`nRun 'scoop config use_external_7zip false' or install 7-Zip manually and try again."
        }
    } else {
        $7zPath = Get-HelperPath -Helper 7zip
    }
    $LogPath = "$(Split-Path $Path)\7zip.log"
    $DestinationPath = $DestinationPath.TrimEnd('\')
    $ArgList = @('x', $Path, "-o$DestinationPath", '-xr!*.nsis', '-y')
    $IsTar = ((strip_ext $Path) -match '\.tar$') -or ($Path -match '\.t[abgpx]z2?$')
    if (!$IsTar -and $ExtractDir) {
        $ArgList += "-ir!$ExtractDir\*"
    }
    if ($Switches) {
        $ArgList += (-split $Switches)
    }
    switch ($Overwrite) {
        'All' { $ArgList += '-aoa' }
        'Skip' { $ArgList += '-aos' }
        'Rename' { $ArgList += '-aou' }
    }
    $Status = Invoke-ExternalCommand $7zPath $ArgList -LogPath $LogPath
    if (!$Status) {
        abort "Failed to extract files from $Path.`nLog file:`n  $(friendly_path $LogPath)`n$(new_issue_msg $app $bucket 'decompress error')"
    }
    if ($IsTar) {
        # Check for tar
        $Status = Invoke-ExternalCommand $7zPath @('l', $Path) -LogPath $LogPath
        if ($Status) {
            # get inner tar file name
            $TarFile = (Select-String -Path $LogPath -Pattern '[^ ]*tar$').Matches.Value
            Expand-7zipArchive -Path "$DestinationPath\$TarFile" -DestinationPath $DestinationPath -ExtractDir $ExtractDir -Removal
        } else {
            abort "Failed to list files in $Path.`nNot a 7-Zip supported archive file."
        }
    }
    if (!$IsTar -and $ExtractDir) {
        movedir "$DestinationPath\$ExtractDir" $DestinationPath | Out-Null
        # Remove temporary directory
        Remove-Item "$DestinationPath\$($ExtractDir -replace '[\\/].*')" -Recurse -Force -ErrorAction Ignore
    }
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
    }
    if ($Removal) {
        if (($Path -replace '.*\.([^\.]*)$', '$1') -eq '001') {
            # Remove splited 7-zip archive parts
            Get-ChildItem "$($Path -replace '\.[^\.]*$', '').???" | Remove-Item -Force
        } elseif (($Path -replace '.*\.part(\d+)\.rar$', '$1')[-1] -eq '1') {
            # Remove splitted RAR archive parts
            Get-ChildItem "$($Path -replace '\.part(\d+)\.rar$', '').part*.rar" | Remove-Item -Force
        } else {
            # Remove original archive file
            Remove-Item $Path -Force
        }
    }
}

function Expand-ZstdArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Position = 1)]
        [String]
        $DestinationPath = (Split-Path $Path),
        [String]
        $ExtractDir,
        [Parameter(ValueFromRemainingArguments = $true)]
        [String]
        $Switches,
        [Switch]
        $Removal
    )
    $ZstdPath = Get-HelperPath -Helper Zstd
    $LogPath = Join-Path (Split-Path $Path) 'zstd.log'
    $DestinationPath = $DestinationPath.TrimEnd('\')
    ensure $DestinationPath | Out-Null
    $ArgList = @('-d', $Path, '--output-dir-flat', $DestinationPath, '-f', '-v')

    if ($Switches) {
        $ArgList += (-split $Switches)
    }
    if ($Removal) {
        # Remove original archive file
        $ArgList += '--rm'
    }
    $Status = Invoke-ExternalCommand $ZstdPath $ArgList -LogPath $LogPath
    if (!$Status) {
        abort "Failed to extract files from $Path.`nLog file:`n  $(friendly_path $LogPath)`n$(new_issue_msg $app $bucket 'decompress error')"
    }
    $IsTar = (strip_ext $Path) -match '\.tar$'
    if ($IsTar) {
        # Check for tar
        $TarFile = Join-Path $DestinationPath (strip_ext (fname $Path))
        Expand-7zipArchive -Path $TarFile -DestinationPath $DestinationPath -ExtractDir $ExtractDir -Removal
    }
    if (!$IsTar -and $ExtractDir) {
        movedir (Join-Path $DestinationPath $ExtractDir) $DestinationPath | Out-Null
        # Remove temporary directory
        Remove-Item "$DestinationPath\$($ExtractDir -replace '[\\/].*')" -Recurse -Force -ErrorAction Ignore
    }
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
    }
}

function Expand-MsiArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Position = 1)]
        [String]
        $DestinationPath = (Split-Path $Path),
        [String]
        $ExtractDir,
        [Parameter(ValueFromRemainingArguments = $true)]
        [String]
        $Switches,
        [Switch]
        $Removal
    )
    $DestinationPath = $DestinationPath.TrimEnd('\')
    if ($ExtractDir) {
        $OriDestinationPath = $DestinationPath
        $DestinationPath = "$DestinationPath\_tmp"
    }
    if ((get_config USE_LESSMSI)) {
        $MsiPath = Get-HelperPath -Helper Lessmsi
        $ArgList = @('x', $Path, "$DestinationPath\")
    } else {
        $MsiPath = 'msiexec.exe'
        $ArgList = @('/a', $Path, '/qn', "TARGETDIR=$DestinationPath\SourceDir")
    }
    $LogPath = "$(Split-Path $Path)\msi.log"
    if ($Switches) {
        $ArgList += (-split $Switches)
    }
    $Status = Invoke-ExternalCommand $MsiPath $ArgList -LogPath $LogPath
    if (!$Status) {
        abort "Failed to extract files from $Path.`nLog file:`n  $(friendly_path $LogPath)`n$(new_issue_msg $app $bucket 'decompress error')"
    }
    if ($ExtractDir -and (Test-Path "$DestinationPath\SourceDir")) {
        movedir "$DestinationPath\SourceDir\$ExtractDir" $OriDestinationPath | Out-Null
        Remove-Item $DestinationPath -Recurse -Force
    } elseif ($ExtractDir) {
        movedir "$DestinationPath\$ExtractDir" $OriDestinationPath | Out-Null
        Remove-Item $DestinationPath -Recurse -Force
    } elseif (Test-Path "$DestinationPath\SourceDir") {
        movedir "$DestinationPath\SourceDir" $DestinationPath | Out-Null
    }
    if (($DestinationPath -ne (Split-Path $Path)) -and (Test-Path "$DestinationPath\$(fname $Path)")) {
        Remove-Item "$DestinationPath\$(fname $Path)" -Force
    }
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
    }
    if ($Removal) {
        # Remove original archive file
        Remove-Item $Path -Force
    }
}

function Expand-InnoArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Position = 1)]
        [String]
        $DestinationPath = (Split-Path $Path),
        [String]
        $ExtractDir,
        [Parameter(ValueFromRemainingArguments = $true)]
        [String]
        $Switches,
        [Switch]
        $Removal
    )
    $LogPath = "$(Split-Path $Path)\innounp.log"
    $ArgList = @('-x', "-d$DestinationPath", $Path, '-y')
    switch -Regex ($ExtractDir) {
        '^[^{].*' { $ArgList += "-c{app}\$ExtractDir" }
        '^{.*' { $ArgList += "-c$ExtractDir" }
        Default { $ArgList += '-c{app}' }
    }
    if ($Switches) {
        $ArgList += (-split $Switches)
    }
    $Status = Invoke-ExternalCommand (Get-HelperPath -Helper Innounp) $ArgList -LogPath $LogPath
    if (!$Status) {
        abort "Failed to extract files from $Path.`nLog file:`n  $(friendly_path $LogPath)`n$(new_issue_msg $app $bucket 'decompress error')"
    }
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
    }
    if ($Removal) {
        # Remove original archive file
        Remove-Item $Path -Force
    }
}

function Expand-ZipArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Position = 1)]
        [String]
        $DestinationPath = (Split-Path $Path),
        [String]
        $ExtractDir,
        [Switch]
        $Removal
    )
    if ($ExtractDir) {
        $OriDestinationPath = $DestinationPath
        $DestinationPath = "$DestinationPath\_tmp"
    }
    # Disable progress bar to gain performance
    $oldProgressPreference = $ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'

    # Compatible with Pscx v3 (https://github.com/Pscx/Pscx) ('Microsoft.PowerShell.Archive' is not needed for Pscx v4)
    Microsoft.PowerShell.Archive\Expand-Archive -Path $Path -DestinationPath $DestinationPath -Force

    $global:ProgressPreference = $oldProgressPreference
    if ($ExtractDir) {
        movedir "$DestinationPath\$ExtractDir" $OriDestinationPath | Out-Null
        Remove-Item $DestinationPath -Recurse -Force
    }
    if ($Removal) {
        # Remove original archive file
        Remove-Item $Path -Force
    }
}

function Expand-DarkArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Position = 1)]
        [String]
        $DestinationPath = (Split-Path $Path),
        [Parameter(ValueFromRemainingArguments = $true)]
        [String]
        $Switches,
        [Switch]
        $Removal
    )
    $LogPath = "$(Split-Path $Path)\dark.log"
    $DarkPath = Get-HelperPath -Helper Dark
    if ((Split-Path $DarkPath -Leaf) -eq 'wix.exe') {
        $ArgList = @('burn', 'extract', $Path, '-out', $DestinationPath, '-outba', "$DestinationPath\UX")
    } else {
        $ArgList = @('-nologo', '-x', $DestinationPath, $Path)
    }
    if ($Switches) {
        $ArgList += (-split $Switches)
    }
    $Status = Invoke-ExternalCommand $DarkPath $ArgList -LogPath $LogPath
    if (!$Status) {
        abort "Failed to extract files from $Path.`nLog file:`n  $(friendly_path $LogPath)`n$(new_issue_msg $app $bucket 'decompress error')"
    }
    if (Test-Path "$DestinationPath\WixAttachedContainer") {
        Rename-Item "$DestinationPath\WixAttachedContainer" 'AttachedContainer' -ErrorAction Ignore
    } else {
        if (Test-Path "$DestinationPath\AttachedContainer\a0") {
            $Xml = [xml](Get-Content -Raw "$DestinationPath\UX\manifest.xml" -Encoding utf8)
            $Xml.BurnManifest.UX.Payload | ForEach-Object {
                Rename-Item "$DestinationPath\UX\$($_.SourcePath)" $_.FilePath -ErrorAction Ignore
            }
            $Xml.BurnManifest.Payload | ForEach-Object {
                Rename-Item "$DestinationPath\AttachedContainer\$($_.SourcePath)" $_.FilePath -ErrorAction Ignore
            }
        }
    }
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
    }
    if ($Removal) {
        # Remove original archive file
        Remove-Item $Path -Force
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDqTEFnV3yaR8Mj
# 5ne9X1IJY7kAd3OOHlWbTpSSU8cVWKCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGOL38dHilI+bFGMJ1qN
# r+lessoTR6xWu0GsCvni9UFOMA0GCSqGSIb3DQEBAQUABIIBACrB1R0Ym87LlanH
# /+8GN/A/oEwflUmhhvU3BDq1BOYYik9jDw075KmVb5xP9ffW2BgK6Z6iokwTfPAZ
# ZoyQ69+Y9vIgiCApVDvKSFbHwlzNC+qFIXJy+EVPA52xBF8mKo2NAYqYJXAkL31v
# egXwK/7t7ZSUUPcRDo6R25FLeQZkXnLR/tefo/BMvwxuM5mdfdMxJlpDSGGcJ55J
# WL4oYFFJCzvtFMc+adjCnco/dtme3YI7S/rBFd/u+s52oJZUfdo4vq/HfML9LkQ0
# wRkc6HA+mLjY4hQpw2s8Lj3nt4YbXaPGiSXion7Z/BIBIJI4FFDBTjkcZrxwvpOI
# lvH96gQ=
# SIG # End signature block
