<#
    .SYNOPSIS
        Gets the SQL Server Reporting Services or Power BI Report Server setup
        configuration from the Registry.

    .DESCRIPTION
        Gets the SQL Server Reporting Services and Power BI Report Server setup
        configuration information from the Registry. This includes information like
        instance name, installation folder, service name, error dump directory,
        customer feedback settings, error reporting settings, virtual root, configuration
        file path, and various version information of the installed Reporting Services
        instance.

        When no InstanceName is specified, it returns configuration information for all
        installed Reporting Services instances.

    .PARAMETER InstanceName
        Specifies the instance name to return configuration information for.
        If not specified, configuration information for all Reporting Services
        and Power BI Report Server instances will be returned.

    .EXAMPLE
        Get-SqlDscRSSetupConfiguration

        Returns configuration information about all SQL Server Reporting Services
        and Power BI Report Server instances.

    .EXAMPLE
        Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

        Returns configuration information about the SQL Server Reporting Services
        instance 'SSRS'.

    .EXAMPLE
        Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS'

        Returns configuration information about the Power BI Report Server
        instance 'PBIRS'.

    .OUTPUTS
        Returns a PSCustomObject with the following properties:
        - InstanceName: The name of the Reporting Services instance.
        - InstallFolder: The installation folder path.
        - ServiceName: The name of the service.
        - ErrorDumpDirectory: The path to the error dump directory.
        - CustomerFeedback: Whether customer feedback is enabled.
        - EnableErrorReporting: Whether error reporting is enabled.
        - ProductVersion: The product version from registry.
        - CurrentVersion: The current version from registry.
        - VirtualRootServer: The virtual root server value.
        - ConfigFilePath: The path to the report server configuration file.
        - EditionID: The edition ID of the Reporting Services instance.
        - EditionName: The edition name of the Reporting Services instance.
        - IsSharePointIntegrated: Whether the instance is SharePoint integrated.
          MSReportServer_Instance.
        - InstanceId: The instance ID of the Reporting Services instance.
#>
function Get-SqlDscRSSetupConfiguration
{
    # cSpell: ignore PBIRS
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName
    )

    $reportingServicesInstances = @()

    # Get all Reporting Services instances or filter by specified instance name
    $getInstalledInstanceParams = @{
        ServiceType = 'ReportingServices'
    }

    if ($PSBoundParameters.ContainsKey('InstanceName'))
    {
        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSSetupConfiguration_GetSpecificInstance -f $InstanceName)

        $getInstalledInstanceParams.InstanceName = $InstanceName
    }
    else
    {
        Write-Verbose -Message $script:localizedData.Get_SqlDscRSSetupConfiguration_GetAllInstances
    }

    $instances = Get-SqlDscInstalledInstance @getInstalledInstanceParams

    foreach ($instance in $instances)
    {
        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSSetupConfiguration_ProcessingInstance -f $instance.InstanceName)

        $returnObject = [PSCustomObject]@{
            InstanceName           = $instance.InstanceName
            InstallFolder          = $null
            ServiceName            = $null
            ErrorDumpDirectory     = $null
            CurrentVersion         = $null
            CustomerFeedback       = $null
            EnableErrorReporting   = $null
            ProductVersion         = $null
            VirtualRootServer      = $null
            ConfigFilePath         = $null
            EditionID              = $null
            EditionName            = $null
            IsSharePointIntegrated = $null
            InstanceId             = $instance.InstanceId
        }

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSSetupConfiguration_FoundInstance -f $instance.InstanceName)

        $getRegistryPropertyValueParameters = @{
            ErrorAction = 'SilentlyContinue'
        }

        # Get values from SSRS\Setup registry key
        $getRegistryPropertyValueParameters.Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\Setup' -f $returnObject.InstanceId

        # InstallRootDirectory
        $getRegistryPropertyValueParameters.Name = 'InstallRootDirectory'
        $returnObject.InstallFolder = Get-RegistryPropertyValue @getRegistryPropertyValueParameters
        # Fallback to SQLPath if InstallRootDirectory is not found. This is the case for SQL 2016 and earlier.
        if ($null -eq $returnObject.InstallFolder)
        {
            $getRegistryPropertyValueParameters.Name = 'SQLPath'
            $returnObject.InstallFolder = Get-RegistryPropertyValue @getRegistryPropertyValueParameters
            if ($null -ne $returnObject.InstallFolder)
            {
                $returnObject.InstallFolder = $returnObject.InstallFolder.TrimEnd('\')
            }
        }

        # ServiceName
        $getRegistryPropertyValueParameters.Name = 'ServiceName'
        $returnObject.ServiceName = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

        # RSVirtualRootServer
        $getRegistryPropertyValueParameters.Name = 'RSVirtualRootServer'
        $returnObject.VirtualRootServer = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

        # RsConfigFilePath
        $getRegistryPropertyValueParameters.Name = 'RsConfigFilePath'
        $returnObject.ConfigFilePath = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

        # Get values from SSRS\CPE registry key
        $getRegistryPropertyValueParameters.Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\CPE' -f $returnObject.InstanceId

        # ErrorDumpDir
        $getRegistryPropertyValueParameters.Name = 'ErrorDumpDir'
        $returnObject.ErrorDumpDirectory = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

        # CustomerFeedback
        $getRegistryPropertyValueParameters.Name = 'CustomerFeedback'
        $returnObject.CustomerFeedback = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

        # EnableErrorReporting
        $getRegistryPropertyValueParameters.Name = 'EnableErrorReporting'
        $returnObject.EnableErrorReporting = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

        # Get values from SSRS\MSSQLServer\CurrentVersion registry key
        $getRegistryPropertyValueParameters.Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\MSSQLServer\CurrentVersion' -f $returnObject.InstanceId

        # CurrentVersion from registry
        $getRegistryPropertyValueParameters.Name = 'CurrentVersion'
        $returnObject.CurrentVersion = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

        # ProductVersion
        $getRegistryPropertyValueParameters.Name = 'ProductVersion'
        $returnObject.ProductVersion = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

        if (-not [System.String]::IsNullOrEmpty($returnObject.CurrentVersion))
        {
            $reportServerCurrentVersion = [System.Version] $returnObject.CurrentVersion

            # Get values from MSReportServer_Instance
            $msReportServerInstance = Get-CimInstance -Namespace ('root\Microsoft\SqlServer\ReportServer\RS_{0}\v{1}' -f $instance.InstanceName, $reportServerCurrentVersion.Major) -ClassName 'MSReportServer_Instance' -ErrorAction 'SilentlyContinue'
            $msReportServerInstance = $msReportServerInstance | Where-Object -FilterScript {
                $_.InstanceId -eq $returnObject.InstanceId
            }

            if ($msReportServerInstance)
            {
                $returnObject.EditionID = $msReportServerInstance.EditionID
                $returnObject.EditionName = $msReportServerInstance.EditionName
                $returnObject.IsSharePointIntegrated = $msReportServerInstance.IsSharePointIntegrated
                $returnObject.InstanceId = $msReportServerInstance.InstanceId
            }
        }

        $reportingServicesInstances += $returnObject
    }

    if ($reportingServicesInstances.Count -eq 0)
    {
        if ($PSBoundParameters.ContainsKey('InstanceName'))
        {
            Write-Verbose -Message ($script:localizedData.Get_SqlDscRSSetupConfiguration_InstanceNotFound -f $InstanceName)
        }
        else
        {
            Write-Verbose -Message $script:localizedData.Get_SqlDscRSSetupConfiguration_NoInstancesFound
        }
    }

    return $reportingServicesInstances
}
