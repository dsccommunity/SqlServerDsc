<#
    .SYNOPSIS
        Installs SQL Server in a failover cluster configuration.

    .DESCRIPTION
        Installs SQL Server in a failover cluster configuration using the Microsoft
        SQL Server setup executable. This command performs a new failover cluster
        installation.

        See the link in the commands help for information on each parameter. The
        link points to SQL Server command line setup documentation.

    .PARAMETER AcceptLicensingTerms
        Required parameter to be able to run unattended install. By specifying this
        parameter you acknowledge the acceptance all license terms and notices for
        the specified features, the terms and notices that the Microsoft SQL Server
        setup executable normally ask for.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .PARAMETER InstanceName
        See the notes section for more information.

    .PARAMETER Features
        See the notes section for more information.

    .PARAMETER InstallSqlDataDir
        See the notes section for more information.

    .PARAMETER SqlSysAdminAccounts
        See the notes section for more information.

    .PARAMETER FailoverClusterNetworkName
        See the notes section for more information.

    .PARAMETER FailoverClusterIPAddresses
        See the notes section for more information.

    .PARAMETER IAcknowledgeEntCalLimits
        See the notes section for more information.

    .PARAMETER Enu
        See the notes section for more information.

    .PARAMETER UpdateEnabled
        See the notes section for more information.

    .PARAMETER UpdateSource
        See the notes section for more information.

    .PARAMETER InstallSharedDir
        See the notes section for more information.

    .PARAMETER InstallSharedWowDir
        See the notes section for more information.

    .PARAMETER InstanceDir
        See the notes section for more information.

    .PARAMETER InstanceId
        See the notes section for more information.

    .PARAMETER PBEngSvcAccount
        See the notes section for more information.

    .PARAMETER PBEngSvcPassword
        See the notes section for more information.

    .PARAMETER PBEngSvcStartupType
        See the notes section for more information.

    .PARAMETER PBStartPortRange
        See the notes section for more information.

    .PARAMETER PBEndPortRange
        See the notes section for more information.

    .PARAMETER PBScaleOut
        See the notes section for more information.

    .PARAMETER ProductKey
        See the notes section for more information.

    .PARAMETER AgtSvcAccount
        See the notes section for more information.

    .PARAMETER AgtSvcPassword
        See the notes section for more information.

    .PARAMETER ASBackupDir
        See the notes section for more information.

    .PARAMETER ASCollation
        See the notes section for more information.

    .PARAMETER ASConfigDir
        See the notes section for more information.

    .PARAMETER ASDataDir
        See the notes section for more information.

    .PARAMETER ASLogDir
        See the notes section for more information.

    .PARAMETER ASTempDir
        See the notes section for more information.

    .PARAMETER ASServerMode
        See the notes section for more information.

    .PARAMETER ASSvcAccount
        See the notes section for more information.

    .PARAMETER ASSvcPassword
        See the notes section for more information.

    .PARAMETER ASSvcStartupType
        See the notes section for more information.

    .PARAMETER ASSysAdminAccounts
        See the notes section for more information.

    .PARAMETER ASProviderMSOLAP
        See the notes section for more information.

    .PARAMETER SqlBackupDir
        See the notes section for more information.

    .PARAMETER SecurityMode
        See the notes section for more information.

    .PARAMETER SAPwd
        See the notes section for more information.

    .PARAMETER SqlCollation
        See the notes section for more information.

    .PARAMETER SqlSvcAccount
        See the notes section for more information.

    .PARAMETER SqlSvcPassword
        See the notes section for more information.

    .PARAMETER SqlSvcStartupType
        See the notes section for more information.

    .PARAMETER SqlTempDbDir
        See the notes section for more information.

    .PARAMETER SqlTempDbLogDir
        See the notes section for more information.

    .PARAMETER SqlTempDbFileCount
        See the notes section for more information.

    .PARAMETER SqlTempDbFileSize
        See the notes section for more information.

    .PARAMETER SqlTempDbFileGrowth
        See the notes section for more information.

    .PARAMETER SqlTempDbLogFileSize
        See the notes section for more information.

    .PARAMETER SqlTempDbLogFileGrowth
        See the notes section for more information.

    .PARAMETER SqlUserDbDir
        See the notes section for more information.

    .PARAMETER SqlUserDbLogDir
        See the notes section for more information.

    .PARAMETER FileStreamLevel
        See the notes section for more information.

    .PARAMETER FileStreamShareName
        See the notes section for more information.

    .PARAMETER ISSvcAccount
        See the notes section for more information.

    .PARAMETER ISSvcPassword
        See the notes section for more information.

    .PARAMETER ISSvcStartupType
        See the notes section for more information.

    .PARAMETER RsInstallMode
        See the notes section for more information.

    .PARAMETER RSSvcAccount
        See the notes section for more information.

    .PARAMETER RSSvcPassword
        See the notes section for more information.

    .PARAMETER RSSvcStartupType
        See the notes section for more information.

    .PARAMETER FailoverClusterGroup
        See the notes section for more information.

    .PARAMETER FailoverClusterDisks
        See the notes section for more information.

    .PARAMETER SkipRules
        See the notes section for more information.

    .PARAMETER ProductCoveredBySA
        See the notes section for more information.

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .PARAMETER Force
        If specified the command will not ask for confirmation. Same as if Confirm:$false
        is used.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        Install-SqlDscFailoverCluster -AcceptLicensingTerms -InstanceName 'MyInstance' -Features 'SQLENGINE' -InstallSqlDataDir 'D:\MSSQL\Data' -SqlSysAdminAccounts @('MyAdminAccount') -FailoverClusterNetworkName 'TestCluster01A' -FailoverClusterIPAddresses 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0' -MediaPath 'E:\'

        Installs the database engine in a failover cluster with the instance name 'MyInstance'.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.
#>
function Install-SqlDscFailoverCluster
{
    # cSpell: ignore PBDMS Admini AZUREEXTENSION
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in Invoke-SetupAction')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $AcceptLicensingTerms,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MediaPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallSqlDataDir,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $SqlSysAdminAccounts,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FailoverClusterIPAddresses,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IAcknowledgeEntCalLimits,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Enu,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UpdateEnabled,

        [Parameter()]
        [System.String]
        $UpdateSource,

        [Parameter()]
        [System.String]
        $InstallSharedDir,

        [Parameter()]
        [System.String]
        $InstallSharedWowDir,

        [Parameter()]
        [System.String]
        $InstanceDir,

        [Parameter()]
        [System.String]
        $InstanceId,

        [Parameter()]
        [System.String]
        $PBEngSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $PBEngSvcPassword,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $PBEngSvcStartupType,

        [Parameter()]
        [System.UInt16]
        $PBStartPortRange,

        [Parameter()]
        [System.UInt16]
        $PBEndPortRange,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PBScaleOut,

        [Parameter()]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.String]
        $AgtSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $AgtSvcPassword,

        [Parameter()]
        [System.String]
        $ASBackupDir,

        [Parameter()]
        [System.String]
        $ASCollation,

        [Parameter()]
        [System.String]
        $ASConfigDir,

        [Parameter()]
        [System.String]
        $ASDataDir,

        [Parameter()]
        [System.String]
        $ASLogDir,

        [Parameter()]
        [System.String]
        $ASTempDir,

        [Parameter()]
        [ValidateSet('Multidimensional', 'PowerPivot', 'Tabular')]
        [System.String]
        $ASServerMode,

        [Parameter()]
        [System.String]
        $ASSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $ASSvcPassword,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $ASSvcStartupType,

        [Parameter()]
        [System.String[]]
        $ASSysAdminAccounts,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ASProviderMSOLAP,

        [Parameter()]
        [System.String]
        $SqlBackupDir,

        [Parameter()]
        [ValidateSet('SQL')]
        [System.String]
        $SecurityMode,

        [Parameter()]
        [System.Security.SecureString]
        $SAPwd,

        [Parameter()]
        [System.String]
        $SqlCollation,

        [Parameter()]
        [System.String]
        $SqlSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $SqlSvcPassword,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $SqlSvcStartupType,

        [Parameter()]
        [System.String]
        $SqlTempDbDir,

        [Parameter()]
        [System.String]
        $SqlTempDbLogDir,

        [Parameter()]
        [System.UInt16]
        $SqlTempDbFileCount,

        [Parameter()]
        [ValidateRange(4, 262144)]
        [System.UInt16]
        $SqlTempDbFileSize,

        [Parameter()]
        [ValidateRange(0, 1024)]
        [System.UInt16]
        $SqlTempDbFileGrowth,

        [Parameter()]
        [ValidateRange(4, 262144)]
        [System.UInt16]
        $SqlTempDbLogFileSize,

        [Parameter()]
        [ValidateRange(0, 1024)]
        [System.UInt16]
        $SqlTempDbLogFileGrowth,

        [Parameter()]
        [System.String]
        $SqlUserDbDir,

        [Parameter()]
        [System.String]
        $SqlUserDbLogDir,

        [Parameter()]
        [ValidateRange(0, 3)]
        [System.UInt16]
        $FileStreamLevel,

        [Parameter()]
        [System.String]
        $FileStreamShareName,

        [Parameter()]
        [System.String]
        $ISSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $ISSvcPassword,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $ISSvcStartupType,

        [Parameter()]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.String]
        $RsInstallMode,

        [Parameter()]
        [System.String]
        $RSSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $RSSvcPassword,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $RSSvcStartupType,

        [Parameter()]
        [System.String]
        $FailoverClusterGroup,

        [Parameter()]
        [System.String[]]
        $FailoverClusterDisks,

        [Parameter()]
        [System.String[]]
        $SkipRules,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ProductCoveredBySA,

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Invoke-SetupAction -InstallFailoverCluster @PSBoundParameters
}
