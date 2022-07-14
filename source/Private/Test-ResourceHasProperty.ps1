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
        $Name
    )

    $hasEnsure = $false

    # Check to see if the property exist and that is it a DSC property.
    $ensureProperty = $InputObject |
        Get-Member -MemberType 'Property' -Name $Name |
        Where-Object -FilterScript {
            $InputObject.GetType().GetMember($_.Name).CustomAttributes.Where(
                {
                    $_.AttributeType.Name -eq 'DscPropertyAttribute'
                }
            )
        }

    if ($ensureProperty)
    {
        $hasEnsure = $true
    }

    return $hasEnsure
}
