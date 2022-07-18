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

    # TODO: This should call Get-DscProperty instead.

    # Check to see if the property exist and that is it a DSC property.
    $isDscProperty = $InputObject |
        Get-Member -MemberType 'Property' -Name $Name |
        Where-Object -FilterScript {
            $InputObject.GetType().GetMember($_.Name).CustomAttributes.Where(
                {
                    $_.AttributeType.Name -eq 'DscPropertyAttribute'
                }
            )
        }

    if ($isDscProperty)
    {
        $hasProperty = $true

        if ($HasValue.IsPresent)
        {
            if ($null -eq $InputObject.$Name)
            {
                $hasProperty = $false
            }
        }
    }

    return $hasProperty
}
