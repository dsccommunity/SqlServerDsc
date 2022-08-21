<#
    .SYNOPSIS
        Executes an install action using Microsoft SQL Server setup executable.

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

    .PARAMETER AcceptTermAndNotices
        Required parameter to be able to run unattended install. By specifying this
        parameter you acknowledge the acceptance all license terms and notices for
        the specified features, the terms and notices that the Microsoft SQL Server
        setup executable normally ask for.

        This will be the same as passing `/SUPPRESSPRIVACYSTATEMENTNOTICE`,
        `/IACCEPTSQLSERVERLICENSETERMS`, `/IACCEPTPYTHONLICENSETERMS`, and
        `/IACCEPTROPENLICENSETERMS` to the setup executable.

    .OUTPUTS
        None.

    .EXAMPLE
        Install-SqlDscServer -Install -AcceptTermAndNotices -InstanceName 'MyInstance' -Features 'SQLENGINE' -MediaPath 'E:\' -SqlSysAdminAccounts @('MyAdminAccount')

        Installs a named instance MyInstance.

    .NOTES
        None.
#>
function Install-SqlDscServer
{
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
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
        [System.String]
        $ConfigurationFile,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Upgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AddNode', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [System.Management.Automation.SwitchParameter]
        $AcceptTermAndNotices,

        [Parameter(Mandatory = $true)]
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
        [System.String]
        $InstanceName,

        [Parameter(ParameterSetName = 'Install')]
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
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.SwitchParameter]
        $UpdateEnabled,

        [Parameter(ParameterSetName = 'Install')]
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
        [System.String]
        $Features,

        # Skipped ERRORREPORTING because it is obsolete.

        # # This is mutually exclusive from parameter Features
        # [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        # [System.String]
        # $Role,

        # TODO: This could be used by Verbose or Debug?
        # [Parameter(ParameterSetName = 'Install')]
        # [System.Management.Automation.SwitchParameter]
        # $IndicateProgress,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstallSharedDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstallSharedWowDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstanceDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $InstanceId,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $PBEngSvcAccount,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [PSCredential]
        $PBEngSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
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
        [System.String]
        $PBDMSSvcAccount, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [PSCredential]
        $PBDMSSvcPassword, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $PBDMSSvcStartupType, # cspell: disable-line

        # TODO: Should be two Integer-parameters *StartRange och *EndRange
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $PBPortRange,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Repair')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.Management.Automation.SwitchParameter]
        $PBScaleOut,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [System.String]
        $ProductKey, # Argument PID but $PID is reserved variable.

        # TODO: Might need to be required?
        # When parameter set InstallFailoverCluster AgtSvcAccount is mandatory if feature 'SQLENGINE' is installed.
        # When parameter set PrepareFailOverCLuster AgtSvcAccount is mandatory if feature 'SQLENGINE' is installed.
        # When parameter set AddNode AgtSvcAccount is mandatory if feature 'SQLENGINE' is a feature of the cluster.
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $AgtSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [PSCredential]
        $AgtSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $AgtSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASBackupDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASCollation,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASConfigDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASDataDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASTempDir,

        # TODO: These values must converted to upper-case before passing as argument
        # TODO: The value PowerPivot is not allowed when parameter set is InstallFailoverCluster or CompleteFailoverCluster
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [ValidateSet('Multidimensional', 'PowerPivot', 'Tabular')]
        [System.String]
        $ASServerMode,

        # TODO: Might need to be required?
        # When parameter set InstallFailoverCluster ASSvcAccount is mandatory if feature 'AS' is installed.
        # When parameter set PrepareFailOverCLuster ASSvcAccount is mandatory if feature 'AS' is installed.
        # When parameter set AddNode ASSvcAccount is mandatory if feature 'AS' is a feature of the cluster.
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $ASSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [PSCredential]
        $ASSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $ASSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String[]]
        $ASSysAdminAccounts,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $ASProviderMSOLAP,

        # TODO: This is mandatory when using /ROLE = SPI_AS_NEWFARM
        # [Parameter(ParameterSetName = 'InstallRole', Mandatory = $true)]
        # [System.String]
        # $FarmAccount,

        # TODO: This is mandatory when using /ROLE = SPI_AS_NEWFARM
        # [Parameter(ParameterSetName = 'InstallRole', Mandatory = $true)]
        # [PSCredential]
        # $FarmPassword,

        # TODO: This is mandatory when using /ROLE = SPI_AS_NEWFARM
        # [Parameter(ParameterSetName = 'InstallRole', Mandatory = $true)]
        # [PSCredential]
        # $Passphrase,

        # TODO: This is mandatory when using /ROLE = SPI_AS_NEWFARM
        # [Parameter(ParameterSetName = 'InstallRole', Mandatory = $true)]
        # [PSCredential]
        # $FarmAdminiPort, # cspell: disable-line

        [Parameter(ParameterSetName = 'Install')]
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
        [Parameter(ParameterSetName = 'CompleteImage')]
        [System.Management.Automation.SwitchParameter]
        $EnableRanU,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [System.String]
        $InstallSqlDataDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlBackupDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [ValidateSet('SQL')]
        [System.String]
        $SecurityMode,

        <#
            TODO: Required when using SecurityMode = 'SQL'. For RebuildDatabase
            it must be set if the instance was installed with SecurityMode = 'SQL'.
        #>
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [PSCredential]
        $SAPwd,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlCollation,

        # TODO: /ADDCURRENTUSERASSQLADMIN or /SQLSYSADMINACCOUNTS is required for SQL Express. Another parameter set InstallSqlExpress?
        # [Parameter(ParameterSetName = 'Install')]
        # [System.Management.Automation.SwitchParameter]
        # $AddCurrentUserAsSqlAdmin,

        # TODO: Might need to be required?
        # When parameter set InstallFailOverCLuster SqlSvcAccount is mandatory if feature 'SQLENGINE' is installed.
        # When parameter set PrepareFailOverCLuster SqlSvcAccount is mandatory if feature 'SQLENGINE' is installed.
        # When parameter set AddNode SqlSvcAccount is mandatory if feature 'SQLENGINE' is a feature of the cluster.
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $SqlSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [PSCredential]
        $SqlSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
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
        [System.String[]]
        $SqlSysAdminAccounts,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbFileCount,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbFileSize,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbFileGrowth,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbLogFileSize,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'RebuildDatabase')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlTempDbLogFileGrowth,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlUserDbDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.Management.Automation.SwitchParameter]
        $SqlSvcInstantFileInit,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $SqlUserDbLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.Int16]
        $SqlMaxDop,

        # TODO: This parameter cannot be used with /SQLMINMEMORY and /SQLMAXMEMORY.
        [Parameter(ParameterSetName = 'Install')]
        [System.Management.Automation.SwitchParameter]
        $UseSqlRecommendedMemoryLimits,

        # TODO: This parameter cannot be used with /USESQLRECOMMENDEDMEMORYLIMITS.
        [Parameter(ParameterSetName = 'Install')]
        [System.Int32]
        $SqlMinMemory,

        # TODO: This parameter cannot be used with /USESQLRECOMMENDEDMEMORYLIMITS.
        [Parameter(ParameterSetName = 'Install')]
        [System.Int32]
        $SqlMaxMemory,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [ValidateRange(0, 3)]
        [System.Int16]
        $FileStreamLevel,

        # TODO: Required when FIleStreamLevel is greater than 1
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $FileStreamShareName,

        # TODO: Ignored in Windows Server 2008 and higher
        # [Parameter(ParameterSetName = 'Install')]
        # [Parameter(ParameterSetName = 'CompleteImage')]
        # [System.String]
        # $FTSvcAccount,

        # [Parameter(ParameterSetName = 'Install')]
        # [Parameter(ParameterSetName = 'CompleteImage')]
        # [PSCredential]
        # $FTSvcPassword,

        # TODO: Might need to be required?
        # When parameter set InstallFailOverCLuster ISSvcAccount is mandatory if feature 'IS' is installed.
        # When parameter set PrepareFailoverCluster ISSvcAccount is mandatory if feature 'IS' is installed.
        # When parameter set AddNode ISSvcAccount is mandatory if feature 'IS' is installed.
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [System.String]
        $ISSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Upgrade')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [PSCredential]
        $ISSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
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
        [Parameter(ParameterSetName = 'CompleteImage')]
        [System.Management.Automation.SwitchParameter]
        $NpEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [System.Management.Automation.SwitchParameter]
        $TcpEnabled,

        # TODO: When parameter set AddNode only the value FilesOnlyMode is allowed.
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.Management.Automation.SwitchParameter]
        $RsInstallMode,

        # TODO: Might need to be required?
        # When parameter set InstallFailOverCLuster RSSvcAccount is mandatory if feature 'RS' is installed.
        # When parameter set PrepareFailoverCluster RSSvcAccount is mandatory if feature 'RS' is installed.
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [System.String]
        $RSSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [PSCredential]
        $RSSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'CompleteImage')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $RSSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $MPYCacheDirectory,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $MRCacheDirectory,

        # TODO: This must be converted to SQL_INST_JAVA
        [Parameter(ParameterSetName = 'Install')]
        [System.Management.Automation.SwitchParameter]
        $SqlInstJava,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlJavaDir,

        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $FailoverClusterGroup,

        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [System.String]
        $FailoverClusterDisks,

        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AddNode', Mandatory = $true)]
        [System.String]
        $FailoverClusterIPAddresses,

        [Parameter(ParameterSetName = 'CompleteFailoverCluster')]
        [Parameter(ParameterSetName = 'AddNode')]
        [Parameter(ParameterSetName = 'RemoveNode')]
        [System.Management.Automation.SwitchParameter]
        $ConfirmIPDependencyChange,

        # TODO: Only when upgrading a failover cluster
        [Parameter(ParameterSetName = 'Upgrade')]
        [ValidateRange(0, 2)]
        [SYstem.Int16]
        $FailoverClusterRollOwnership,

        # TODO: Azure* parameters only allowed when /FEATURES contain 'ARC', and all must be set except AzureArcProxy
        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureSubscriptionId,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureResourceGroup,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureRegion,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureTenantId,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [System.String]
        $AzureServicePrincipal,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent', Mandatory = $true)]
        [PSCredential]
        $AzureServicePrincipalSecret,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallAzureArcAgent')]
        [System.String]
        $AzureArcProxy,

        # TODO: This parameter could be added automatically when using parameters set Install and one Azure* parameter is set.
        # [Parameter(ParameterSetName = 'Install')]
        # [System.Management.Automation.SwitchParameter]
        # $OnboardSqlToArc,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'InstallFailoverCluster')]
        [Parameter(ParameterSetName = 'EditionUpgrade')]
        [System.String[]]
        $SkipRules,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent)
    {
        $ConfirmPreference = 'None'
    }

    # TODO: Build command line.

    $verboseDescriptionMessage = $script:localizedData.Server_Install_ShouldProcessVerboseDescription -f $PSCmdlet.ParameterSetName
    $verboseWarningMessage = $script:localizedData.Server_Install_ShouldProcessVerboseWarning -f $PSCmdlet.ParameterSetName
    $captionMessage = $script:localizedData.Server_Install_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        # TODO: Run setup executable
    }

    # if verbose (or debug) is used, add argument /INDICATEPROGRESS (if it works to output to console)

    ## Install
    #setup.exe /q /ACTION=Install /FEATURES=SQL /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="<DomainName\UserName>" /SQLSVCPASSWORD="<StrongPassword>" /SQLSYSADMINACCOUNTS="<DomainName\UserName>" /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /SQLSVCINSTANTFILEINIT="True" /IACCEPTSQLSERVERLICENSETERMS

    ##  AzureArc (onboard) - note the parameter /ONBOARDSQLTOARC that is not present in the documentations parameter list
    #setup.exe /q /ACTION=Install /FEATURES=SQLEngine,ARC /INSTANCENAME=<instance name> /SQLSYSADMINACCOUNTS="<sysadmin account>" /IACCEPTSQLSERVERLICENSETERMS /ONBOARDSQLTOARC /AZURESUBSCRIPTIONID="<Azure subscription>" /AZURETENANTID="<00000000-0000-0000-0000-000000000000" /AZURERESOURCEGROUP="<resource group name>" /AZURESERVICEPRINCIPAL="<service principal>" /AZURESERVICEPRINCIPALSECRET="<secret>" /AZUREREGION=<Azure region>

    ## Azure Arc Agent
    # Using parameter set InstallAzureArcAgent should default to /FEATURES=ARC
    #setup.exe /qs /ACTION=Install /FEATURES=ARC  /IACCEPTSQLSERVERLICENSETERMS /AZURESUBSCRIPTIONID="<Azure subscription>" /AZURETENANTID="<00000000-0000-0000-0000-000000000000" /AZURERESOURCEGROUP="<resource group name>" /AZURESERVICEPRINCIPAL="<service principal>" /AZURESERVICEPRINCIPALSECRET="<secret>" /AZUREREGION=<Azure region>

    ## PrepareImage
    #setup.exe /q /ACTION=PrepareImage /FEATURES=SQL,RS /InstanceID =<MYINST> /IACCEPTSQLSERVERLICENSETERMS

    ## CompleteImage
    #setup.exe /q /ACTION=CompleteImage /INSTANCENAME=MYNEWINST /INSTANCEID=<MYINST> /SQLSVCACCOUNT="<DomainName\UserName>" /SQLSVCPASSWORD="<StrongPassword>" /SQLSYSADMINACCOUNTS="<DomainName\UserName>" /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /IACCEPTSQLSERVERLICENSETERMS

    ## Upgrade
    #setup.exe /q /ACTION=upgrade /INSTANCEID = <INSTANCEID>/INSTANCENAME=MSSQLSERVER /RSUPGRADEDATABASEACCOUNT="<Provide a SQL Server logon account that can connect to the report server during upgrade>" /RSUPGRADEPASSWORD="<Provide a password for the report server upgrade account>" /ISSVCAccount="NT Authority\Network Service" /IACCEPTSQLSERVERLICENSETERMS

    ## Repair
    #setup.exe /q /ACTION=Repair /INSTANCENAME=<instancename>

    ## RebuildDatabase
    # None

    ## Uninstall
    #setup.exe /Action=Uninstall /FEATURES=SQL,AS,RS,IS,Tools /INSTANCENAME=MSSQLSERVER

    ## InstallFailoverCluster
    #setup.exe /q /ACTION=InstallFailoverCluster /InstanceName=MSSQLSERVER /INDICATEPROGRESS /ASSYSADMINACCOUNTS="<DomainName\UserName>" /ASDATADIR=<Drive>:\OLAP\Data /ASLOGDIR=<Drive>:\OLAP\Log /ASBACKUPDIR=<Drive>:\OLAP\Backup /ASCONFIGDIR=<Drive>:\OLAP\Config /ASTEMPDIR=<Drive>:\OLAP\Temp /FAILOVERCLUSTERDISKS="<Cluster Disk Resource Name - for example, 'Disk S:'" /FAILOVERCLUSTERNETWORKNAME="<Insert Network Name>" /FAILOVERCLUSTERIPADDRESSES="IPv4;xx.xxx.xx.xx;Cluster Network;xxx.xxx.xxx.x" /FAILOVERCLUSTERGROUP="MSSQLSERVER" /Features=AS,SQL /ASSVCACCOUNT="<DomainName\UserName>" /ASSVCPASSWORD="xxxxxxxxxxx" /AGTSVCACCOUNT="<DomainName\UserName>" /AGTSVCPASSWORD="xxxxxxxxxxx" /INSTALLSQLDATADIR="<Drive>:\<Path>\MSSQLSERVER" /SQLCOLLATION="SQL_Latin1_General_CP1_CS_AS" /SQLSVCACCOUNT="<DomainName\UserName>" /SQLSVCPASSWORD="xxxxxxxxxxx" /SQLSYSADMINACCOUNTS="<DomainName\UserName> /IACCEPTSQLSERVERLICENSETERMS

    ## PrepareFailoverCluster
    #setup.exe /q /ACTION=PrepareFailoverCluster /InstanceName=MSSQLSERVER /Features=AS,SQL /INDICATEPROGRESS /ASSVCACCOUNT="<DomainName\UserName>" /ASSVCPASSWORD="xxxxxxxxxxx" /SQLSVCACCOUNT="<DomainName\UserName>" /SQLSVCPASSWORD="xxxxxxxxxxx" /AGTSVCACCOUNT="<DomainName\UserName>" /AGTSVCPASSWORD="xxxxxxxxxxx" /IACCEPTSQLSERVERLICENSETERMS

    ## CompleteFailoverCLuster
    #setup.exe /q /ACTION=CompleteFailoverCluster /InstanceName=MSSQLSERVER /INDICATEPROGRESS /ASSYSADMINACCOUNTS="<DomainName\Username>" /ASDATADIR=<Drive>:\OLAP\Data /ASLOGDIR=<Drive>:\OLAP\Log /ASBACKUPDIR=<Drive>:\OLAP\Backup /ASCONFIGDIR=<Drive>:\OLAP\Config /ASTEMPDIR=<Drive>:\OLAP\Temp /FAILOVERCLUSTERDISKS="<Cluster Disk Resource Name - for example, 'Disk S:'>:" /FAILOVERCLUSTERNETWORKNAME="<Insert FOI Network Name>" /FAILOVERCLUSTERIPADDRESSES="IPv4;xx.xxx.xx.xx;Cluster Network;xxx.xxx.xxx.x" /FAILOVERCLUSTERGROUP="MSSQLSERVER" /INSTALLSQLDATADIR="<Drive>:\<Path>\MSSQLSERVER" /SQLCOLLATION="SQL_Latin1_General_CP1_CS_AS" /SQLSYSADMINACCOUNTS="<DomainName\UserName>"

    ## AddNode
    #setup.exe /q /ACTION=AddNode /INSTANCENAME="<Insert Instance Name>" /SQLSVCACCOUNT="<SQL account that is used on other nodes>" /SQLSVCPASSWORD="<password for SQL account>" /AGTSVCACCOUNT="<SQL Server Agent account that is used on other nodes>", /AGTSVCPASSWORD="<SQL Server Agent account password>" /ASSVCACCOUNT="<AS account that is used on other nodes>" /ASSVCPASSWORD="<password for AS account>" /INDICATEPROGRESS /IACCEPTSQLSERVERLICENSETERMS /FAILOVERCLUSTERIPADDRESSES="IPv4;xx.xxx.xx.xx;ClusterNetwork1;xxx.xxx.xxx.x" /CONFIRMIPDEPENDENCYCHANGE=0

    ## RemoveNode
    #setup.exe /q /ACTION=RemoveNode /INSTANCENAME="<Insert Instance Name>" [/INDICATEPROGRESS] /CONFIRMIPDEPENDENCYCHANGE=0

    ## EditionUpgrade
    #setup.exe /q /ACTION=editionupgrade /InstanceName=MSSQLSERVER /PID=<appropriatePid> /SkipRules=Engine_SqlEngineHealthCheck
}
