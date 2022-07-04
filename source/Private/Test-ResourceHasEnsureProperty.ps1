<#
    .SYNOPSIS
        Tests wether the class-based resource has an Ensure property.

    .DESCRIPTION
        Tests wether the class-based resource has an Ensure property.

    .PARAMETER InputObject
        The object that should be tested for existens of property Ensure.

    .OUTPUTS
        [Boolean]
#>
function Test-ResourceHasEnsureProperty
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject
    )

    $hasEnsure = $false

    # Get all key properties.
    $ensureProperty = $InputObject |
        Get-Member -MemberType 'Property' -Name 'Ensure' |
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
