
<#
    .SYNOPSIS
        Returns the properties that should be enforced for the desired state.

    .DESCRIPTION
        Returns the properties that should be enforced for the desired state.
        This function converts a PSObject into a hashtable containing the properties
        that should be enforced.

    .PARAMETER InputObject
        The object that contain the properties with the desired state.

    .OUTPUTS
        Hashtable
#>
function Get-DesiredStateProperty
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject
    )

    $desiredStateProperty = $InputObject | ConvertFrom-DscResourceInstance

    <#
        Remove properties that have $null as the value, and remove read
        properties so that there is no chance to compare those.
    #>
    @($desiredStateProperty.Keys) | ForEach-Object -Process {
        $isReadProperty = $InputObject.GetType().GetMember($_).CustomAttributes.Where( { $_.NamedArguments.MemberName -eq 'NotConfigurable' }).NamedArguments.TypedValue.Value -eq $true

        if ($isReadProperty -or $null -eq $desiredStateProperty[$_])
        {
            $desiredStateProperty.Remove($_)
        }
    }

    return $desiredStateProperty
}
