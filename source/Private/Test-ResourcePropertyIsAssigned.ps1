<#
    .SYNOPSIS
        Tests wether the class-based resource property is assigned a non-null value.

    .DESCRIPTION
        Tests wether the class-based resource property is assigned a non-null value.

    .PARAMETER InputObject
        Specifies the object that contain the property.

    .PARAMETER Name
        Specifies the name of the property.

    .OUTPUTS
        [Boolean]
#>
function Test-ResourcePropertyIsAssigned
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
        $Name
    )

    $isAssigned = -not ($null -eq $InputObject.$Name)

    return $isAssigned
}
