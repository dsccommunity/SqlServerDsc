<#
    .SYNOPSIS
        The `SqlInstall` DSC resource is used to create, modify, or remove
        server audits.

    .DESCRIPTION
        The `SqlInstall` DSC resource is used to create, modify, or remove
        server audits.

        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. See the [SQL Server command line setup](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt)
        documentation which will stay relevant.

        The built-in parameter **PSDscRunAsCredential** can be used to run the resource
        as another user. The resource will then authenticate to the SQL Server
        instance as that user. It also possible to instead use impersonation by the
        parameter **Credential**.

        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must be running SQL Server Database Engine 2012 or later.
        * Target machine must have access to the SQLPS PowerShell module or the SqlServer
          PowerShell module.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlInstall).

        ### Property **Reasons** does not work with **PSDscRunAsCredential**

        When using the built-in parameter **PSDscRunAsCredential** the read-only
        property **Reasons** will return empty values for the properties **Code**
        and **Phrase. The built-in property **PSDscRunAsCredential** does not work
        together with class-based resources that using advanced type like the parameter
        **Reasons** have.

        ### Using **Credential** property

        SQL Authentication and Group Managed Service Accounts is not supported as
        impersonation credentials. Currently only Windows Integrated Security is
        supported to use as credentials.

        For Windows Authentication the username must either be provided with the User
        Principal Name (UPN), e.g. `username@domain.local` or if using non-domain
        (for example a local Windows Server account) account the username must be
        provided without the NetBIOS name, e.g. `username`. Using the NetBIOS name, e.g
        using the format `DOMAIN\username` will not work.

        See more information in [Credential Overview](https://github.com/dsccommunity/SqlServerDsc/wiki/CredentialOverview).

    .PARAMETER AcceptLicensingTerms
        Required parameter to be able to run unattended install. By specifying this
        parameter you acknowledge the acceptance all license terms and notices for
        the specified features, the terms and notices that the Microsoft SQL Server
        setup executable normally ask for.

    .PARAMETER SuppressPrivacyStatementNotice
        See the notes section for more information.

    .PARAMETER IAcknowledgeEntCalLimits
        See the notes section for more information.

    .PARAMETER Enu
        See the notes section for more information.

    .PARAMETER UpdateEnabled
        See the notes section for more information.

    .PARAMETER UpdateSource
        See the notes section for more information.

    .PARAMETER Features
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

    .PARAMETER PBDMSSvcAccount
        See the notes section for more information.

    .PARAMETER PBDMSSvcPassword
        See the notes section for more information.

    .PARAMETER PBDMSSvcStartupType
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

    .PARAMETER AgtSvcStartupType
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

    .PARAMETER BrowserSvcStartupType
        See the notes section for more information.

    .PARAMETER FTUpgradeOption
        See the notes section for more information.

    .PARAMETER EnableRanU
        See the notes section for more information.

    .PARAMETER InstallSqlDataDir
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

    .PARAMETER SqlSysAdminAccounts
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

    .PARAMETER SqlSvcInstantFileInit
        See the notes section for more information.

    .PARAMETER SqlUserDbLogDir
        See the notes section for more information.

    .PARAMETER SqlMaxDop
        See the notes section for more information.

    .PARAMETER UseSqlRecommendedMemoryLimits
        See the notes section for more information.

    .PARAMETER SqlMinMemory
        See the notes section for more information.

    .PARAMETER SqlMaxMemory
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

    .PARAMETER AllowUpgradeForSSRSSharePointMode
        See the notes section for more information.

    .PARAMETER NpEnabled
        See the notes section for more information.

    .PARAMETER TcpEnabled
        See the notes section for more information.

    .PARAMETER RsInstallMode
        See the notes section for more information.

    .PARAMETER RSSvcAccount
        See the notes section for more information.

    .PARAMETER RSSvcPassword
        See the notes section for more information.

    .PARAMETER RSSvcStartupType
        See the notes section for more information.

    .PARAMETER MPYCacheDirectory
        See the notes section for more information.

    .PARAMETER MRCacheDirectory
        See the notes section for more information.

    .PARAMETER SqlInstJava
        See the notes section for more information.

    .PARAMETER SqlJavaDir
        See the notes section for more information.

    .PARAMETER FailoverClusterGroup
        See the notes section for more information.

    .PARAMETER FailoverClusterDisks
        See the notes section for more information.

    .PARAMETER FailoverClusterNetworkName
        See the notes section for more information.

    .PARAMETER FailoverClusterIPAddresses
        See the notes section for more information.

    .PARAMETER FailoverClusterRollOwnership
        See the notes section for more information.

    .PARAMETER AzureSubscriptionId
        See the notes section for more information.

    .PARAMETER AzureResourceGroup
        See the notes section for more information.

    .PARAMETER AzureRegion
        See the notes section for more information.

    .PARAMETER AzureTenantId
        See the notes section for more information.

    .PARAMETER AzureServicePrincipal
        See the notes section for more information.

    .PARAMETER AzureServicePrincipalSecret
        See the notes section for more information.

    .PARAMETER AzureArcProxy
        See the notes section for more information.

    .PARAMETER SkipRules
        See the notes section for more information.

    .PARAMETER ProductCoveredBySA
        See the notes section for more information.

    .EXAMPLE
        TODO: Must update the example.

        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlInstall -Method Get -Property @{
            ServerName           = 'localhost'
            InstanceName         = 'SQL2017'
            Credential           = (Get-Credential -UserName 'myuser@company.local' -Message 'Password:')
            Features             = 'SQLENGINE'
        }

        This example shows how to call the resource using Invoke-DscResource.
#>
[DscResource(RunAsCredential = 'Optional')]
class SqlInstall : SqlSetupBase
{
    [DscProperty(Mandatory)]
    [Nullable[System.Boolean]]
    $AcceptLicensingTerms

    [DscProperty()]
    [Nullable[System.Boolean]]
    $SuppressPrivacyStatementNotice

    [DscProperty()]
    [Nullable[System.Boolean]]
    $IAcknowledgeEntCalLimits

    [DscProperty()]
    [Nullable[System.Boolean]]
    $Enu

    [DscProperty()]
    [Nullable[System.Boolean]]
    $UpdateEnabled

    [DscProperty()]
    [System.String]
    $UpdateSource

    [DscProperty(Mandatory)]
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
    $Features

    [DscProperty()]
    [System.String]
    $InstallSharedDir

    [DscProperty()]
    [System.String]
    $InstallSharedWowDir

    [DscProperty()]
    [System.String]
    $InstanceDir

    [DscProperty()]
    [System.String]
    $InstanceId

    [DscProperty()]
    [System.String]
    $PBEngSvcAccount

    [DscProperty()]
    [System.Security.SecureString]
    $PBEngSvcPassword

    [DscProperty()]
    [ValidateSet('Automatic', 'Disabled', 'Manual')]
    [System.String]
    $PBEngSvcStartupType

    [DscProperty()]
    [System.String]
    $PBDMSSvcAccount

    [DscProperty()]
    [System.Security.SecureString]
    $PBDMSSvcPassword

    [DscProperty()]
    [ValidateSet('Automatic', 'Disabled', 'Manual')]
    [System.String]
    $PBDMSSvcStartupType

    [DscProperty()]
    [Nullable[System.UInt16]]
    $PBStartPortRange

    [DscProperty()]
    [Nullable[System.UInt16]]
    $PBEndPortRange

    [DscProperty()]
    [Nullable[System.Boolean]]
    $PBScaleOut

    [DscProperty()]
    [System.String]
    $ProductKey # This is argument PID but $PID is reserved variable.

    [DscProperty()]
    [System.String]
    $AgtSvcAccount

    [DscProperty()]
    [System.Security.SecureString]
    $AgtSvcPassword

    [DscProperty()]
    [ValidateSet('Automatic', 'Disabled', 'Manual')]
    [System.String]
    $AgtSvcStartupType

    [DscProperty()]
    [System.String]
    $ASBackupDir

    [DscProperty()]
    [System.String]
    $ASCollation

    [DscProperty()]
    [System.String]
    $ASConfigDir

    [DscProperty()]
    [System.String]
    $ASDataDir

    [DscProperty()]
    [System.String]
    $ASLogDir

    [DscProperty()]
    [System.String]
    $ASTempDir

    [DscProperty()]
    [ValidateSet('Multidimensional', 'PowerPivot', 'Tabular')]
    [System.String]
    $ASServerMode

    [DscProperty()]
    [System.String]
    $ASSvcAccount

    [DscProperty()]
    [System.Security.SecureString]
    $ASSvcPassword

    [DscProperty()]
    [ValidateSet('Automatic', 'Disabled', 'Manual')]
    [System.String]
    $ASSvcStartupType

    [DscProperty()]
    [System.String[]]
    $ASSysAdminAccounts

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ASProviderMSOLAP

    [DscProperty()]
    [ValidateSet('Automatic', 'Disabled', 'Manual')]
    [System.String]
    $BrowserSvcStartupType

    [DscProperty()]
    [Nullable[System.Boolean]]
    $EnableRanU

    [DscProperty()]
    [System.String]
    $InstallSqlDataDir

    [DscProperty()]
    [System.String]
    $SqlBackupDir

    [DscProperty()]
    [ValidateSet('SQL')]
    [System.String]
    $SecurityMode

    [DscProperty()]
    [System.Security.SecureString]
    $SAPwd

    [DscProperty()]
    [System.String]
    $SqlCollation

    [DscProperty()]
    [System.String]
    $SqlSvcAccount

    [DscProperty()]
    [System.Security.SecureString]
    $SqlSvcPassword

    [DscProperty()]
    [ValidateSet('Automatic', 'Disabled', 'Manual')]
    [System.String]
    $SqlSvcStartupType

    [DscProperty()]
    [System.String[]]
    $SqlSysAdminAccounts

    [DscProperty()]
    [System.String]
    $SqlTempDbDir

    [DscProperty()]
    [System.String]
    $SqlTempDbLogDir

    [DscProperty()]
    [Nullable[System.UInt16]]
    $SqlTempDbFileCount

    [DscProperty()]
    [ValidateRange(4, 262144)]
    [Nullable[System.UInt16]]
    $SqlTempDbFileSize

    [DscProperty()]
    [ValidateRange(0, 1024)]
    [Nullable[System.UInt16]]
    $SqlTempDbFileGrowth

    [DscProperty()]
    [ValidateRange(4, 262144)]
    [Nullable[System.UInt16]]
    $SqlTempDbLogFileSize

    [DscProperty()]
    [ValidateRange(0, 1024)]
    [Nullable[System.UInt16]]
    $SqlTempDbLogFileGrowth

    [DscProperty()]
    [System.String]
    $SqlUserDbDir

    [DscProperty()]
    [Nullable[System.Boolean]]
    $SqlSvcInstantFileInit

    [DscProperty()]
    [System.String]
    $SqlUserDbLogDir

    [DscProperty()]
    [ValidateRange(0, 32767)]
    [Nullable[System.UInt16]]
    $SqlMaxDop

    [DscProperty()]
    [Nullable[System.Boolean]]
    $UseSqlRecommendedMemoryLimits

    [DscProperty()]
    [ValidateRange(0, 2147483647)]
    [Nullable[System.UInt32]]
    $SqlMinMemory

    [DscProperty()]
    [ValidateRange(0, 2147483647)]
    [Nullable[System.UInt32]]
    $SqlMaxMemory

    [DscProperty()]
    [ValidateRange(0, 3)]
    [Nullable[System.UInt16]]
    $FileStreamLevel

    [DscProperty()]
    [System.String]
    $FileStreamShareName

    [DscProperty()]
    [System.String]
    $ISSvcAccount

    [DscProperty()]
    [System.Security.SecureString]
    $ISSvcPassword

    [DscProperty()]
    [ValidateSet('Automatic', 'Disabled', 'Manual')]
    [System.String]
    $ISSvcStartupType

    [DscProperty()]
    [Nullable[System.Boolean]]
    $NpEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $TcpEnabled

    [DscProperty()]
    [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
    [System.String]
    $RsInstallMode

    [DscProperty()]
    [System.String]
    $RSSvcAccount

    [DscProperty()]
    [System.Security.SecureString]
    $RSSvcPassword

    [DscProperty()]
    [ValidateSet('Automatic', 'Disabled', 'Manual')]
    [System.String]
    $RSSvcStartupType

    [DscProperty()]
    [System.String]
    $MPYCacheDirectory

    [DscProperty()]
    [System.String]
    $MRCacheDirectory

    [DscProperty()]
    [Nullable[System.Boolean]]
    $SqlInstJava

    [DscProperty()]
    [System.String]
    $SqlJavaDir

    [DscProperty()]
    [System.String]
    $AzureSubscriptionId

    [DscProperty()]
    [System.String]
    $AzureResourceGroup

    [DscProperty()]
    [System.String]
    $AzureRegion

    [DscProperty()]
    [System.String]
    $AzureTenantId

    [DscProperty()]
    [System.String]
    $AzureServicePrincipal

    [DscProperty()]
    [System.Security.SecureString]
    $AzureServicePrincipalSecret

    [DscProperty()]
    [System.String]
    $AzureArcProxy

    [DscProperty()]
    [System.String[]]
    $SkipRules

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ProductCoveredBySA

    SqlInstall () : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'ServerName'
            'InstanceName'
            'Name'
            'Credential'
            'Force'
        )
    }

    [SqlInstall] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [Nullable[System.Boolean]] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        return ([ResourceBase] $this).Test()
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    <#
        Base method Get() call this method to get the current state as a hashtable.
        The parameter properties will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message (
            $this.localizedData.EvaluateServerAudit -f @(
                $properties.Name,
                $properties.InstanceName
            )
        )

        $currentStateCredential = $null

        if ($this.Credential)
        {
            <#
                This does not work, even if username is set, the method Get() will
                return an empty PSCredential-object. Kept it here so it at least
                return a Credential object.
            #>
            $currentStateCredential = [PSCredential]::new(
                $this.Credential.UserName,
                [SecureString]::new()
            )
        }

        <#
            Only set key property Name if the audit exist. Base class will set it
            and handle Ensure.
        #>
        $currentState = @{
            Credential   = $currentStateCredential
            InstanceName = $properties.InstanceName
            ServerName   = $this.ServerName
        }

        $serverObject = $this.GetServerObject()

        # TODO: Should call commands that can return the installed state.

        # $auditObjectArray = $serverObject |
        #     Get-SqlDscAudit -Name $properties.Name -ErrorAction 'SilentlyContinue'

        return $currentState
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced are not in desired state. It is not called if all properties
        are in desired state. The variable $properties contain the properties
        that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        Install-SqlDscServer @properties -Force -ErrorAction 'Stop'
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # TODO: There might be a need to assert properties, if not this should be removed.
    }
}
# This has intentionally been put last in the file: cSpell: ignore PBDMS AZUREEXTENSION
