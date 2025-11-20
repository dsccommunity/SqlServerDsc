<#
    .SYNOPSIS
        Gets the SQL Server Reporting Services configuration settings from the
        MSReportServer_ConfigurationSetting WMI class.

    .DESCRIPTION
        Gets the SQL Server Reporting Services configuration settings from the
        MSReportServer_ConfigurationSetting WMI class for installed Reporting Services
        instances. This includes information like initialization status, database
        configuration, virtual directories, service account, and other configuration
        settings.

        When no InstanceName is specified, it returns configuration information for all
        installed Reporting Services instances.

    .PARAMETER InstanceName
        Specifies the instance name to return configuration information for.
        If not specified, configuration information for all Reporting Services
        instances will be returned.

    .EXAMPLE
        Get-SqlDscRSConfigurationSetting

        Returns configuration settings for all SQL Server Reporting Services instances.

    .EXAMPLE
        Get-SqlDscRSConfigurationSetting -InstanceName 'SSRS'

        Returns configuration settings for the SQL Server Reporting Services
        instance 'SSRS'.

    .OUTPUTS
        Returns a PSCustomObject array with the following properties from
        MSReportServer_ConfigurationSetting:
        - InstanceName: The name of the Reporting Services instance.
        - Version: The version of the Reporting Services instance.
        - PathName: The Reporting Services configuration file path.
        - InstallationID: The Reporting Services unique installation identifier.
        - IsInitialized: Whether the instance is initialized.
        - IsSharePointIntegrated: Whether the instance is SharePoint integrated.
        - IsWebServiceEnabled: Whether the Web service is enabled.
        - IsWindowsServiceEnabled: Whether the Windows service is enabled.
        - IsTlsConfigured: Whether TLS is configured (true if SecureConnectionLevel >= 1, false if 0).
        - DatabaseServerName: The database server name.
        - DatabaseName: The database name.
        - DatabaseLogonType: The database login type.
        - DatabaseLogonAccount: The database login account.
        - ServiceAccount: The Windows service account (from WindowsServiceIdentityActual).
        - WebServiceVirtualDirectory: The Web service virtual directory (from VirtualDirectoryReportServer).
        - WebPortalVirtualDirectory: The Web portal virtual directory (from VirtualDirectoryReportManager or VirtualDirectoryReportServerWebApp).
        - WebPortalApplicationName: The Web portal application name (ReportServerWebApp or ReportManager).
        - WebServiceApplicationName: The Web service application name (ReportServerWebService).
#>
function Get-SqlDscRSConfigurationSetting
{
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
    $getRSSetupConfigurationParams = @{}

    if ($PSBoundParameters.ContainsKey('InstanceName'))
    {
        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfigurationSetting_GetSpecificInstance -f $InstanceName)
        $getRSSetupConfigurationParams.InstanceName = $InstanceName
    }
    else
    {
        Write-Verbose -Message $script:localizedData.Get_SqlDscRSConfigurationSetting_GetAllInstances
    }

    $setupConfigurations = Get-SqlDscRSSetupConfiguration @getRSSetupConfigurationParams

    foreach ($setupConfig in $setupConfigurations)
    {
        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfigurationSetting_ProcessingInstance -f $setupConfig.InstanceName)

        # Initialize return object with InstanceName and null/default values
        $returnObject = [PSCustomObject]@{
            InstanceName               = $setupConfig.InstanceName
            Version                    = $null
            PathName                   = $null
            InstallationID             = $null
            IsInitialized              = $null
            IsSharePointIntegrated     = $null
            IsWebServiceEnabled        = $null
            IsWindowsServiceEnabled    = $null
            IsTlsConfigured           = $null
            DatabaseServerName         = $null
            DatabaseName               = $null
            DatabaseLogonType          = $null
            DatabaseLogonAccount       = $null
            ServiceAccount             = $null
            WebServiceApplicationName  = 'ReportServerWebService'
            WebServiceVirtualDirectory = $null
            WebPortalApplicationName   = $null
            WebPortalVirtualDirectory  = $null
        }

        # Error if CurrentVersion is empty (cannot determine namespace)
        if ([System.String]::IsNullOrEmpty($setupConfig.CurrentVersion))
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfigurationSetting_CurrentVersionEmpty -f $setupConfig.InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'GSDCRSCS0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $setupConfig.InstanceName
                )
            )
        }

        # Parse CurrentVersion to get major version number
        try
        {
            $reportServerCurrentVersion = [System.Version] $setupConfig.CurrentVersion
            $sqlMajorVersion = $reportServerCurrentVersion.Major

            Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfigurationSetting_FoundInstance -f $setupConfig.InstanceName, $sqlMajorVersion)
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfigurationSetting_InvalidVersion -f $setupConfig.CurrentVersion, $setupConfig.InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'GSDCRSCS0002', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $setupConfig.CurrentVersion
                )
            )
        }

        # Get MSReportServer_ConfigurationSetting instance
        $getCimInstanceParameters = @{
            Filter      = "InstanceName='{0}'" -f $returnObject.InstanceName
            Namespace   = 'root\Microsoft\SQLServer\ReportServer\RS_{0}\v{1}\Admin' -f $returnObject.InstanceName, $sqlMajorVersion
            ClassName   = 'MSReportServer_ConfigurationSetting'
            ErrorAction = 'Stop'
        }

        try
        {
            $reportingServicesConfiguration = Get-CimInstance @getCimInstanceParameters
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfigurationSetting_ConfigurationNotFound -f $setupConfig.InstanceName, $namespace, $_.Exception.Message

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'GSDCRSCS0003', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $setupConfig.InstanceName
                )
            )
        }

        # Determine Web Portal Application Name based on SQL version
        if ($sqlMajorVersion -ge 13)
        {
            $returnObject.WebPortalApplicationName = 'ReportServerWebApp'
        }
        else
        {
            $returnObject.WebPortalApplicationName = 'ReportManager'
        }

        # Populate return object with properties from MSReportServer_ConfigurationSetting
        $returnObject.Version = $reportingServicesConfiguration.Version
        $returnObject.PathName = $reportingServicesConfiguration.PathName
        $returnObject.InstallationID = $reportingServicesConfiguration.InstallationID
        $returnObject.IsInitialized = $reportingServicesConfiguration.IsInitialized
        $returnObject.IsSharePointIntegrated = $reportingServicesConfiguration.IsSharePointIntegrated
        $returnObject.IsWebServiceEnabled = $reportingServicesConfiguration.IsWebServiceEnabled
        $returnObject.IsWindowsServiceEnabled = $reportingServicesConfiguration.IsWindowsServiceEnabled
        $returnObject.IsTlsConfigured = $reportingServicesConfiguration.SecureConnectionLevel -ge 1
        $returnObject.DatabaseServerName = $reportingServicesConfiguration.DatabaseServerName
        $returnObject.DatabaseName = $reportingServicesConfiguration.DatabaseName
        $returnObject.DatabaseLogonType = $reportingServicesConfiguration.DatabaseLogonType
        $returnObject.DatabaseLogonAccount = $reportingServicesConfiguration.DatabaseLogonAccount
        $returnObject.ServiceAccount = $reportingServicesConfiguration.WindowsServiceIdentityActual
        $returnObject.WebServiceVirtualDirectory = $reportingServicesConfiguration.VirtualDirectoryReportServer
        $returnObject.WebPortalVirtualDirectory = $reportingServicesConfiguration.VirtualDirectoryReportManager

        $reportingServicesInstances += $returnObject
    }

    if ($reportingServicesInstances.Count -eq 0)
    {
        if ($PSBoundParameters.ContainsKey('InstanceName'))
        {
            Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfigurationSetting_InstanceNotFound -f $InstanceName)
        }
        else
        {
            Write-Verbose -Message $script:localizedData.Get_SqlDscRSConfigurationSetting_NoInstancesFound
        }
    }

    return $reportingServicesInstances
}
