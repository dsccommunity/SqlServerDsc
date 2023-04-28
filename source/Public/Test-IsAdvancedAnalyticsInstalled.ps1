<#
    .SYNOPSIS
        Returns whether the component Advanced Analytics is installed.

    .DESCRIPTION
        Returns whether the component Advanced Analytics is installed.

    .PARAMETER InstanceId
       Specifies the instance id on which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-IsReplicationInstalled -InstanceId 'MSSQL16.SQL2022'

        Returns $true if Advanced Analytics is installed.
#>
function Test-IsAdvancedAnalyticsInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceId
    )

    $configurationStateRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\ConfigurationState'

    $getRegistryPropertyValueParameters = @{
        Path        = $configurationStateRegistryPath -f $InstanceId
        Name        = 'AdvancedAnalytics'
        ErrorAction = 'SilentlyContinue'
    }

    $isAdvancedAnalyticsInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isAdvancedAnalyticsInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
