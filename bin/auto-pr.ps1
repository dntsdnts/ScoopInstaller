<#
.SYNOPSIS
    Updates manifests and pushes them or creates pull-requests.
.DESCRIPTION
    Updates manifests and pushes them directly to the origin branch or creates pull-requests for upstream.
.PARAMETER Upstream
    Upstream repository with the target branch.
    Must be in format '<user>/<repo>:<branch>'
.PARAMETER OriginBranch
    Origin (local) branch name.
.PARAMETER App
    Manifest name to search.
    Placeholders are supported.
.PARAMETER CommitMessageFormat
    The format of the commit message.
    <app> will be replaced with the file name of manifest.
    <version> will be replaced with the version of the latest manifest.
.PARAMETER Dir
    The directory where to search for manifests.
.PARAMETER Push
    Push updates directly to 'origin branch'.
.PARAMETER Request
    Create pull-requests on 'upstream branch' for each update.
.PARAMETER Help
    Print help to console.
.PARAMETER SpecialSnowflakes
    An array of manifests, which should be updated all the time. (-ForceUpdate parameter to checkver)
.PARAMETER SkipUpdated
    Updated manifests will not be shown.
.PARAMETER ThrowError
    Throw error as exception instead of just printing it.
.EXAMPLE
    PS BUCKETROOT > .\bin\auto-pr.ps1 'someUsername/repository:branch' -Request
.EXAMPLE
    PS BUCKETROOT > .\bin\auto-pr.ps1 -Push
    Update all manifests inside 'bucket/' directory.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( {
        if (!($_ -match '^(.*)\/(.*):(.*)$')) {
            throw 'Upstream must be in this format: <user>/<repo>:<branch>'
        }
        $true
    })]
    [String] $Upstream,
    [String] $OriginBranch = 'master',
    [String] $App = '*',
    [String] $CommitMessageFormat = '<app>: Update to version <version>',
    [ValidateScript( {
        if (!(Test-Path $_ -Type Container)) {
            throw "$_ is not a directory!"
        } else {
            $true
        }
    })]
    [String] $Dir,
    [Switch] $Push,
    [Switch] $Request,
    [Switch] $Help,
    [string[]] $SpecialSnowflakes,
    [Switch] $SkipUpdated,
    [Switch] $ThrowError
)

. "$PSScriptRoot\..\lib\manifest.ps1"
. "$PSScriptRoot\..\lib\json.ps1"

if ($App -ne '*' -and (Test-Path $App -PathType Leaf)) {
    $Dir = Split-Path $App
} elseif ($Dir) {
    $Dir = Convert-Path $Dir
} else {
    throw "'-Dir' parameter required if '-App' is not a filepath!"
}

if ((!$Push -and !$Request) -or $Help) {
    Write-Host @'
Usage: auto-pr.ps1 [OPTION]

Mandatory options:
  -p,  -push                       push updates directly to 'origin branch'
  -r,  -request                    create pull-requests on 'upstream branch' for each update

Optional options:
  -u,  -upstream                   upstream repository with target branch
  -o,  -originbranch               origin (local) branch name
  -h,  -help
'@
    exit 0
}

if ($IsLinux -or $IsMacOS) {
    if (!(which hub)) {
        Write-Host "Please install hub ('brew install hub' or visit: https://hub.github.com/)" -ForegroundColor Yellow
        exit 1
    }
} else {
    if (!(scoop which hub)) {
        Write-Host "Please install hub 'scoop install hub'" -ForegroundColor Yellow
        exit 1
    }
}

function execute($cmd) {
    Write-Host $cmd -ForegroundColor Green
    $output = Invoke-Command ([scriptblock]::Create($cmd))

    if ($LASTEXITCODE -gt 0) {
        abort "^^^ Error! See above ^^^ (last command: $cmd)"
    }

    return $output
}

function pull_requests($json, [String] $app, [String] $upstream, [String] $manifest, [String] $commitMessage) {
    $version = $json.version
    $homepage = $json.homepage
    $branch = "manifest/$app-$version"

    execute "hub checkout $OriginBranch"
    Write-Host "hub rev-parse --verify $branch" -ForegroundColor Green
    hub rev-parse --verify $branch

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Skipping update $app ($version) ..." -ForegroundColor Yellow
        return
    }

    Write-Host "Creating update $app ($version) ..." -ForegroundColor DarkCyan
    execute "hub checkout -b $branch"
    execute "hub add $manifest"
    execute "hub commit -m '$commitMessage"
    Write-Host "Pushing update $app ($version) ..." -ForegroundColor DarkCyan
    execute "hub push origin $branch"

    if ($LASTEXITCODE -gt 0) {
        error "Push failed! (hub push origin $branch)"
        execute 'hub reset'
        return
    }

    Start-Sleep 1
    Write-Host "Pull-Request update $app ($version) ..." -ForegroundColor DarkCyan
    Write-Host "hub pull-request -m '<msg>' -b '$upstream' -h '$branch'" -ForegroundColor Green

    $msg = @"
$commitMessage

Hello lovely humans,
a new version of [$app]($homepage) is available.

| State       | Update :rocket: |
| :---------- | :-------------- |
| New version | $version        |
"@

    hub pull-request -m "$msg" -b "$upstream" -h "$branch"
    if ($LASTEXITCODE -gt 0) {
        execute 'hub reset'
        abort "Pull Request failed! (hub pull-request -m '$commitMessage' -b '$upstream' -h '$branch')"
    }
}

Write-Host 'Updating ...' -ForegroundColor DarkCyan
if ($Push) {
    execute "hub pull origin $OriginBranch"
    execute "hub checkout $OriginBranch"
} else {
    execute "hub pull upstream $OriginBranch"
    execute "hub push origin $OriginBranch"
}

. "$PSScriptRoot\checkver.ps1" -App $App -Dir $Dir -Update -SkipUpdated:$SkipUpdated -ThrowError:$ThrowError
if ($SpecialSnowflakes) {
    Write-Host "Forcing update on our special snowflakes: $($SpecialSnowflakes -join ',')" -ForegroundColor DarkCyan
    $SpecialSnowflakes -split ',' | ForEach-Object {
        . "$PSScriptRoot\checkver.ps1" $_ -Dir $Dir -ForceUpdate -ThrowError:$ThrowError
    }
}

hub diff --name-only | ForEach-Object {
    $manifest = $_
    if (!$manifest.EndsWith('.json')) {
        return
    }

    $app = ([System.IO.Path]::GetFileNameWithoutExtension($manifest))
    $json = parse_json $manifest
    if (!$json.version) {
        error "Invalid manifest: $manifest ..."
        return
    }
    $version = $json.version
    $CommitMessage = $CommitMessageFormat -replace '<app>',$app -replace '<version>',$version
    if ($Push) {
        Write-Host "Creating update $app ($version) ..." -ForegroundColor DarkCyan
        execute "hub add $manifest"

        # detect if file was staged, because it's not when only LF or CRLF have changed
        $status = execute 'hub status --porcelain -uno'
        $status = $status | Where-Object { $_ -match "M\s{2}.*$app.json" }
        if ($status -and $status.StartsWith('M  ') -and $status.EndsWith("$app.json")) {
            execute "hub commit -m '$commitMessage'"
        } else {
            Write-Host "Skipping $app because only LF/CRLF changes were detected ..." -ForegroundColor Yellow
        }
    } else {
        pull_requests $json $app $Upstream $manifest $CommitMessage
    }
}

if ($Push) {
    Write-Host 'Pushing updates ...' -ForegroundColor DarkCyan
    execute "hub push origin $OriginBranch"
} else {
    Write-Host "Returning to $OriginBranch branch and removing unstaged files ..." -ForegroundColor DarkCyan
    execute "hub checkout -f $OriginBranch"
}

execute 'hub reset --hard'

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB1Qc1FfHY5IgpQ
# asQM8LV0xjaB4JPLffUg5v7PcSf2caCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILz6ow1T6nCmgq2WYHO7
# FdjAIZUU/SopBrkGfDx5M4+6MA0GCSqGSIb3DQEBAQUABIIBAK0eDNcAXuB93FiC
# UGVyid80HydGZ5yPKSm2d4udiPnIFqHZQiz4L4dfopz/6OfN7A8H6igYqORX6xu5
# hOfp+1XiLK2O+psG5lBlj3Qec66FAlTtJj7euTlY7rgu/UIAbzjrosatpk77qozw
# BtNY6Fveb4P/wG7xvoWCbw5gnfL/9QQyYQh2oRlH9/bIKPy+pOCm6M9KMUAMYGmP
# tX/LcLBYqvNkp878rA6M01y0HPvZHf8RZjlaZhQ1/thcyAxytGdnACBtVO8U1ORj
# /HGGR5/rs12XjVDgqpRVUZ41pxMLpJ/PVAI48OfqyJUrYrCWxxBVysQd0ChPggpi
# NB26qL4=
# SIG # End signature block
