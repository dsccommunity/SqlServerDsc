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

    foreach ($parameter in $BoundParameters.Keys)
    {
        if ($parameter -notin $Exclude)
        {
            $value = $BoundParameters[$parameter]
            $parameterDescriptions += "$parameter`: '$value'"
        }
    }

    if ($parameterDescriptions.Count -gt 0)
    {
        return "`r`n    " + ($parameterDescriptions -join "`r`n    ")
    }
    else
    {
        return " (no parameters to update)"
    }
}
