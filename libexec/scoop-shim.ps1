# Usage: scoop shim <subcommand> [<shim_name>...] [options] [other_args]
# Summary: Manipulate Scoop shims
# Help: Available subcommands: add, rm, list, info, alter.
#
# To add a custom shim, use the 'add' subcommand:
#
#     scoop shim add <shim_name> <command_path> [<args>...]
#
# To remove shims, use the 'rm' subcommand: (CAUTION: this could remove shims added by an app manifest)
#
#     scoop shim rm <shim_name> [<shim_name>...]
#
# To list all shims or matching shims, use the 'list' subcommand:
#
#     scoop shim list [<shim_name>/<pattern>...]
#
# To show a shim's information, use the 'info' subcommand:
#
#     scoop shim info <shim_name>
#
# To alternate a shim's target source, use the 'alter' subcommand:
#
#     scoop shim alter <shim_name>
#
# Options:
#   -g, --global       Manipulate global shim(s)
#
# HINT: The FIRST double-hyphen '--', if any, will be treated as the POSIX-style command option terminator
# and will NOT be included in arguments, so if you want to pass arguments like '-g' or '--global' to
# the shim, put them after a '--'. Note that in PowerShell, you must use a QUOTED '--', e.g.,
#
#     scoop shim add myapp 'D:\path\myapp.exe' '--' myapp_args --global

param($SubCommand)

. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\install.ps1" # for rm_shim

if ($SubCommand -notin @('add', 'rm', 'list', 'info', 'alter')) {
    if (!$SubCommand) {
        error '<subcommand> missing'
    } else {
        error "'$SubCommand' is not one of available subcommands: add, rm, list, info, alter"
    }
    my_usage
    exit 1
}

$opt, $other, $err = getopt $Args 'g' 'global'
if ($err) { "scoop shim: $err"; exit 1 }

$global = $opt.g -or $opt.global

if ($SubCommand -ne 'list' -and $other.Length -eq 0) {
    error "<shim_name> must be specified for subcommand '$SubCommand'"
    my_usage
    exit 1
}

if (-not (Get-FormatData ScoopShims)) {
    Update-FormatData "$PSScriptRoot\..\supporting\formats\ScoopTypes.Format.ps1xml"
}

$localShimDir = shimdir $false
$globalShimDir = shimdir $true

function Get-ShimInfo($ShimPath) {
    $info = [Ordered]@{}
    $info.Name = strip_ext (fname $ShimPath)
    $info.Path = $ShimPath -replace 'shim$', 'exe'
    $info.Source = (get_app_name_from_shim $ShimPath) -replace '^$', 'External'
    $info.Type = if ($ShimPath.EndsWith('.ps1')) { 'ExternalScript' } else { 'Application' }
    $altShims = Get-Item -Path "$ShimPath.*" -Exclude '*.shim', '*.cmd', '*.ps1'
    if ($altShims) {
        $info.Alternatives = (@($info.Source) + ($altShims | ForEach-Object { $_.Extension.Remove(0, 1) } | Select-Object -Unique)) -join ' '
    }
    $info.IsGlobal = $ShimPath.StartsWith("$globalShimDir")
    $info.IsHidden = !((Get-Command -Name $info.Name).Path -eq $info.Path)
    [PSCustomObject]$info
}

function Get-ShimPath($ShimName, $Global) {
    '.shim', '.ps1' | ForEach-Object {
        $shimPath = Join-Path (shimdir $Global) "$ShimName$_"
        if (Test-Path $shimPath) {
            return $shimPath
        }
    }
}

switch ($SubCommand) {
    'add' {
        if ($other.Length -lt 2 -or $other[1] -eq '') {
            error "<command_path> must be specified for subcommand 'add'"
            my_usage
            exit 1
        }
        $shimName = $other[0]
        $commandPath = $other[1]
        if ($other.Length -gt 2) {
            $commandArgs = $other[2..($other.Length - 1)]
        }
        if ($commandPath -notmatch '[\\/]') {
            $shortPath = $commandPath
            $commandPath = Get-ShimTarget (Get-ShimPath $shortPath $global)
            if (!$commandPath) {
                $exCommand = Get-Command $shortPath -ErrorAction SilentlyContinue
                if ($exCommand -and $exCommand.CommandType -eq 'Application') {
                    $commandPath = $exCommand.Path
                } # TODO - add support for more command types: Alias, Cmdlet, ExternalScript, Filter, Function, Script, and Workflow
            }
        }
        if ($commandPath -and (Test-Path $commandPath)) {
            Write-Host "Adding $(if ($global) { 'global' } else { 'local' }) shim " -NoNewline
            Write-Host $shimName -ForegroundColor Cyan -NoNewline
            Write-Host '...'
            shim $commandPath $global $shimName $commandArgs
        } else {
            Write-Host "ERROR: Command path does not exist: " -ForegroundColor Red -NoNewline
            Write-Host $($other[1]) -ForegroundColor Cyan
            exit 3
        }
    }
    'rm' {
        $failed = @()
        $other | ForEach-Object {
            if (Get-ShimPath $_ $global) {
                rm_shim $_ (shimdir $global)
            } else {
                $failed += $_
            }
        }
        if ($failed) {
            $failed | ForEach-Object {
                Write-Host "ERROR: $(if ($global) { 'Global' } else {'Local' }) shim not found: " -ForegroundColor Red -NoNewline
                Write-Host $_ -ForegroundColor Cyan
            }
            exit 3
        }
    }
    'list' {
        $other = @($other) -ne '*'
        # Validate all given patterns before matching.
        $other | ForEach-Object {
            try {
                $pattern = $_
                [Regex]::New($pattern)
            } catch {
                Write-Host "ERROR: Invalid pattern: " -ForegroundColor Red -NoNewline
                Write-Host $pattern -ForegroundColor Magenta
                exit 1
            }
        }
        $pattern = $other -join '|'
        $shims = @()
        if (!$global) {
            $shims += Get-ChildItem -Path $localShimDir -Recurse -Include '*.shim', '*.ps1' |
                Where-Object { !$pattern -or ($_.BaseName -match $pattern) } |
                Select-Object -ExpandProperty FullName
        }
        if (Test-Path $globalShimDir) {
            $shims += Get-ChildItem -Path $globalShimDir -Recurse -Include '*.shim', '*.ps1' |
                Where-Object { !$pattern -or ($_.BaseName -match $pattern) } |
                Select-Object -ExpandProperty FullName
        }
        $shims.ForEach({ Get-ShimInfo $_ }) | Add-Member -TypeName 'ScoopShims' -PassThru
    }
    'info' {
        $shimName = $other[0]
        $shimPath = Get-ShimPath $shimName $global
        if ($shimPath) {
            Get-ShimInfo $shimPath
        } else {
            Write-Host "ERROR: $(if ($global) { 'Global' } else { 'Local' }) shim not found: " -ForegroundColor Red -NoNewline
            Write-Host $shimName -ForegroundColor Cyan
            if (Get-ShimPath $shimName (!$global)) {
                Write-Host "But a $(if ($global) { 'local' } else {'global' }) shim exists, " -NoNewline
                Write-Host "run 'scoop shim info $shimName$(if (!$global) { ' --global' })' to show its info"
                exit 2
            }
            exit 3
        }
    }
    'alter' {
        $shimName = $other[0]
        $shimPath = Get-ShimPath $shimName $global
        if ($shimPath) {
            $shimInfo = Get-ShimInfo $shimPath
            if ($null -eq $shimInfo.Alternatives) {
                Write-Host 'ERROR: No alternatives of ' -ForegroundColor Red -NoNewline
                Write-Host $shimName -ForegroundColor Cyan -NoNewline
                Write-Host ' found.' -ForegroundColor Red
                exit 2
            }
            $shimInfo.Alternatives = $shimInfo.Alternatives.Split(' ')
            [System.Management.Automation.Host.ChoiceDescription[]]$altApps = 1..$shimInfo.Alternatives.Length | ForEach-Object {
                New-Object System.Management.Automation.Host.ChoiceDescription "&$($_)`b$($shimInfo.Alternatives[$_ - 1])", "Sets '$shimName' shim from $($shimInfo.Alternatives[$_ - 1])."
            }
            $selected = $Host.UI.PromptForChoice("Alternatives of '$shimName' command", "Please choose one that provides '$shimName' as default:", $altApps, 0)
            if ($selected -eq 0) {
                Write-Host 'INFO: ' -ForegroundColor Blue -NoNewline
                Write-Host $shimName -ForegroundColor Cyan -NoNewline
                Write-Host ' is already from ' -NoNewline
                Write-Host $shimInfo.Source -ForegroundColor DarkYellow -NoNewline
                Write-Host ', nothing changed.'
            } else {
                $newApp = $shimInfo.Alternatives[$selected]
                Write-Host 'Use ' -NoNewline
                Write-Host $shimName -ForegroundColor Cyan -NoNewline
                Write-Host ' from ' -NoNewline
                Write-Host $newApp -ForegroundColor DarkYellow -NoNewline
                Write-Host ' as default...' -NoNewline
                $pathNoExt = strip_ext $shimPath
                '', '.shim', '.cmd', '.ps1' | ForEach-Object {
                    $oldShimPath = "$pathNoExt$_"
                    $newShimPath = "$oldShimPath.$newApp"
                    if (Test-Path -Path $oldShimPath -PathType Leaf) {
                        Rename-Item -Path $oldShimPath -NewName "$oldShimPath.$($shimInfo.Source)" -Force
                        if (Test-Path -Path $newShimPath -PathType Leaf) {
                            Rename-Item -Path $newShimPath -NewName $oldShimPath -Force
                        }
                    }
                }
                Write-Host 'done.'
            }
        } else {
            Write-Host "ERROR: $(if ($global) { 'Global' } else { 'Local' }) shim not found: " -ForegroundColor Red -NoNewline
            Write-Host $shimName -ForegroundColor Cyan
            if (Get-ShimPath $shimName (!$global)) {
                Write-Host "But a $(if ($global) { 'local' } else {'global' }) shim exists, " -NoNewline
                Write-Host "run 'scoop shim alter $shimName$(if (!$global) { ' --global' })' to alternate its source"
                exit 2
            }
            exit 3
        }
    }
}

exit 0

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9SLCgd93FXgHY8sEXw5Otwpy
# 5dSgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUhuFC389pKrMO1VuPghv2wV7IWaEwDQYJKoZIhvcNAQEBBQAEggEA
# FuccsrD10OkhEfp45vL6qxKIqHzH4I7eMtaMu3lpOOMLnUi61xMCB4oLK8y3bB8C
# IYfIb9I+kQF9F7xUF4bnaqHJh3cviHt/2E5E1zqDGaHrFtC6JmRHz7RWXi/+Lrmc
# Tr6HW7aXB+ar/mR37Fx5LvYn1iVizKniSKsIdjPtZf5UQda3FTKoRfJn6FAOYdUH
# X0sPjUSvtGeZk/OfWWJfQjXvYDasQ71NY5Wx/YBUyYuXLyKsNl9Sl3xTVZ7ADe5p
# ZKhdV3dq/hf43xSURtHVcV1A2zZW3ocMk324cMx+T881TtL8Qq8ZT+2a2qzEtz4m
# w/RmGnIroo3/yrVqmE0mfA==
# SIG # End signature block
