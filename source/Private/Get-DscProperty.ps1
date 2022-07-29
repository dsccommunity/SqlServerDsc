
<#
    .SYNOPSIS
        Returns DSC resource properties that is part of a class-based DSC resource.

    .DESCRIPTION
        Returns DSC resource properties that is part of a class-based DSC resource.
        The properties can be filtered using name, type, or has been assigned a value.

    .PARAMETER InputObject
        The object that contain one or more key properties.

    .PARAMETER Name
        Specifies one or more property names to return. If left out all properties
        are returned.

    .PARAMETER Type
        Specifies one or more property types to return. If left out all property
        types are returned.

    .PARAMETER HasValue
        Specifies to return only properties that has been assigned a non-null value.
        If left out all properties are returned regardless if there is a value
        assigned or not.

    .EXAMPLE
        Get-DscProperty -InputObject $this

        Returns all DSC resource properties of the DSC resource.

    .EXAMPLE
        Get-DscProperty -InputObject $this -Name @('MyProperty1', 'MyProperty2')

        Returns the specified DSC resource properties names of the DSC resource.

    .EXAMPLE
        Get-DscProperty -InputObject $this -Type @('Mandatory', 'Optional')

        Returns the specified DSC resource property types of the DSC resource.

    .EXAMPLE
        Get-DscProperty -InputObject $this -Type @('Optional') -HasValue

        Returns the specified DSC resource property types of the DSC resource,
        but only those properties that has been assigned a non-null value.

    .OUTPUTS
        [System.Collections.Hashtable]
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
            $isAssigned = Test-ResourceDscPropertyIsAssigned -Name $currentProperty -InputObject $InputObject

            if (-not $isAssigned)
            {
                continue
            }
        }

        $getPropertyResult.$currentProperty = $InputObject.$currentProperty
    }

    return $getPropertyResult
}
