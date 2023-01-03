<#
    .SYNOPSIS
        Executes an setup action using Microsoft SQL Server setup executable.

    .DESCRIPTION
        Executes an setup action using Microsoft SQL Server setup executable.

        See the link in the commands help for information on each parameter. The
        link points to SQL Server command line setup documentation.

    .PARAMETER Install
        Specifies the setup action Install.

    .PARAMETER Uninstall
        Specifies the setup action Uninstall.

    .PARAMETER PrepareImage
        Specifies the setup action PrepareImage.

    .PARAMETER Upgrade
        Specifies the setup action Upgrade.

    .PARAMETER EditionUpgrade
        Specifies the setup action EditionUpgrade.

    .PARAMETER InstallFailoverCluster
        Specifies the setup action InstallFailoverCluster.

    .PARAMETER PrepareFailoverCluster
        Specifies the setup action PrepareFailoverCluster.

    .PARAMETER ConfigurationFile
        Specifies an configuration file to use during SQL Server setup. This
        parameter cannot be used together with any of the setup actions, but instead
        it is expected that the configuration file specifies what setup action to
        run.

    .PARAMETER AcceptLicensingTerms
        Required parameter to be able to run unattended install. By specifying this
        parameter you acknowledge the acceptance all license terms and notices for
        the specified features, the terms and notices that the Microsoft SQL Server
        setup executable normally ask for.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .PARAMETER Force
        If specified the command will not ask for confirmation. Same as if Confirm:$false
        is used.

    .PARAMETER SuppressPrivacyStatementNotice
        See notes section.

    .PARAMETER IAcknowledgeEntCalLimits
        See notes section.

    .PARAMETER InstanceName
        See notes section.

    .PARAMETER Enu
        See notes section.

    .PARAMETER UpdateEnabled
        See notes section.

    .PARAMETER UpdateSource
        See notes section.

    .PARAMETER Features
        See notes section.

    .PARAMETER Role
        See notes section.

    .PARAMETER InstallSharedDir
        See notes section.

    .PARAMETER InstallSharedWowDir
        See notes section.

    .PARAMETER InstanceDir
        See notes section.

    .PARAMETER InstanceId
        See notes section.

    .PARAMETER PBEngSvcAccount
        See notes section.

    .PARAMETER PBEngSvcPassword
        See notes section.

    .PARAMETER PBEngSvcStartupType
        See notes section.

    .PARAMETER PBDMSSvcAccount
        See notes section.

    .PARAMETER PBDMSSvcPassword
        See notes section.

    .PARAMETER PBDMSSvcStartupType
        See notes section.

    .PARAMETER PBStartPortRange
        See notes section.

    .PARAMETER PBEndPortRange
        See notes section.

    .PARAMETER PBScaleOut
        See notes section.

    .PARAMETER ProductKey
        See notes section.

    .PARAMETER AgtSvcAccount
        See notes section.

    .PARAMETER AgtSvcPassword
        See notes section.

    .PARAMETER AgtSvcStartupType
        See notes section.

    .PARAMETER ASBackupDir
        See notes section.

    .PARAMETER ASCollation
        See notes section.

    .PARAMETER ASConfigDir
        See notes section.

    .PARAMETER ASDataDir
        See notes section.

    .PARAMETER ASLogDir
        See notes section.

    .PARAMETER ASTempDir
        See notes section.

    .PARAMETER ASServerMode
        See notes section.

    .PARAMETER ASSvcAccount
        See notes section.

    .PARAMETER ASSvcPassword
        See notes section.

    .PARAMETER ASSvcStartupType
        See notes section.

    .PARAMETER ASSysAdminAccounts
        See notes section.

    .PARAMETER ASProviderMSOLAP
        See notes section.

    .PARAMETER FarmAccount
        See notes section.

    .PARAMETER FarmPassword
        See notes section.

    .PARAMETER Passphrase
        See notes section.

    .PARAMETER FarmAdminiPort
        See notes section.

    .PARAMETER BrowserSvcStartupType
        See notes section.

    .PARAMETER FTUpgradeOption
        See notes section.

    .PARAMETER EnableRanU
        See notes section.

    .PARAMETER InstallSqlDataDir
        See notes section.

    .PARAMETER SqlBackupDir
        See notes section.

    .PARAMETER SecurityMode
        See notes section.

    .PARAMETER SAPwd
        See notes section.

    .PARAMETER SqlCollation
        See notes section.

    .PARAMETER AddCurrentUserAsSqlAdmin
        See notes section.

    .PARAMETER SqlSvcAccount
        See notes section.

    .PARAMETER SqlSvcPassword
        See notes section.

    .PARAMETER SqlSvcStartupType
        See notes section.

    .PARAMETER SqlSysAdminAccounts
        See notes section.

    .PARAMETER SqlTempDbDir
        See notes section.

    .PARAMETER SqlTempDbLogDir
        See notes section.

    .PARAMETER SqlTempDbFileCount
        See notes section.

    .PARAMETER SqlTempDbFileSize
        See notes section.

    .PARAMETER SqlTempDbFileGrowth
        See notes section.

    .PARAMETER SqlTempDbLogFileSize
        See notes section.

    .PARAMETER SqlTempDbLogFileGrowth
        See notes section.

    .PARAMETER SqlUserDbDir
        See notes section.

    .PARAMETER SqlSvcInstantFileInit
        See notes section.

    .PARAMETER SqlUserDbLogDir
        See notes section.

    .PARAMETER SqlMaxDop
        See notes section.

    .PARAMETER UseSqlRecommendedMemoryLimits
        See notes section.

    .PARAMETER SqlMinMemory
        See notes section.

    .PARAMETER SqlMaxMemory
        See notes section.

    .PARAMETER FileStreamLevel
        See notes section.

    .PARAMETER FileStreamShareName
        See notes section.

    .PARAMETER ISSvcAccount
        See notes section.

    .PARAMETER ISSvcPassword
        See notes section.

    .PARAMETER ISSvcStartupType
        See notes section.

    .PARAMETER AllowUpgradeForSSRSSharePointMode
        See notes section.

    .PARAMETER NpEnabled
        See notes section.

    .PARAMETER TcpEnabled
        See notes section.

    .PARAMETER RsInstallMode
        See notes section.

    .PARAMETER RSSvcAccount
        See notes section.

    .PARAMETER RSSvcPassword
        See notes section.

    .PARAMETER RSSvcStartupType
        See notes section.

    .PARAMETER MPYCacheDirectory
        See notes section.

    .PARAMETER MRCacheDirectory
        See notes section.

    .PARAMETER SqlInstJava
        See notes section.

    .PARAMETER SqlJavaDir
        See notes section.

    .PARAMETER FailoverClusterGroup
        See notes section.

    .PARAMETER FailoverClusterDisks
        See notes section.

    .PARAMETER FailoverClusterNetworkName
        See notes section.

    .PARAMETER FailoverClusterIPAddresses
        See notes section.

    .PARAMETER FailoverClusterRollOwnership
        See notes section.

    .PARAMETER AzureSubscriptionId
        See notes section.

    .PARAMETER AzureResourceGroup
        See notes section.

    .PARAMETER AzureRegion
        See notes section.

    .PARAMETER AzureTenantId
        See notes section.

    .PARAMETER AzureServicePrincipal
        See notes section.

    .PARAMETER AzureServicePrincipalSecret
        See notes section.

    .PARAMETER AzureArcProxy
        See notes section.

    .PARAMETER SkipRules
        See notes section.

    .PARAMETER ProductCoveredBySA
        See notes section.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Install-SqlDscServer -Install -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -SqlSysAdminAccounts @('MyAdminAccount') -MediaPath 'E:\'

        Installs the database engine for the named instance MyInstance.

    .EXAMPLE
        Install-SqlDscServer -Install -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE','ARC' -SqlSysAdminAccounts @('MyAdminAccount') -MediaPath 'E:\' -AzureSubscriptionId 'MySubscriptionId' -AzureResourceGroup 'MyRG' -AzureRegion 'West-US' -AzureTenantId 'MyTenantId' -AzureServicePrincipal 'MyPrincipalName' -AzureServicePrincipalSecret ('MySecret' | ConvertTo-SecureString -AsPlainText -Force)

        Installs the database engine for the named instance MyInstance and onboard the server to Azure Arc.

    .EXAMPLE
        Install-SqlDscServer -Install -AcceptLicensingTerms -MediaPath 'E:\' -AzureSubscriptionId 'MySubscriptionId' -AzureResourceGroup 'MyRG' -AzureRegion 'West-US' -AzureTenantId 'MyTenantId' -AzureServicePrincipal 'MyPrincipalName' -AzureServicePrincipalSecret ('MySecret' | ConvertTo-SecureString -AsPlainText -Force)

        Installs the Azure Arc Agent on the server.

    .EXAMPLE
        Install-SqlDscServer -ConfigurationFile 'MySqlConfig.ini' -MediaPath 'E:\'

        Installs SQL Server using the configuration file 'MySqlConfig.ini'.

    .EXAMPLE
        Install-SqlDscServer -PrepareImage -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -InstanceId 'MyInstance' -MediaPath 'E:\'

        Prepares the server for using the database engine for an instance named 'MyInstance'.

    .EXAMPLE
        Install-SqlDscServer -Upgrade -AcceptLicensingTerms -InstanceName 'MyInstance' -MediaPath 'E:\'

        Upgrades the instance 'MyInstance' with the SQL Server version that is provided by the media path.

    .EXAMPLE
        Install-SqlDscServer -EditionUpgrade -AcceptLicensingTerms -ProductKey 'NewEditionProductKey' -InstanceName 'MyInstance' -MediaPath 'E:\'

        Upgrades the instance 'MyInstance' with the SQL Server edition that is provided by the media path.

    .EXAMPLE
        Install-SqlDscServer -InstallFailoverCluster -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -InstallSqlDataDir 'D:\MSSQL\Data' -SqlSysAdminAccounts @('MyAdminAccount') -FailoverClusterNetworkName 'TestCluster01A' -FailoverClusterIPAddresses 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0' -MediaPath 'E:\'

        Installs the database engine in a failover cluster with the instance name 'MyInstance'.

    .EXAMPLE
        Install-SqlDscServer -PrepareFailoverCluster -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -MediaPath 'E:\'

        Prepares to installs the database engine in a failover cluster with the instance name 'MyInstance'.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.
#>
function Install-SqlDscServer
{
    # cSpell: ignore PBDMS Admini AZUREEXTENSION
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in Invoke-SetupAction')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallRole', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Install,

        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $PrepareImage,

        [Parameter(ParameterSetName = 'Upgrade', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Upgrade,

        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $EditionUpgrade,

        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $InstallFailoverCluster,

        [Parameter(ParameterSetName = 'PrepareFailoverCluster', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $PrepareFailoverCluster,

        [Parameter(ParameterSetName = 'UsingConfigurationFile', Mandatory = $true)]
        [System.String]
        $ConfigurationFile,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallRole', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Upgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $AcceptLicensingTerms,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $SuppressPrivacyStatementNotice,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Management.Automation.SwitchParameter]
        $IAcknowledgeEntCalLimits,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MediaPath,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Upgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $InstanceName,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Management.Automation.SwitchParameter]
        $Enu,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Management.Automation.SwitchParameter]
        $UpdateEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $UpdateSource,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateSet(
            'SQL',
            'SQLEngine', # Part of parent feature SQL
            'Replication', # Part of parent feature SQL
            'FullText', # Part of parent feature SQL
            'DQ', # Part of parent feature SQL
            'PolyBase', # Part of parent feature SQL
            'PolyBaseCore', # Part of parent feature SQL
            'PolyBaseJava', # Part of parent feature SQL
            'AdvancedAnalytics', # Part of parent feature SQL
            'SQL_INST_MR', # Part of parent feature SQL
            'SQL_INST_MPY', # Part of parent feature SQL
            'SQL_INST_JAVA', # Part of parent feature SQL
            'AS',
            'RS',
            'RS_SHP',
            'RS_SHPWFE', # cspell: disable-line
            'DQC',
            'IS',
            'IS_Master', # Part of parent feature IS
            'IS_Worker', # Part of parent feature IS
            'MDS',
            'SQL_SHARED_MPY',
            'SQL_SHARED_MR',
            'Tools',
            'BC', # Part of parent feature Tools
            'Conn', # Part of parent feature Tools
            'DREPLAY_CTLR', # Part of parent feature Tools (cspell: disable-line)
            'DREPLAY_CLT', # Part of parent feature Tools (cspell: disable-line)
            'SNAC_SDK', # Part of parent feature Tools (cspell: disable-line)
            'SDK', # Part of parent feature Tools
            'LocalDB', # Part of parent feature Tools
            'AZUREEXTENSION'
        )]
        [System.String[]]
        $Features,

        [Parameter(ParameterSetName = 'InstallRole', Mandatory = $true)]
        [ValidateSet(
            'ALLFeatures_WithDefaults',
            'SPI_AS_NewFarm',
            'SPI_AS_ExistingFarm'
        )]
        [System.String]
        $Role,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstallSharedDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstallSharedWowDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstanceDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstanceId,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $PBEngSvcAccount,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Security.SecureString]
        $PBEngSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $PBEngSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $PBDMSSvcAccount, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Security.SecureString]
        $PBDMSSvcPassword, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $PBDMSSvcStartupType, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.UInt16]
        $PBStartPortRange,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.UInt16]
        $PBEndPortRange,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Management.Automation.SwitchParameter]
        $PBScaleOut,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [System.String]
        $ProductKey, # This is argument PID but $PID is reserved variable.

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $AgtSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Security.SecureString]
        $AgtSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $AgtSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $ASBackupDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $ASCollation,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $ASConfigDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $ASDataDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $ASLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $ASTempDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateSet('Multidimensional', 'PowerPivot', 'Tabular')]
        [System.String]
        $ASServerMode,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $ASSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Security.SecureString]
        $ASSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $ASSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String[]]
        $ASSysAdminAccounts,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.Management.Automation.SwitchParameter]
        $ASProviderMSOLAP,

        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $FarmAccount,

        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Security.SecureString]
        $FarmPassword,

        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Security.SecureString]
        $Passphrase,

        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateRange(0, 65536)]
        [System.UInt16]
        $FarmAdminiPort, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $BrowserSvcStartupType,

        [Parameter(ParameterSetName = 'Upgrade')]
        [ValidateSet('Rebuild', 'Reset', 'Import')]
        [System.String]
        $FTUpgradeOption,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $EnableRanU,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [System.String]
        $InstallSqlDataDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $SqlBackupDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateSet('SQL')]
        [System.String]
        $SecurityMode,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.Security.SecureString]
        $SAPwd,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $SqlCollation,

        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $AddCurrentUserAsSqlAdmin,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $SqlSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Security.SecureString]
        $SqlSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $SqlSvcStartupType,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String[]]
        $SqlSysAdminAccounts,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $SqlTempDbDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $SqlTempDbLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.UInt16]
        $SqlTempDbFileCount,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateRange(4, 262144)]
        [System.UInt16]
        $SqlTempDbFileSize,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateRange(0, 1024)]
        [System.UInt16]
        $SqlTempDbFileGrowth,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateRange(4, 262144)]
        [System.UInt16]
        $SqlTempDbLogFileSize,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateRange(0, 1024)]
        [System.UInt16]
        $SqlTempDbLogFileGrowth,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $SqlUserDbDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $SqlSvcInstantFileInit,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $SqlUserDbLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateRange(0, 32767)]
        [System.UInt16]
        $SqlMaxDop,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $UseSqlRecommendedMemoryLimits,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateRange(0, 2147483647)]
        [System.UInt32]
        $SqlMinMemory,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateRange(0, 2147483647)]
        [System.UInt32]
        $SqlMaxMemory,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [ValidateRange(0, 3)]
        [System.UInt16]
        $FileStreamLevel,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $FileStreamShareName,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $ISSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Security.SecureString]
        $ISSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $ISSvcStartupType,

        [Parameter(ParameterSetName = 'Upgrade')]
        [System.Management.Automation.SwitchParameter]
        $AllowUpgradeForSSRSSharePointMode,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $NpEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $TcpEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.String]
        $RsInstallMode,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $RSSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.Security.SecureString]
        $RSSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $RSSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $MPYCacheDirectory,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $MRCacheDirectory,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $SqlInstJava,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $SqlJavaDir,

        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String]
        $FailoverClusterGroup,

        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [System.String[]]
        $FailoverClusterDisks,

        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [System.String[]]
        $FailoverClusterIPAddresses,

        [Parameter(ParameterSetName = 'Upgrade')]
        [ValidateRange(0, 2)]
        [System.UInt16]
        $FailoverClusterRollOwnership,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureSubscriptionId,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureResourceGroup,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureRegion,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureTenantId,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureServicePrincipal,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.Security.SecureString]
        $AzureServicePrincipalSecret,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent')]
        [System.String]
        $AzureArcProxy,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'EditionUpgrade')]
        [System.String[]]
        $SkipRules,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'EditionUpgrade')]
        [System.Management.Automation.SwitchParameter]
        $ProductCoveredBySA,

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Invoke-SetupAction @PSBoundParameters -ErrorAction 'Stop'
}
