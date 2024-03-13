<#
    .SYNOPSIS
        Returns whether the component R Services (In-Database) are installed.

    .DESCRIPTION
        Returns whether the component R Services (In-Database) is installed.

    .PARAMETER InstanceId
       Specifies the instance id on which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-IsRServicesInstalled -InstanceId 'MSSQL16.SQL2022'

        Returns $true if R Services (In-Database) is installed.
#>
function Test-SqlDscIsRServicesInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
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
