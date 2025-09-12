<#
    .SYNOPSIS
        Converts a hashtable of bound parameters into a formatted string for ShouldProcess descriptions.

    .DESCRIPTION
        This function takes a hashtable of bound parameters and formats them into a readable string
        for use in ShouldProcess verbose descriptions. It excludes non-settable parameters and
        formats each parameter as 'ParameterName: Value'.

    .PARAMETER BoundParameters
        Hashtable of bound parameters (typically $PSBoundParameters).

    .PARAMETER Exclude
        Array of parameter names to exclude from the formatted output.

    .OUTPUTS
        System.String

        Returns a formatted string with parameters and their values.

    .EXAMPLE
        $formattedText = ConvertTo-FormattedParameterDescription -BoundParameters $PSBoundParameters -Exclude @('ServerObject', 'Name', 'Force')

        Returns a formatted string like:
        "
            EmailAddress: 'admin@company.com'
            CategoryName: 'Notifications'
        "
#>
function ConvertTo-FormattedParameterDescription
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $BoundParameters,

        [Parameter()]
        [System.String[]]
        $Exclude = @()
    )

    $parameterDescriptions = @()

    foreach ($parameter in ($BoundParameters.Keys | Sort-Object))
    {
        if ($parameter -notin $Exclude)
        {
            $raw = $BoundParameters[$parameter]

            $value = if ($raw -is [System.Security.SecureString])
            {
                '***'
            }
            elseif ($raw -is [System.Management.Automation.PSCredential])
            {
                $raw.UserName
            }
            elseif ($raw -is [System.Array])
            {
                ($raw -join ', ')
            }
            else
            {
                $raw
            }

            $parameterDescriptions += "$parameter`: '$value'"
        }
    }

    if ($parameterDescriptions.Count -gt 0)
    {
        return "`r`n    " + ($parameterDescriptions -join "`r`n    ")
    }
    else
    {
        return " $($script:localizedData.ConvertTo_FormattedParameterDescription_NoParametersToUpdate)"
    }
}
