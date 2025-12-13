<#
    .SYNOPSIS
        Returns installed SQL Server components.

    .DESCRIPTION
        Returns installed SQL Server components on the system. The command discovers
        all installed components by scanning registry keys and returns detailed
        information about each component including version information.

    .PARAMETER Component
       Specifies one or more SQL Server components to retrieve. When omitted, returns
       all installed components.

    .PARAMETER Version
       Specifies the version for which to retrieve components. Only applicable
       for version-based components. When omitted, all installed versions are returned.

    .PARAMETER InstanceId
       Specifies the instance ID for which to retrieve components. Only applicable
       for instance-based components.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject[]]

        Returns an array of objects with the following properties:
        - Component: The component name
        - Version: The component version (for version-based components)
        - InstanceId: The instance ID (for instance-based components)

    .EXAMPLE
        Get-SqlDscInstalledComponent

        Returns all installed SQL Server components on the system.

    .EXAMPLE
        Get-SqlDscInstalledComponent -Component IntegrationServices

        Returns all installed versions of Integration Services.

    .EXAMPLE
        Get-SqlDscInstalledComponent -Component IntegrationServices, ManagementStudio

        Returns all installed versions of Integration Services and Management Studio.

    .EXAMPLE
        Get-SqlDscInstalledComponent -Component IntegrationServices -Version ([System.Version] '16.0')

        Returns Integration Services version 16.0 if installed.

    .EXAMPLE
        Get-SqlDscInstalledComponent -Component Replication -InstanceId 'MSSQL16.SQL2022'

        Returns Replication component for the specified instance if installed.

    .EXAMPLE
        Get-SqlDscInstalledComponent -Component ManagementStudio

        Returns all installed versions of SQL Server Management Studio.
#>
function Get-SqlDscInstalledComponent
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([System.Management.Automation.PSCustomObject[]])]
    param
    (
        [Parameter(ParameterSetName = 'ByComponent', ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ByComponentVersion', ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ByComponentInstanceId', ValueFromPipeline = $true)]
        [SqlServerComponent[]]
        $Component,

        [Parameter(ParameterSetName = 'ByComponentVersion')]
        [System.Version]
        $Version,

        [Parameter(ParameterSetName = 'ByComponentInstanceId')]
        [System.String]
        $InstanceId
    )

    # Component registry configuration lookup table
    $componentConfig = @{
        BackwardCompatibility = @{
            Type         = 'Version'
            RegistryName = 'Tools_Legacy_Full'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\ConfigurationState'
        }
        BooksOnline = @{
            Type         = 'Version'
            RegistryName = 'SQL_BOL_Components'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\ConfigurationState'
        }
        Connectivity = @{
            Type         = 'Version'
            RegistryName = 'Connectivity_Full'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\ConfigurationState'
        }
        DataQualityClient = @{
            Type         = 'Version'
            RegistryName = 'SQL_DQ_CLIENT_Full'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\ConfigurationState'
        }
        DataQualityServer = @{
            Type         = 'InstanceId'
            RegistryName = 'SQL_DQ_Full'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\ConfigurationState'
        }
        IntegrationServices = @{
            Type         = 'Version'
            UseCommand   = 'Get-SqlDscIntegrationServicesInstalledSetting'
        }
        ManagementStudio = @{
            Type = 'UninstallRegistry'
            ProductGuids = @{
                10 = '{72AB7E6F-BC24-481E-8C45-1AB5B3DD795D}'
                11 = '{A7037EB2-F953-4B12-B843-195F4D988DA1}'
                12 = '{75A54138-3B98-4705-92E4-F619825B121F}'
            }
        }
        ManagementStudioAdvanced = @{
            Type = 'UninstallRegistry'
            ProductGuids = @{
                10 = '{B5FE23CC-0151-4595-84C3-F1DE6F44FE9B}'
                11 = '{7842C220-6E9A-4D5A-AE70-0E138271F883}'
                12 = '{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}'
            }
        }
        MasterDataServices = @{
            Type       = 'Version'
            UseCommand = 'Get-SqlDscMasterDataServicesInstalledSetting'
        }
        ROpenRPackages = @{
            Type         = 'InstanceId'
            RegistryName = 'sql_inst_mr'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\ConfigurationState'
        }
        RServices = @{
            Type         = 'InstanceId'
            RegistryName = 'AdvancedAnalytics'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\ConfigurationState'
        }
        Replication = @{
            Type         = 'InstanceId'
            RegistryName = 'SQL_Replication_Core_Inst'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\ConfigurationState'
        }
        SoftwareDevelopmentKit = @{
            Type         = 'Version'
            RegistryName = 'SDK_Full'
            PathTemplate = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\ConfigurationState'
        }
    }

    $installedComponents = @()

    # Determine which components to check
    $componentsToCheck = if ($Component)
    {
        $Component | ForEach-Object { $_.ToString() }
    }
    else
    {
        $componentConfig.Keys
    }

    foreach ($componentName in $componentsToCheck)
    {
        $config = $componentConfig[$componentName]

        switch ($config.Type)
        {
            'Version'
            {
                # Get all installed database levels (100, 110, 120, ..., 160, etc.)
                $installedDatabaseLevels = (Split-Path -Leaf -Path (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\' -ErrorAction 'SilentlyContinue').Name) -match '^\d\d\d$'

                $versionsToCheck = if ($Version)
                {
                    @($Version.Major)
                }
                else
                {
                    $installedDatabaseLevels | ForEach-Object { [System.Int32] ($_.Substring(0, 2)) } | Select-Object -Unique
                }

                foreach ($majorVersion in $versionsToCheck)
                {
                    $componentVersion = [System.Version] ('{0}.0' -f $majorVersion)
                    $isInstalled = $false

                    if ($config.UseCommand)
                    {
                        # Use Get-* command for components with complex logic
                        $commandResult = & $config.UseCommand -Version $componentVersion -ErrorAction 'SilentlyContinue'

                        if ($commandResult)
                        {
                            $isInstalled = $true
                        }
                    }
                    else
                    {
                        # Check registry for component installation
                        $registryPath = $config.PathTemplate -f $majorVersion

                        $getRegistryPropertyValueParameters = @{
                            Path        = $registryPath
                            Name        = $config.RegistryName
                            ErrorAction = 'SilentlyContinue'
                        }

                        $registryValue = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

                        if ($registryValue -eq 1)
                        {
                            $isInstalled = $true
                        }
                    }

                    if ($isInstalled)
                    {
                        $installedComponents += [PSCustomObject] @{
                            PSTypeName = 'SqlServerDsc.InstalledComponent'
                            Component  = $componentName
                            Version    = $componentVersion
                        }
                    }
                }

                break
            }

            'UninstallRegistry'
            {
                $registryUninstallPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

                $versionsToCheck = if ($Version)
                {
                    if ($config.ProductGuids.ContainsKey($Version.Major))
                    {
                        @($Version.Major)
                    }
                    else
                    {
                        @()
                    }
                }
                else
                {
                    $config.ProductGuids.Keys
                }

                foreach ($majorVersion in $versionsToCheck)
                {
                    $productGuid = $config.ProductGuids[$majorVersion]

                    if ($productGuid)
                    {
                        $getItemPropertyParameters = @{
                            Path        = Join-Path -Path $registryUninstallPath -ChildPath $productGuid
                            ErrorAction = 'SilentlyContinue'
                        }

                        $registryObject = Get-ItemProperty @getItemPropertyParameters

                        if ($registryObject)
                        {
                            $installedComponents += [PSCustomObject] @{
                                PSTypeName = 'SqlServerDsc.InstalledComponent'
                                Component  = $componentName
                                Version    = [System.Version] ('{0}.0' -f $majorVersion)
                            }
                        }
                    }
                }

                break
            }

            'InstanceId'
            {
                if ($InstanceId)
                {
                    $registryPath = $config.PathTemplate -f $InstanceId

                    $getRegistryPropertyValueParameters = @{
                        Path        = $registryPath
                        Name        = $config.RegistryName
                        ErrorAction = 'SilentlyContinue'
                    }

                    $registryValue = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

                    if ($registryValue -eq 1)
                    {
                        $installedComponents += [PSCustomObject] @{
                            PSTypeName = 'SqlServerDsc.InstalledComponent'
                            Component  = $componentName
                            InstanceId = $InstanceId
                        }
                    }
                }
                else
                {
                    # When no InstanceId is specified, check all instances
                    $installedInstances = Get-SqlDscInstalledInstance -ServiceType 'DatabaseEngine' -ErrorAction 'SilentlyContinue'

                    foreach ($instance in $installedInstances)
                    {
                        $registryPath = $config.PathTemplate -f $instance.InstanceId

                        $getRegistryPropertyValueParameters = @{
                            Path        = $registryPath
                            Name        = $config.RegistryName
                            ErrorAction = 'SilentlyContinue'
                        }

                        $registryValue = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

                        if ($registryValue -eq 1)
                        {
                            $installedComponents += [PSCustomObject] @{
                                PSTypeName   = 'SqlServerDsc.InstalledComponent'
                                Component    = $componentName
                                InstanceId   = $instance.InstanceId
                                InstanceName = $instance.InstanceName
                            }
                        }
                    }
                }

                break
            }
        }
    }

    return $installedComponents
}
