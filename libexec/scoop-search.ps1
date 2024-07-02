# Usage: scoop search <query>
# Summary: Search available apps
# Help: Searches for apps that are available to install.
#
# If used with [query], shows app names that match the query.
# Without [query], shows all the available apps.
param($query)

. "$PSScriptRoot\..\lib\manifest.ps1" # 'manifest'
. "$PSScriptRoot\..\lib\versions.ps1" # 'Get-LatestVersion'

$list = [System.Collections.Generic.List[PSCustomObject]]::new()

try {
    $query = New-Object Regex $query, 'IgnoreCase'
} catch {
    abort "Invalid regular expression: $($_.Exception.InnerException.Message)"
}

$githubtoken = Get-GitHubToken
$authheader = @{}
if ($githubtoken) {
    $authheader = @{'Authorization' = "token $githubtoken"}
}

function bin_match($manifest, $query) {
    if (!$manifest.bin) { return $false }
    $bins = foreach ($bin in $manifest.bin) {
        $exe, $alias, $args = $bin
        $fname = Split-Path $exe -Leaf -ErrorAction Stop

        if ((strip_ext $fname) -match $query) { $fname }
        elseif ($alias -match $query) { $alias }
    }

    if ($bins) { return $bins }
    else { return $false }
}

function bin_match_json($json, $query) {
    [System.Text.Json.JsonElement]$bin = [System.Text.Json.JsonElement]::new()
    if (!$json.RootElement.TryGetProperty("bin", [ref] $bin)) { return $false }
    $bins = @()
    if($bin.ValueKind -eq [System.Text.Json.JsonValueKind]::String -and [System.IO.Path]::GetFileNameWithoutExtension($bin) -match $query) {
        $bins += [System.IO.Path]::GetFileName($bin)
    } elseif ($bin.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
        foreach($subbin in $bin.EnumerateArray()) {
            if($subbin.ValueKind -eq [System.Text.Json.JsonValueKind]::String -and [System.IO.Path]::GetFileNameWithoutExtension($subbin) -match $query) {
                $bins += [System.IO.Path]::GetFileName($subbin)
            } elseif ($subbin.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
                if([System.IO.Path]::GetFileNameWithoutExtension($subbin[0]) -match $query) {
                    $bins += [System.IO.Path]::GetFileName($subbin[0])
                } elseif ($subbin.GetArrayLength() -ge 2 -and $subbin[1] -match $query) {
                    $bins += $subbin[1]
                }
            }
        }
    }

    if ($bins) { return $bins }
    else { return $false }
}

function search_bucket($bucket, $query) {
    $apps = Get-ChildItem (Find-BucketDirectory $bucket) -Filter '*.json' -Recurse

    $apps | ForEach-Object {
        $json = [System.Text.Json.JsonDocument]::Parse([System.IO.File]::ReadAllText($_.FullName))
        $name = $_.BaseName

        if ($name -match $query) {
            $list.Add([PSCustomObject]@{
                Name = $name
                Version = $json.RootElement.GetProperty("version")
                Source = $bucket
                Binaries = ""
            })
        } else {
            $bin = bin_match_json $json $query
            if ($bin) {
                $list.Add([PSCustomObject]@{
                    Name = $name
                    Version = $json.RootElement.GetProperty("version")
                    Source = $bucket
                    Binaries = $bin -join ' | '
                })
            }
        }
    }
}

# fallback function for PowerShell 5
function search_bucket_legacy($bucket, $query) {
    $apps = Get-ChildItem (Find-BucketDirectory $bucket) -Filter '*.json' -Recurse

    $apps | ForEach-Object {
        $manifest = [System.IO.File]::ReadAllText($_.FullName) | ConvertFrom-Json -ErrorAction Continue
        $name = $_.BaseName

        if ($name -match $query) {
            $list.Add([PSCustomObject]@{
                Name = $name
                Version = $manifest.Version
                Source = $bucket
                Binaries = ""
            })
        } else {
            $bin = bin_match $manifest $query
            if ($bin) {
                $list.Add([PSCustomObject]@{
                    Name = $name
                    Version = $manifest.Version
                    Source = $bucket
                    Binaries = $bin -join ' | '
                })
            }
        }
    }
}

function download_json($url) {
    $ProgressPreference = 'SilentlyContinue'
    $result = Invoke-WebRequest $url -UseBasicParsing -Headers $authheader | Select-Object -ExpandProperty content | ConvertFrom-Json
    $ProgressPreference = 'Continue'
    $result
}

function github_ratelimit_reached {
    $api_link = 'https://api.github.com/rate_limit'
    $ret = (download_json $api_link).rate.remaining -eq 0
    if ($ret) {
        Write-Host "GitHub API rate limit reached.
Please try again later or configure your API token using 'scoop config gh_token <your token>'."
    }
    $ret
}

function search_remote($bucket, $query) {
    $uri = [System.Uri](known_bucket_repo $bucket)
    if ($uri.AbsolutePath -match '/([a-zA-Z0-9]*)/([a-zA-Z0-9-]*)(?:.git|/)?') {
        $user = $Matches[1]
        $repo_name = $Matches[2]
        $api_link = "https://api.github.com/repos/$user/$repo_name/git/trees/HEAD?recursive=1"
        $result = download_json $api_link | Select-Object -ExpandProperty tree |
            Where-Object -Value "^bucket/(.*$query.*)\.json$" -Property Path -Match |
            ForEach-Object { $Matches[1] }
    }

    $result
}

function search_remotes($query) {
    $buckets = known_bucket_repos
    $names = $buckets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name

    $results = $names | Where-Object { !(Test-Path $(Find-BucketDirectory $_)) } | ForEach-Object {
        @{ "bucket" = $_; "results" = (search_remote $_ $query) }
    } | Where-Object { $_.results }

    if ($results.count -gt 0) {
        Write-Host "Results from other known buckets...
(add them using 'scoop bucket add <bucket name>')"
    }

    $remote_list = @()
    $results | ForEach-Object {
        $bucket = $_.bucket
        $_.results | ForEach-Object {
            $item = [ordered]@{}
            $item.Name = $_
            $item.Source = $bucket
            $remote_list += [PSCustomObject]$item
        }
    }
    $remote_list
}

$jsonTextAvailable = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-object { [System.IO.Path]::GetFileNameWithoutExtension($_.Location) -eq "System.Text.Json" }

Get-LocalBucket | ForEach-Object {
    if ($jsonTextAvailable) {
        search_bucket $_ $query
    } else {
        search_bucket_legacy $_ $query
    }
}

if ($list.Count -gt 0) {
    Write-Host "Results from local buckets..."
    $list
}

if ($list.Count -eq 0 -and !(github_ratelimit_reached)) {
    $remote_results = search_remotes $query
    if (!$remote_results) {
        warn "No matches found."
        exit 1
    }
    $remote_results
}

exit 0

# SIG # Begin signature block
# MIIFcQYJKoZIhvcNAQcCoIIFYjCCBV4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCd4PWPEKh7ElrA
# 3fg9SQNZZ3vTNSaRz1qn0NSe7vFxFqCCAvIwggLuMIIB1qADAgECAhBRXjN43tOe
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
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPqHxihxowg8AhQ5UB2F
# 4DFqlUplsWKtofriPIk2Qia2MA0GCSqGSIb3DQEBAQUABIIBAMnV2EnH4x6frDWB
# WPSdp2F1gKar5Se3sN8Hf/0X1BgVwF93XJlK2wmXcR0UNgFTDJZ0JCqzJ5swDv1t
# YTqQI2dk/RC072TbCSgfowoTUR/8S3QJTvIKM26vW+6k/4rj0Pj+NWa9ufBT6u6D
# +KgLWQahZqzoo5H3zU+V/75qYfz1dOcAAnoEjE2XCV2TaP2fQLBo2z0RtTzMrQrR
# tO+QNam4Ay6jDhHSDZfuP0GFhaoD/1zc/cd0HCSgb3DNpWUkk2ghQIxbHTfu12As
# 5ww9kJtLayQko7HfMGmkElDZU0T/wZlQJCns5p7bryHoULgZIEZqvH7Ktzj86RYE
# tmBhT5g=
# SIG # End signature block
