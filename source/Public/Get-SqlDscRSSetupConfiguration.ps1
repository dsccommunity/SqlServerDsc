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
            InstanceName         = $instance.InstanceName
            InstallFolder        = $null
            ServiceName          = $null
            ErrorDumpDirectory   = $null
            CurrentVersion       = $null
            CustomerFeedback     = $null
            EnableErrorReporting = $null
            ProductVersion       = $null
            VirtualRootServer    = $null
            ConfigFilePath       = $null
        }

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSSetupConfiguration_FoundInstance -f $instance.InstanceName)

        $getItemPropertyValueParameters = @{
            ErrorAction = 'SilentlyContinue'
        }

        # Get values from SSRS\Setup registry key
        $getItemPropertyValueParameters.Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup'

        # InstallRootDirectory
        $getItemPropertyValueParameters.Name = 'InstallRootDirectory'
        $returnObject.InstallFolder = Get-ItemPropertyValue @getItemPropertyValueParameters

        # ServiceName
        $getItemPropertyValueParameters.Name = 'ServiceName'
        $returnObject.ServiceName = Get-ItemPropertyValue @getItemPropertyValueParameters

        # RSVirtualRootServer
        $getItemPropertyValueParameters.Name = 'RSVirtualRootServer'
        $returnObject.VirtualRootServer = Get-ItemPropertyValue @getItemPropertyValueParameters

        # RsConfigFilePath
        $getItemPropertyValueParameters.Name = 'RsConfigFilePath'
        $returnObject.ConfigFilePath = Get-ItemPropertyValue @getItemPropertyValueParameters

        # Get values from SSRS\CPE registry key
        $getItemPropertyValueParameters.Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE'

        # ErrorDumpDir
        $getItemPropertyValueParameters.Name = 'ErrorDumpDir'
        $returnObject.ErrorDumpDirectory = Get-ItemPropertyValue @getItemPropertyValueParameters

        # CustomerFeedback
        $getItemPropertyValueParameters.Name = 'CustomerFeedback'
        $returnObject.CustomerFeedback = Get-ItemPropertyValue @getItemPropertyValueParameters

        # EnableErrorReporting
        $getItemPropertyValueParameters.Name = 'EnableErrorReporting'
        $returnObject.EnableErrorReporting = Get-ItemPropertyValue @getItemPropertyValueParameters

        # Get values from SSRS\MSSQLServer\CurrentVersion registry key
        $getItemPropertyValueParameters.Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\MSSQLServer\CurrentVersion'

        # CurrentVersion from registry
        $getItemPropertyValueParameters.Name = 'CurrentVersion'
        $returnObject.CurrentVersion = Get-ItemPropertyValue @getItemPropertyValueParameters

        # ProductVersion
        $getItemPropertyValueParameters.Name = 'ProductVersion'
        $returnObject.ProductVersion = Get-ItemPropertyValue @getItemPropertyValueParameters

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
