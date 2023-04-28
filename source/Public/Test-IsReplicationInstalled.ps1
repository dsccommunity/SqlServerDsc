<#
    .SYNOPSIS
        Returns whether the component Replication is installed.

    .DESCRIPTION
        Returns whether the component Replication is installed.

    .PARAMETER InstanceId
       Specifies the instance id on which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-IsReplicationInstalled -InstanceId 'MSSQL13.SQL2016'

        Returns $true if Replication is installed.
#>
function Test-IsReplicationInstalled
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
        Name        = 'SQL_Replication_Core_Inst'
        ErrorAction = 'SilentlyContinue'
    }

    $isReplicationInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isReplicationInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
