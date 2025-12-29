<#
    .SYNOPSIS
        The `SqlDatabase` DSC resource is used to create, modify, or remove
        databases on a SQL Server instance.

    .DESCRIPTION
        The `SqlDatabase` DSC resource is used to create, modify, or remove
        databases on a SQL Server instance.

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

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabase).

        ### Property **Reasons** does not work with **PSDscRunAsCredential**

        When using the built-in parameter **PSDscRunAsCredential** the read-only
        property **Reasons** will return empty values for the properties **Code**
        and **Phrase**. The built-in property **PSDscRunAsCredential** does not work
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

        ### Read-only properties after creation

        The following properties cannot be modified after database creation and can
        only be set during creation:

        - **CatalogCollation**: The catalog-level collation used for metadata and
          temporary objects.
        - **IsLedger**: Ledger status cannot be changed after database is created.

    .PARAMETER Name
        The name of the database.

    .PARAMETER Ensure
        Specifies if the database should be present or absent. If set to `Present`
        the database will be added if it does not exist, or updated if the database
        exist. If `Absent` then the database will be removed from the server.
        Defaults to `Present`.

    .PARAMETER Collation
        Specifies the default collation for the database.

    .PARAMETER CompatibilityLevel
        Specifies the database compatibility level.

    .PARAMETER RecoveryModel
        Specifies the database recovery model.

    .PARAMETER OwnerName
        Specifies the name of the login that should be the owner of the database.

    .PARAMETER SnapshotIsolation
        Specifies whether snapshot isolation should be enabled for the database.

    .PARAMETER CatalogCollation
        Specifies the collation type for the system catalog. Can only be set during
        database creation. Requires SQL Server 2019 or later.

    .PARAMETER IsLedger
        Specifies whether to create a ledger database. Can only be set during
        database creation. Requires SQL Server 2022 or later.

    .PARAMETER AcceleratedRecoveryEnabled
        Specifies whether Accelerated Database Recovery (ADR) is enabled. Requires
        SQL Server 2019 or later.

    .PARAMETER AnsiNullDefault
        Specifies whether new columns allow NULL by default unless explicitly
        specified.

    .PARAMETER AnsiNullsEnabled
        Specifies whether comparisons to NULL follow ANSI SQL behavior.

    .PARAMETER AnsiPaddingEnabled
        Specifies whether padding for variable-length columns follows ANSI rules.

    .PARAMETER AnsiWarningsEnabled
        Specifies whether ANSI warnings are generated for certain conditions.

    .PARAMETER ArithmeticAbortEnabled
        Specifies whether a query is terminated when an overflow or divide-by-zero
        error occurs.

    .PARAMETER AutoClose
        Specifies whether the database closes after the last user exits.

    .PARAMETER AutoCreateIncrementalStatisticsEnabled
        Specifies whether creation of incremental statistics on partitioned tables
        is allowed.

    .PARAMETER AutoCreateStatisticsEnabled
        Specifies whether single-column statistics are automatically created for
        query optimization.

    .PARAMETER AutoShrink
        Specifies whether the database automatically shrinks files when free space
        is detected.

    .PARAMETER AutoUpdateStatisticsAsync
        Specifies whether statistics are updated asynchronously.

    .PARAMETER AutoUpdateStatisticsEnabled
        Specifies whether statistics are automatically updated when out-of-date.

    .PARAMETER BrokerEnabled
        Specifies whether Service Broker is enabled for the database.

    .PARAMETER ChangeTrackingAutoCleanUp
        Specifies whether automatic cleanup of change tracking information is
        enabled.

    .PARAMETER ChangeTrackingEnabled
        Specifies whether change tracking is enabled for the database.

    .PARAMETER ChangeTrackingRetentionPeriod
        Specifies the retention period value for change tracking information.

    .PARAMETER ChangeTrackingRetentionPeriodUnits
        Specifies the units for the retention period.

    .PARAMETER CloseCursorsOnCommitEnabled
        Specifies whether open cursors are closed when a transaction is committed.

    .PARAMETER ConcatenateNullYieldsNull
        Specifies whether concatenation with NULL results in NULL.

    .PARAMETER ContainmentType
        Specifies the containment level of the database.

    .PARAMETER DatabaseOwnershipChaining
        Specifies whether ownership chaining across objects within the database is
        enabled.

    .PARAMETER DataRetentionEnabled
        Specifies whether SQL Server data retention policy is enabled. Requires SQL
        Server 2017 or later.

    .PARAMETER DateCorrelationOptimization
        Specifies whether date correlation optimization is enabled.

    .PARAMETER DefaultFullTextLanguage
        Specifies the LCID of the default full-text language.

    .PARAMETER DefaultLanguage
        Specifies the ID of the default language for the database.

    .PARAMETER DelayedDurability
        Specifies the delayed durability setting for the database.

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
        Specifies whether forced parameterization is enabled.

    .PARAMETER IsReadCommittedSnapshotOn
        Specifies whether READ_COMMITTED_SNAPSHOT isolation is ON.

    .PARAMETER IsSqlDw
        Specifies whether the database is a SQL Data Warehouse database.

    .PARAMETER IsVarDecimalStorageFormatEnabled
        Specifies whether vardecimal compression is enabled.

    .PARAMETER LegacyCardinalityEstimation
        Specifies the legacy cardinality estimator setting for the primary.

    .PARAMETER LegacyCardinalityEstimationForSecondary
        Specifies the legacy cardinality estimator setting for secondary replicas.

    .PARAMETER LocalCursorsDefault
        Specifies whether cursors are local by default instead of global.

    .PARAMETER MaxDop
        Specifies the MAXDOP database-scoped configuration for primary replicas.

    .PARAMETER MaxDopForSecondary
        Specifies the MAXDOP database-scoped configuration for secondary replicas.

    .PARAMETER MaxSizeInBytes
        Specifies the maximum size of the database in bytes.

    .PARAMETER MirroringPartner
        Specifies the mirroring partner server name.

    .PARAMETER MirroringPartnerInstance
        Specifies the mirroring partner instance name.

    .PARAMETER MirroringRedoQueueMaxSize
        Specifies the redo queue maximum size for mirroring/AGs.

    .PARAMETER MirroringSafetyLevel
        Specifies the mirroring safety level.

    .PARAMETER MirroringTimeout
        Specifies the timeout in seconds for mirroring sessions.

    .PARAMETER MirroringWitness
        Specifies the mirroring witness server.

    .PARAMETER NestedTriggersEnabled
        Specifies whether triggers are allowed to fire other triggers.

    .PARAMETER NumericRoundAbortEnabled
        Specifies whether an error is raised on loss of precision due to rounding.

    .PARAMETER PageVerify
        Specifies the page verification setting.

    .PARAMETER ParameterSniffing
        Specifies the parameter sniffing setting for the primary.

    .PARAMETER ParameterSniffingForSecondary
        Specifies the parameter sniffing setting for secondary replicas.

    .PARAMETER PersistentVersionStoreFileGroup
        Specifies the filegroup used for the Persistent Version Store (PVS).
        Requires SQL Server 2019 or later.

    .PARAMETER PrimaryFilePath
        Specifies the path of the primary data files directory.

    .PARAMETER QueryOptimizerHotfixes
        Specifies the query optimizer hotfixes setting for the primary.

    .PARAMETER QueryOptimizerHotfixesForSecondary
        Specifies the query optimizer hotfixes setting for secondary replicas.

    .PARAMETER QuotedIdentifiersEnabled
        Specifies whether identifiers can be delimited by double quotes.

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
        Specifies whether automatic cleanup of system-versioned temporal history is
        enabled. Requires SQL Server 2017 or later.

    .PARAMETER TransformNoiseWords
        Specifies how full-text noise word behavior is controlled during queries.

    .PARAMETER Trustworthy
        Specifies whether implicit access to external resources by modules is
        allowed.

    .PARAMETER TwoDigitYearCutoff
        Specifies the two-digit year cutoff used for date conversion.

    .PARAMETER UserAccess
        Specifies the database user access mode.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlDatabase -Method Get -Property @{
            ServerName   = 'localhost'
            InstanceName = 'SQL2019'
            Name         = 'MyDatabase'
        }

        This example shows how to call the resource using Invoke-DscResource.
#>
[DscResource(RunAsCredential = 'Optional')]
class SqlDatabase : SqlResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    # Basic database properties
    [DscProperty()]
    [System.String]
    $Collation

    [DscProperty()]
    [DatabaseCompatibilityLevel]
    $CompatibilityLevel

    [DscProperty()]
    [ValidateSet('Simple', 'Full', 'BulkLogged')]
    [System.String]
    $RecoveryModel

    [DscProperty()]
    [System.String]
    $OwnerName

    [DscProperty()]
    [Nullable[System.Boolean]]
    $SnapshotIsolation

    # Read-only after creation properties
    [DscProperty()]
    [ValidateSet('DatabaseDefault', 'SqlLatin1GeneralCp1CiAs')]
    [System.String]
    $CatalogCollation

    [DscProperty()]
    [Nullable[System.Boolean]]
    $IsLedger

    # Boolean properties
    [DscProperty()]
    [Nullable[System.Boolean]]
    $AcceleratedRecoveryEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AnsiNullDefault

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AnsiNullsEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AnsiPaddingEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AnsiWarningsEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ArithmeticAbortEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AutoClose

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AutoCreateIncrementalStatisticsEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AutoCreateStatisticsEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AutoShrink

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AutoUpdateStatisticsAsync

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AutoUpdateStatisticsEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $BrokerEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ChangeTrackingAutoCleanUp

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ChangeTrackingEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $CloseCursorsOnCommitEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ConcatenateNullYieldsNull

    [DscProperty()]
    [Nullable[System.Boolean]]
    $DatabaseOwnershipChaining

    [DscProperty()]
    [Nullable[System.Boolean]]
    $DataRetentionEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $DateCorrelationOptimization

    [DscProperty()]
    [Nullable[System.Boolean]]
    $EncryptionEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $HonorBrokerPriority

    [DscProperty()]
    [Nullable[System.Boolean]]
    $IsFullTextEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $IsParameterizationForced

    [DscProperty()]
    [Nullable[System.Boolean]]
    $IsReadCommittedSnapshotOn

    [DscProperty()]
    [Nullable[System.Boolean]]
    $IsSqlDw

    [DscProperty()]
    [Nullable[System.Boolean]]
    $IsVarDecimalStorageFormatEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $LocalCursorsDefault

    [DscProperty()]
    [Nullable[System.Boolean]]
    $NestedTriggersEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $NumericRoundAbortEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $QuotedIdentifiersEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ReadOnly

    [DscProperty()]
    [Nullable[System.Boolean]]
    $RecursiveTriggersEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $RemoteDataArchiveEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $RemoteDataArchiveUseFederatedServiceAccount

    [DscProperty()]
    [Nullable[System.Boolean]]
    $TemporalHistoryRetentionEnabled

    [DscProperty()]
    [Nullable[System.Boolean]]
    $TransformNoiseWords

    [DscProperty()]
    [Nullable[System.Boolean]]
    $Trustworthy

    # Integer properties
    [DscProperty()]
    [Nullable[System.Int32]]
    $ChangeTrackingRetentionPeriod

    [DscProperty()]
    [Nullable[System.Int32]]
    $DefaultFullTextLanguage

    [DscProperty()]
    [Nullable[System.Int32]]
    $DefaultLanguage

    [DscProperty()]
    [Nullable[System.Int32]]
    $MaxDop

    [DscProperty()]
    [Nullable[System.Int32]]
    $MaxDopForSecondary

    [DscProperty()]
    [Nullable[System.Int32]]
    $MirroringRedoQueueMaxSize

    [DscProperty()]
    [Nullable[System.Int32]]
    $MirroringTimeout

    [DscProperty()]
    [Nullable[System.Int32]]
    $TargetRecoveryTime

    [DscProperty()]
    [Nullable[System.Int32]]
    $TwoDigitYearCutoff

    # Double properties
    [DscProperty()]
    [Nullable[System.Double]]
    $MaxSizeInBytes

    # String properties
    [DscProperty()]
    [System.String]
    $FilestreamDirectoryName

    [DscProperty()]
    [System.String]
    $MirroringPartner

    [DscProperty()]
    [System.String]
    $MirroringPartnerInstance

    [DscProperty()]
    [System.String]
    $MirroringWitness

    [DscProperty()]
    [System.String]
    $PersistentVersionStoreFileGroup

    [DscProperty()]
    [System.String]
    $PrimaryFilePath

    [DscProperty()]
    [System.String]
    $RemoteDataArchiveCredential

    [DscProperty()]
    [System.String]
    $RemoteDataArchiveEndpoint

    [DscProperty()]
    [System.String]
    $RemoteDataArchiveLinkedServer

    [DscProperty()]
    [System.String]
    $RemoteDatabaseName

    # Enum properties (using string to avoid SMO type dependencies)
    [DscProperty()]
    [ValidateSet('Minutes', 'Hours', 'Days')]
    [System.String]
    $ChangeTrackingRetentionPeriodUnits

    [DscProperty()]
    [ValidateSet('None', 'Partial')]
    [System.String]
    $ContainmentType

    [DscProperty()]
    [ValidateSet('Disabled', 'Allowed', 'Forced')]
    [System.String]
    $DelayedDurability

    [DscProperty()]
    [ValidateSet('Off', 'ReadOnly', 'Full')]
    [System.String]
    $FilestreamNonTransactedAccess

    [DscProperty()]
    [ValidateSet('Off', 'On', 'Primary')]
    [System.String]
    $LegacyCardinalityEstimation

    [DscProperty()]
    [ValidateSet('Off', 'On', 'Primary')]
    [System.String]
    $LegacyCardinalityEstimationForSecondary

    [DscProperty()]
    [ValidateSet('Off', 'Full', 'Unknown')]
    [System.String]
    $MirroringSafetyLevel

    [DscProperty()]
    [ValidateSet('None', 'TornPageDetection', 'Checksum')]
    [System.String]
    $PageVerify

    [DscProperty()]
    [ValidateSet('Off', 'On', 'Primary')]
    [System.String]
    $ParameterSniffing

    [DscProperty()]
    [ValidateSet('Off', 'On', 'Primary')]
    [System.String]
    $ParameterSniffingForSecondary

    [DscProperty()]
    [ValidateSet('Off', 'On', 'Primary')]
    [System.String]
    $QueryOptimizerHotfixes

    [DscProperty()]
    [ValidateSet('Off', 'On', 'Primary')]
    [System.String]
    $QueryOptimizerHotfixesForSecondary

    [DscProperty()]
    [ValidateSet('Multiple', 'Restricted', 'Single')]
    [System.String]
    $UserAccess

    SqlDatabase () : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties += @(
            'Name'
        )
    }

    [SqlDatabase] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [System.Boolean] Test()
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
            $this.localizedData.EvaluatingDatabaseState -f @(
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
            Only set key property Name if the database exist. Base class will set it
            and handle Ensure.
        #>
        $currentState = @{
            Credential   = $currentStateCredential
            InstanceName = $properties.InstanceName
            ServerName   = $this.ServerName
        }

        $serverObject = $this.GetServerObject()

        $databaseObject = $serverObject |
            Get-SqlDscDatabase -Name $properties.Name -ErrorAction 'SilentlyContinue'

        if ($databaseObject)
        {
            $currentState.Name = $properties.Name

            # Basic properties
            $currentState.Collation = $databaseObject.Collation
            $currentState.CompatibilityLevel = [DatabaseCompatibilityLevel] $databaseObject.CompatibilityLevel.ToString()
            $currentState.RecoveryModel = $databaseObject.RecoveryModel.ToString()
            $currentState.OwnerName = $databaseObject.Owner
            $currentState.SnapshotIsolation = $databaseObject.SnapshotIsolationState -eq 'Enabled'

            # Read-only after creation properties
            if ($null -ne $databaseObject.CatalogCollation)
            {
                $currentState.CatalogCollation = switch ($databaseObject.CatalogCollation.ToString())
                {
                    'DatabaseDefault'
                    {
                        'DatabaseDefault'
                    }

                    'SQL_Latin1_General_CP1_CI_AS'
                    {
                        'SqlLatin1GeneralCp1CiAs'
                    }
                }
            }

            $currentState.IsLedger = $databaseObject.IsLedger

            # Properties that can be directly copied from the database object
            $directCopyProperties = @(
                # Boolean properties
                'AcceleratedRecoveryEnabled'
                'AnsiNullDefault'
                'AnsiNullsEnabled'
                'AnsiPaddingEnabled'
                'AnsiWarningsEnabled'
                'ArithmeticAbortEnabled'
                'AutoClose'
                'AutoCreateIncrementalStatisticsEnabled'
                'AutoCreateStatisticsEnabled'
                'AutoShrink'
                'AutoUpdateStatisticsAsync'
                'AutoUpdateStatisticsEnabled'
                'BrokerEnabled'
                'ChangeTrackingAutoCleanUp'
                'ChangeTrackingEnabled'
                'CloseCursorsOnCommitEnabled'
                'ConcatenateNullYieldsNull'
                'DatabaseOwnershipChaining'
                'DataRetentionEnabled'
                'DateCorrelationOptimization'
                'EncryptionEnabled'
                'HonorBrokerPriority'
                'IsFullTextEnabled'
                'IsParameterizationForced'
                'IsReadCommittedSnapshotOn'
                'IsSqlDw'
                'IsVarDecimalStorageFormatEnabled'
                'LocalCursorsDefault'
                'NestedTriggersEnabled'
                'NumericRoundAbortEnabled'
                'QuotedIdentifiersEnabled'
                'ReadOnly'
                'RecursiveTriggersEnabled'
                'RemoteDataArchiveEnabled'
                'RemoteDataArchiveUseFederatedServiceAccount'
                'TemporalHistoryRetentionEnabled'
                'TransformNoiseWords'
                'Trustworthy'

                # String properties
                'FilestreamDirectoryName'
                'MirroringPartner'
                'MirroringPartnerInstance'
                'MirroringWitness'
                'PersistentVersionStoreFileGroup'
                'PrimaryFilePath'
                'RemoteDataArchiveCredential'
                'RemoteDataArchiveEndpoint'
                'RemoteDataArchiveLinkedServer'
                'RemoteDatabaseName'
            )

            foreach ($propertyName in $directCopyProperties)
            {
                $currentState.$propertyName = $databaseObject.$propertyName
            }

            # Integer properties (require type cast)
            $integerProperties = @(
                'ChangeTrackingRetentionPeriod'
                'DefaultFullTextLanguage'
                'DefaultLanguage'
                'MaxDop'
                'MaxDopForSecondary'
                'MirroringRedoQueueMaxSize'
                'MirroringTimeout'
                'TargetRecoveryTime'
                'TwoDigitYearCutoff'
            )

            foreach ($propertyName in $integerProperties)
            {
                $currentState.$propertyName = [System.Int32] $databaseObject.$propertyName
            }

            # Double properties
            $currentState.MaxSizeInBytes = [System.Double] $databaseObject.MaxSizeInBytes

            # Enum properties (convert to string with null check)
            $enumProperties = @(
                'ChangeTrackingRetentionPeriodUnits'
                'ContainmentType'
                'DelayedDurability'
                'FilestreamNonTransactedAccess'
                'LegacyCardinalityEstimation'
                'LegacyCardinalityEstimationForSecondary'
                'MirroringSafetyLevel'
                'PageVerify'
                'ParameterSniffing'
                'ParameterSniffingForSecondary'
                'QueryOptimizerHotfixes'
                'QueryOptimizerHotfixesForSecondary'
                'UserAccess'
            )

            foreach ($propertyName in $enumProperties)
            {
                if ($null -ne $databaseObject.$propertyName)
                {
                    $currentState.$propertyName = $databaseObject.$propertyName.ToString()
                }
            }
        }

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
        $serverObject = $this.GetServerObject()

        if ($properties.Keys -contains 'Ensure')
        {
            # Evaluate the desired state for property Ensure.
            switch ($properties.Ensure)
            {
                'Present'
                {
                    # Create the database since it was missing.
                    $this.CreateDatabase($serverObject)
                }

                'Absent'
                {
                    # Remove the database since it was present
                    $this.RemoveDatabase($serverObject)
                }
            }
        }
        else
        {
            <#
                Update any properties not in desired state if the database should be present.
                At this point it is assumed the database exist since Ensure property was
                in desired state.

                If the desired state happens to be Absent then ignore any properties not
                in desired state (user have in that case wrongly added properties to an
                "absent configuration").
            #>
            if ($this.Ensure -eq [Ensure]::Present)
            {
                $this.UpdateDatabase($serverObject, $properties)
            }
        }
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # Assert that read-only after creation properties are not being modified on existing database
        if ($properties.Keys -contains 'CatalogCollation' -or $properties.Keys -contains 'IsLedger')
        {
            $serverObject = $this.GetServerObject()
            $databaseObject = $serverObject | Get-SqlDscDatabase -Name $this.Name -ErrorAction 'SilentlyContinue'

            if ($databaseObject)
            {
                if ($properties.Keys -contains 'CatalogCollation')
                {
                    $currentCatalogCollation = switch ($databaseObject.CatalogCollation.ToString())
                    {
                        'DatabaseDefault'
                        {
                            'DatabaseDefault'
                        }
                        'SQL_Latin1_General_CP1_CI_AS'
                        {
                            'SqlLatin1GeneralCp1CiAs'
                        }
                    }

                    if ($properties.CatalogCollation -ne $currentCatalogCollation)
                    {
                        New-InvalidOperationException -Message $this.localizedData.CatalogCollationCannotBeChanged
                    }
                }

                if ($properties.Keys -contains 'IsLedger')
                {
                    if ($properties.IsLedger -ne $databaseObject.IsLedger)
                    {
                        New-InvalidOperationException -Message $this.localizedData.IsLedgerCannotBeChanged
                    }
                }
            }
        }

        # Validate collation if specified
        if ($properties.Keys -contains 'Collation')
        {
            $serverObject = $this.GetServerObject()

            if ($properties.Collation -notin $serverObject.EnumCollations().Name)
            {
                $errorMessage = $this.localizedData.InvalidCollation -f $properties.Collation, $this.InstanceName

                New-ArgumentException -ArgumentName 'Collation' -Message $errorMessage
            }
        }

        # Validate compatibility level if specified
        if ($properties.Keys -contains 'CompatibilityLevel')
        {
            $serverObject = $this.GetServerObject()
            $supportedLevels = $serverObject | Get-SqlDscCompatibilityLevel

            # Use runtime type resolution to avoid parse-time errors when SMO isn't loaded
            $smoCompatibilityLevelType = [System.Type]::GetType('Microsoft.SqlServer.Management.Smo.CompatibilityLevel', $false, $true)

            if ($null -eq $smoCompatibilityLevelType)
            {
                # Fallback: try to get the type from the loaded assemblies
                $smoCompatibilityLevelType = [System.AppDomain]::CurrentDomain.GetAssemblies().GetTypes() |
                    Where-Object -FilterScript { $_.FullName -eq 'Microsoft.SqlServer.Management.Smo.CompatibilityLevel' } |
                    Select-Object -First 1
            }

            if ($null -eq $smoCompatibilityLevelType)
            {
                $errorMessage = $this.localizedData.SmoCompatibilityLevelTypeNotFound

                New-InvalidOperationException -Message $errorMessage
            }

            # Convert the DatabaseCompatibilityLevel enum to the SMO CompatibilityLevel enum
            $compatibilityLevelValue = [System.Enum]::Parse($smoCompatibilityLevelType, $properties.CompatibilityLevel.ToString(), $true)

            if ($compatibilityLevelValue -notin $supportedLevels)
            {
                $errorMessage = $this.localizedData.InvalidCompatibilityLevel -f $properties.CompatibilityLevel.ToString(), $this.InstanceName

                New-ArgumentException -ArgumentName 'CompatibilityLevel' -Message $errorMessage
            }
        }
    }

    hidden [void] CreateDatabase([System.Object] $serverObject)
    {
        Write-Verbose -Message (
            $this.localizedData.CreatingDatabase -f $this.Name, $this.InstanceName
        )

        # Get all properties that have an assigned value for creation.
        $newDatabaseParameters = $this | Get-DscProperty -HasValue -IgnoreZeroEnum -Attribute @(
            'Key'
            'Optional'
        ) -ExcludeName @(
            # Remove properties that are not database properties.
            'InstanceName'
            'ServerName'
            'Port'
            'Protocol'
            'Ensure'
            'Credential'

            # Remove properties that must be handled after creation.
            'SnapshotIsolation'
        )

        # Convert CompatibilityLevel to string (New-SqlDscDatabase expects string).
        if ($newDatabaseParameters.ContainsKey('CompatibilityLevel'))
        {
            $newDatabaseParameters.CompatibilityLevel = $newDatabaseParameters.CompatibilityLevel.ToString()
        }

        # Convert CatalogCollation to SMO enum type.
        if ($newDatabaseParameters.ContainsKey('CatalogCollation'))
        {
            $catalogCollationValue = switch ($newDatabaseParameters.CatalogCollation)
            {
                'DatabaseDefault'
                {
                    $this.ConvertToSmoEnumType('CatalogCollationType', 'DatabaseDefault')
                }

                'SqlLatin1GeneralCp1CiAs'
                {
                    $this.ConvertToSmoEnumType('CatalogCollationType', 'SQL_Latin1_General_CP1_CI_AS')
                }
            }

            $newDatabaseParameters.CatalogCollation = $catalogCollationValue
        }

        try
        {
            $serverObject | New-SqlDscDatabase @newDatabaseParameters -Force -ErrorAction 'Stop'
        }
        catch
        {
            $errorMessage = $this.localizedData.FailedToCreateDatabase -f $this.Name

            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }

        # Handle SnapshotIsolation after creation (not supported by New-SqlDscDatabase).
        if ($null -ne $this.SnapshotIsolation -and $this.SnapshotIsolation)
        {
            $databaseObject = $serverObject | Get-SqlDscDatabase -Name $this.Name -Refresh -ErrorAction 'Stop'

            Write-Verbose -Message (
                $this.localizedData.EnablingSnapshotIsolation
            )

            try
            {
                Enable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $databaseObject -Force -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $this.localizedData.FailedToEnableSnapshotIsolation -f $this.Name

                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }

    hidden [void] RemoveDatabase([System.Object] $serverObject)
    {
        Write-Verbose -Message (
            $this.localizedData.DroppingDatabase -f $this.Name, $this.InstanceName
        )

        try
        {
            $serverObject | Remove-SqlDscDatabase -Name $this.Name -Force -ErrorAction 'Stop'
        }
        catch
        {
            $errorMessage = $this.localizedData.FailedToDropDatabase -f $this.Name

            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }

    hidden [void] UpdateDatabase([System.Object] $serverObject, [System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message (
            $this.localizedData.UpdatingDatabase -f $this.Name, $this.InstanceName
        )

        $databaseObject = $serverObject | Get-SqlDscDatabase -Name $this.Name -ErrorAction 'Stop'

        # Handle OwnerName separately as it requires a method call
        if ($properties.Keys -contains 'OwnerName')
        {
            Write-Verbose -Message (
                $this.localizedData.SettingOwner -f $properties.OwnerName
            )

            try
            {
                $databaseObject.SetOwner($properties.OwnerName)
            }
            catch
            {
                $errorMessage = $this.localizedData.FailedToSetOwner -f $properties.OwnerName, $this.Name

                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }

            $properties.Remove('OwnerName')
        }

        # Handle SnapshotIsolation separately as it requires special commands
        if ($properties.Keys -contains 'SnapshotIsolation')
        {
            if ($properties.SnapshotIsolation)
            {
                Write-Verbose -Message (
                    $this.localizedData.EnablingSnapshotIsolation
                )

                Enable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $databaseObject -Force -ErrorAction 'Stop'
            }
            else
            {
                Write-Verbose -Message (
                    $this.localizedData.DisablingSnapshotIsolation
                )

                Disable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $databaseObject -Force -ErrorAction 'Stop'
            }

            $properties.Remove('SnapshotIsolation')
        }

        # Handle remaining properties using Set-SqlDscDatabaseProperty
        if ($properties.Count -gt 0)
        {
            # Mapping of property names to their SMO enum type names
            $smoEnumTypeMapping = @{
                CompatibilityLevel                      = 'CompatibilityLevel'
                RecoveryModel                           = 'RecoveryModel'
                ChangeTrackingRetentionPeriodUnits      = 'RetentionPeriodUnits'
                ContainmentType                         = 'ContainmentType'
                DelayedDurability                       = 'DelayedDurability'
                FilestreamNonTransactedAccess           = 'FilestreamNonTransactedAccessType'
                LegacyCardinalityEstimation             = 'DatabaseScopedConfigurationOnOff'
                LegacyCardinalityEstimationForSecondary = 'DatabaseScopedConfigurationOnOff'
                MirroringSafetyLevel                    = 'MirroringSafetyLevel'
                PageVerify                              = 'PageVerify'
                ParameterSniffing                       = 'DatabaseScopedConfigurationOnOff'
                ParameterSniffingForSecondary           = 'DatabaseScopedConfigurationOnOff'
                QueryOptimizerHotfixes                  = 'DatabaseScopedConfigurationOnOff'
                QueryOptimizerHotfixesForSecondary      = 'DatabaseScopedConfigurationOnOff'
                UserAccess                              = 'DatabaseUserAccess'
            }

            $setDatabasePropertyParameters = @{}

            foreach ($propertyName in $properties.Keys)
            {
                $propertyValue = $properties.$propertyName

                if ($smoEnumTypeMapping.ContainsKey($propertyName))
                {
                    # Convert string value to SMO enum type
                    $setDatabasePropertyParameters.$propertyName = $this.ConvertToSmoEnumType(
                        $smoEnumTypeMapping[$propertyName],
                        $propertyValue.ToString()
                    )
                }
                else
                {
                    $setDatabasePropertyParameters.$propertyName = $propertyValue
                }
            }

            try
            {
                $databaseObject | Set-SqlDscDatabaseProperty @setDatabasePropertyParameters -Force -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $this.localizedData.FailedToUpdateDatabase -f $this.Name

                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }

}
