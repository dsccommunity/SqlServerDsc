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

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $AcceptTermAndNotices,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MediaPath,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Uninstall', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteImage', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Upgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'EditionUpgrade', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Repair', Mandatory = $true)]
        [Parameter(ParameterSetName = 'RebuildDatabase', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InstallFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CompleteFailoverCluster', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AddNode', Mandatory = $true)]
        [Parameter(ParameterSetName = 'RemoveNode', Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [System.Management.Automation.SwitchParameter]
        $Enu,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [System.Management.Automation.SwitchParameter]
        $UpdateEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [System.String]
        $UpdateSource,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
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
        [System.String]
        $InstallSharedDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $InstallSharedWowDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [System.String]
        $InstanceDir,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage', Mandatory = $true)]
        [System.String]
        $InstanceId,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [System.String]
        $PBEngSvcAccount,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [PSCredential]
        $PBEngSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
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
        [System.String]
        $PBPortRange,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'PrepareImage')]
        [System.Management.Automation.SwitchParameter]
        $PBScaleOut,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ProductKey, # Argument PID but $PID is reserved variable.

        # TODO: Might need to be required?
        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $AgtSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [PSCredential]
        $AgtSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $AgtSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ASBackupDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ASCollation,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ASConfigDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ASDataDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ASLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ASTempDir,

        # TODO: These values must converted to upper-case before passing as argument
        [Parameter(ParameterSetName = 'Install')]
        [ValidateSet('Multidimensional', 'PowerPivot', 'Tabular')]
        [System.String]
        $ASServerMode,

        # TODO: Might need to be required?
        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ASSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [PSCredential]
        $ASSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $ASSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ASSysAdminAccounts,

        [Parameter(ParameterSetName = 'Install')]
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
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $BrowserSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [System.Management.Automation.SwitchParameter]
        $EnableRanU,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $InstallSqlDataDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlBackupDir,

        [Parameter(ParameterSetName = 'Install')]
        [ValidateSet('SQL')]
        [System.String]
        $SecurityMode,

        # TODO: Required when using SecurityMode
        [Parameter(ParameterSetName = 'Install')]
        [PSCredential]
        $SAPwd,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlCollation,

        # TODO: /ADDCURRENTUSERASSQLADMIN or /SQLSYSADMINACCOUNTS is required for SQL Express. Another parameter set InstallSqlExpress?
        # [Parameter(ParameterSetName = 'Install')]
        # [System.Management.Automation.SwitchParameter]
        # $AddCurrentUserAsSqlAdmin,

        # TODO: Might need to be required?
        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [PSCredential]
        $SqlSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $SqlSvcStartupType,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [System.String[]]
        $SqlSysAdminAccounts,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlTempDbDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlTempDbLogDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlTempDbFileCount,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlTempDbFileSize,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlTempDbFileGrowth,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlTempDbLogFileSize,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlTempDbLogFileGrowth,

        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $SqlUserDbDir,

        [Parameter(ParameterSetName = 'Install')]
        [System.Management.Automation.SwitchParameter]
        $SqlSvcInstantFileInit,

        [Parameter(ParameterSetName = 'Install')]
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
        [ValidateRange(0, 3)]
        [System.Int16]
        $FileStreamLevel,

        # TODO: Required when FIleStreamLevel is greater than 1
        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $FileStreamShareName,

        # TODO: Ignored in Windows Server 2008 and higher
        # [Parameter(ParameterSetName = 'Install')]
        # [System.String]
        # $FTSvcAccount,

        # [Parameter(ParameterSetName = 'Install')]
        # [PSCredential]
        # $FTSvcPassword,

        # TODO: Might need to be required?
        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $ISSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [PSCredential]
        $ISSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $ISSvcStartupType,

        [Parameter(ParameterSetName = 'Install')]
        [System.Management.Automation.SwitchParameter]
        $NpEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [System.Management.Automation.SwitchParameter]
        $TcpEnabled,

        [Parameter(ParameterSetName = 'Install')]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.Management.Automation.SwitchParameter]
        $RsInstallMode,

        # TODO: Might need to be required?
        [Parameter(ParameterSetName = 'Install')]
        [System.String]
        $RSSvcAccount,

        [Parameter(ParameterSetName = 'UsingConfigurationFile')]
        [Parameter(ParameterSetName = 'Install')]
        [PSCredential]
        $RSSvcPassword,

        [Parameter(ParameterSetName = 'Install')]
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

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent)
    {
        $ConfirmPreference = 'None'
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


}
