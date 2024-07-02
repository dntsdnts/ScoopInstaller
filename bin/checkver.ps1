<#
.SYNOPSIS
    Check manifest for a newer version.
.DESCRIPTION
    Checks websites for newer versions using an (optional) regular expression defined in the manifest.
.PARAMETER App
    Manifest name to search.
    Placeholders are supported.
.PARAMETER Dir
    Where to search for manifest(s).
.PARAMETER Update
    Update given manifest
.PARAMETER ForceUpdate
    Update given manifest(s) even when there is no new version.
    Useful for hash updates.
.PARAMETER SkipUpdated
    Updated manifests will not be shown.
.PARAMETER Version
    Update manifest to specific version.
.PARAMETER ThrowError
    Throw error as exception instead of just printing it.
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1
    Check all manifest inside default directory.
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 -SkipUpdated
    Check all manifest inside default directory (list only outdated manifests).
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 -Update
    Check all manifests and update All outdated manifests.
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 APP
    Check manifest APP.json inside default directory.
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 APP -Update
    Check manifest APP.json and update, if there is newer version.
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 APP -ForceUpdate
    Check manifest APP.json and update, even if there is no new version.
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 APP -Update -Version VER
    Check manifest APP.json and update, using version VER
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 APP DIR
    Check manifest APP.json inside ./DIR directory.
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 -Dir DIR
    Check all manifests inside ./DIR directory.
.EXAMPLE
    PS BUCKETROOT > .\bin\checkver.ps1 APP DIR -Update
    Check manifest APP.json inside ./DIR directory and update if there is newer version.
#>
param(
    [String] $App = '*',
    [ValidateScript( {
        if (!(Test-Path $_ -Type Container)) {
            throw "$_ is not a directory!"
        } else {
            $true
        }
    })]
    [String] $Dir,
    [Switch] $Update,
    [Switch] $ForceUpdate,
    [Switch] $SkipUpdated,
    [String] $Version = '',
    [Switch] $ThrowError
)

. "$PSScriptRoot\..\lib\core.ps1"
. "$PSScriptRoot\..\lib\autoupdate.ps1"
. "$PSScriptRoot\..\lib\manifest.ps1"
. "$PSScriptRoot\..\lib\buckets.ps1"
. "$PSScriptRoot\..\lib\json.ps1"
. "$PSScriptRoot\..\lib\versions.ps1"
. "$PSScriptRoot\..\lib\install.ps1" # needed for hash generation

if ($App -ne '*' -and (Test-Path $App -PathType Leaf)) {
    $Dir = Split-Path $App
    $files = Get-ChildItem $Dir -Filter (Split-Path $App -Leaf)
} elseif ($Dir) {
    $Dir = Convert-Path $Dir
    $files = Get-ChildItem $Dir -Filter "$App.json" -Recurse
} else {
    throw "'-Dir' parameter required if '-App' is not a filepath!"
}

$GitHubToken = Get-GitHubToken

# don't use $Version with $App = '*'
if ($App -eq '*' -and $Version -ne '') {
    throw "Don't use '-Version' with '-App *'!"
}

# get apps to check
$Queue = @()
$json = ''
$files | ForEach-Object {
    $file = $_.FullName
    $json = parse_json $file
    if ($json.checkver) {
        $Queue += , @($_.BaseName, $json, $file)
    }
}

# clear any existing events
Get-Event | Remove-Event
Get-EventSubscriber | Unregister-Event

# start all downloads
$Queue | ForEach-Object {
    $name, $json, $file = $_

    $substitutions = Get-VersionSubstitution $json.version # 'autoupdate.ps1'

    $wc = New-Object Net.Webclient
    if ($json.checkver.useragent) {
        $wc.Headers.Add('User-Agent', (substitute $json.checkver.useragent $substitutions))
    } else {
        $wc.Headers.Add('User-Agent', (Get-UserAgent))
    }
    Register-ObjectEvent $wc downloadDataCompleted -ErrorAction Stop | Out-Null

    # Not Specified
    if ($json.checkver.url) {
        $url = $json.checkver.url
    } else {
        $url = $json.homepage
    }

    if ($json.checkver.re) {
        $regex = $json.checkver.re
    } elseif ($json.checkver.regex) {
        $regex = $json.checkver.regex
    } else {
        $regex = ''
    }

    $jsonpath = ''
    $xpath = ''
    $replace = ''
    $useGithubAPI = $false

    # GitHub
    if ($regex) {
        $githubRegex = $regex
    } else {
        $githubRegex = '/releases/tag/(?:v|V)?([\d.]+)'
    }
    if ($json.checkver -eq 'github') {
        if (!$json.homepage.StartsWith('https://github.com/')) {
            error "$name checkver expects the homepage to be a github repository"
        }
        $url = $json.homepage.TrimEnd('/') + '/releases/latest'
        $regex = $githubRegex
        $useGithubAPI = $true
    }

    if ($json.checkver.github) {
        $url = $json.checkver.github.TrimEnd('/') + '/releases/latest'
        $regex = $githubRegex
        if ($json.checkver.PSObject.Properties.Count -eq 1) { $useGithubAPI = $true }
    }

    # SourceForge
    if ($regex) {
        $sourceforgeRegex = $regex
    } else {
        $sourceforgeRegex = '(?!\.)([\d.]+)(?<=\d)'
    }
    if ($json.checkver -eq 'sourceforge') {
        if ($json.homepage -match '//(sourceforge|sf)\.net/projects/(?<project>[^/]+)(/files/(?<path>[^/]+))?|//(?<project>[^.]+)\.(sourceforge\.(net|io)|sf\.net)') {
            $project = $Matches['project']
            $path = $Matches['path']
        } else {
            $project = strip_ext $name
        }
        $url = "https://sourceforge.net/projects/$project/rss"
        if ($path) {
            $url = $url + '?path=/' + $path.TrimStart('/')
        }
        $regex = "CDATA\[/$path/.*?$sourceforgeRegex.*?\]".Replace('//', '/')
    }
    if ($json.checkver.sourceforge) {
        if ($json.checkver.sourceforge -is [System.String] -and $json.checkver.sourceforge -match '(?<project>[\w-]*)(/(?<path>.*))?') {
            $project = $Matches['project']
            $path = $Matches['path']
        } else {
            $project = $json.checkver.sourceforge.project
            $path = $json.checkver.sourceforge.path
        }
        $url = "https://sourceforge.net/projects/$project/rss"
        if ($path) {
            $url = $url + '?path=/' + $path.TrimStart('/')
        }
        $regex = "CDATA\[/$path/.*?$sourceforgeRegex.*?\]".Replace('//', '/')
    }

    if ($json.checkver.jp) {
        $jsonpath = $json.checkver.jp
    }
    if ($json.checkver.jsonpath) {
        $jsonpath = $json.checkver.jsonpath
    }
    if ($json.checkver.xpath) {
        $xpath = $json.checkver.xpath
    }

    if ($json.checkver.replace -is [System.String]) { # If `checkver` is [System.String], it has a method called `Replace`
        $replace = $json.checkver.replace
    }

    if (!$jsonpath -and !$regex -and !$xpath) {
        $regex = $json.checkver
    }

    $reverse = $json.checkver.reverse -and $json.checkver.reverse -eq 'true'

    if ($url -like '*api.github.com/*') { $useGithubAPI = $true }

    if ($useGithubAPI -and ($null -ne $GitHubToken)) {
        $url = $url -replace '//(www\.)?github.com/', '//api.github.com/repos/'
        $wc.Headers.Add('Authorization', "token $GitHubToken")
    }

    $url = substitute $url $substitutions

    $state = New-Object psobject @{
        app      = $name
        file     = $file
        url      = $url
        regex    = $regex
        json     = $json
        jsonpath = $jsonpath
        xpath    = $xpath
        reverse  = $reverse
        replace  = $replace
    }

    get_config PRIVATE_HOSTS | Where-Object { $_ -ne $null -and $url -match $_.match } | ForEach-Object {
        (ConvertFrom-StringData -StringData $_.Headers).GetEnumerator() | ForEach-Object {
            $wc.Headers[$_.Key] = $_.Value
        }
    }

    $wc.Headers.Add('Referer', (strip_filename $url))
    $wc.DownloadDataAsync($url, $state)
}

function next($er) {
    Write-Host "$App`: " -NoNewline
    Write-Host $er -ForegroundColor DarkRed
}

# wait for all to complete
$in_progress = $Queue.length
while ($in_progress -gt 0) {
    $ev = Wait-Event
    Remove-Event $ev.SourceIdentifier
    $in_progress--

    $state = $ev.SourceEventArgs.UserState
    $result = $ev.SourceEventArgs.Result
    $app = $state.app
    $file = $state.file
    $json = $state.json
    $url = $state.url
    $regexp = $state.regex
    $jsonpath = $state.jsonpath
    $xpath = $state.xpath
    $script = $json.checkver.script
    $reverse = $state.reverse
    $replace = $state.replace
    $expected_ver = $json.version
    $ver = $Version

    if (!$ver) {
        if (!$regex -and $replace) {
            next "'replace' requires 're' or 'regex'"
            continue
        }
        $err = $ev.SourceEventArgs.Error
        if ($err) {
            next "$($err.message)`r`nURL $url is not valid"
            continue
        }

        if ($url) {
            $ms = New-Object System.IO.MemoryStream
            $ms.Write($result, 0, $result.Length)
            $ms.Seek(0, 0) | Out-Null
            if ($result[0] -eq 0x1F -and $result[1] -eq 0x8B) {
                $ms = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
            }
            $page = (New-Object System.IO.StreamReader($ms, (Get-Encoding $wc))).ReadToEnd()
        }
        if ($script) {
            $page = Invoke-Command ([scriptblock]::Create($script -join "`r`n"))
        }

        if ($jsonpath) {
            # Return only a single value if regex is absent
            $noregex = [String]::IsNullOrEmpty($regex)
            # If reverse is ON and regex is ON,
            # Then reverse would have no effect because regex handles reverse
            # on its own
            # So in this case we have to disable reverse
            $ver = json_path $page $jsonpath $null ($reverse -and $noregex) $noregex
            if (!$ver) {
                $ver = json_path_legacy $page $jsonpath
            }
            if (!$ver) {
                next "couldn't find '$jsonpath' in $url"
                continue
            }
        }

        if ($xpath) {
            $xml = [xml]$page
            # Find all `significant namespace declarations` from the XML file
            $nsList = $xml.SelectNodes("//namespace::*[not(. = ../../namespace::*)]")
            # Then add them into the NamespaceManager
            $nsmgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
            $nsList | ForEach-Object {
                if ($_.LocalName -eq 'xmlns') {
                    $nsmgr.AddNamespace('ns', $_.Value)
                    $xpath = $xpath -replace '/([^:/]+)((?=/)|(?=$))', '/ns:$1'
                } else {
                    $nsmgr.AddNamespace($_.LocalName, $_.Value)
                }
            }
            # Getting version from XML, using XPath
            $ver = $xml.SelectSingleNode($xpath, $nsmgr).'#text'
            if (!$ver) {
                next "couldn't find '$($xpath -replace 'ns:', '')' in $url"
                continue
            }
        }

        if ($jsonpath -and $regexp) {
            $page = $ver
            $ver = ''
        }

        if ($xpath -and $regexp) {
            $page = $ver
            $ver = ''
        }

        if ($regexp) {
            $regex = New-Object System.Text.RegularExpressions.Regex($regexp)
            if ($reverse) {
                $match = $regex.Matches($page) | Select-Object -Last 1
            } else {
                $match = $regex.Matches($page) | Select-Object -First 1
            }

            if ($match -and $match.Success) {
                $matchesHashtable = @{}
                $regex.GetGroupNames() | ForEach-Object { $matchesHashtable.Add($_, $match.Groups[$_].Value) }
                $ver = $matchesHashtable['1']
                if ($replace) {
                    $ver = $regex.Replace($match.Value, $replace)
                }
                if (!$ver) {
                    $ver = $matchesHashtable['version']
                }
            } else {
                next "couldn't match '$regexp' in $url"
                continue
            }
        }

        if (!$ver) {
            next "couldn't find new version in $url"
            continue
        }
    }

    # Skip actual only if versions are same and there is no -f
    if (($ver -eq $expected_ver) -and !$ForceUpdate -and $SkipUpdated) { continue }

    Write-Host "$app`: " -NoNewline

    # version hasn't changed (step over if forced update)
    if ($ver -eq $expected_ver -and !$ForceUpdate) {
        Write-Host $ver -ForegroundColor DarkGreen
        continue
    }

    Write-Host $ver -ForegroundColor DarkRed -NoNewline
    Write-Host " (scoop version is $expected_ver)" -NoNewline
    $update_available = (Compare-Version -ReferenceVersion $ver -DifferenceVersion $expected_ver) -ne 0

    if ($json.autoupdate -and $update_available) {
        Write-Host ' autoupdate available' -ForegroundColor Cyan
    } else {
        Write-Host ''
    }

    # forcing an update implies updating, right?
    if ($ForceUpdate) { $Update = $true }

    if ($Update -and $json.autoupdate) {
        if ($ForceUpdate) {
            Write-Host 'Forcing autoupdate!' -ForegroundColor DarkMagenta
        }
        try {
            Invoke-AutoUpdate $app $file $json $ver $matchesHashtable # 'autoupdate.ps1'
        } catch {
            if ($ThrowError) {
                throw $_
            } else {
                error $_.Exception.Message
            }
        }
    }
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1MCvtdV5uiwTW
# hZwJGhEZcPieKRmpXiBK3PY4yETkQqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFEUIEMtJIMyjQ7o6Isi
# O3r9XRYnSieWsssYP7u9M4q+MA0GCSqGSIb3DQEBAQUABIIBAIgvTUOc1DGw+S4M
# c0rjpCmtIZEMSVOOXgFfOE4ixTX4eSjv3FYg1WNJXIO+ohAEXokEzPFTcP6c7kVP
# wNFvr0/1y0Rjl73LEYJKI0PSehKF66J5nPZ8g3nQhfc9EbySvujAznTkWOkuy4pJ
# lrE0idU9oksxueEic0O10I4iJi62E1Got185URGx9Y01WgdDmJYGuAVE/ebNVUCS
# ssCWGZizV5pSwlyY+UVvMcXgS9uzuVCG3pYa2YcX3NBW4c9M8xdBQQwto5u2IFlk
# 45tcSpu0pOO6ok/VmnDFmDsCsjVBus4y2rPrP8y/MDR6JrKDOGqSob0gojuMomn5
# HqNWzfU=
# SIG # End signature block
