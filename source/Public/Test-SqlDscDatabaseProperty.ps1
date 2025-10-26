<#
    .SYNOPSIS
        Tests if database properties on a SQL Server Database Engine instance are
        in the desired state.

    .DESCRIPTION
        This command tests if database properties on a SQL Server Database Engine
        instance are in the desired state.

        The command supports a comprehensive set of database properties including
        configuration settings, metadata, security properties, performance settings,
        and state information. Users can test one or multiple properties in a
        single command execution.

        All properties correspond directly to Microsoft SQL Server Management Objects (SMO)
        Database class properties and support the same data types and values as the
        underlying SMO implementation.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to test properties for. The logical
        database name as it appears in SQL Server.

    .PARAMETER DatabaseObject
        Specifies the database object to test properties for (from Get-SqlDscDatabase).

    .PARAMETER Collation
        Specifies the default collation for the database.

    .PARAMETER RecoveryModel
        Specifies the database recovery model (FULL, BULK_LOGGED, SIMPLE).

    .PARAMETER CompatibilityLevel
        Specifies the database compatibility level (affects query processor behavior and features).

    .PARAMETER Owner
        Specifies the owner (login) of the database.

    .PARAMETER ReadOnly
        Specifies whether the database is in read-only mode.

    .PARAMETER Trustworthy
        Specifies whether implicit access to external resources by modules is allowed (use with caution).

    .PARAMETER AcceleratedRecoveryEnabled
        Specifies whether Accelerated Database Recovery (ADR) is enabled for the database.

    .PARAMETER ActiveConnections
        Specifies the number of active connections to the database (as observed by SMO).

    .PARAMETER ActiveDirectory
        Specifies whether the database participates in Active Directory integration features.

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

    .PARAMETER AvailabilityDatabaseSynchronizationState
        Specifies the synchronization state of the database in an Availability Group.

    .PARAMETER AvailabilityGroupName
        Specifies the name of the Availability Group to which the database belongs, if any.

    .PARAMETER AzureEdition
        Specifies the Azure SQL Database edition (e.g., Basic/Standard/Premium/GeneralPurpose/BusinessCritical).

    .PARAMETER AzureServiceObjective
        Specifies the Azure SQL Database service objective (e.g., S3, P1, GP_Gen5_4).

    .PARAMETER BrokerEnabled
        Specifies whether Service Broker is enabled for the database.

    .PARAMETER CaseSensitive
        Specifies whether the database collation is case-sensitive.

    .PARAMETER CatalogCollation
        Specifies the catalog-level collation used for metadata and temporary objects.

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

    .PARAMETER CreateDate
        Specifies the date and time that the database was created.

    .PARAMETER DatabaseEngineEdition
        Specifies the edition of the database engine hosting the database.

    .PARAMETER DatabaseEngineType
        Specifies the engine type (e.g., Standalone, AzureSqlDatabase, SqlOnDemand).

    .PARAMETER DatabaseGuid
        Specifies the unique identifier (GUID) of the database.

    .PARAMETER DatabaseOwnershipChaining
        Specifies whether ownership chaining across objects within the database is enabled.

    .PARAMETER DataRetentionEnabled
        Specifies whether SQL Server data retention policy is enabled at the database level.

    .PARAMETER DateCorrelationOptimization
        Specifies whether date correlation optimization is enabled to speed up temporal joins.

    .PARAMETER DboLogin
        Specifies the login that owns the database (dbo).

    .PARAMETER DefaultFileGroup
        Specifies the name of the default filegroup for the database.

    .PARAMETER DefaultFileStreamFileGroup
        Specifies the name of the default FILESTREAM filegroup.

    .PARAMETER DefaultFullTextCatalog
        Specifies the default full-text catalog used for full-text indexes.

    .PARAMETER DefaultFullTextLanguage
        Specifies the LCID of the default full-text language.

    .PARAMETER DefaultLanguage
        Specifies the ID of the default language for the database.

    .PARAMETER DefaultSchema
        Specifies the default schema name for users without an explicit default schema.

    .PARAMETER DelayedDurability
        Specifies whether delayed transaction log flushes are enabled to improve throughput.

    .PARAMETER EncryptionEnabled
        Specifies whether Transparent Data Encryption (TDE) is enabled.

    .PARAMETER FilestreamDirectoryName
        Specifies the directory name used for FILESTREAM data.

    .PARAMETER FilestreamNonTransactedAccess
        Specifies the FILESTREAM access level for non-transactional access.

    .PARAMETER HasDatabaseEncryptionKey
        Specifies whether the database has a database encryption key (TDE).

    .PARAMETER HasFileInCloud
        Specifies whether the database has one or more files in Azure Storage.

    .PARAMETER HasMemoryOptimizedObjects
        Specifies whether the database contains memory-optimized (In-Memory OLTP) objects.

    .PARAMETER HonorBrokerPriority
        Specifies whether honoring Service Broker conversation priority is enabled.

    .PARAMETER ID
        Specifies the database ID (DB_ID). Unique numeric identifier assigned to the database by SQL Server.

    .PARAMETER IndexSpaceUsage
        Specifies the space used by indexes in KB.

    .PARAMETER IsAccessible
        Specifies whether the database is accessible to the current connection.

    .PARAMETER IsDatabaseSnapshot
        Specifies whether the database is a database snapshot.

    .PARAMETER IsDatabaseSnapshotBase
        Specifies whether the database is the source (base) of one or more snapshots.

    .PARAMETER IsDbAccessAdmin
        Specifies whether the caller is member of db_accessadmin for this database.

    .PARAMETER IsDbBackupOperator
        Specifies whether the caller is member of db_backupoperator.

    .PARAMETER IsDbDataReader
        Specifies whether the caller is member of db_datareader.

    .PARAMETER IsDbDataWriter
        Specifies whether the caller is member of db_datawriter.

    .PARAMETER IsDbDdlAdmin
        Specifies whether the caller is member of db_ddladmin.

    .PARAMETER IsDbDenyDataReader
        Specifies whether the caller is member of db_denydatareader.

    .PARAMETER IsDbDenyDataWriter
        Specifies whether the caller is member of db_denydatawriter.

    .PARAMETER IsDbManager
        Specifies whether the caller is member of db_manager (Azure role).

    .PARAMETER IsDbOwner
        Specifies whether the caller is member of db_owner.

    .PARAMETER IsDbSecurityAdmin
        Specifies whether the caller is member of db_securityadmin.

    .PARAMETER IsFabricDatabase
        Specifies whether the database is a Microsoft Fabric SQL database.

    .PARAMETER IsFullTextEnabled
        Specifies whether full-text search is enabled.

    .PARAMETER IsLedger
        Specifies whether the database is enabled for SQL Ledger features.

    .PARAMETER IsLoginManager
        Specifies whether the caller is member of the login manager role (Azure).

    .PARAMETER IsMailHost
        Specifies whether Database Mail host features are configured on this database.

    .PARAMETER IsManagementDataWarehouse
        Specifies whether the database is configured as the Management Data Warehouse.

    .PARAMETER IsMaxSizeApplicable
        Specifies whether MaxSizeInBytes is enforced for the database.

    .PARAMETER IsMirroringEnabled
        Specifies whether database mirroring is configured.

    .PARAMETER IsParameterizationForced
        Specifies whether parameterization of queries is forced by default (when ON).

    .PARAMETER IsReadCommittedSnapshotOn
        Specifies whether READ_COMMITTED_SNAPSHOT isolation is ON.

    .PARAMETER IsSqlDw
        Specifies whether the database is an Azure Synapse (SQL DW) database.

    .PARAMETER IsSqlDwEdition
        Specifies whether the edition corresponds to Azure Synapse (DW).

    .PARAMETER IsSystemObject
        Specifies whether the database is a system database (master, model, msdb, tempdb).

    .PARAMETER IsVarDecimalStorageFormatEnabled
        Specifies whether vardecimal storage format is enabled.

    .PARAMETER IsVarDecimalStorageFormatSupported
        Specifies whether vardecimal storage format is supported by the server.

    .PARAMETER LastBackupDate
        Specifies the timestamp of the last full database backup.

    .PARAMETER LastDifferentialBackupDate
        Specifies the timestamp of the last differential backup.

    .PARAMETER LastGoodCheckDbTime
        Specifies the timestamp when DBCC CHECKDB last completed successfully.

    .PARAMETER LastLogBackupDate
        Specifies the timestamp of the last transaction log backup.

    .PARAMETER LegacyCardinalityEstimation
        Specifies whether the legacy cardinality estimator is enabled for the primary.

    .PARAMETER LegacyCardinalityEstimationForSecondary
        Specifies whether the legacy cardinality estimator is enabled for secondary replicas.

    .PARAMETER LocalCursorsDefault
        Specifies whether cursors are local by default instead of global (when ON).

    .PARAMETER LogReuseWaitStatus
        Specifies the reason why the transaction log cannot be reused.

    .PARAMETER MaxDop
        Specifies the MAXDOP database-scoped configuration for primary replicas.

    .PARAMETER MaxDopForSecondary
        Specifies the MAXDOP database-scoped configuration for secondary replicas.

    .PARAMETER MaxSizeInBytes
        Specifies the maximum size of the database in bytes.

    .PARAMETER MemoryAllocatedToMemoryOptimizedObjectsInKB
        Specifies the memory allocated to memory-optimized objects (KB).

    .PARAMETER MemoryUsedByMemoryOptimizedObjectsInKB
        Specifies the memory used by memory-optimized objects (KB).

    .PARAMETER MirroringFailoverLogSequenceNumber
        Specifies the mirroring failover LSN (if mirroring configured).

    .PARAMETER MirroringID
        Specifies the unique mirroring ID for the database.

    .PARAMETER MirroringPartner
        Specifies the mirroring partner server name (if configured).

    .PARAMETER MirroringPartnerInstance
        Specifies the mirroring partner instance name (if configured).

    .PARAMETER MirroringRedoQueueMaxSize
        Specifies the redo queue maximum size for mirroring/AGs.

    .PARAMETER MirroringRoleSequence
        Specifies the sequence number for mirroring role transitions.

    .PARAMETER MirroringSafetyLevel
        Specifies the mirroring safety level (FULL/Off/HighPerformance).

    .PARAMETER MirroringSafetySequence
        Specifies the sequence for mirroring safety changes.

    .PARAMETER MirroringStatus
        Specifies the current mirroring state of the database.

    .PARAMETER MirroringTimeout
        Specifies the timeout in seconds for mirroring sessions.

    .PARAMETER MirroringWitness
        Specifies the mirroring witness server (if used).

    .PARAMETER MirroringWitnessStatus
        Specifies the status of the mirroring witness.

    .PARAMETER NestedTriggersEnabled
        Specifies whether triggers are allowed to fire other triggers (nested triggers).

    .PARAMETER NumericRoundAbortEnabled
        Specifies whether an error is raised on loss of precision due to rounding (when ON).

    .PARAMETER PageVerify
        Specifies the page verification setting (NONE, TORN_PAGE_DETECTION, CHECKSUM).

    .PARAMETER ParameterSniffing
        Specifies whether parameter sniffing behavior is enabled on the primary.

    .PARAMETER ParameterSniffingForSecondary
        Specifies whether parameter sniffing is enabled on secondary replicas.

    .PARAMETER PersistentVersionStoreFileGroup
        Specifies the filegroup used for the Persistent Version Store (PVS).

    .PARAMETER PersistentVersionStoreSizeKB
        Specifies the size of the Persistent Version Store in KB.

    .PARAMETER PrimaryFilePath
        Specifies the path of the primary data files directory.

    .PARAMETER QueryOptimizerHotfixes
        Specifies whether query optimizer hotfixes are enabled on the primary.

    .PARAMETER QueryOptimizerHotfixesForSecondary
        Specifies whether query optimizer hotfixes are enabled on secondary replicas.

    .PARAMETER QuotedIdentifiersEnabled
        Specifies whether identifiers can be delimited by double quotes (when ON).

    .PARAMETER RecoveryForkGuid
        Specifies the GUID for the current recovery fork of the database.

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

    .PARAMETER ReplicationOptions
        Specifies the replication options that are enabled for the database.

    .PARAMETER ServiceBrokerGuid
        Specifies the unique Service Broker identifier for the database.

    .PARAMETER Size
        Specifies the approximate size of the database in MB (as reported by SMO).

    .PARAMETER SnapshotIsolationState
        Specifies whether SNAPSHOT isolation is OFF/ON/IN_TRANSITION.

    .PARAMETER SpaceAvailable
        Specifies the free space available in the database (KB).

    .PARAMETER State
        Specifies the general state of the SMO object.

    .PARAMETER Status
        Specifies the operational status of the database as reported by SMO.

    .PARAMETER TargetRecoveryTime
        Specifies the target recovery time (seconds) for indirect checkpointing.

    .PARAMETER TemporalHistoryRetentionEnabled
        Specifies whether automatic cleanup of system-versioned temporal history is enabled.

    .PARAMETER TransformNoiseWords
        Specifies how full-text noise word behavior is controlled during queries.

    .PARAMETER TwoDigitYearCutoff
        Specifies the two-digit year cutoff used for date conversion.

    .PARAMETER UserAccess
        Specifies the database user access mode (MULTI_USER, RESTRICTED_USER, SINGLE_USER).

    .PARAMETER UserName
        Specifies the user name for the current connection context (as seen by SMO).

    .PARAMETER Version
        Specifies the internal version number of the database.

    .PARAMETER WarnOnRename
        Specifies whether a warning is emitted when objects are renamed.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscDatabaseProperty -ServerObject $serverObject -Name 'MyDatabase' -Collation 'SQL_Latin1_General_CP1_CI_AS'

        Tests if the database named **MyDatabase** has the specified collation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Test-SqlDscDatabaseProperty -DatabaseObject $databaseObject -RecoveryModel 'Simple' -CompatibilityLevel 'Version160'

        Tests if the database has the specified recovery model and compatibility level using a database object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscDatabaseProperty -ServerObject $serverObject -Name 'MyDatabase' -Owner 'sa' -AutoClose $false -Trustworthy $false

        Tests multiple database properties at once.

    .INPUTS
        `[Microsoft.SqlServer.Management.Smo.Database]`

        The database object to test properties for (from Get-SqlDscDatabase).

    .OUTPUTS
        `[System.Boolean]`
#>
function Test-SqlDscDatabaseProperty
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'This is not a password but a credential name reference.')]
    [OutputType([System.Boolean])]
    [CmdletBinding(DefaultParameterSetName = 'ServerObjectSet')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'DatabaseObjectSet', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        # Boolean Properties
        [Parameter()]
        [System.Boolean]
        $AcceleratedRecoveryEnabled,

        [Parameter()]
        [System.Boolean]
        $ActiveDirectory,

        [Parameter()]
        [System.Boolean]
        $AnsiNullDefault,

        [Parameter()]
        [System.Boolean]
        $AnsiNullsEnabled,

        [Parameter()]
        [System.Boolean]
        $AnsiPaddingEnabled,

        [Parameter()]
        [System.Boolean]
        $AnsiWarningsEnabled,

        [Parameter()]
        [System.Boolean]
        $ArithmeticAbortEnabled,

        [Parameter()]
        [System.Boolean]
        $AutoClose,

        [Parameter()]
        [System.Boolean]
        $AutoCreateIncrementalStatisticsEnabled,

        [Parameter()]
        [System.Boolean]
        $AutoCreateStatisticsEnabled,

        [Parameter()]
        [System.Boolean]
        $AutoShrink,

        [Parameter()]
        [System.Boolean]
        $AutoUpdateStatisticsAsync,

        [Parameter()]
        [System.Boolean]
        $AutoUpdateStatisticsEnabled,

        [Parameter()]
        [System.Boolean]
        $BrokerEnabled,

        [Parameter()]
        [System.Boolean]
        $CaseSensitive,

        [Parameter()]
        [System.Boolean]
        $ChangeTrackingAutoCleanUp,

        [Parameter()]
        [System.Boolean]
        $ChangeTrackingEnabled,

        [Parameter()]
        [System.Boolean]
        $CloseCursorsOnCommitEnabled,

        [Parameter()]
        [System.Boolean]
        $ConcatenateNullYieldsNull,

        [Parameter()]
        [System.Boolean]
        $DatabaseOwnershipChaining,

        [Parameter()]
        [System.Boolean]
        $DataRetentionEnabled,

        [Parameter()]
        [System.Boolean]
        $DateCorrelationOptimization,

        [Parameter()]
        [System.Boolean]
        $DelayedDurability,

        [Parameter()]
        [System.Boolean]
        $EncryptionEnabled,

        [Parameter()]
        [System.Boolean]
        $HasDatabaseEncryptionKey,

        [Parameter()]
        [System.Boolean]
        $HasFileInCloud,

        [Parameter()]
        [System.Boolean]
        $HasMemoryOptimizedObjects,

        [Parameter()]
        [System.Boolean]
        $HonorBrokerPriority,

        [Parameter()]
        [System.Boolean]
        $IsAccessible,

        [Parameter()]
        [System.Boolean]
        $IsDatabaseSnapshot,

        [Parameter()]
        [System.Boolean]
        $IsDatabaseSnapshotBase,

        [Parameter()]
        [System.Boolean]
        $IsDbAccessAdmin,

        [Parameter()]
        [System.Boolean]
        $IsDbBackupOperator,

        [Parameter()]
        [System.Boolean]
        $IsDbDataReader,

        [Parameter()]
        [System.Boolean]
        $IsDbDataWriter,

        [Parameter()]
        [System.Boolean]
        $IsDbDdlAdmin,

        [Parameter()]
        [System.Boolean]
        $IsDbDenyDataReader,

        [Parameter()]
        [System.Boolean]
        $IsDbDenyDataWriter,

        [Parameter()]
        [System.Boolean]
        $IsDbManager,

        [Parameter()]
        [System.Boolean]
        $IsDbOwner,

        [Parameter()]
        [System.Boolean]
        $IsDbSecurityAdmin,

        [Parameter()]
        [System.Boolean]
        $IsFabricDatabase,

        [Parameter()]
        [System.Boolean]
        $IsFullTextEnabled,

        [Parameter()]
        [System.Boolean]
        $IsLedger,

        [Parameter()]
        [System.Boolean]
        $IsLoginManager,

        [Parameter()]
        [System.Boolean]
        $IsMailHost,

        [Parameter()]
        [System.Boolean]
        $IsManagementDataWarehouse,

        [Parameter()]
        [System.Boolean]
        $IsMaxSizeApplicable,

        [Parameter()]
        [System.Boolean]
        $IsMirroringEnabled,

        [Parameter()]
        [System.Boolean]
        $IsParameterizationForced,

        [Parameter()]
        [System.Boolean]
        $IsReadCommittedSnapshotOn,

        [Parameter()]
        [System.Boolean]
        $IsSqlDw,

        [Parameter()]
        [System.Boolean]
        $IsSqlDwEdition,

        [Parameter()]
        [System.Boolean]
        $IsSystemObject,

        [Parameter()]
        [System.Boolean]
        $IsVarDecimalStorageFormatEnabled,

        [Parameter()]
        [System.Boolean]
        $IsVarDecimalStorageFormatSupported,

        [Parameter()]
        [System.Boolean]
        $LegacyCardinalityEstimation,

        [Parameter()]
        [System.Boolean]
        $LegacyCardinalityEstimationForSecondary,

        [Parameter()]
        [System.Boolean]
        $LocalCursorsDefault,

        [Parameter()]
        [System.Boolean]
        $NestedTriggersEnabled,

        [Parameter()]
        [System.Boolean]
        $NumericRoundAbortEnabled,

        [Parameter()]
        [System.Boolean]
        $ParameterSniffing,

        [Parameter()]
        [System.Boolean]
        $ParameterSniffingForSecondary,

        [Parameter()]
        [System.Boolean]
        $QueryOptimizerHotfixes,

        [Parameter()]
        [System.Boolean]
        $QueryOptimizerHotfixesForSecondary,

        [Parameter()]
        [System.Boolean]
        $QuotedIdentifiersEnabled,

        [Parameter()]
        [System.Boolean]
        $ReadOnly,

        [Parameter()]
        [System.Boolean]
        $RecursiveTriggersEnabled,

        [Parameter()]
        [System.Boolean]
        $RemoteDataArchiveEnabled,

        [Parameter()]
        [System.Boolean]
        $RemoteDataArchiveUseFederatedServiceAccount,

        [Parameter()]
        [System.Boolean]
        $TemporalHistoryRetentionEnabled,

        [Parameter()]
        [System.Boolean]
        $TransformNoiseWords,

        [Parameter()]
        [System.Boolean]
        $Trustworthy,

        [Parameter()]
        [System.Boolean]
        $WarnOnRename,

        # Integer Properties
        [Parameter()]
        [System.Int32]
        $ActiveConnections,

        [Parameter()]
        [System.Int32]
        $ChangeTrackingRetentionPeriod,

        [Parameter()]
        [System.Int32]
        $DefaultFullTextLanguage,

        [Parameter()]
        [System.Int32]
        $DefaultLanguage,

        [Parameter()]
        [System.Int32]
        $ID,

        [Parameter()]
        [System.Int32]
        $MaxDop,

        [Parameter()]
        [System.Int32]
        $MaxDopForSecondary,

        [Parameter()]
        [System.Int32]
        $MirroringRedoQueueMaxSize,

        [Parameter()]
        [System.Int32]
        $MirroringRoleSequence,

        [Parameter()]
        [System.Int32]
        $MirroringSafetySequence,

        [Parameter()]
        [System.Int32]
        $MirroringTimeout,

        [Parameter()]
        [System.Int32]
        $TargetRecoveryTime,

        [Parameter()]
        [System.Int32]
        $TwoDigitYearCutoff,

        [Parameter()]
        [System.Int32]
        $Version,

        # Long Integer Properties
        [Parameter()]
        [System.Int64]
        $IndexSpaceUsage,

        [Parameter()]
        [System.Int64]
        $MaxSizeInBytes,

        [Parameter()]
        [System.Int64]
        $MemoryAllocatedToMemoryOptimizedObjectsInKB,

        [Parameter()]
        [System.Int64]
        $MemoryUsedByMemoryOptimizedObjectsInKB,

        [Parameter()]
        [System.Int64]
        $MirroringFailoverLogSequenceNumber,

        [Parameter()]
        [System.Int64]
        $PersistentVersionStoreSizeKB,

        [Parameter()]
        [System.Int64]
        $SpaceAvailable,

        # Double Properties
        [Parameter()]
        [System.Double]
        $Size,

        # String Properties
        [Parameter()]
        [System.String]
        $AvailabilityGroupName,

        [Parameter()]
        [System.String]
        $AzureServiceObjective,

        [Parameter()]
        [System.String]
        $CatalogCollation,

        [Parameter()]
        [System.String]
        $Collation,

        [Parameter()]
        [System.String]
        $DboLogin,

        [Parameter()]
        [System.String]
        $DefaultFileGroup,

        [Parameter()]
        [System.String]
        $DefaultFileStreamFileGroup,

        [Parameter()]
        [System.String]
        $DefaultFullTextCatalog,

        [Parameter()]
        [System.String]
        $DefaultSchema,

        [Parameter()]
        [System.String]
        $FilestreamDirectoryName,

        [Parameter()]
        [System.String]
        $MirroringPartner,

        [Parameter()]
        [System.String]
        $MirroringPartnerInstance,

        [Parameter()]
        [System.String]
        $MirroringWitness,

        [Parameter()]
        [System.String]
        $Owner,

        [Parameter()]
        [System.String]
        $PersistentVersionStoreFileGroup,

        [Parameter()]
        [System.String]
        $PrimaryFilePath,

        [Parameter()]
        [System.String]
        $RemoteDataArchiveCredential,

        [Parameter()]
        [System.String]
        $RemoteDataArchiveEndpoint,

        [Parameter()]
        [System.String]
        $RemoteDataArchiveLinkedServer,

        [Parameter()]
        [System.String]
        $RemoteDatabaseName,

        [Parameter()]
        [System.String]
        $UserName,

        [Parameter()]
        [System.String]
        $AzureEdition,

        # DateTime Properties
        [Parameter()]
        [System.DateTime]
        $CreateDate,

        [Parameter()]
        [System.DateTime]
        $LastBackupDate,

        [Parameter()]
        [System.DateTime]
        $LastDifferentialBackupDate,

        [Parameter()]
        [System.DateTime]
        $LastGoodCheckDbTime,

        [Parameter()]
        [System.DateTime]
        $LastLogBackupDate,

        # GUID Properties
        [Parameter()]
        [System.Guid]
        $DatabaseGuid,

        [Parameter()]
        [System.Guid]
        $MirroringID,

        [Parameter()]
        [System.Guid]
        $RecoveryForkGuid,

        [Parameter()]
        [System.Guid]
        $ServiceBrokerGuid,

        # Enum Properties (as strings for simplicity)
        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseSynchronizationState]
        $AvailabilityDatabaseSynchronizationState,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.RetentionPeriodUnits]
        $ChangeTrackingRetentionPeriodUnits,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]
        $CompatibilityLevel,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.ContainmentType]
        $ContainmentType,

        [Parameter()]
        [Microsoft.SqlServer.Management.Common.DatabaseEngineEdition]
        $DatabaseEngineEdition,

        [Parameter()]
        [Microsoft.SqlServer.Management.Common.DatabaseEngineType]
        $DatabaseEngineType,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.FilestreamNonTransactedAccessType]
        $FilestreamNonTransactedAccess,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.LogReuseWaitStatus]
        $LogReuseWaitStatus,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.MirroringSafetyLevel]
        $MirroringSafetyLevel,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.MirroringStatus]
        $MirroringStatus,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.MirroringWitnessStatus]
        $MirroringWitnessStatus,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.PageVerify]
        $PageVerify,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.RecoveryModel]
        $RecoveryModel,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.ReplicationOptions]
        $ReplicationOptions,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.SnapshotIsolationState]
        $SnapshotIsolationState,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.SqlSmoState]
        $State,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseStatus]
        $Status,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]
        $UserAccess
    )

    process
    {
        # Get the database object based on the parameter set
        switch ($PSCmdlet.ParameterSetName)
        {
            'ServerObjectSet'
            {
                Write-Verbose -Message ($script:localizedData.DatabaseProperty_TestingProperties -f $Name, $ServerObject.InstanceName)

                $previousErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                $sqlDatabaseObject = $ServerObject | Get-SqlDscDatabase -Name $Name -ErrorAction 'Stop'
                $ErrorActionPreference = $previousErrorActionPreference
            }

            'DatabaseObjectSet'
            {
                Write-Verbose -Message ($script:localizedData.DatabaseProperty_TestingPropertiesFromObject -f $DatabaseObject.Name, $DatabaseObject.Parent.InstanceName)

                $sqlDatabaseObject = $DatabaseObject
            }
        }

        $isInDesiredState = $true

        # Remove common parameters and function-specific parameters, leaving only database properties
        $boundParameters = Remove-CommonParameter -Hashtable $PSBoundParameters

        # Remove function-specific parameters
        foreach ($parameterToRemove in @('ServerObject', 'Name', 'DatabaseObject'))
        {
            $boundParameters.Remove($parameterToRemove)
        }

        # Test each specified property
        foreach ($parameterName in $boundParameters.Keys)
        {
            if ($sqlDatabaseObject.PSObject.Properties.Name -notcontains $parameterName)
            {
                Write-Error -Message ($script:localizedData.DatabaseProperty_PropertyNotFound -f $parameterName, $sqlDatabaseObject.Name) -Category 'InvalidArgument' -ErrorId 'TSDDP0001' -TargetObject $parameterName
                continue
            }

            $expectedValue = $boundParameters.$parameterName
            $actualValue = $sqlDatabaseObject.$parameterName

            # Use a robust comparison that handles empty strings, nulls, and different types
            $valuesMatch = $false

            # Check if both values are null or empty strings (treat them as equivalent)
            $actualIsNullOrEmpty = [System.String]::IsNullOrEmpty($actualValue)
            $expectedIsNullOrEmpty = [System.String]::IsNullOrEmpty($expectedValue)

            if ($actualIsNullOrEmpty -and $expectedIsNullOrEmpty)
            {
                # Both are null or empty, consider them equal
                $valuesMatch = $true
            }
            elseif ($actualIsNullOrEmpty -or $expectedIsNullOrEmpty)
            {
                # One is null/empty and the other is not
                $valuesMatch = $false
            }
            else
            {
                # Both have values, compare them directly
                $valuesMatch = $actualValue -eq $expectedValue
            }

            if (-not $valuesMatch)
            {
                Write-Verbose -Message ($script:localizedData.DatabaseProperty_PropertyWrong -f $sqlDatabaseObject.Name, $parameterName, $actualValue, $expectedValue)
                $isInDesiredState = $false
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.DatabaseProperty_PropertyCorrect -f $sqlDatabaseObject.Name, $parameterName, $actualValue)
            }
        }

        return $isInDesiredState
    }
}
