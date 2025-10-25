<#
    .SYNOPSIS
        Tests if database properties on a SQL Server Database Engine instance are in the desired state.

    .DESCRIPTION
        This command tests if database properties on a SQL Server Database Engine instance are in the desired state.

        The command supports a comprehensive set of database properties including configuration settings,
        metadata, security properties, performance settings, and state information. Users can test one or
        multiple properties in a single command execution.

        All properties correspond directly to Microsoft SQL Server Management Objects (SMO) Database class
        properties and support the same data types and values as the underlying SMO implementation.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to test properties for.

    .PARAMETER DatabaseObject
        Specifies the database object to test properties for (from Get-SqlDscDatabase).

    .PARAMETER Collation
        Specifies the default collation for the database.

    .PARAMETER RecoveryModel
        Specifies the database recovery model (FULL, BULK_LOGGED, SIMPLE).

    .PARAMETER CompatibilityLevel
        Specifies the database compatibility level (affects query processor behavior and features).

    .PARAMETER AutoClose
        Specifies whether the database closes after the last user exits.

    .PARAMETER AutoShrink
        Specifies whether the database automatically shrinks files when free space is detected.

    .PARAMETER Owner
        Specifies the owner (login) of the database.

    .PARAMETER ReadOnly
        Specifies whether the database is in read-only mode.

    .PARAMETER Trustworthy
        Specifies whether implicit access to external resources by modules is allowed (use with caution).

    .PARAMETER AcceleratedRecoveryEnabled
        Enables Accelerated Database Recovery (ADR) for the database.

    .PARAMETER ActiveConnections
        Number of active connections to the database (as observed by SMO).

    .PARAMETER ActiveDirectory
        Indicates whether the database participates in Active Directory integration features.

    .PARAMETER AnsiNullDefault
        When ON, new columns allow NULL by default unless explicitly specified.

    .PARAMETER AnsiNullsEnabled
        When ON, comparisons to NULL follow ANSI SQL behavior (x = NULL yields UNKNOWN).

    .PARAMETER AnsiPaddingEnabled
        Controls padding for variable-length columns (e.g., CHAR/VARCHAR) per ANSI rules.

    .PARAMETER AnsiWarningsEnabled
        When ON, ANSI warnings are generated for certain conditions (e.g., divide by zero).

    .PARAMETER ArithmeticAbortEnabled
        Terminates a query when an overflow or divide-by-zero error occurs.

    .PARAMETER AutoClose
        Closes the database after the last user exits.

    .PARAMETER AutoCreateIncrementalStatisticsEnabled
        Allows creation of incremental statistics on partitioned tables.

    .PARAMETER AutoCreateStatisticsEnabled
        Automatically creates single-column statistics for query optimization.

    .PARAMETER AutoShrink
        Automatically shrinks database files when free space is detected.

    .PARAMETER AutoUpdateStatisticsAsync
        Updates statistics asynchronously, allowing queries to proceed with old stats.

    .PARAMETER AutoUpdateStatisticsEnabled
        Automatically updates statistics when they are out-of-date.

    .PARAMETER AvailabilityDatabaseSynchronizationState
        Synchronization state of the database in an Availability Group.

    .PARAMETER AvailabilityGroupName
        Name of the Availability Group to which the database belongs, if any.

    .PARAMETER AzureEdition
        Azure SQL Database edition (e.g., Basic/Standard/Premium/GeneralPurpose/BusinessCritical).

    .PARAMETER AzureServiceObjective
        Azure SQL Database service objective (e.g., S3, P1, GP_Gen5_4).

    .PARAMETER BrokerEnabled
        Indicates whether Service Broker is enabled for the database.

    .PARAMETER CaseSensitive
        True if the database collation is case-sensitive.

    .PARAMETER CatalogCollation
        Catalog-level collation used for metadata and temporary objects.

    .PARAMETER ChangeTrackingAutoCleanUp
        Enables automatic cleanup of change tracking information.

    .PARAMETER ChangeTrackingEnabled
        Enables change tracking for the database.

    .PARAMETER ChangeTrackingRetentionPeriod
        Retention period value for change tracking information.

    .PARAMETER ChangeTrackingRetentionPeriodUnits
        Units for the retention period (e.g., DAYS, HOURS).

    .PARAMETER CloseCursorsOnCommitEnabled
        Closes open cursors when a transaction is committed.

    .PARAMETER ConcatenateNullYieldsNull
        When ON, concatenation with NULL results in NULL.

    .PARAMETER ContainmentType
        Specifies the containment level of the database (NONE or PARTIAL).

    .PARAMETER CreateDate
        Date and time that the database was created.

    .PARAMETER DatabaseEngineEdition
        Edition of the database engine hosting the database.

    .PARAMETER DatabaseEngineType
        Engine type (e.g., Standalone, AzureSqlDatabase, SqlOnDemand).

    .PARAMETER DatabaseGuid
        Unique identifier (GUID) of the database.

    .PARAMETER DatabaseOwnershipChaining
        Enables ownership chaining across objects within the database.

    .PARAMETER DataRetentionEnabled
        Enables SQL Server data retention policy at the database level.

    .PARAMETER DateCorrelationOptimization
        Enables date correlation optimization to speed up temporal joins.

    .PARAMETER DboLogin
        Login that owns the database (dbo).

    .PARAMETER DefaultFileGroup
        Name of the default filegroup for the database.

    .PARAMETER DefaultFileStreamFileGroup
        Name of the default FILESTREAM filegroup.

    .PARAMETER DefaultFullTextCatalog
        Default full-text catalog used for full-text indexes.

    .PARAMETER DefaultFullTextLanguage
        LCID of the default full-text language.

    .PARAMETER DefaultLanguage
        ID of the default language for the database.

    .PARAMETER DefaultSchema
        Default schema name for users without an explicit default schema.

    .PARAMETER DelayedDurability
        Enables delayed transaction log flushes to improve throughput.

    .PARAMETER EncryptionEnabled
        Indicates whether Transparent Data Encryption (TDE) is enabled.

    .PARAMETER FilestreamDirectoryName
        Directory name used for FILESTREAM data.

    .PARAMETER FilestreamNonTransactedAccess
        Configures FILESTREAM access level for non-transactional access.

    .PARAMETER HasDatabaseEncryptionKey
        True if the database has a database encryption key (TDE).

    .PARAMETER HasFileInCloud
        Indicates the database has one or more files in Azure Storage.

    .PARAMETER HasMemoryOptimizedObjects
        True if the database contains memory-optimized (In-Memory OLTP) objects.

    .PARAMETER HonorBrokerPriority
        Enables honoring Service Broker conversation priority.

    .PARAMETER ID
        Database ID (DB_ID). Unique numeric identifier assigned to the database by SQL Server.

    .PARAMETER IndexSpaceUsage
        Space used by indexes in KB.

    .PARAMETER IsAccessible
        True if the database is accessible to the current connection.

    .PARAMETER IsDatabaseSnapshot
        Indicates whether the database is a database snapshot.

    .PARAMETER IsDatabaseSnapshotBase
        True if the database is the source (base) of one or more snapshots.

    .PARAMETER IsDbAccessAdmin
        True if the caller is member of db_accessadmin for this database.

    .PARAMETER IsDbBackupOperator
        True if the caller is member of db_backupoperator.

    .PARAMETER IsDbDataReader
        True if the caller is member of db_datareader.

    .PARAMETER IsDbDataWriter
        True if the caller is member of db_datawriter.

    .PARAMETER IsDbDdlAdmin
        True if the caller is member of db_ddladmin.

    .PARAMETER IsDbDenyDataReader
        True if the caller is member of db_denydatareader.

    .PARAMETER IsDbDenyDataWriter
        True if the caller is member of db_denydatawriter.

    .PARAMETER IsDbManager
        True if the caller is member of db_manager (Azure role).

    .PARAMETER IsDbOwner
        True if the caller is member of db_owner.

    .PARAMETER IsDbSecurityAdmin
        True if the caller is member of db_securityadmin.

    .PARAMETER IsFabricDatabase
        True if the database is a Microsoft Fabric SQL database.

    .PARAMETER IsFullTextEnabled
        Indicates whether full-text search is enabled.

    .PARAMETER IsLedger
        True if the database is enabled for SQL Ledger features.

    .PARAMETER IsLoginManager
        True if the caller is member of the login manager role (Azure).

    .PARAMETER IsMailHost
        Indicates whether Database Mail host features are configured on this DB.

    .PARAMETER IsManagementDataWarehouse
        True if the database is configured as the Management Data Warehouse.

    .PARAMETER IsMaxSizeApplicable
        True if MaxSizeInBytes is enforced for the database.

    .PARAMETER IsMirroringEnabled
        Indicates whether database mirroring is configured.

    .PARAMETER IsParameterizationForced
        When ON, forces parameterization of queries by default.

    .PARAMETER IsReadCommittedSnapshotOn
        True if READ_COMMITTED_SNAPSHOT isolation is ON.

    .PARAMETER IsSqlDw
        True if the database is an Azure Synapse (SQL DW) database.

    .PARAMETER IsSqlDwEdition
        True if the edition corresponds to Azure Synapse (DW).

    .PARAMETER IsSystemObject
        True for system databases (master, model, msdb, tempdb).

    .PARAMETER IsVarDecimalStorageFormatEnabled
        True if vardecimal storage format is enabled.

    .PARAMETER IsVarDecimalStorageFormatSupported
        True if vardecimal storage format is supported by the server.

    .PARAMETER LastBackupDate
        Timestamp of the last full database backup.

    .PARAMETER LastDifferentialBackupDate
        Timestamp of the last differential backup.

    .PARAMETER LastGoodCheckDbTime
        Timestamp when DBCC CHECKDB last completed successfully.

    .PARAMETER LastLogBackupDate
        Timestamp of the last transaction log backup.

    .PARAMETER LegacyCardinalityEstimation
        Enables legacy cardinality estimator for the primary.

    .PARAMETER LegacyCardinalityEstimationForSecondary
        Enables legacy cardinality estimator for secondary replicas.

    .PARAMETER LocalCursorsDefault
        When ON, cursors are local by default instead of global.

    .PARAMETER LogReuseWaitStatus
        Reason why the transaction log cannot be reused.

    .PARAMETER MaxDop
        MAXDOP database-scoped configuration for primary replicas.

    .PARAMETER MaxDopForSecondary
        MAXDOP database-scoped configuration for secondary replicas.

    .PARAMETER MaxSizeInBytes
        Maximum size of the database in bytes.

    .PARAMETER MemoryAllocatedToMemoryOptimizedObjectsInKB
        Memory allocated to memory-optimized objects (KB).

    .PARAMETER MemoryUsedByMemoryOptimizedObjectsInKB
        Memory used by memory-optimized objects (KB).

    .PARAMETER MirroringFailoverLogSequenceNumber
        Mirroring failover LSN (if mirroring configured).

    .PARAMETER MirroringID
        Unique mirroring ID for the database.

    .PARAMETER MirroringPartner
        Mirroring partner server name (if configured).

    .PARAMETER MirroringPartnerInstance
        Mirroring partner instance name (if configured).

    .PARAMETER MirroringRedoQueueMaxSize
        Redo queue maximum size for mirroring/AGs.

    .PARAMETER MirroringRoleSequence
        Sequence number for mirroring role transitions.

    .PARAMETER MirroringSafetyLevel
        Mirroring safety level (FULL/Off/HighPerformance).

    .PARAMETER MirroringSafetySequence
        Sequence for mirroring safety changes.

    .PARAMETER MirroringStatus
        Current mirroring state of the database.

    .PARAMETER MirroringTimeout
        Timeout in seconds for mirroring sessions.

    .PARAMETER MirroringWitness
        Mirroring witness server (if used).

    .PARAMETER MirroringWitnessStatus
        Status of the mirroring witness.

    .PARAMETER Name
        Name of the database. The logical database name as it appears in SQL Server.

    .PARAMETER NestedTriggersEnabled
        Allows triggers to fire other triggers (nested triggers).

    .PARAMETER NumericRoundAbortEnabled
        When ON, raises an error on loss of precision due to rounding.

    .PARAMETER PageVerify
        Page verification setting (NONE, TORN_PAGE_DETECTION, CHECKSUM).

    .PARAMETER ParameterSniffing
        Enables parameter sniffing behavior on the primary.

    .PARAMETER ParameterSniffingForSecondary
        Enables parameter sniffing on secondary replicas.

    .PARAMETER PersistentVersionStoreFileGroup
        Filegroup used for the Persistent Version Store (PVS).

    .PARAMETER PersistentVersionStoreSizeKB
        Size of the Persistent Version Store in KB.

    .PARAMETER PrimaryFilePath
        Path of the primary data files directory.

    .PARAMETER QueryOptimizerHotfixes
        Enables query optimizer hotfixes on the primary.

    .PARAMETER QueryOptimizerHotfixesForSecondary
        Enables query optimizer hotfixes on secondary replicas.

    .PARAMETER QuotedIdentifiersEnabled
        When ON, identifiers can be delimited by double quotes.

    .PARAMETER RecoveryForkGuid
        GUID for the current recovery fork of the database.

    .PARAMETER RecursiveTriggersEnabled
        Allows a trigger to fire itself recursively.

    .PARAMETER RemoteDataArchiveCredential
        Credential name for Stretch Database/remote data archive.

    .PARAMETER RemoteDataArchiveEnabled
        Enables Stretch Database (remote data archive).

    .PARAMETER RemoteDataArchiveEndpoint
        Endpoint URL for remote data archive.

    .PARAMETER RemoteDataArchiveLinkedServer
        Linked server used by remote data archive.

    .PARAMETER RemoteDataArchiveUseFederatedServiceAccount
        Use federated service account for remote data archive.

    .PARAMETER RemoteDatabaseName
        Remote database name for remote data archive.

    .PARAMETER ReplicationOptions
        Replication options that are enabled for the database.

    .PARAMETER ServiceBrokerGuid
        Unique Service Broker identifier for the database.

    .PARAMETER Size
        Approximate size of the database in MB (as reported by SMO).

    .PARAMETER SnapshotIsolationState
        Indicates whether SNAPSHOT isolation is OFF/ON/IN_TRANSITION.

    .PARAMETER SpaceAvailable
        Free space available in the database (KB).

    .PARAMETER State
        General state of the SMO object.

    .PARAMETER Status
        Operational status of the database as reported by SMO.

    .PARAMETER TargetRecoveryTime
        Target recovery time (seconds) for indirect checkpointing.

    .PARAMETER TemporalHistoryRetentionEnabled
        Enables automatic cleanup of system-versioned temporal history.

    .PARAMETER TransformNoiseWords
        Controls full-text noise word behavior during queries.

    .PARAMETER TwoDigitYearCutoff
        Two-digit year cutoff used for date conversion.

    .PARAMETER UserAccess
        Database user access mode (MULTI_USER, RESTRICTED_USER, SINGLE_USER).

    .PARAMETER UserName
        User name for the current connection context (as seen by SMO).

    .PARAMETER Version
        Internal version number of the database.

    .PARAMETER WarnOnRename
        Emits a warning when objects are renamed.

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
        Test-SqlDscDatabaseProperty -ServerObject $serverObject -Name 'MyDatabase' -Owner 'sa' -AutoClose $false -TrustWorthy $false

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
        [Microsoft.SqlServer.Management.Smo.DatabaseEngineEdition]
        $DatabaseEngineEdition,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseEngineType]
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
                $sqlDatabaseObject = $ServerObject | Get-SqlDscDatabase -Name $Name
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
            $expectedValue = $boundParameters.$parameterName
            $actualValue = $sqlDatabaseObject.$parameterName

            if ($actualValue -ne $expectedValue)
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
