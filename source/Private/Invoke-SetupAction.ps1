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

    .PARAMETER CompleteImage
        Specifies the setup action CompleteImage.

    .PARAMETER Upgrade
        Specifies the setup action Upgrade.

    .PARAMETER EditionUpgrade
        Specifies the setup action EditionUpgrade.

    .PARAMETER Repair
        Specifies the setup action Repair.

    .PARAMETER RebuildDatabase
        Specifies the setup action RebuildDatabase.

    .PARAMETER InstallFailoverCluster
        Specifies the setup action InstallFailoverCluster.

    .PARAMETER PrepareFailoverCluster
        Specifies the setup action PrepareFailoverCluster.

    .PARAMETER CompleteFailoverCluster
        Specifies the setup action CompleteFailoverCluster.

    .PARAMETER AddNode
        Specifies the setup action AddNode.

    .PARAMETER RemoveNode
        Specifies the setup action RemoveNode.

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

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Invoke-SetupAction -Install -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -SqlSysAdminAccounts @('MyAdminAccount') -MediaPath 'E:\'

        Installs the database engine for the named instance MyInstance.

    .EXAMPLE
        Invoke-SetupAction -Install -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE','ARC' -SqlSysAdminAccounts @('MyAdminAccount') -MediaPath 'E:\' -AzureSubscriptionId 'MySubscriptionId' -AzureResourceGroup 'MyRG' -AzureRegion 'West-US' -AzureTenantId 'MyTenantId' -AzureServicePrincipal 'MyPrincipalName' -AzureServicePrincipalSecret ([PSCredential]::new('Any',('MySecret' | ConvertTo-SecureString -AsPlainText -Force)))

        Installs the database engine for the named instance MyInstance and onboard the server to Azure Arc.

    .EXAMPLE
        Invoke-SetupAction -Install -AcceptLicensingTerms -MediaPath 'E:\' -AzureSubscriptionId 'MySubscriptionId' -AzureResourceGroup 'MyRG' -AzureRegion 'West-US' -AzureTenantId 'MyTenantId' -AzureServicePrincipal 'MyPrincipalName' -AzureServicePrincipalSecret ([PSCredential]::new('Any',('MySecret' | ConvertTo-SecureString -AsPlainText -Force)))

        Installs the Azure Arc Agent on the server.

    .EXAMPLE
        Invoke-SetupAction -ConfigurationFile 'MySqlConfig.ini' -MediaPath 'E:\'

        Installs SQL Server using the configuration file 'MySqlConfig.ini'.

    .EXAMPLE
        Invoke-SetupAction -Uninstall -InstanceName 'MyInstance' -Features 'SQLENGINE' -MediaPath 'E:\'

        Uninstalls the database engine from the named instance MyInstance.

    .EXAMPLE
        Invoke-SetupAction -PrepareImage -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -InstanceId 'MyInstance' -MediaPath 'E:\'

        Prepares the server for using the database engine for an instance named 'MyInstance'.

    .EXAMPLE
        Invoke-SetupAction -CompleteImage -AcceptLicensingTerms -MediaPath 'E:\'

        Completes install on a server that was previously prepared (by using prepare image).

    .EXAMPLE
        Invoke-SetupAction -Upgrade -AcceptLicensingTerms -InstanceName 'MyInstance' -MediaPath 'E:\'

        Upgrades the instance 'MyInstance' with the SQL Server version that is provided by the media path.

    .EXAMPLE
        Invoke-SetupAction -EditionUpgrade -AcceptLicensingTerms -ProductKey 'NewEditionProductKey' -InstanceName 'MyInstance' -MediaPath 'E:\'

        Upgrades the instance 'MyInstance' with the SQL Server edition that is provided by the media path.

    .EXAMPLE
        Invoke-SetupAction -Repair -InstanceName 'MyInstance' -Features 'SQLENGINE' -MediaPath 'E:\'

        Repairs the database engine of the instance 'MyInstance'.

    .EXAMPLE
        Invoke-SetupAction -RebuildDatabase -InstanceName 'MyInstance' -SqlSysAdminAccounts @('MyAdminAccount') -MediaPath 'E:\'

        Rebuilds the database of the instance 'MyInstance'.

    .EXAMPLE
        Invoke-SetupAction -InstallFailoverCluster -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -InstallSqlDataDir 'D:\MSSQL\Data' -SqlSysAdminAccounts @('MyAdminAccount') -FailoverClusterNetworkName 'TestCluster01A' -FailoverClusterIPAddresses 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0' -MediaPath 'E:\'

        Installs the database engine in a failover cluster with the instance name 'MyInstance'.

    .EXAMPLE
        Invoke-SetupAction -PrepareFailoverCluster -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -MediaPath 'E:\'

        Prepares to installs the database engine in a failover cluster with the instance name 'MyInstance'.

    .EXAMPLE
        Invoke-SetupAction -CompleteFailoverCluster -InstanceName 'MyInstance' -InstallSqlDataDir 'D:\MSSQL\Data' -SqlSysAdminAccounts @('MyAdminAccount') -FailoverClusterNetworkName 'TestCluster01A' -FailoverClusterIPAddresses 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0' -MediaPath 'E:\'

        Completes the install of the database engine in the failover cluster with the instance name 'MyInstance'.

    .EXAMPLE
        Invoke-SetupAction -AddNode -AcceptLicensingTerms -InstanceName 'MyInstance' -FailoverClusterIPAddresses 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0' -MediaPath 'E:\'

        Adds the node to the failover cluster for the instance 'MyInstance'.

    .EXAMPLE
        Invoke-SetupAction -RemoveNode -InstanceName 'MyInstance' -MediaPath 'E:\'

        Removes the node from the failover cluster of the instance 'MyInstance'.

    .NOTES
        All parameters has intentionally not been added to this comment-based help
        since it would take a lot of effort to keep it up to date. Instead there is
        a link in the comment-based help that points to the SQL Server command line
        setup documentation which will stay relevant.

        For RebuildDatabase the parameter SAPwd must be set if the instance was
        installed with SecurityMode = 'SQL'.
#>
function Invoke-SetupAction
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallRole', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Install,

        [Parameter(ParameterSetName = 'Uninstall', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Uninstall,

        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $PrepareImage,

        [Parameter(ParameterSetName = 'CompleteImage', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $CompleteImage,

        [Parameter(ParameterSetName = 'Upgrade', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Upgrade,

        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $EditionUpgrade,

        [Parameter(ParameterSetName = 'Repair', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Repair,

        [Parameter(ParameterSetName = 'RebuildDatabase', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $RebuildDatabase,

        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $InstallFailoverCluster,

        [Parameter(ParameterSetName = 'PrepareFailoverCluster', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $PrepareFailoverCluster,

        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $CompleteFailoverCluster,

        [Parameter(ParameterSetName = 'AddNode', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $AddNode,

        [Parameter(ParameterSetName = 'RemoveNode', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $RemoveNode,

        [Parameter(ParameterSetName = 'UsingConfigurationFile', Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path -Path $_))
            {
                throw $script:localizedData.Server_ConfigurationFileNotFound
            }

            return $true
        })]
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
        [Parameter(ParameterSetName = 'AddNode', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteImage', Mandatory = $true)]
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
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.SwitchParameter]
        $IAcknowledgeEntCalLimits,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path -Path (Join-Path -Path $_ -ChildPath 'setup.exe')))
            {
                throw $script:localizedData.Server_MediaPathNotFound
            }

            return $true
        })]
        [System.String]
        $MediaPath,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Uninstall', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Upgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Repair', Mandatory = $true)]
        [Parameter(ParameterSetName = 'RebuildDatabase', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AddNode', Mandatory = $true)]
        [Parameter(ParameterSetName = 'RemoveNode', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $InstanceName,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.SwitchParameter]
        $Enu,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.SwitchParameter]
        $UpdateEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $UpdateSource,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Repair', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Uninstall', Mandatory = $true)]
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
            'ARC'
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
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstanceId,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $PBEngSvcAccount,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.PSCredential]
        $PBEngSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $PBEngSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $PBDMSSvcAccount, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.PSCredential]
        $PBDMSSvcPassword, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $PBDMSSvcStartupType, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.UInt16]
        $PBStartPortRange,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.UInt16]
        $PBEndPortRange,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.SwitchParameter]
        $PBScaleOut,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [System.String]
        $ProductKey, # This is argument PID but $PID is reserved variable.

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $AgtSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.PSCredential]
        $AgtSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $AgtSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASBackupDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASCollation,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASConfigDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASDataDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASTempDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [ValidateSet('Multidimensional', 'PowerPivot', 'Tabular')]
        [System.String]
        $ASServerMode,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $ASSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.PSCredential]
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
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String[]]
        $ASSysAdminAccounts,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.Management.Automation.SwitchParameter]
        $ASProviderMSOLAP,

        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String]
        $FarmAccount,

        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.PSCredential]
        $FarmPassword,

        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.PSCredential]
        $Passphrase,

        [Parameter(ParameterSetName = 'InstallRole')]
        [ValidateRange(0, 65536)]
        [System.UInt16]
        $FarmAdminiPort, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
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
        [Parameter(ParameterSetName = 'CompleteImage')]
        [System.Management.Automation.SwitchParameter]
        $EnableRanU,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [System.String]
        $InstallSqlDataDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlBackupDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [ValidateSet('SQL')]
        [System.String]
        $SecurityMode,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.Management.Automation.PSCredential]
        $SAPwd,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlCollation,

        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $AddCurrentUserAsSqlAdmin,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $SqlSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.PSCredential]
        $SqlSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $SqlSvcStartupType,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.String[]]
        $SqlSysAdminAccounts,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.UInt16]
        $SqlTempDbFileCount,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [ValidateRange(4, 262144)]
        [System.UInt16]
        $SqlTempDbFileSize,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [ValidateRange(0, 1024)]
        [System.UInt16]
        $SqlTempDbFileGrowth,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [ValidateRange(4, 262144)]
        [System.UInt16]
        $SqlTempDbLogFileSize,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [ValidateRange(0, 1024)]
        [System.UInt16]
        $SqlTempDbLogFileGrowth,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlUserDbDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [System.Management.Automation.SwitchParameter]
        $SqlSvcInstantFileInit,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
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
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [ValidateRange(0, 3)]
        [System.UInt16]
        $FileStreamLevel,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $FileStreamShareName,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $ISSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.PSCredential]
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
        [Parameter(ParameterSetName = 'CompleteImage')]
        [System.Management.Automation.SwitchParameter]
        $NpEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [System.Management.Automation.SwitchParameter]
        $TcpEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.String]
        $RsInstallMode,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $RSSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.PSCredential]
        $RSSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallRole')]
        [Parameter(ParameterSetName = 'CompleteImage')]
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
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $FailoverClusterGroup,

        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String[]]
        $FailoverClusterDisks,

        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AddNode', Mandatory = $true)]
        [System.String[]]
        $FailoverClusterIPAddresses,

        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [Parameter(ParameterSetName = 'RemoveNode')]
        [System.Management.Automation.SwitchParameter]
        $ConfirmIPDependencyChange,

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
        [System.Management.Automation.PSCredential]
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

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent)
    {
        $ConfirmPreference = 'None'
    }

    Assert-ElevatedUser -ErrorAction 'Stop'

    switch ($PSCmdlet.ParameterSetName)
    {
        'InstallRole'
        {
            $setupAction = 'Install'

            break
        }

        'InstallAzureArcAgent'
        {
            $setupAction = 'Install'

            <#
                For this setup action the parameter Features is not part of the
                parameter set, so this can be safely set.
            #>
            $PSBoundParameters.Features = @('ARC')

            break
        }

        default
        {
            $setupAction = $PSCmdlet.ParameterSetName

            break
        }
    }

    Assert-SetupActionProperties -Property $PSBoundParameters -SetupAction $setupAction -ErrorAction 'Stop'

    $setupArgument = '/QUIET /ACTION={0}' -f $setupAction

    if ($DebugPreference -in @('Continue', 'Inquire'))
    {
        $setupArgument += ' /INDICATEPROGRESS' # cspell: disable-line
    }

    if ($AcceptLicensingTerms.IsPresent)
    {
        $setupArgument += ' /IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line

        if ($PSBoundParameters.ContainsKey('Features'))
        {
            if ($PSBoundParameters.Features -contains 'SQL_SHARED_MR' )
            {
                $setupArgument += ' /IACCEPTROPENLICENSETERMS' # cspell: disable-line
            }

            if ($PSBoundParameters.Features -contains 'SQL_SHARED_MPY' )
            {
                $setupArgument += ' /IACCEPTPYTHONLICENSETERMS' # cspell: disable-line
            }
        }
    }

    $ignoreParameters = @(
        $PSCmdlet.ParameterSetName
        'Install' # Must add this exclusively because of parameter set InstallAzureArcAgent
        'AcceptLicensingTerms'
        'MediaPath'
        'Timeout'
        'Force'
    )

    $ignoreParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
    $ignoreParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    $boundParameterName = $PSBoundParameters.Keys.Where({ $_ -notin $ignoreParameters })

    $sensitiveValue = @()

    $pathParameter = @(
        'InstallSharedDir'
        'InstallSharedWowDir'
        'InstanceDir'
        'ASBackupDir'
        'ASConfigDir'
        'ASDataDir'
        'ASLogDir'
        'ASTempDir'
        'InstallSqlDataDir'
        'SqlBackupDir'
        'SqlTempDbDir'
        'SqlTempDbLogDir'
        'SqlUserDbDir'
        'SqlUserDbLogDir'
        'MPYCacheDirectory'
        'MRCacheDirectory'
        'SqlJavaDir'
    )

    <#
        Remove trialing backslash from paths so they are not interpreted as
        escape-characters for a double-quote.
        See issue https://github.com/dsccommunity/SqlServerDsc/issues/1254.
    #>
    $boundParameterName.Where( { $_ -in $pathParameter } ).ForEach({
        # Must not change paths that reference a root directory (they are handle differently later)
        if ($PSBoundParameters.$_ -notmatch '^[a-zA-Z]:\\$')
        {
            $PSBoundParameters.$_ = $PSBoundParameters.$_.TrimEnd('\')
        }
    })

    # Loop through all bound parameters and build arguments for the setup executable.
    foreach ($parameterName in $boundParameterName)
    {
        # Make sure parameter is upper-case.
        $parameterName = $parameterName.ToUpper()

        $setupArgument += ' /{0}' -f $parameterName

        switch ($parameterName)
        {
            <#
                Must be handled differently because it is an array and have a comma
                separating the values, and the value shall be upper-case.
            #>
            { $_ -in @('FEATURES', 'ROLE') }
            {
                $setupArgument += '={0}' -f ($PSBoundParameters.$parameterName.ToUpper() -join ',')

                if ($PSBoundParameters.Features -contains 'ARC' -and $PSBoundParameters.Features -contains 'SQLENGINE')
                {
                    $setupArgument += ' /ONBOARDSQLTOARC' # cspell: disable-line
                }

                break
            }

            # Must be handled differently because the value MUST be upper-case.
            'ASSERVERMODE' # cspell: disable-line
            {
                $setupArgument += '={0}' -f $PSBoundParameters.$parameterName.ToUpper()

                break
            }

            # Must be handled differently because the parameter name could not be $PID.
            'PRODUCTKEY' # cspell: disable-line
            {
                # Remove the argument that was added above.
                $setupArgument = $setupArgument -replace ' \/{0}' -f $parameterName

                $sensitiveValue += $PSBoundParameters.$parameterName

                $setupArgument += ' /PID="{0}"' -f $PSBoundParameters.$parameterName

                break
            }

            # Must be handled differently because the argument name shall have an underscore in the argument.
            'SQLINSTJAVA' # cspell: disable-line
            {
                # Remove the argument that was added above.
                $setupArgument = $setupArgument -replace ' \/{0}' -f $parameterName

                $setupArgument += ' /SQL_INST_JAVA'

                break
            }

            # Must be handled differently because each value shall be separated by a semi-colon.
            'FAILOVERCLUSTERDISKS' # cspell: disable-line
            {
                $setupArgument += '="{0}"' -f ($PSBoundParameters.$parameterName -join ';')

                break
            }

            # Must be handled differently because two parameters shall become one argument.
            { $_ -in ('PBSTARTPORTRANGE', 'PBENDPORTRANGE') } # cspell: disable-line
            {
                # Remove the argument that was added above.
                $setupArgument = $setupArgument -replace ' \/{0}' -f $parameterName

                # Only set argument if it is not present already.
                if ($setupArgument -notmatch '\/PBPORTRANGE') # cspell: disable-line
                {
                    # cspell: disable-next
                    $setupArgument += ' /PBPORTRANGE={0}-{1}' -f $PSBoundParameters.PBStartPortRange, $PSBoundParameters.PBEndPortRange
                }

                break
            }

            { $PSBoundParameters.$parameterName -is [System.Management.Automation.SwitchParameter] }
            {
                <#
                    If a switch parameter is not included below then those arguments
                    shall not have any value after argument name, e.g. '/ENU'.
                #>
                switch ($parameterName)
                {
                    # Arguments that shall have the value set to the boolean numeric representation.
                    { $parameterName -in ('ASPROVIDERMSOLAP', 'NPENABLED', 'TCPENABLED', 'CONFIRMIPDEPENDENCYCHANGE') } # cspell: disable-line
                    {
                        $setupArgument += '={0}' -f [System.Byte] $PSBoundParameters.$parameterName.ToBool()

                        break
                    }

                    <#
                        Arguments that shall have the value set to the boolean string representation.
                        Excluding parameter names that shall be handled differently, those arguments
                        shall not have any value after argument name, e.g. '/ENU'.
                    #>
                    { $parameterName -in @('UPDATEENABLED', 'PBSCALEOUT', 'SQLSVCINSTANTFILEINIT', 'ALLOWUPGRADEFORSSRSSHAREPOINTMODE', 'ADDCURRENTUSERASSQLADMIN', 'IACKNOWLEDGEENTCALLIMITS') } # cspell: disable-line
                    {
                        $setupArgument += '={0}' -f $PSBoundParameters.$parameterName.ToString()

                        break
                    }
                }

                break
            }

            <#
                Must be handled differently because it is an numeric value and does not need to
                be surrounded by double-quote.
            #>
            { $PSBoundParameters.$parameterName | Test-IsNumericType }
            {
                $setupArgument += '={0}' -f ($PSBoundParameters.$parameterName -join '" "')

                break
            }

            <#
                Must be handled differently because it is an array and have a space
                separating the values, and each value is surrounded by double-quote.
            #>
            { $PSBoundParameters.$parameterName -is [System.Array] }
            {
                $setupArgument += '="{0}"' -f ($PSBoundParameters.$parameterName -join '" "')

                break
            }

            { $PSBoundParameters.$parameterName -is [System.Management.Automation.PSCredential] }
            {
                $sensitiveValue += $PSBoundParameters.$parameterName.GetNetworkCredential().Password

                $setupArgument += '="{0}"' -f $PSBoundParameters.$parameterName.GetNetworkCredential().Password

                break
            }

            default
            {
                <#
                    When there is backslash followed by a double-quote then the backslash
                    is treated as an escape character for the double-quote. For arguments
                    that holds a path and the value references a root directory, e.g. 'E:\',
                    then the value must not be surrounded by double-quotes. Other paths
                    should be surrounded by double-quotes as they can contain spaces.
                    See issue https://github.com/dsccommunity/SqlServerDsc/issues/1254.
                #>
                if ($PSBoundParameters.$parameterName -match '^[a-zA-Z]:\\$')
                {
                    $setupArgument += '={0}' -f $PSBoundParameters.$parameterName
                }
                else
                {
                    $setupArgument += '="{0}"' -f $PSBoundParameters.$parameterName
                }
                break
            }
        }
    }

    $verboseSetupArgument = $setupArgument

    # Obfuscate sensitive values.
    foreach ($currentSensitiveValue in $sensitiveValue)
    {
        $escapedRegExString = [System.Text.RegularExpressions.Regex]::Escape($currentSensitiveValue)

        $verboseSetupArgument = $verboseSetupArgument -replace $escapedRegExString, '********'
    }

    # Clear sensitive values.
    $sensitiveValue = $null

    Write-Verbose -Message ($script:localizedData.Server_SetupArguments -f $verboseSetupArgument)

    $verboseDescriptionMessage = $script:localizedData.Server_Install_ShouldProcessVerboseDescription -f $PSCmdlet.ParameterSetName
    $verboseWarningMessage = $script:localizedData.Server_Install_ShouldProcessVerboseWarning -f $PSCmdlet.ParameterSetName
    $captionMessage = $script:localizedData.Server_Install_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $startProcessParameters = @{
            FilePath     = Join-Path -Path $MediaPath -ChildPath 'setup.exe'
            ArgumentList = $setupArgument
            Timeout      = $Timeout
        }

        # Clear setupArgument to remove any sensitive values.
        $setupArgument = $null

        # Run setup executable.
        $processExitCode = Start-SqlSetupProcess @startProcessParameters

        $setupExitMessage = ($script:localizedData.Server_SetupExitMessage -f $processExitCode)

        if ($processExitCode -eq 3010)
        {
            Write-Warning -Message (
                '{0} {1}' -f $setupExitMessage, $script:localizedData.Server_SetupSuccessfulRebootRequired
            )
        }
        elseif ($processExitCode -ne 0)
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ('{0} {1}' -f $setupExitMessage, $script:localizedData.Server_SetupFailed),
                    'ISDS0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $InstanceName
                )
            )
        }
        else
        {
            Write-Verbose -Message (
                '{0} {1}' -f $setupExitMessage, ($script:localizedData.Server_SetupSuccessful)
            )
        }
    }
}
