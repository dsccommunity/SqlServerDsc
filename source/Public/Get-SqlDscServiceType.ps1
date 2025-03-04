<#
    .SYNOPSIS
        Returns all the registered service types.

    .DESCRIPTION
        Returns all the registered service types.

    .OUTPUTS
        `[System.Object[]]`

    .EXAMPLE
        Get-SqlDscServiceType

        Returns all service types.
#>
function Get-SqlDscServiceType
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param ()

    $registeredServiceTypes = @()

    $registeredServiceType = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services'

    foreach ($currentServiceType in $registeredServiceType)
    {
        $foundServiceType = [PSCustomObject]@{
            DisplayName = $currentServiceType.PSChildName
        }

        $properties = $currentServiceType.GetValueNames()

        foreach ($property in $properties)
        {
            $foundServiceType |
                Add-Member -MemberType 'NoteProperty' -Name $property -Value $currentServiceType.GetValue($property)
        }

        $managedServiceType = [Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType]::Parse([Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType], $currentServiceType.GetValue('Type'))

        $foundServiceType |
            Add-Member -MemberType 'NoteProperty' -Name 'ManagedServiceType' -Value $managedServiceType

            $foundServiceType |
                Add-Member -MemberType 'NoteProperty' -Name 'NormalizedServiceType' -Value (
                    ConvertFrom-ManagedServiceType -ServiceType $managedServiceType -ErrorAction 'SilentlyContinue'
                )

        $registeredServiceTypes += $foundServiceType
    }

    return $registeredServiceTypes
}
