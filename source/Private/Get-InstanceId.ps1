<#
    .SYNOPSIS
        Returns the SQL Server instance id of the specified service type and instance
        name.

    .DESCRIPTION
        Returns the SQL Server instance id of the specified service type and instance
        name.

    .PARAMETER ServiceType
        Specifies one supported normalized service type for which to return the
        instance id.

    .PARAMETER InstanceName
       Specifies the instance name for which to return the instance id.

    .EXAMPLE
        Get-InstanceId -ServiceType 'DatabaseEngine' -InstanceName 'SQL2022'

        Returns the registry value for the property name 'Version' in the specified
        registry path.
#>
function Get-InstanceId
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet(
            'DatabaseEngine',
            'AnalysisServices',
            'ReportingServices'
        )]
        [System.String]
        $ServiceType,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    switch ($ServiceType)
    {
        'DatabaseEngine'
        {
            $registryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'

            break
        }

        'AnalysisServices'
        {
            $registryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\OLAP'

            break
        }

        'ReportingServices'
        {
            $registryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

            break
        }
    }

    $instanceId = Get-RegistryPropertyValue -Path $registryPath -Name $InstanceName

    return $instanceId
}
