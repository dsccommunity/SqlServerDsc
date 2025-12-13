<#
    .SYNOPSIS
        Tests whether a specific SQL Server component is installed.

    .DESCRIPTION
        Tests whether a specific SQL Server component is installed on the system.
        This command provides a generic way to check for component installations
        by specifying the component type. This command replaces the individual
        component-specific test commands (Test-SqlDscIsBackwardCompatibilityComponentsInstalled,
        Test-SqlDscIsBooksOnlineInstalled, etc.) by consolidating their logic into
        a single, flexible command.

    .PARAMETER Component
       Specifies one or more SQL Server components to check for installation.

    .PARAMETER Version
       Specifies the version for which to check if the component is installed.
       Optional for version-based components.

    .PARAMETER InstanceId
       Specifies the instance ID for which to check if the component is installed.
       Required for instance-based components: DataQualityServer, Replication,
       ROpenRPackages, and RServices.

    .OUTPUTS
        [System.Boolean]

        Returns $true if the specified component is installed, $false otherwise.

    .EXAMPLE
        Test-SqlDscIsInstalledComponent -Component IntegrationServices -Version ([System.Version] '16.0')

        Returns $true if Integration Services version 16.0 are installed.

    .EXAMPLE
        Test-SqlDscIsInstalledComponent -Component IntegrationServices

        Returns $true if any version of Integration Services is installed.

    .EXAMPLE
        Test-SqlDscIsInstalledComponent -Component IntegrationServices, ManagementStudio

        Returns $true if any version of Integration Services or Management Studio is installed.

    .EXAMPLE
        Test-SqlDscIsInstalledComponent -Component Replication -InstanceId 'MSSQL16.SQL2022'

        Returns $true if Replication is installed for the specified instance.

    .EXAMPLE
        Test-SqlDscIsInstalledComponent -Component BooksOnline -Version ([System.Version] '15.0')

        Returns $true if SQL Server Books Online version 15.0 is installed.

    .EXAMPLE
        Test-SqlDscIsInstalledComponent -Component ManagementStudio -Version ([System.Version] '12.0')

        Returns $true if SQL Server Management Studio 2014 (version 12.0) is installed.
#>
function Test-SqlDscIsInstalledComponent
{
    [CmdletBinding(DefaultParameterSetName = 'ByComponent')]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [SqlServerComponent[]]
        $Component,

        [Parameter(ParameterSetName = 'ByComponent')]
        [Parameter(ParameterSetName = 'ByVersion')]
        [System.Version]
        $Version,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByInstanceId')]
        [System.String]
        $InstanceId
    )

    $getInstalledComponentParameters = @{
        Component = $Component
    }

    if ($Version)
    {
        $getInstalledComponentParameters['Version'] = $Version
    }

    if ($InstanceId)
    {
        $getInstalledComponentParameters['InstanceId'] = $InstanceId
    }

    $installedComponents = Get-SqlDscInstalledComponent @getInstalledComponentParameters

    return ($installedComponents.Count -gt 0)
}
