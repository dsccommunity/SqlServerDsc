<#
    .SYNOPSIS
        Returns whether the component Data Quality Server is installed.

    .DESCRIPTION
        Returns whether the component Data Quality Server is installed.

    .PARAMETER InstanceId
       Specifies the instance id on which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsDataQualityServerInstalled -InstanceId 'MSSQL16.SQL2022'

        Returns $true if Data Quality Server is installed.
#>
function Test-SqlDscIsDataQualityServerInstalled
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
        Name        = 'SQL_DQ_Full'
        ErrorAction = 'SilentlyContinue'
    }

    $isDataQualityServerInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isDataQualityServerInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
