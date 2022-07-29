<#
    .SYNOPSIS
        Tests whether the class-based resource has the specified property.

    .DESCRIPTION
        Tests whether the class-based resource has the specified property.

    .PARAMETER InputObject
        Specifies the object that should be tested for existens of the specified
        property.

    .PARAMETER Name
        Specifies the name of the property.

    .PARAMETER HasValue
        Specifies if the property should be evaluated to have a non-value. If
        the property exist but is assigned `$null` the command returns `$false`.

    .EXAMPLE
        Test-ResourceHasDscProperty -InputObject $this -Name 'MyDscProperty'

        Returns $true or $false whether the property exist or not.

    .EXAMPLE
        Test-ResourceHasDscProperty -InputObject $this -Name 'MyDscProperty' -HasValue

        Returns $true if the property exist and is assigned a non-null value, if not
        $false is returned.

    .OUTPUTS
        [System.Boolean]
#>
function Test-ResourceHasDscProperty
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
