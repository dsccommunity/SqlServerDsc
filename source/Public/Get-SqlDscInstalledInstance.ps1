<#
    .SYNOPSIS
        Returns the installed instances on the current node.

    .DESCRIPTION
        Returns the installed instances on the current node.

    .PARAMETER InstanceName
       Specifies the instance name to return instances for.

    .PARAMETER ServiceType
        Specifies the service type to filter instances by. Valid values are
        'DatabaseEngine', 'AnalysisServices', and 'ReportingServices'.

    .OUTPUTS
        `[System.Object[]]`

    .EXAMPLE
        Get-SqlDscInstalledInstance

        Returns all installed instances.
#>
function Get-SqlDscInstalledInstance
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('DatabaseEngine', 'AnalysisServices', 'ReportingServices')]
        [System.String[]]
        $ServiceType
    )

    $ErrorActionPreference = 'Stop'

    if ($PSBoundParameters.ContainsKey('InstanceName'))
    {
        $InstanceName = $InstanceName.ToUpper()
    }

    $instances = @()

    $installedServiceType = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names' -ErrorAction 'SilentlyContinue'

    foreach ($currentServiceType in $installedServiceType)
    {
        $serviceTypeName = switch ($currentServiceType.PSChildName)
        {
            'OLAP'
            {
                'AnalysisServices'

                break
            }

            'SQL'
            {
                'DatabaseEngine'

                break
            }

           'RS'
            {
                'ReportingServices'

                break
            }
        }

        if ($PSBoundParameters.ContainsKey('ServiceType') -and $serviceTypeName -notin $ServiceType)
        {
            continue
        }

        $instanceNames = $currentServiceType.GetValueNames()

        foreach ($currentInstanceName in $instanceNames)
        {
            if ($PSBoundParameters.ContainsKey('InstanceName') -and $currentInstanceName -ne $InstanceName)
            {
                continue
            }

            $foundInstance = [PSCustomObject] @{
                ServiceType = $serviceTypeName
                InstanceName = $currentInstanceName
                InstanceId = $currentServiceType.GetValue($currentInstanceName)
            }

            $instances += $foundInstance
        }
    }

    return $instances
}
