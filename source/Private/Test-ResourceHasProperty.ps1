<#
    .SYNOPSIS
        Tests wether the class-based resource has the specified property.

    .DESCRIPTION
        Tests wether the class-based resource has the specified property.

    .PARAMETER InputObject
        Specifies the object that should be tested for existens of the specified
        property.

    .PARAMETER Name
        Specifies the name of the property.

    .PARAMETER HasValue
        Specifies if the property should be evaluated to have a non-value. If
        the property exist but is assigned `$null` the command returns `$false`.

    .OUTPUTS
        [Boolean]
#>
function Test-ResourceHasProperty
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $HasValue
    )

    $hasProperty = $false

    $isDscProperty = (Get-DscProperty @PSBoundParameters).ContainsKey($Name)

    if ($isDscProperty)
    {
        $hasProperty = $true
    }

    return $hasProperty
}
