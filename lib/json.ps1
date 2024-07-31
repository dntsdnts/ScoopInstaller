# Convert objects to pretty json
# Only needed until PowerShell ConvertTo-Json will be improved https://github.com/PowerShell/PowerShell/issues/2736
# https://github.com/PowerShell/PowerShell/issues/2736 was fixed in pwsh
# Still needed in normal powershell

function ConvertToPrettyJson {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $data
    )

    Process {
        $data = normalize_values $data

        # convert to string
        [String]$json = $data | ConvertTo-Json -Depth 8 -Compress
        [String]$output = ''

        # state
        [String]$buffer = ''
        [Int]$depth = 0
        [Bool]$inString = $false

        # configuration
        [String]$indent = ' ' * 4
        [Bool]$unescapeString = $true
        [String]$eol = "`r`n"

        for ($i = 0; $i -lt $json.Length; $i++) {
            # read current char
            $buffer = $json.Substring($i, 1)

            $objectStart = !$inString -and $buffer.Equals('{')
            $objectEnd = !$inString -and $buffer.Equals('}')
            $arrayStart = !$inString -and $buffer.Equals('[')
            $arrayEnd = !$inString -and $buffer.Equals(']')
            $colon = !$inString -and $buffer.Equals(':')
            $comma = !$inString -and $buffer.Equals(',')
            $quote = $buffer.Equals('"')
            $escape = $buffer.Equals('\')

            if ($quote) {
                $inString = !$inString
            }

            # skip escape sequences
            if ($escape) {
                $buffer = $json.Substring($i, 2)
                ++$i

                # Unescape unicode
                if ($inString -and $unescapeString) {
                    if ($buffer.Equals('\n')) {
                        $buffer = "`n"
                    } elseif ($buffer.Equals('\r')) {
                        $buffer = "`r"
                    } elseif ($buffer.Equals('\t')) {
                        $buffer = "`t"
                    } elseif ($buffer.Equals('\u')) {
                        $buffer = [regex]::Unescape($json.Substring($i - 1, 6))
                        $i += 4
                    }
                }

                $output += $buffer
                continue
            }

            # indent / outdent
            if ($objectStart -or $arrayStart) {
                ++$depth
            } elseif ($objectEnd -or $arrayEnd) {
                --$depth
                $output += $eol + ($indent * $depth)
            }

            # add content
            $output += $buffer

            # add whitespace and newlines after the content
            if ($colon) {
                $output += ' '
            } elseif ($comma -or $arrayStart -or $objectStart) {
                $output += $eol
                $output += $indent * $depth
            }
        }

        return $output
    }
}

function json_path([String] $json, [String] $jsonpath, [Hashtable] $substitutions, [Boolean] $reverse, [Boolean] $single) {
    Add-Type -Path "$PSScriptRoot\..\supporting\validator\bin\Newtonsoft.Json.dll"
    if ($null -ne $substitutions) {
        $jsonpath = substitute $jsonpath $substitutions ($jsonpath -like "*=~*")
    }
    try {
        $settings = New-Object -Type Newtonsoft.Json.JsonSerializerSettings
        $settings.DateParseHandling = [Newtonsoft.Json.DateParseHandling]::None
        $obj = [Newtonsoft.Json.JsonConvert]::DeserializeObject($json, $settings)
    } catch [Newtonsoft.Json.JsonReaderException] {
        return $null
    }
    try {
        $result = $obj.SelectTokens($jsonpath, $true)
        if ($reverse) {
            # Return versions in reverse order
            $result = [System.Linq.Enumerable]::Reverse($result)
        }
        if ([System.Linq.Enumerable]::Count($result) -eq 1 -or $single) {
            # Extract First value
            $result = [System.Linq.Enumerable]::First($result)
            # Convert first value to string
            $result = $result.ToString()
        } else {
            $result = [Newtonsoft.Json.JsonConvert]::SerializeObject($result)
        }
        return $result
    } catch [Exception] {
        Write-Host $_ -ForegroundColor DarkRed
    }

    return $null
}

function json_path_legacy([String] $json, [String] $jsonpath, [Hashtable] $substitutions) {
    $result = $json | ConvertFrom-Json -ea stop
    $isJsonPath = $jsonpath.StartsWith('$')
    $jsonpath.split('.') | ForEach-Object {
        $el = $_

        # substitute the basename and version varibales into the jsonpath
        if ($null -ne $substitutions) {
            $el = substitute $el $substitutions
        }

        # skip $ if it's jsonpath format
        if ($el -eq '$' -and $isJsonPath) {
            return
        }

        # array detection
        if ($el -match '^(?<property>\w+)?\[(?<index>\d+)\]$') {
            $property = $matches['property']
            if ($property) {
                $result = $result.$property[$matches['index']]
            } else {
                $result = $result[$matches['index']]
            }
            return
        }

        $result = $result.$el
    }
    return $result
}

function normalize_values([psobject] $json) {
    # Iterate Through Manifest Properties
    $json.PSObject.Properties | ForEach-Object {
        # Recursively edit psobjects
        # If the values is psobjects, its not normalized
        # For example if manifest have architecture and it's architecture have array with single value it's not formatted.
        # @see https://github.com/ScoopInstaller/Scoop/pull/2642#issue-220506263
        if ($_.Value -is [System.Management.Automation.PSCustomObject]) {
            $_.Value = normalize_values $_.Value
        }

        # Process String Values
        if ($_.Value -is [String]) {

            # Split on new lines
            [Array] $parts = ($_.Value -split '\r?\n').Trim()

            # Replace with string array if result is multiple lines
            if ($parts.Count -gt 1) {
                $_.Value = $parts
            }
        }

        # Convert single value array into string
        if ($_.Value -is [Array]) {
            # Array contains only 1 element String or Array
            if ($_.Value.Count -eq 1) {
                # Array
                if ($_.Value[0] -is [Array]) {
                    $_.Value = $_.Value
                } else {
                    # String
                    $_.Value = $_.Value[0]
                }
            } else {
                # Array of Arrays
                $resulted_arrs = @()
                foreach ($element in $_.Value) {
                    if ($element.Count -eq 1) {
                        $resulted_arrs += $element
                    } else {
                        $resulted_arrs += , $element
                    }
                }

                $_.Value = $resulted_arrs
            }
        }

        # Process other values as needed...
    }

    return $json
}

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2NN01RPNzkG40vMtFpdzFYwL
# h2SgggLyMIIC7jCCAdagAwIBAgIQUV4zeN7Tnr5I+Jfnrr0i6zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQU5WKubE3OEHChFI3PjQEUliP8N6owDQYJKoZIhvcNAQEBBQAEggEA
# ZXa2FgsEJG5T9jp4bTFuC2UKvZPrEEIZxnCdG7X/fxXDVYzQ6HkGdN65j9TSjVYc
# veAJTjurTjRRPaEtgS/El0z3ozTy1aAPZgplpiwbapfuFeBHYW9V+djN3B379OLA
# rMwZ/9sLIu1ZWhzg57cew5SUE5u1ibXSntu0kuy4f4rIQ0mXPQkHHRojcizme5iS
# 73ctm7ksIS9x0KsKhktcRiqNsJbvNbb2Lr8BOTZ7ypyYqBOMlowbfScAHTS8Ugtz
# y3yp7b6U1dBiu6JOcOSJGTeOHTlNRntGELJUAVIukRKYdYd6YaJ0LiepyfZynxjj
# sfbBh7f6Mpzgel2EE2Mnzg==
# SIG # End signature block
