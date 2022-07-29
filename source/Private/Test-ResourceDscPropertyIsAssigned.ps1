<#
    .SYNOPSIS
        Tests whether the class-based resource property is assigned a non-null value.

    .DESCRIPTION
        Tests whether the class-based resource property is assigned a non-null value.

    .PARAMETER InputObject
        Specifies the object that contain the property.

    .PARAMETER Name
        Specifies the name of the property.

    .EXAMPLE
        Test-ResourceDscPropertyIsAssigned -InputObject $this -Name 'MyDscProperty'

        Returns $true or $false whether the property is assigned or not.

    .OUTPUTS
        [System.Boolean]
#>
function Test-ResourceDscPropertyIsAssigned
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
