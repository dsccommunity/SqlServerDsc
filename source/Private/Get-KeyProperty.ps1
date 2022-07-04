
<#
    .SYNOPSIS
        Returns the DSC resource key property and its value.

    .DESCRIPTION
        Returns the DSC resource key property and its value.

    .PARAMETER InputObject
        The object that contain the key property.

    .OUTPUTS
        Hashtable
#>
function Get-KeyProperty
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject
    )

    # Get all key properties.
    $keyProperty = $InputObject |
        Get-Member -MemberType 'Property' |
        Select-Object -ExpandProperty 'Name' |
        Where-Object -FilterScript {
            $InputObject.GetType().GetMember($_).CustomAttributes.Where(
                {
                    $_.AttributeType.Name -eq 'DscPropertyAttribute' -and
                    $_.NamedArguments.MemberName -eq 'Key'
                }
            ).NamedArguments.TypedValue.Value -eq $true
        }

    # Return a hashtable containing each key property and its value.
    $getKeyPropertyResult = @{}

    $keyProperty | ForEach-Object -Process {
        $getKeyPropertyResult.$_ = $InputObject.$_
    }

    return $getKeyPropertyResult
}
