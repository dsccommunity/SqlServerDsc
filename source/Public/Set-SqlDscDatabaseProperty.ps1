<#
    .SYNOPSIS
        Sets properties of a database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command sets properties of a database in a SQL Server Database Engine instance.

        The command supports a comprehensive set of settable database properties including
        configuration settings, security properties, performance settings, and state
        information. Users can set one or multiple properties in a single command execution.

        All properties correspond directly to Microsoft SQL Server Management Objects (SMO)
        Database class properties and support the same data types and values as the
        underlying SMO implementation.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to modify.

    .PARAMETER DatabaseObject
        Specifies the database object to modify (from Get-SqlDscDatabase).

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        trying to get the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

        This parameter is only used when setting properties using **ServerObject** and
        **Name** parameters.

    .PARAMETER Collation
        Specifies the default collation for the database.

    .PARAMETER RecoveryModel
        Specifies the database recovery model (FULL, BULK_LOGGED, SIMPLE).

    .PARAMETER CompatibilityLevel
        Specifies the database compatibility level (affects query processor behavior and features).

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

    .PARAMETER Force
        Specifies that the database should be modified without any confirmation.

    .PARAMETER PassThru
        Specifies that the database object should be returned after modification.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseProperty -ServerObject $serverObject -Name 'MyDatabase' -RecoveryModel 'Simple'

        Sets the recovery model of the database named **MyDatabase** to **Simple**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Set-SqlDscDatabaseProperty -DatabaseObject $databaseObject -ReadOnly:$false -AutoClose:$false

        Sets multiple database properties at once using a database object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseProperty -ServerObject $serverObject -Name 'MyDatabase' -CompatibilityLevel 'Version160' -Trustworthy:$false -Force

        Sets the compatibility level and trustworthy property of the database without prompting for confirmation.

    .INPUTS
        `[Microsoft.SqlServer.Management.Smo.Database]`

        The database object to modify (from Get-SqlDscDatabase).

    .OUTPUTS
        None.

        When PassThru is not specified, no output is returned.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Database

        When PassThru is specified, returns the updated database object.

    .NOTES
        The following database properties are read-only after creation and cannot be modified
        using this command:

        - **CatalogCollation**: The catalog-level collation used for metadata and temporary
          objects. This property is marked as ReadOnlyAfterCreation in the SMO Database
          class and can only be set during database creation (e.g., using `New-SqlDscDatabase`
          or CREATE DATABASE statements).

        - **DatabaseSnapshotBaseName**: The base name of the source database for a database
          snapshot. This property is marked as ReadOnlyAfterCreation in the SMO Database
          class. To create database snapshots, use the `New-SqlDscDatabaseSnapshot` or
          `New-SqlDscDatabase` command with the `-DatabaseSnapshotBaseName` parameter.

        - **IsLedger**: Specifies whether the database is a ledger database. Ledger
          status can only be set during database creation using the `New-SqlDscDatabase`
          command with the `-IsLedger` parameter. Once a database is created, its ledger
          status cannot be changed.

        There are some database properties that require method calls instead of direct
        property assignment and will be supported through separate commands, e.g.
        `Set-SqlDscDatabaseDefaultFileGroup`.

        Azure SQL Database service tier and service objective changes should be managed
        using Azure management cmdlets (e.g., `Set-AzSqlDatabase` with `-Edition` and
        `-RequestedServiceObjectiveName` parameters) rather than through SMO.
#>
function Set-SqlDscDatabaseProperty
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'This is not a password but a credential name reference.')]
    [OutputType()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(DefaultParameterSetName = 'ServerObjectSet', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'ServerObjectSet')]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter(ParameterSetName = 'DatabaseObjectSet', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        # Boolean Properties
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AcceleratedRecoveryEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AnsiNullDefault,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AnsiNullsEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AnsiPaddingEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AnsiWarningsEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ArithmeticAbortEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AutoClose,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AutoCreateIncrementalStatisticsEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AutoCreateStatisticsEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AutoShrink,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AutoUpdateStatisticsAsync,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AutoUpdateStatisticsEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $BrokerEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ChangeTrackingAutoCleanUp,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ChangeTrackingEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $CloseCursorsOnCommitEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ConcatenateNullYieldsNull,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $DatabaseOwnershipChaining,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $DataRetentionEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $DateCorrelationOptimization,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $EncryptionEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $HonorBrokerPriority,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IsFullTextEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IsParameterizationForced,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IsReadCommittedSnapshotOn,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IsSqlDw,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IsVarDecimalStorageFormatEnabled,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $LegacyCardinalityEstimation,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $LegacyCardinalityEstimationForSecondary,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $LocalCursorsDefault,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NestedTriggersEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NumericRoundAbortEnabled,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $ParameterSniffing,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $ParameterSniffingForSecondary,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $QueryOptimizerHotfixes,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseScopedConfigurationOnOff]
        $QueryOptimizerHotfixesForSecondary,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $QuotedIdentifiersEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ReadOnly,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RecursiveTriggersEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RemoteDataArchiveEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RemoteDataArchiveUseFederatedServiceAccount,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $TemporalHistoryRetentionEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $TransformNoiseWords,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Trustworthy,

        # Integer Properties
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
        $MaxDop,

        [Parameter()]
        [System.Int32]
        $MaxDopForSecondary,

        [Parameter()]
        [System.Int32]
        $MirroringRedoQueueMaxSize,

        [Parameter()]
        [System.Int32]
        $MirroringTimeout,

        [Parameter()]
        [System.Int32]
        $TargetRecoveryTime,

        [Parameter()]
        [System.Int32]
        $TwoDigitYearCutoff,

        # Long Integer Properties
        [Parameter()]
        [System.Double]
        $MaxSizeInBytes,

        # String Properties
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Collation,

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

        # Enum Properties
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
        [Microsoft.SqlServer.Management.Smo.DelayedDurability]
        $DelayedDurability,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.FilestreamNonTransactedAccessType]
        $FilestreamNonTransactedAccess,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.MirroringSafetyLevel]
        $MirroringSafetyLevel,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.PageVerify]
        $PageVerify,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.RecoveryModel]
        $RecoveryModel,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]
        $UserAccess,

        # Control Parameters
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        # Get the server object based on parameter set
        $serverInstance = if ($PSCmdlet.ParameterSetName -eq 'DatabaseObjectSet')
        {
            $DatabaseObject.Parent
        }
        else
        {
            $ServerObject
        }

        # Validate compatibility level if specified
        if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
        {
            $supportedCompatibilityLevels = $serverInstance | Get-SqlDscCompatibilityLevel

            if ($CompatibilityLevel -notin $supportedCompatibilityLevels)
            {
                $errorMessage = $script:localizedData.Set_SqlDscDatabaseProperty_InvalidCompatibilityLevel -f $CompatibilityLevel, $serverInstance.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.ArgumentException]::new($errorMessage),
                        'SSDD0002', # SQL Server Database - Invalid compatibility level
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $CompatibilityLevel
                    )
                )
            }
        }

        # Validate collation if specified
        if ($PSBoundParameters.ContainsKey('Collation'))
        {
            if ($Collation -notin $serverInstance.EnumCollations().Name)
            {
                $errorMessage = $script:localizedData.Set_SqlDscDatabaseProperty_InvalidCollation -f $Collation, $serverInstance.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.ArgumentException]::new($errorMessage),
                        'SSDD0003', # SQL Server Database - Invalid collation
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Collation
                    )
                )
            }
        }
    }

    process
    {
        # Get the database object based on the parameter set
        switch ($PSCmdlet.ParameterSetName)
        {
            'ServerObjectSet'
            {
                Write-Verbose -Message ($script:localizedData.Database_Set -f $Name, $ServerObject.InstanceName)

                $previousErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'

                $sqlDatabaseObject = $ServerObject |
                    Get-SqlDscDatabase -Name $Name -Refresh:$Refresh -ErrorAction 'Stop'

                $ErrorActionPreference = $previousErrorActionPreference
            }

            'DatabaseObjectSet'
            {
                Write-Verbose -Message ($script:localizedData.Database_Set -f $DatabaseObject.Name, $DatabaseObject.Parent.InstanceName)

                $sqlDatabaseObject = $DatabaseObject
            }
        }

        # Remove common parameters and function-specific parameters, leaving only database properties
        $boundParameters = Remove-CommonParameter -Hashtable $PSBoundParameters

        # Remove function-specific parameters
        foreach ($parameterToRemove in @('ServerObject', 'Name', 'DatabaseObject', 'Refresh', 'Force', 'PassThru'))
        {
            $boundParameters.Remove($parameterToRemove)
        }

        $verboseDescriptionMessage = $script:localizedData.Database_Set_ShouldProcessVerboseDescription -f $sqlDatabaseObject.Name, $sqlDatabaseObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Database_Set_ShouldProcessVerboseWarning -f $sqlDatabaseObject.Name
        $captionMessage = $script:localizedData.Database_Set_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            $wasUpdated = $false

            # Set each specified property
            foreach ($parameterName in $boundParameters.Keys)
            {
                # Check if property exists on the database object
                if ($sqlDatabaseObject.PSObject.Properties.Name -notcontains $parameterName)
                {
                    Write-Error -Message ($script:localizedData.Set_SqlDscDatabaseProperty_PropertyNotFound -f $parameterName, $sqlDatabaseObject.Name) -Category ([System.Management.Automation.ErrorCategory]::InvalidArgument) -ErrorId 'SSDDP0010' -TargetObject $sqlDatabaseObject
                    continue
                }

                $currentValue = $sqlDatabaseObject.$parameterName
                $newValue = $boundParameters.$parameterName

                # Convert SwitchParameter to Boolean for SMO properties
                if ($newValue -is [System.Management.Automation.SwitchParameter])
                {
                    $newValue = $newValue.IsPresent
                }

                # Only update if the value is different
                if ($currentValue -ne $newValue)
                {
                    Write-Debug -Message ($script:localizedData.Database_UpdatingProperty -f $parameterName, $newValue)
                    $sqlDatabaseObject.$parameterName = $newValue
                    $wasUpdated = $true
                }
                else
                {
                    Write-Debug -Message ($script:localizedData.Database_PropertyAlreadySet -f $parameterName, $currentValue)
                }
            }

            # Apply changes if any properties were updated
            if ($wasUpdated)
            {
                Write-Debug -Message ($script:localizedData.Database_Updating -f $sqlDatabaseObject.Name)

                try
                {
                    $sqlDatabaseObject.Alter()
                }
                catch
                {
                    $errorMessage = $script:localizedData.Database_SetFailed -f $sqlDatabaseObject.Name, $sqlDatabaseObject.Parent.InstanceName

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'SSDD0004', # SQL Server Database - Set failed
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $sqlDatabaseObject
                        )
                    )
                }
                Write-Debug -Message ($script:localizedData.Database_Updated -f $sqlDatabaseObject.Name)
            }
            else
            {
                Write-Debug -Message ($script:localizedData.Database_NoPropertiesChanged -f $sqlDatabaseObject.Name)
            }

            if ($PassThru.IsPresent)
            {
                return $sqlDatabaseObject
            }
        }
    }
}
