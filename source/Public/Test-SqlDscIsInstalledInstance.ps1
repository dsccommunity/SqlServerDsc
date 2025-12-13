<#
    .SYNOPSIS
        Tests whether an instance is installed.

    .DESCRIPTION
        Tests whether an instance is installed on the current node.

    .PARAMETER InstanceName
       Specifies the instance name to test for.

    .PARAMETER ServiceType
        Specifies the service type to filter instances by. Valid values are
        'DatabaseEngine', 'AnalysisServices', and 'ReportingServices'.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsInstalledInstance -InstanceName 'MSSQLSERVER'

        Returns $true if the default instance MSSQLSERVER is installed.

    .EXAMPLE
        Test-SqlDscIsInstalledInstance -InstanceName 'MSSQLSERVER' -ServiceType 'DatabaseEngine'

        Returns $true if the default instance MSSQLSERVER with DatabaseEngine service type is installed.

    .EXAMPLE
        Test-SqlDscIsInstalledInstance -ServiceType 'DatabaseEngine'

        Returns $true if any DatabaseEngine instance is installed.
#>
function Test-SqlDscIsInstalledInstance
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('DatabaseEngine', 'AnalysisServices', 'ReportingServices')]
        [System.String[]]
        $ServiceType
    )

    $getSqlDscInstalledInstanceParameters = @{}

    if ($PSBoundParameters.ContainsKey('InstanceName'))
    {
        $getSqlDscInstalledInstanceParameters.InstanceName = $InstanceName
    }

    if ($PSBoundParameters.ContainsKey('ServiceType'))
    {
        $getSqlDscInstalledInstanceParameters.ServiceType = $ServiceType
    }

    $installedInstances = Get-SqlDscInstalledInstance @getSqlDscInstalledInstanceParameters -ErrorAction 'SilentlyContinue'

    return ($null -ne $installedInstances -and $installedInstances.Count -gt 0)
}
