
<#
    .SYNOPSIS
        Returns all of the DSC resource key properties and their values.

    .DESCRIPTION
        Returns all of the DSC resource key properties and their values.

    .PARAMETER InputObject
        The object that contain one or more key properties.

    .OUTPUTS
        Hashtable
#>
function Get-DscProperty
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject,

        [Parameter()]
        [System.String[]]
        $Name,

        [Parameter()]
        [ValidateSet('Key', 'Mandatory', 'NotConfigurable', 'Optional')]
        [System.String[]]
        $Type,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $HasValue
    )

    $property = $InputObject.PSObject.Properties.Name |
        Where-Object -FilterScript {
            <#
                Return all properties if $Name is not assigned, or if assigned
                just those properties.
            #>
            (-not $Name -or $_ -in $Name) -and

            # Only return the property if it is a DSC property.
            $InputObject.GetType().GetMember($_).CustomAttributes.Where(
                {
                    $_.AttributeType.Name -eq 'DscPropertyAttribute'
                }
            )
        }

    if (-not [System.String]::IsNullOrEmpty($property))
    {
        if ($PSBoundParameters.ContainsKey('Type'))
        {
            $propertiesOfType = @()

            $propertiesOfType += $property | Where-Object -FilterScript {
                $InputObject.GetType().GetMember($_).CustomAttributes.Where(
                    {
                        <#
                            To simplify the code, ignoring that this will compare
                            MemberNAme against type 'Optional' which does not exist.
                        #>
                        $_.NamedArguments.MemberName -in $Type
                    }
                ).NamedArguments.TypedValue.Value -eq $true
            }

            # Include all optional parameter if it was requested.
            if ($Type -contains 'Optional')
            {
                $propertiesOfType += $property | Where-Object -FilterScript {
                    $InputObject.GetType().GetMember($_).CustomAttributes.Where(
                        {
                            $_.NamedArguments.MemberName -notin @('Key', 'Mandatory', 'NotConfigurable')
                        }
                    )
                }
            }

            $property = $propertiesOfType
        }
    }

    # Return a hashtable containing each key property and its value.
    $getPropertyResult = @{}

    foreach ($currentProperty in $property)
    {
        if ($HasValue.IsPresent)
        {
            $isAssigned = Test-ResourcePropertyIsAssigned -Name $currentProperty -InputObject $InputObject

            if (-not $isAssigned)
            {
                continue
            }
        }

        $getPropertyResult.$currentProperty = $InputObject.$currentProperty
    }

    return $getPropertyResult
}
