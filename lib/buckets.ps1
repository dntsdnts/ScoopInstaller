$bucketsdir = "$scoopdir\buckets"

function Find-BucketDirectory {
    <#
    .DESCRIPTION
        Return full path for bucket with given name.
        Main bucket will be returned as default.
    .PARAMETER Name
        Name of bucket.
    .PARAMETER Root
        Root folder of bucket repository will be returned instead of 'bucket' subdirectory (if exists).
    #>
    param(
        [string] $Name = 'main',
        [switch] $Root
    )

    # Handle info passing empty string as bucket ($install.bucket)
    if (($null -eq $Name) -or ($Name -eq '')) {
        $Name = 'main'
    }
    $bucket = "$bucketsdir\$Name"

    if ((Test-Path "$bucket\bucket") -and !$Root) {
        $bucket = "$bucket\bucket"
    }

    return $bucket
}

function bucketdir($name) {
    Show-DeprecatedWarning $MyInvocation 'Find-BucketDirectory'

    return Find-BucketDirectory $name
}

function known_bucket_repos {
    $json = "$PSScriptRoot\..\buckets.json"

    return Get-Content $json -Raw | ConvertFrom-Json -ErrorAction stop
}

function known_bucket_repo($name) {
    $buckets = known_bucket_repos
    $buckets.$name
}

function known_buckets {
    known_bucket_repos | ForEach-Object { $_.PSObject.Properties | Select-Object -Expand 'name' }
}

function apps_in_bucket($dir) {
    return (Get-ChildItem $dir -Filter '*.json' -Recurse).BaseName
}

function Get-LocalBucket {
    <#
    .SYNOPSIS
        List all local buckets.
    #>
    $bucketNames = [System.Collections.Generic.List[String]](Get-ChildItem -Path $bucketsdir -Directory).Name
    if ($null -eq $bucketNames) {
        return @() # Return a zero-length list instead of $null.
    } else {
        $knownBuckets = known_buckets
        for ($i = $knownBuckets.Count - 1; $i -ge 0 ; $i--) {
            $name = $knownBuckets[$i]
            if ($bucketNames.Contains($name)) {
                [void]$bucketNames.Remove($name)
                $bucketNames.Insert(0, $name)
            }
        }
        return $bucketNames
    }
}

function buckets {
    Show-DeprecatedWarning $MyInvocation 'Get-LocalBucket'

    return Get-LocalBucket
}

function Convert-RepositoryUri {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String] $Uri
    )

    process {
        # https://git-scm.com/docs/git-clone#_git_urls
        # https://regex101.com/r/xGmwRr/1
        if ($Uri -match '(?:@|/{1,3})(?:www\.|.*@)?(?<provider>[^/]+?)(?::\d+)?[:/](?<user>.+)/(?<repo>.+?)(?:\.git)?/?$') {
            $Matches.provider, $Matches.user, $Matches.repo -join '/'
        } else {
            error "$Uri is not a valid Git URL!"
            error "Please see https://git-scm.com/docs/git-clone#_git_urls for valid ones."
            return $null
        }
    }
}

function list_buckets {
    $buckets = @()
    Get-LocalBucket | ForEach-Object {
        $bucket = [Ordered]@{ Name = $_ }
        $path = Find-BucketDirectory $_ -Root
        if ((Test-Path (Join-Path $path '.git')) -and (Get-Command git -ErrorAction SilentlyContinue)) {
            $bucket.Source = Invoke-Git -Path $path -ArgumentList @('config', 'remote.origin.url')
            $bucket.Updated = Invoke-Git -Path $path -ArgumentList @('log', '--format=%aD', '-n', '1') | Get-Date
        } else {
            $bucket.Source = friendly_path $path
            $bucket.Updated = (Get-Item "$path\bucket" -ErrorAction SilentlyContinue).LastWriteTime
        }
        $bucket.Manifests = Get-ChildItem "$path\bucket" -Force -Recurse -ErrorAction SilentlyContinue |
                Measure-Object | Select-Object -ExpandProperty Count
        $buckets += [PSCustomObject]$bucket
    }
    ,$buckets
}

function add_bucket($name, $repo) {
    if (!(Test-GitAvailable)) {
        error "Git is required for buckets. Run 'scoop install git' and try again."
        return 1
    }

    $dir = Find-BucketDirectory $name -Root
    if (Test-Path $dir) {
        warn "The '$name' bucket already exists. To add this bucket again, first remove it by running 'scoop bucket rm $name'."
        return 2
    }

    $uni_repo = Convert-RepositoryUri -Uri $repo
    if ($null -eq $uni_repo) {
        return 1
    }
    foreach ($bucket in Get-LocalBucket) {
        if (Test-Path -Path "$bucketsdir\$bucket\.git") {
            $remote = Invoke-Git -Path "$bucketsdir\$bucket" -ArgumentList @('config', '--get', 'remote.origin.url')
            if ((Convert-RepositoryUri -Uri $remote) -eq $uni_repo) {
                warn "Bucket $bucket already exists for $repo"
                return 2
            }
        }
    }

    Write-Host 'Checking repo... ' -NoNewline
    $out = Invoke-Git -ArgumentList @('ls-remote', $repo) 2>&1
    if ($LASTEXITCODE -ne 0) {
        error "'$repo' doesn't look like a valid git repository`n`nError given:`n$out"
        return 1
    }
    ensure $bucketsdir | Out-Null
    $dir = ensure $dir
    Invoke-Git -ArgumentList @('clone', $repo, $dir, '-q')
    Write-Host 'OK'
    success "The $name bucket was added successfully."
    return 0
}

function rm_bucket($name) {
    $dir = Find-BucketDirectory $name -Root
    if (!(Test-Path $dir)) {
        error "'$name' bucket not found."
        return 1
    }

    Remove-Item $dir -Recurse -Force -ErrorAction Stop
    return 0
}

function new_issue_msg($app, $bucket, $title, $body) {
    $app, $manifest, $bucket, $url = Get-Manifest "$bucket/$app"
    $url = known_bucket_repo $bucket
    $bucket_path = "$bucketsdir\$bucket"

    if (Test-Path $bucket_path) {
        $remote = Invoke-Git -Path $bucket_path -ArgumentList @('config', '--get', 'remote.origin.url')
        # Support ssh and http syntax
        # git@PROVIDER:USER/REPO.git
        # https://PROVIDER/USER/REPO.git
        $remote -match '(@|:\/\/)(?<provider>.+)[:/](?<user>.*)\/(?<repo>.*)(\.git)?$' | Out-Null
        $url = "https://$($Matches.Provider)/$($Matches.User)/$($Matches.Repo)"
    }

    if (!$url) { return 'Please contact the bucket maintainer!' }

    # Print only github repositories
    if ($url -like '*github*') {
        $title = [System.Web.HttpUtility]::UrlEncode("$app@$($manifest.version): $title")
        $body = [System.Web.HttpUtility]::UrlEncode($body)
        $url = $url -replace '\.git$', ''
        $url = "$url/issues/new?title=$title"
        if ($body) {
            $url += "&body=$body"
        }
    }

    $msg = "`nPlease try again or create a new issue by using the following link and paste your console output:"
    return "$msg`n$url"
}

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDGd2gHlAZu8DMo
# zjpbVEX7E/qiZYWbpjtOy0XxAOCLCqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMyX5yVbBlf2zjlq9soY
# y433g2vuef7ZR2JUlv1tdOZhMA0GCSqGSIb3DQEBAQUABIIBAEr1OqkU2UwryOZO
# 9KDPLYp0eggvGp3cappcO9vq7eD1Oa0qLLx3KL/kFT/rxLzT+uddnfKu4LO8H8Es
# pGWXpdvyXQ8cDNKWE5VtJ3MjO0sXTQfIMKdve8CLvKyd9LdhElQy83ijnA22P2P7
# LTnAyvJ/6bH3QD7tyPuUuymgK/r72JP34BbDLry6d/55Q1pIN4t7HaDjmPl7A3Vq
# g4bKNaJeK7EInZFlarKEAGIRingYrKldmPkxkKBIZkW+pI75VD/hTLSmk1ik38TQ
# sFHCR+/ezoTWAPDNrn/F6bBGYmgpPI4S3ISL2yuQlGYLUncG+SxAAqKToVXwR/e2
# vbAPwiQ=
# SIG # End signature block
