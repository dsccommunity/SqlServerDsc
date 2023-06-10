<#
    .SYNOPSIS
        Returns whether the Master Data Services are installed.

    .DESCRIPTION
        Returns whether the Master Data Services are installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .PARAMETER InstanceName
       Specifies the instance name on which to check if component is installed.

    .PARAMETER InstanceId
       Specifies the instance id on which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsDatabaseEngineInstalled -Version ([System.Version] '16.0')

        Returns $true if Database Engine with version 16 is installed.

    .NOTES
        The parameters are all mutually exclusive.
#>
function Test-SqlDscIsDatabaseEngineInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.Version]
        $Version,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceId
    )

    $commandParameter = (Remove-CommonParameter -Hashtable $PSCmdlet.MyInvocation.MyCommand.Parameters).Keys

    foreach ($currentParameterName in $commandParameter)
    {
        $assertBoundParameterParameters = @{
            BoundParameterList = $PSBoundParameters
            MutuallyExclusiveList1 = $currentParameterName
            MutuallyExclusiveList2 = @([System.String[]] $commandParameter.Where({ $_ -ne $currentParameterName }))
        }

        Assert-BoundParameter @assertBoundParameterParameters
    }

    $getSqlDscInstalledInstanceParameters = @{
        ServiceType = 'DatabaseEngine'
    }

    $installedInstances = Get-SqlDscInstalledInstance @getSqlDscInstalledInstanceParameters -ErrorAction 'SilentlyContinue'

    $result = $false

    if ($PSBoundParameters.ContainsKey('InstanceId'))
    {
        $result = $installedInstances.InstanceId -contains $InstanceId
    }
    elseif ($PSBoundParameters.ContainsKey('InstanceName'))
    {
        $result = $installedInstances.InstanceName -contains $InstanceName
    }
    elseif ($PSBoundParameters.ContainsKey('Version'))
    {
        $result = ($installedInstances.InstanceId | Get-SqlDscDatabaseEngineInstalledSetting).Version.Major -contains $Version.Major
    }

    return $result
}
