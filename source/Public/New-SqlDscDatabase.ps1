<#
    .SYNOPSIS
        Creates a new database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command creates a new database in a SQL Server Database Engine instance.
        It supports creating both regular databases and database snapshots.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to be created.

    .PARAMETER Collation
        The name of the SQL collation to use for the new database.
        Default value is server collation.

    .PARAMETER CatalogCollation
        Specifies the collation type for the system catalog. Valid values are
        DATABASE_DEFAULT and SQL_Latin1_General_CP1_CI_AS. This property can
        only be set during database creation and cannot be modified afterward.
        This parameter requires SQL Server 2019 (version 15) or later.

    .PARAMETER CompatibilityLevel
        The version of the SQL compatibility level to use for the new database.
        Default value is server version.

    .PARAMETER RecoveryModel
        The recovery model to be used for the new database.
        Default value is Full.

    .PARAMETER OwnerName
        Specifies the name of the login that should be the owner of the database.

    .PARAMETER IsLedger
        Specifies whether to create a ledger database. Ledger databases provide
        tamper-evidence capabilities and are immutable once created. This parameter
        can only be set during database creation - ledger status cannot be changed
        after the database is created. This parameter requires SQL Server 2022
        (version 16) or later, or Azure SQL Database.

    .PARAMETER AcceleratedRecoveryEnabled
        Specifies whether Accelerated Database Recovery (ADR) is enabled for the database.
        This parameter requires SQL Server 2019 (version 15) or later.

    .PARAMETER AnsiNullDefault
        Specifies whether new columns allow NULL by default unless explicitly specified (when ON).

    .PARAMETER AnsiNullsEnabled
        Specifies whether comparisons to NULL follow ANSI SQL behavior (when ON, x = NULL yields UNKNOWN).

    .PARAMETER AnsiPaddingEnabled
        Specifies whether padding for variable-length columns (e.g., CHAR/VARCHAR) follows ANSI rules.

    .PARAMETER AnsiWarningsEnabled
        Specifies whether ANSI warnings are generated for certain conditions (when ON, e.g., divide by zero).

    .PARAMETER ArithmeticAbortEnabled
        Specifies whether a query is terminated when an overflow or divide-by-zero error occurs.

    .PARAMETER AutoClose
        Specifies whether the database closes after the last user exits.

    .PARAMETER AutoCreateIncrementalStatisticsEnabled
        Specifies whether creation of incremental statistics on partitioned tables is allowed.

    .PARAMETER AutoCreateStatisticsEnabled
        Specifies whether single-column statistics are automatically created for query optimization.

    .PARAMETER AutoShrink
        Specifies whether the database automatically shrinks files when free space is detected.

    .PARAMETER AutoUpdateStatisticsAsync
        Specifies whether statistics are updated asynchronously, allowing queries to proceed with old stats.

    .PARAMETER AutoUpdateStatisticsEnabled
        Specifies whether statistics are automatically updated when they are out-of-date.

    .PARAMETER BrokerEnabled
        Specifies whether Service Broker is enabled for the database.

    .PARAMETER ChangeTrackingAutoCleanUp
        Specifies whether automatic cleanup of change tracking information is enabled.

    .PARAMETER ChangeTrackingEnabled
        Specifies whether change tracking is enabled for the database.

    .PARAMETER ChangeTrackingRetentionPeriod
        Specifies the retention period value for change tracking information.

    .PARAMETER ChangeTrackingRetentionPeriodUnits
        Specifies the units for the retention period (e.g., DAYS, HOURS).

    .PARAMETER CloseCursorsOnCommitEnabled
        Specifies whether open cursors are closed when a transaction is committed.

    .PARAMETER ConcatenateNullYieldsNull
        Specifies whether concatenation with NULL results in NULL (when ON).

    .PARAMETER ContainmentType
        Specifies the containment level of the database (NONE or PARTIAL).

    .PARAMETER DatabaseOwnershipChaining
        Specifies whether ownership chaining across objects within the database is enabled.

    .PARAMETER DataRetentionEnabled
        Specifies whether SQL Server data retention policy is enabled at the database level.
        This parameter requires SQL Server 2017 (version 14) or later.

    .PARAMETER DateCorrelationOptimization
        Specifies whether date correlation optimization is enabled to speed up temporal joins.

    .PARAMETER DefaultFullTextLanguage
        Specifies the LCID of the default full-text language.

    .PARAMETER DefaultLanguage
        Specifies the ID of the default language for the database.

    .PARAMETER DelayedDurability
        Specifies the delayed durability setting for the database (DISABLED, ALLOWED, FORCED).

    .PARAMETER EncryptionEnabled
        Specifies whether Transparent Data Encryption (TDE) is enabled.

    .PARAMETER FilestreamDirectoryName
        Specifies the directory name used for FILESTREAM data.

    .PARAMETER FilestreamNonTransactedAccess
        Specifies the FILESTREAM access level for non-transactional access.

    .PARAMETER HonorBrokerPriority
        Specifies whether honoring Service Broker conversation priority is enabled.

    .PARAMETER IsFullTextEnabled
        Specifies whether full-text search is enabled.

    .PARAMETER IsParameterizationForced
        Specifies whether forced parameterization is enabled for the database.

    .PARAMETER IsReadCommittedSnapshotOn
        Specifies whether READ_COMMITTED_SNAPSHOT isolation is ON.

    .PARAMETER IsSqlDw
        Specifies whether the database is a SQL Data Warehouse database.

    .PARAMETER IsVarDecimalStorageFormatEnabled
        Specifies whether vardecimal compression is enabled.

    .PARAMETER LegacyCardinalityEstimation
        Specifies the legacy cardinality estimator setting for the primary.
        Valid values are Off, On, or Primary (for secondary replicas to use primary's setting).

    .PARAMETER LegacyCardinalityEstimationForSecondary
        Specifies the legacy cardinality estimator setting for secondary replicas.
        Valid values are Off, On, or Primary (to use primary's setting).

    .PARAMETER LocalCursorsDefault
        Specifies whether cursors are local by default instead of global (when ON).

    .PARAMETER MaxDop
        Specifies the MAXDOP database-scoped configuration for primary replicas.

    .PARAMETER MaxDopForSecondary
        Specifies the MAXDOP database-scoped configuration for secondary replicas.

    .PARAMETER MaxSizeInBytes
        Specifies the maximum size of the database in bytes.

    .PARAMETER MirroringPartner
        Specifies the mirroring partner server name (if configured).

    .PARAMETER MirroringPartnerInstance
        Specifies the mirroring partner instance name (if configured).

    .PARAMETER MirroringRedoQueueMaxSize
        Specifies the redo queue maximum size for mirroring/AGs.

    .PARAMETER MirroringSafetyLevel
        Specifies the mirroring safety level (FULL/Off/HighPerformance).

    .PARAMETER MirroringTimeout
        Specifies the timeout in seconds for mirroring sessions.

    .PARAMETER MirroringWitness
        Specifies the mirroring witness server (if used).

    .PARAMETER NestedTriggersEnabled
        Specifies whether triggers are allowed to fire other triggers (nested triggers).

    .PARAMETER NumericRoundAbortEnabled
        Specifies whether an error is raised on loss of precision due to rounding (when ON).

    .PARAMETER PageVerify
        Specifies the page verification setting (NONE, TORN_PAGE_DETECTION, CHECKSUM).

    .PARAMETER ParameterSniffing
        Specifies the parameter sniffing setting for the primary.
        Valid values are Off, On, or Primary (for secondary replicas to use primary's setting).

    .PARAMETER ParameterSniffingForSecondary
        Specifies the parameter sniffing setting for secondary replicas.
        Valid values are Off, On, or Primary (to use primary's setting).

    .PARAMETER PersistentVersionStoreFileGroup
        Specifies the filegroup used for the Persistent Version Store (PVS).
        This parameter requires SQL Server 2019 (version 15) or later.

    .PARAMETER PrimaryFilePath
        Specifies the path of the primary data files directory.

    .PARAMETER QueryOptimizerHotfixes
        Specifies the query optimizer hotfixes setting for the primary.
        Valid values are Off, On, or Primary (for secondary replicas to use primary's setting).

    .PARAMETER QueryOptimizerHotfixesForSecondary
        Specifies the query optimizer hotfixes setting for secondary replicas.
        Valid values are Off, On, or Primary (to use primary's setting).

    .PARAMETER QuotedIdentifiersEnabled
        Specifies whether identifiers can be delimited by double quotes (when ON).

    .PARAMETER ReadOnly
        Specifies whether the database is in read-only mode.

    .PARAMETER RecursiveTriggersEnabled
        Specifies whether a trigger is allowed to fire itself recursively.

    .PARAMETER RemoteDataArchiveCredential
        Specifies the credential name for Stretch Database/remote data archive.

    .PARAMETER RemoteDataArchiveEnabled
        Specifies whether Stretch Database (remote data archive) is enabled.

    .PARAMETER RemoteDataArchiveEndpoint
        Specifies the endpoint URL for remote data archive.

    .PARAMETER RemoteDataArchiveLinkedServer
        Specifies the linked server used by remote data archive.

    .PARAMETER RemoteDataArchiveUseFederatedServiceAccount
        Specifies whether to use federated service account for remote data archive.

    .PARAMETER RemoteDatabaseName
        Specifies the remote database name for remote data archive.

    .PARAMETER TargetRecoveryTime
        Specifies the target recovery time (seconds) for indirect checkpointing.

    .PARAMETER TemporalHistoryRetentionEnabled
        Specifies whether automatic cleanup of system-versioned temporal history is enabled.
        This parameter requires SQL Server 2017 (version 14) or later.

    .PARAMETER TransformNoiseWords
        Specifies how full-text noise word behavior is controlled during queries.

    .PARAMETER Trustworthy
        Specifies whether implicit access to external resources by modules is allowed (use with caution).

    .PARAMETER TwoDigitYearCutoff
        Specifies the two-digit year cutoff used for date conversion.

    .PARAMETER UserAccess
        Specifies the database user access mode. Valid values are Multiple, Restricted, and Single.

    .PARAMETER DatabaseSnapshotBaseName
        Specifies the name of the source database from which to create a snapshot.
        When this parameter is specified, a database snapshot will be created instead
        of a regular database. The snapshot name is specified in the Name parameter.

    .PARAMETER FileGroup
        Specifies an array of DatabaseFileGroupSpec objects that define the file groups
        and data files for the database. Each DatabaseFileGroupSpec contains the file group
        name and an array of DatabaseFileSpec objects for the data files.

        This parameter allows you to specify custom file and filegroup configurations
        before the database is created, avoiding the SMO limitation where DataFile objects
        require an existing database context.

        For database snapshots, the FileName in each DatabaseFileSpec must point to sparse
        file locations. For regular databases, this allows full control over PRIMARY and
        secondary file group configurations.

    .PARAMETER Force
        Specifies that the database should be created without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        creating the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscDatabase -Name 'MyDatabase'

        Creates a new database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscDatabase -Name 'MyDatabase' -Collation 'SQL_Latin1_General_Pref_CP850_CI_AS' -RecoveryModel 'Simple' -Force

        Creates a new database named **MyDatabase** with the specified collation and recovery model
        without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscDatabase -Name 'MyDatabaseSnapshot' -DatabaseSnapshotBaseName 'MyDatabase' -Force

        Creates a database snapshot named **MyDatabaseSnapshot** from the source database **MyDatabase**
        without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'

        $primaryFile = New-SqlDscDataFile -Name 'MyDatabase_Primary' -FileName 'D:\SQLData\MyDatabase.mdf' -Size 102400 -Growth 10240 -GrowthType 'KB' -IsPrimaryFile -AsSpec
        $primaryFileGroup = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($primaryFile) -IsDefault $true -AsSpec

        $secondaryFile = New-SqlDscDataFile -Name 'MyDatabase_Secondary' -FileName 'E:\SQLData\MyDatabase.ndf' -Size 204800 -AsSpec
        $secondaryFileGroup = New-SqlDscFileGroup -Name 'SECONDARY' -Files @($secondaryFile) -AsSpec

        $serverObject | New-SqlDscDatabase -Name 'MyDatabase' -FileGroup @($primaryFileGroup, $secondaryFileGroup) -Force

        Creates a new database named **MyDatabase** with custom PRIMARY and SECONDARY file groups
        using specification objects created with the -AsSpec parameter. All properties are set
        directly via parameters without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscDatabase -Name 'MyDatabase' -LegacyCardinalityEstimation 'On' -ParameterSniffing 'Off' -QueryOptimizerHotfixes 'On' -Force

        Creates a new database named **MyDatabase** with database-scoped configuration settings:
        legacy cardinality estimation enabled, parameter sniffing disabled, and query optimizer
        hotfixes enabled, without prompting for confirmation.

    
    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Accepts input via the pipeline.

.OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Database]`
#>
function New-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'RemoteDataArchiveCredential is not a password but a credential name reference.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Database')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'Database')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Collation,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.CatalogCollationType]
        $CatalogCollation,

        [Parameter(ParameterSetName = 'Database')]
        [ValidateSet('Version80', 'Version90', 'Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150', 'Version160')]
        [System.String]
        $CompatibilityLevel,

        [Parameter(ParameterSetName = 'Database')]
        [ValidateSet('Simple', 'Full', 'BulkLogged')]
        [System.String]
        $RecoveryModel,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $OwnerName,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $IsLedger,

        # Boolean Properties
        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AcceleratedRecoveryEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AnsiNullDefault,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AnsiNullsEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AnsiPaddingEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AnsiWarningsEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $ArithmeticAbortEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AutoClose,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AutoCreateIncrementalStatisticsEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AutoCreateStatisticsEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AutoShrink,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AutoUpdateStatisticsAsync,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $AutoUpdateStatisticsEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $BrokerEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $ChangeTrackingAutoCleanUp,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $ChangeTrackingEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $CloseCursorsOnCommitEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $ConcatenateNullYieldsNull,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $DatabaseOwnershipChaining,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $DataRetentionEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $DateCorrelationOptimization,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $EncryptionEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $HonorBrokerPriority,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $IsFullTextEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $IsParameterizationForced,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $IsReadCommittedSnapshotOn,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $IsSqlDw,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $IsVarDecimalStorageFormatEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $LegacyCardinalityEstimation,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $LegacyCardinalityEstimationForSecondary,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $LocalCursorsDefault,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $NestedTriggersEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $NumericRoundAbortEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $ParameterSniffing,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $ParameterSniffingForSecondary,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $QueryOptimizerHotfixes,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $QueryOptimizerHotfixesForSecondary,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $QuotedIdentifiersEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $ReadOnly,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $RecursiveTriggersEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $RemoteDataArchiveEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $RemoteDataArchiveUseFederatedServiceAccount,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $TemporalHistoryRetentionEnabled,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $TransformNoiseWords,

        [Parameter(ParameterSetName = 'Database')]
        [System.Management.Automation.SwitchParameter]
        $Trustworthy,

        # Integer Properties
        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $ChangeTrackingRetentionPeriod,

        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $DefaultFullTextLanguage,

        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $DefaultLanguage,

        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $MaxDop,

        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $MaxDopForSecondary,

        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $MirroringRedoQueueMaxSize,

        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $MirroringTimeout,

        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $TargetRecoveryTime,

        [Parameter(ParameterSetName = 'Database')]
        [System.Int32]
        $TwoDigitYearCutoff,

        # Long Integer Properties
        [Parameter(ParameterSetName = 'Database')]
        [System.Double]
        $MaxSizeInBytes,

        # String Properties
        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $FilestreamDirectoryName,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $MirroringPartner,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $MirroringPartnerInstance,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $MirroringWitness,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $PersistentVersionStoreFileGroup,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $PrimaryFilePath,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $RemoteDataArchiveCredential,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $RemoteDataArchiveEndpoint,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $RemoteDataArchiveLinkedServer,

        [Parameter(ParameterSetName = 'Database')]
        [System.String]
        $RemoteDatabaseName,

        # Enum Properties
        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.RetentionPeriodUnits]
        $ChangeTrackingRetentionPeriodUnits,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.ContainmentType]
        $ContainmentType,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.DelayedDurability]
        $DelayedDurability,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.FilestreamNonTransactedAccessType]
        $FilestreamNonTransactedAccess,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.MirroringSafetyLevel]
        $MirroringSafetyLevel,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.PageVerify]
        $PageVerify,

        [Parameter(ParameterSetName = 'Database')]
        [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]
        $UserAccess,

        [Parameter(Mandatory = $true, ParameterSetName = 'Snapshot')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseSnapshotBaseName,

        [Parameter()]
        [DatabaseFileGroupSpec[]]
        $FileGroup,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        if ($Refresh.IsPresent)
        {
            # Refresh the server object's databases collection
            $ServerObject.Databases.Refresh()
        }

        Write-Verbose -Message ($script:localizedData.Database_Create -f $Name, $ServerObject.InstanceName)

        # Check if the database already exists
        if ($ServerObject.Databases[$Name])
        {
            $errorMessage = $script:localizedData.Database_AlreadyExists -f $Name, $ServerObject.InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'NSD0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $Name
                )
            )
        }

        # Validate compatibility level if specified
        if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
        {
            $supportedCompatibilityLevels = @{
                8  = @('Version80')
                9  = @('Version80', 'Version90')
                10 = @('Version80', 'Version90', 'Version100')
                11 = @('Version90', 'Version100', 'Version110')
                12 = @('Version100', 'Version110', 'Version120')
                13 = @('Version100', 'Version110', 'Version120', 'Version130')
                14 = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140')
                15 = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150')
                16 = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150', 'Version160')
            }

            if ($CompatibilityLevel -notin $supportedCompatibilityLevels.$($ServerObject.VersionMajor))
            {
                $errorMessage = $script:localizedData.Database_InvalidCompatibilityLevel -f $CompatibilityLevel, $ServerObject.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.ArgumentException]::new($errorMessage),
                        'NSD0003', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $CompatibilityLevel
                    )
                )
            }
        }

        # Validate collation if specified
        if ($PSBoundParameters.ContainsKey('Collation'))
        {
            if ($Collation -notin $ServerObject.EnumCollations().Name)
            {
                $errorMessage = $script:localizedData.Database_InvalidCollation -f $Collation, $ServerObject.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.ArgumentException]::new($errorMessage),
                        'NSD0004', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Collation
                    )
                )
            }
        }

        # Validate CatalogCollation if specified (requires SQL Server 2019+)
        if ($PSBoundParameters.ContainsKey('CatalogCollation'))
        {
            if ($ServerObject.VersionMajor -lt 15)
            {
                $errorMessage = $script:localizedData.Database_CatalogCollationNotSupported -f $ServerObject.InstanceName, $ServerObject.VersionMajor

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'NSD0005', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $CatalogCollation
                    )
                )
            }
        }

        # Validate IsLedger if specified (requires SQL Server 2022+)
        if ($PSBoundParameters.ContainsKey('IsLedger'))
        {
            if ($ServerObject.VersionMajor -lt 16)
            {
                $errorMessage = $script:localizedData.Database_IsLedgerNotSupported -f $ServerObject.InstanceName, $ServerObject.VersionMajor

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'NSD0007', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $IsLedger
                    )
                )
            }
        }

        # Validate source database exists when creating a snapshot
        if ($PSCmdlet.ParameterSetName -eq 'Snapshot')
        {
            if (-not $ServerObject.Databases[$DatabaseSnapshotBaseName])
            {
                $errorMessage = $script:localizedData.Database_SnapshotSourceDatabaseNotFound -f $DatabaseSnapshotBaseName, $ServerObject.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'NSD0006', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $DatabaseSnapshotBaseName
                    )
                )
            }
        }

        $verboseDescriptionMessage = $script:localizedData.Database_Create_ShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.Database_Create_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.Database_Create_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                $sqlDatabaseObjectToCreate = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList $ServerObject, $Name

                # Handle database snapshot creation
                if ($PSCmdlet.ParameterSetName -eq 'Snapshot')
                {
                    Write-Verbose -Message ($script:localizedData.Database_CreatingSnapshot -f $Name, $DatabaseSnapshotBaseName)

                    $sqlDatabaseObjectToCreate.DatabaseSnapshotBaseName = $DatabaseSnapshotBaseName
                }
                else
                {
                    # Handle regular database creation
                    if ($PSBoundParameters.ContainsKey('RecoveryModel'))
                    {
                        $sqlDatabaseObjectToCreate.RecoveryModel = $RecoveryModel
                    }

                    if ($PSBoundParameters.ContainsKey('Collation'))
                    {
                        $sqlDatabaseObjectToCreate.Collation = $Collation
                    }

                    if ($PSBoundParameters.ContainsKey('CatalogCollation'))
                    {
                        $sqlDatabaseObjectToCreate.CatalogCollation = $CatalogCollation
                    }

                    if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
                    {
                        $sqlDatabaseObjectToCreate.CompatibilityLevel = $CompatibilityLevel
                    }

                    if ($PSBoundParameters.ContainsKey('IsLedger'))
                    {
                        $sqlDatabaseObjectToCreate.IsLedger = $IsLedger.IsPresent
                    }

                    # Boolean Properties
                    if ($PSBoundParameters.ContainsKey('AcceleratedRecoveryEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.AcceleratedRecoveryEnabled = $AcceleratedRecoveryEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AnsiNullDefault'))
                    {
                        $sqlDatabaseObjectToCreate.AnsiNullDefault = $AnsiNullDefault.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AnsiNullsEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.AnsiNullsEnabled = $AnsiNullsEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AnsiPaddingEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.AnsiPaddingEnabled = $AnsiPaddingEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AnsiWarningsEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.AnsiWarningsEnabled = $AnsiWarningsEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('ArithmeticAbortEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.ArithmeticAbortEnabled = $ArithmeticAbortEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AutoClose'))
                    {
                        $sqlDatabaseObjectToCreate.AutoClose = $AutoClose.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AutoCreateIncrementalStatisticsEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.AutoCreateIncrementalStatisticsEnabled = $AutoCreateIncrementalStatisticsEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AutoCreateStatisticsEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.AutoCreateStatisticsEnabled = $AutoCreateStatisticsEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AutoShrink'))
                    {
                        $sqlDatabaseObjectToCreate.AutoShrink = $AutoShrink.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AutoUpdateStatisticsAsync'))
                    {
                        $sqlDatabaseObjectToCreate.AutoUpdateStatisticsAsync = $AutoUpdateStatisticsAsync.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('AutoUpdateStatisticsEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.AutoUpdateStatisticsEnabled = $AutoUpdateStatisticsEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('BrokerEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.BrokerEnabled = $BrokerEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('ChangeTrackingAutoCleanUp'))
                    {
                        $sqlDatabaseObjectToCreate.ChangeTrackingAutoCleanUp = $ChangeTrackingAutoCleanUp.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('ChangeTrackingEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.ChangeTrackingEnabled = $ChangeTrackingEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('CloseCursorsOnCommitEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.CloseCursorsOnCommitEnabled = $CloseCursorsOnCommitEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('ConcatenateNullYieldsNull'))
                    {
                        $sqlDatabaseObjectToCreate.ConcatenateNullYieldsNull = $ConcatenateNullYieldsNull.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('DatabaseOwnershipChaining'))
                    {
                        $sqlDatabaseObjectToCreate.DatabaseOwnershipChaining = $DatabaseOwnershipChaining.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('DataRetentionEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.DataRetentionEnabled = $DataRetentionEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('DateCorrelationOptimization'))
                    {
                        $sqlDatabaseObjectToCreate.DateCorrelationOptimization = $DateCorrelationOptimization.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('EncryptionEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.EncryptionEnabled = $EncryptionEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('HonorBrokerPriority'))
                    {
                        $sqlDatabaseObjectToCreate.HonorBrokerPriority = $HonorBrokerPriority.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('IsFullTextEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.IsFullTextEnabled = $IsFullTextEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('IsParameterizationForced'))
                    {
                        $sqlDatabaseObjectToCreate.IsParameterizationForced = $IsParameterizationForced.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('IsReadCommittedSnapshotOn'))
                    {
                        $sqlDatabaseObjectToCreate.IsReadCommittedSnapshotOn = $IsReadCommittedSnapshotOn.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('IsSqlDw'))
                    {
                        $sqlDatabaseObjectToCreate.IsSqlDw = $IsSqlDw.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('IsVarDecimalStorageFormatEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.IsVarDecimalStorageFormatEnabled = $IsVarDecimalStorageFormatEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('LegacyCardinalityEstimation'))
                    {
                        $sqlDatabaseObjectToCreate.LegacyCardinalityEstimation = $LegacyCardinalityEstimation
                    }

                    if ($PSBoundParameters.ContainsKey('LegacyCardinalityEstimationForSecondary'))
                    {
                        $sqlDatabaseObjectToCreate.LegacyCardinalityEstimationForSecondary = $LegacyCardinalityEstimationForSecondary
                    }

                    if ($PSBoundParameters.ContainsKey('LocalCursorsDefault'))
                    {
                        $sqlDatabaseObjectToCreate.LocalCursorsDefault = $LocalCursorsDefault.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('NestedTriggersEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.NestedTriggersEnabled = $NestedTriggersEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('NumericRoundAbortEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.NumericRoundAbortEnabled = $NumericRoundAbortEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('ParameterSniffing'))
                    {
                        $sqlDatabaseObjectToCreate.ParameterSniffing = $ParameterSniffing
                    }

                    if ($PSBoundParameters.ContainsKey('ParameterSniffingForSecondary'))
                    {
                        $sqlDatabaseObjectToCreate.ParameterSniffingForSecondary = $ParameterSniffingForSecondary
                    }

                    if ($PSBoundParameters.ContainsKey('QueryOptimizerHotfixes'))
                    {
                        $sqlDatabaseObjectToCreate.QueryOptimizerHotfixes = $QueryOptimizerHotfixes
                    }

                    if ($PSBoundParameters.ContainsKey('QueryOptimizerHotfixesForSecondary'))
                    {
                        $sqlDatabaseObjectToCreate.QueryOptimizerHotfixesForSecondary = $QueryOptimizerHotfixesForSecondary
                    }

                    if ($PSBoundParameters.ContainsKey('QuotedIdentifiersEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.QuotedIdentifiersEnabled = $QuotedIdentifiersEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('ReadOnly'))
                    {
                        $sqlDatabaseObjectToCreate.ReadOnly = $ReadOnly.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('RecursiveTriggersEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.RecursiveTriggersEnabled = $RecursiveTriggersEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('RemoteDataArchiveEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.RemoteDataArchiveEnabled = $RemoteDataArchiveEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('RemoteDataArchiveUseFederatedServiceAccount'))
                    {
                        $sqlDatabaseObjectToCreate.RemoteDataArchiveUseFederatedServiceAccount = $RemoteDataArchiveUseFederatedServiceAccount.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('TemporalHistoryRetentionEnabled'))
                    {
                        $sqlDatabaseObjectToCreate.TemporalHistoryRetentionEnabled = $TemporalHistoryRetentionEnabled.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('TransformNoiseWords'))
                    {
                        $sqlDatabaseObjectToCreate.TransformNoiseWords = $TransformNoiseWords.IsPresent
                    }

                    if ($PSBoundParameters.ContainsKey('Trustworthy'))
                    {
                        $sqlDatabaseObjectToCreate.Trustworthy = $Trustworthy.IsPresent
                    }

                    # Integer Properties
                    if ($PSBoundParameters.ContainsKey('ChangeTrackingRetentionPeriod'))
                    {
                        $sqlDatabaseObjectToCreate.ChangeTrackingRetentionPeriod = $ChangeTrackingRetentionPeriod
                    }

                    if ($PSBoundParameters.ContainsKey('DefaultFullTextLanguage'))
                    {
                        $sqlDatabaseObjectToCreate.DefaultFullTextLanguage = $DefaultFullTextLanguage
                    }

                    if ($PSBoundParameters.ContainsKey('DefaultLanguage'))
                    {
                        $sqlDatabaseObjectToCreate.DefaultLanguage = $DefaultLanguage
                    }

                    if ($PSBoundParameters.ContainsKey('MaxDop'))
                    {
                        $sqlDatabaseObjectToCreate.MaxDop = $MaxDop
                    }

                    if ($PSBoundParameters.ContainsKey('MaxDopForSecondary'))
                    {
                        $sqlDatabaseObjectToCreate.MaxDopForSecondary = $MaxDopForSecondary
                    }

                    if ($PSBoundParameters.ContainsKey('MirroringRedoQueueMaxSize'))
                    {
                        $sqlDatabaseObjectToCreate.MirroringRedoQueueMaxSize = $MirroringRedoQueueMaxSize
                    }

                    if ($PSBoundParameters.ContainsKey('MirroringTimeout'))
                    {
                        $sqlDatabaseObjectToCreate.MirroringTimeout = $MirroringTimeout
                    }

                    if ($PSBoundParameters.ContainsKey('TargetRecoveryTime'))
                    {
                        $sqlDatabaseObjectToCreate.TargetRecoveryTime = $TargetRecoveryTime
                    }

                    if ($PSBoundParameters.ContainsKey('TwoDigitYearCutoff'))
                    {
                        $sqlDatabaseObjectToCreate.TwoDigitYearCutoff = $TwoDigitYearCutoff
                    }

                    # Long Integer Properties
                    if ($PSBoundParameters.ContainsKey('MaxSizeInBytes'))
                    {
                        $sqlDatabaseObjectToCreate.MaxSizeInBytes = $MaxSizeInBytes
                    }

                    # String Properties
                    if ($PSBoundParameters.ContainsKey('FilestreamDirectoryName'))
                    {
                        $sqlDatabaseObjectToCreate.FilestreamDirectoryName = $FilestreamDirectoryName
                    }

                    if ($PSBoundParameters.ContainsKey('MirroringPartner'))
                    {
                        $sqlDatabaseObjectToCreate.MirroringPartner = $MirroringPartner
                    }

                    if ($PSBoundParameters.ContainsKey('MirroringPartnerInstance'))
                    {
                        $sqlDatabaseObjectToCreate.MirroringPartnerInstance = $MirroringPartnerInstance
                    }

                    if ($PSBoundParameters.ContainsKey('MirroringWitness'))
                    {
                        $sqlDatabaseObjectToCreate.MirroringWitness = $MirroringWitness
                    }

                    if ($PSBoundParameters.ContainsKey('PersistentVersionStoreFileGroup'))
                    {
                        $sqlDatabaseObjectToCreate.PersistentVersionStoreFileGroup = $PersistentVersionStoreFileGroup
                    }

                    if ($PSBoundParameters.ContainsKey('PrimaryFilePath'))
                    {
                        $sqlDatabaseObjectToCreate.PrimaryFilePath = $PrimaryFilePath
                    }

                    if ($PSBoundParameters.ContainsKey('RemoteDataArchiveCredential'))
                    {
                        $sqlDatabaseObjectToCreate.RemoteDataArchiveCredential = $RemoteDataArchiveCredential
                    }

                    if ($PSBoundParameters.ContainsKey('RemoteDataArchiveEndpoint'))
                    {
                        $sqlDatabaseObjectToCreate.RemoteDataArchiveEndpoint = $RemoteDataArchiveEndpoint
                    }

                    if ($PSBoundParameters.ContainsKey('RemoteDataArchiveLinkedServer'))
                    {
                        $sqlDatabaseObjectToCreate.RemoteDataArchiveLinkedServer = $RemoteDataArchiveLinkedServer
                    }

                    if ($PSBoundParameters.ContainsKey('RemoteDatabaseName'))
                    {
                        $sqlDatabaseObjectToCreate.RemoteDatabaseName = $RemoteDatabaseName
                    }

                    # Enum Properties
                    if ($PSBoundParameters.ContainsKey('ChangeTrackingRetentionPeriodUnits'))
                    {
                        $sqlDatabaseObjectToCreate.ChangeTrackingRetentionPeriodUnits = $ChangeTrackingRetentionPeriodUnits
                    }

                    if ($PSBoundParameters.ContainsKey('ContainmentType'))
                    {
                        $sqlDatabaseObjectToCreate.ContainmentType = $ContainmentType
                    }

                    if ($PSBoundParameters.ContainsKey('DelayedDurability'))
                    {
                        $sqlDatabaseObjectToCreate.DelayedDurability = $DelayedDurability
                    }

                    if ($PSBoundParameters.ContainsKey('FilestreamNonTransactedAccess'))
                    {
                        $sqlDatabaseObjectToCreate.FilestreamNonTransactedAccess = $FilestreamNonTransactedAccess
                    }

                    if ($PSBoundParameters.ContainsKey('MirroringSafetyLevel'))
                    {
                        $sqlDatabaseObjectToCreate.MirroringSafetyLevel = $MirroringSafetyLevel
                    }

                    if ($PSBoundParameters.ContainsKey('PageVerify'))
                    {
                        $sqlDatabaseObjectToCreate.PageVerify = $PageVerify
                    }

                    if ($PSBoundParameters.ContainsKey('UserAccess'))
                    {
                        $sqlDatabaseObjectToCreate.UserAccess = $UserAccess
                    }
                }

                # Add FileGroups if provided (applies to both regular databases and snapshots)
                if ($PSBoundParameters.ContainsKey('FileGroup'))
                {
                    foreach ($fileGroupSpec in $FileGroup)
                    {
                        # Create FileGroup using New-SqlDscFileGroup with spec object
                        $smoFileGroup = New-SqlDscFileGroup -Database $sqlDatabaseObjectToCreate -FileGroupSpec $fileGroupSpec -Force

                        # Add the file group to the database
                        Add-SqlDscFileGroup -Database $sqlDatabaseObjectToCreate -FileGroup $smoFileGroup -Force
                    }
                }

                Write-Verbose -Message ($script:localizedData.Database_Creating -f $Name)

                $sqlDatabaseObjectToCreate.Create()

                <#
                    This must be run after the object is created because
                    the owner property is read-only and the method cannot
                    be call until the object has been created.
                    This only applies to regular databases, not snapshots.
                #>
                if ($PSCmdlet.ParameterSetName -eq 'Database' -and $PSBoundParameters.ContainsKey('OwnerName'))
                {
                    $sqlDatabaseObjectToCreate.SetOwner($OwnerName)
                }

                Write-Verbose -Message ($script:localizedData.Database_Created -f $Name)

                return $sqlDatabaseObjectToCreate
            }
            catch
            {
                $errorMessage = $script:localizedData.Database_CreateFailed -f $Name, $ServerObject.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'NSD0002', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Name
                    )
                )
            }
        }
    }
}
