[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }

    # Loading mocked classes for discovery time
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    # Define test data for all database properties with sample values (needed at discovery time for ForEach)
    $testPropertyData = @{
        # Boolean Properties
        'AcceleratedRecoveryEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'ActiveDirectory' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'AnsiNullDefault' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'AnsiNullsEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'AnsiPaddingEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'AnsiWarningsEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'ArithmeticAbortEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'AutoClose' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'AutoCreateIncrementalStatisticsEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'AutoCreateStatisticsEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'AutoShrink' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'AutoUpdateStatisticsAsync' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'AutoUpdateStatisticsEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'BrokerEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'CaseSensitive' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'ChangeTrackingAutoCleanUp' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'ChangeTrackingEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'CloseCursorsOnCommitEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'ConcatenateNullYieldsNull' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'DatabaseOwnershipChaining' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'DataRetentionEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'DateCorrelationOptimization' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'DelayedDurability' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'EncryptionEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'HasDatabaseEncryptionKey' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'HasFileInCloud' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'HasMemoryOptimizedObjects' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'HonorBrokerPriority' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsAccessible' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'IsDatabaseSnapshot' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDatabaseSnapshotBase' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbAccessAdmin' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbBackupOperator' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbDatareader' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbDatawriter' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbDdlAdmin' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbDenyDatareader' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbDenyDatawriter' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbManager' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsDbOwner' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'IsDbSecurityAdmin' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsFabricDatabase' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsFullTextEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsLedger' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsLoginManager' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsMailHost' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsManagementDataWarehouse' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsMaxSizeApplicable' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsMirroringEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsParameterizationForced' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsReadCommittedSnapshotOn' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsSqlDw' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsSqlDwEdition' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsSystemObject' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsVarDecimalStorageFormatEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'IsVarDecimalStorageFormatSupported' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'LegacyCardinalityEstimation' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'LegacyCardinalityEstimationForSecondary' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'LocalCursorsDefault' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'NestedTriggersEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'NumericRoundAbortEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'ParameterSniffing' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'ParameterSniffingForSecondary' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'QueryOptimizerHotfixes' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'QueryOptimizerHotfixesForSecondary' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'QuotedIdentifiersEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'ReadOnly' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'RecursiveTriggersEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'RemoteDataArchiveEnabled' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'RemoteDataArchiveUseFederatedServiceAccount' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'TemporalHistoryRetentionEnabled' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }
        'TransformNoiseWords' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'Trustworthy' = @{ Type = 'Boolean'; TestValue = $false; ExpectedValue = $false }
        'WarnOnRename' = @{ Type = 'Boolean'; TestValue = $true; ExpectedValue = $true }

        # String Properties
        'AvailabilityGroupName' = @{ Type = 'String'; TestValue = 'TestAG'; ExpectedValue = 'TestAG' }
        'AzureServiceObjective' = @{ Type = 'String'; TestValue = 'S1'; ExpectedValue = 'S1' }
        'CatalogCollation' = @{ Type = 'String'; TestValue = 'SQL_Latin1_General_CP1_CI_AS'; ExpectedValue = 'SQL_Latin1_General_CP1_CI_AS' }
        'Collation' = @{ Type = 'String'; TestValue = 'SQL_Latin1_General_CP1_CI_AS'; ExpectedValue = 'SQL_Latin1_General_CP1_CI_AS' }
        'DboLogin' = @{ Type = 'String'; TestValue = 'sa'; ExpectedValue = 'sa' }
        'DefaultFileGroup' = @{ Type = 'String'; TestValue = 'PRIMARY'; ExpectedValue = 'PRIMARY' }
        'DefaultFileStreamFileGroup' = @{ Type = 'String'; TestValue = 'FileStreamGroup'; ExpectedValue = 'FileStreamGroup' }
        'DefaultFullTextCatalog' = @{ Type = 'String'; TestValue = 'TestCatalog'; ExpectedValue = 'TestCatalog' }
        'DefaultSchema' = @{ Type = 'String'; TestValue = 'dbo'; ExpectedValue = 'dbo' }
        'FilestreamDirectoryName' = @{ Type = 'String'; TestValue = 'TestDirectory'; ExpectedValue = 'TestDirectory' }
        'MirroringPartner' = @{ Type = 'String'; TestValue = 'TestPartner'; ExpectedValue = 'TestPartner' }
        'MirroringPartnerInstance' = @{ Type = 'String'; TestValue = 'TestInstance'; ExpectedValue = 'TestInstance' }
        'MirroringWitness' = @{ Type = 'String'; TestValue = 'TestWitness'; ExpectedValue = 'TestWitness' }
        'Owner' = @{ Type = 'String'; TestValue = 'sa'; ExpectedValue = 'sa' }
        'PersistentVersionStoreFileGroup' = @{ Type = 'String'; TestValue = 'PRIMARY'; ExpectedValue = 'PRIMARY' }
        'PrimaryFilePath' = @{ Type = 'String'; TestValue = 'C:\Data\'; ExpectedValue = 'C:\Data\' }
        'RemoteDataArchiveCredential' = @{ Type = 'String'; TestValue = 'TestCredential'; ExpectedValue = 'TestCredential' }
        'RemoteDataArchiveEndpoint' = @{ Type = 'String'; TestValue = 'https://test.endpoint.com'; ExpectedValue = 'https://test.endpoint.com' }
        'RemoteDataArchiveLinkedServer' = @{ Type = 'String'; TestValue = 'TestLinkedServer'; ExpectedValue = 'TestLinkedServer' }
        'RemoteDatabaseName' = @{ Type = 'String'; TestValue = 'RemoteDB'; ExpectedValue = 'RemoteDB' }
        'UserName' = @{ Type = 'String'; TestValue = 'TestUser'; ExpectedValue = 'TestUser' }

        # Integer Properties
        'ActiveConnections' = @{ Type = 'Int32'; TestValue = 5; ExpectedValue = 5 }
        'ChangeTrackingRetentionPeriod' = @{ Type = 'Int32'; TestValue = 2; ExpectedValue = 2 }
        'DefaultFullTextLanguage' = @{ Type = 'Int32'; TestValue = 1033; ExpectedValue = 1033 }
        'DefaultLanguage' = @{ Type = 'Int32'; TestValue = 0; ExpectedValue = 0 }
        'ID' = @{ Type = 'Int32'; TestValue = 5; ExpectedValue = 5 }
        'MaxDop' = @{ Type = 'Int32'; TestValue = 0; ExpectedValue = 0 }
        'MaxDopForSecondary' = @{ Type = 'Int32'; TestValue = 0; ExpectedValue = 0 }
        'MirroringRedoQueueMaxSize' = @{ Type = 'Int32'; TestValue = 100; ExpectedValue = 100 }
        'MirroringRoleSequence' = @{ Type = 'Int32'; TestValue = 1; ExpectedValue = 1 }
        'MirroringSafetySequence' = @{ Type = 'Int32'; TestValue = 1; ExpectedValue = 1 }
        'MirroringTimeout' = @{ Type = 'Int32'; TestValue = 10; ExpectedValue = 10 }
        'TargetRecoveryTime' = @{ Type = 'Int32'; TestValue = 60; ExpectedValue = 60 }
        'TwoDigitYearCutoff' = @{ Type = 'Int32'; TestValue = 2049; ExpectedValue = 2049 }
        'Version' = @{ Type = 'Int32'; TestValue = 904; ExpectedValue = 904 }

        # Enum Properties
        'AvailabilityDatabaseSynchronizationState' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseSynchronizationState]::Synchronized; ExpectedValue = [Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseSynchronizationState]::Synchronized }
        'ChangeTrackingRetentionPeriodUnits' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.RetentionPeriodUnits]::Days; ExpectedValue = [Microsoft.SqlServer.Management.Smo.RetentionPeriodUnits]::Days }
        'CompatibilityLevel' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]::Version150; ExpectedValue = [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]::Version150 }
        'ContainmentType' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.ContainmentType]::None; ExpectedValue = [Microsoft.SqlServer.Management.Smo.ContainmentType]::None }
        'DatabaseEngineEdition' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.DatabaseEngineEdition]::Standard; ExpectedValue = [Microsoft.SqlServer.Management.Smo.DatabaseEngineEdition]::Standard }
        'DatabaseEngineType' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.DatabaseEngineType]::Standalone; ExpectedValue = [Microsoft.SqlServer.Management.Smo.DatabaseEngineType]::Standalone }
        'FilestreamNonTransactedAccess' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.FilestreamNonTransactedAccessType]::Off; ExpectedValue = [Microsoft.SqlServer.Management.Smo.FilestreamNonTransactedAccessType]::Off }
        'LogReuseWaitStatus' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.LogReuseWaitStatus]::Nothing; ExpectedValue = [Microsoft.SqlServer.Management.Smo.LogReuseWaitStatus]::Nothing }
        'MirroringSafetyLevel' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.MirroringSafetyLevel]::Full; ExpectedValue = [Microsoft.SqlServer.Management.Smo.MirroringSafetyLevel]::Full }
        'MirroringStatus' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.MirroringStatus]::None; ExpectedValue = [Microsoft.SqlServer.Management.Smo.MirroringStatus]::None }
        'MirroringWitnessStatus' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.MirroringWitnessStatus]::None; ExpectedValue = [Microsoft.SqlServer.Management.Smo.MirroringWitnessStatus]::None }
        'ReplicationOptions' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.ReplicationOptions]::None; ExpectedValue = [Microsoft.SqlServer.Management.Smo.ReplicationOptions]::None }
        'SnapshotIsolationState' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.SnapshotIsolationState]::Disabled; ExpectedValue = [Microsoft.SqlServer.Management.Smo.SnapshotIsolationState]::Disabled }
        'State' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.SqlSmoState]::Existing; ExpectedValue = [Microsoft.SqlServer.Management.Smo.SqlSmoState]::Existing }
        'Status' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal; ExpectedValue = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal }
        'PageVerify' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.PageVerify]::Checksum; ExpectedValue = [Microsoft.SqlServer.Management.Smo.PageVerify]::Checksum }
        'RecoveryModel' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full; ExpectedValue = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full }
        'UserAccess' = @{ Type = 'Enum'; TestValue = [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Multiple; ExpectedValue = [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Multiple }
    }

    # Create test cases array for ForEach (needed at discovery time)
    $script:testCases = @()
    foreach ($kvp in $testPropertyData.GetEnumerator()) {
        $script:testCases += @{
            PropertyName = $kvp.Key
            TestValue = $kvp.Value.TestValue
            Type = $kvp.Value.Type
            ExpectedValue = $kvp.Value.ExpectedValue
        }
    }

    # Create smaller test set for mismatch testing (first 10 properties)
    $script:mismatchTestCases = @()
    $counter = 0
    foreach ($kvp in $testPropertyData.GetEnumerator()) {
        if ($counter -ge 10) { break }

        # Create a different test value based on type
        $differentValue = switch ($kvp.Value.Type) {
            'Boolean' { -not $kvp.Value.ExpectedValue }
            'String' { 'DifferentValue' }
            'Int32' { $kvp.Value.ExpectedValue + 100 }
            'Enum' {
                # For enum types, use a different valid enum value
                switch ($kvp.Key) {
                    'AvailabilityDatabaseSynchronizationState' { [Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseSynchronizationState]::Synchronizing }
                    'ChangeTrackingRetentionPeriodUnits' { [Microsoft.SqlServer.Management.Smo.RetentionPeriodUnits]::Hours }
                    'CompatibilityLevel' { [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]::Version140 }
                    'ContainmentType' { [Microsoft.SqlServer.Management.Smo.ContainmentType]::Partial }
                    'DatabaseEngineEdition' { [Microsoft.SqlServer.Management.Smo.DatabaseEngineEdition]::Enterprise }
                    'DatabaseEngineType' { [Microsoft.SqlServer.Management.Smo.DatabaseEngineType]::SqlAzureDatabase }
                    'FilestreamNonTransactedAccess' { [Microsoft.SqlServer.Management.Smo.FilestreamNonTransactedAccessType]::ReadOnly }
                    'LogReuseWaitStatus' { [Microsoft.SqlServer.Management.Smo.LogReuseWaitStatus]::LogBackup }
                    'MirroringSafetyLevel' { [Microsoft.SqlServer.Management.Smo.MirroringSafetyLevel]::Off }
                    'MirroringStatus' { [Microsoft.SqlServer.Management.Smo.MirroringStatus]::Suspended }
                    'MirroringWitnessStatus' { [Microsoft.SqlServer.Management.Smo.MirroringWitnessStatus]::Disconnected }
                    'ReplicationOptions' { [Microsoft.SqlServer.Management.Smo.ReplicationOptions]::Published }
                    'SnapshotIsolationState' { [Microsoft.SqlServer.Management.Smo.SnapshotIsolationState]::Enabled }
                    'State' { [Microsoft.SqlServer.Management.Smo.SqlSmoState]::Creating }
                    'Status' { [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline }
                    'PageVerify' { [Microsoft.SqlServer.Management.Smo.PageVerify]::None }
                    'RecoveryModel' { [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple }
                    'UserAccess' { [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Single }
                    default { 'DifferentValue' }
                }
            }
            default { 'DifferentValue' }
        }

        $script:mismatchTestCases += @{
            PropertyName = $kvp.Key
            DifferentValue = $differentValue
        }
        $counter++
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Test-SqlDscDatabaseProperty' -Tag 'Public' {
    Context 'When using ServerObjectSet parameter set' {
        BeforeAll {
            $mockExistingDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version150' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'sa' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'AutoClose' -Value $false -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'AutoShrink' -Value $false -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'ReadOnly' -Value $false -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Trustworthy' -Value $false -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockExistingDatabase
                }
            } -Force

            $mockDatabaseObjectWithParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version150' -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'sa' -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'AutoClose' -Value $false -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'AutoShrink' -Value $false -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'ReadOnly' -Value $false -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'Trustworthy' -Value $false -Force
            $mockDatabaseObjectWithParent | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force
        }

        It 'Should return true when database exists and no properties specified' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase'

            $result | Should -BeTrue
        }

        It 'Should throw an error when database does not exist' {
            { Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'NonExistentDatabase' } | Should -Throw -ExpectedMessage "Database 'NonExistentDatabase' was not found."
        }

        It 'Should return true when single property matches' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -Collation 'SQL_Latin1_General_CP1_CI_AS'

            $result | Should -BeTrue
        }

        It 'Should return false when single property does not match' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -Collation 'Different_Collation'

            $result | Should -BeFalse
        }

        It 'Should return true when multiple properties match' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -Collation 'SQL_Latin1_General_CP1_CI_AS' -CompatibilityLevel 'Version150' -Owner 'sa'

            $result | Should -BeTrue
        }

        It 'Should return false when one of multiple properties does not match' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -Collation 'SQL_Latin1_General_CP1_CI_AS' -CompatibilityLevel 'Version140' -Owner 'sa'

            $result | Should -BeFalse
        }

        It 'Should return true when boolean property matches' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -AutoClose $false

            $result | Should -BeTrue
        }

        It 'Should return false when boolean property does not match' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -AutoClose $true

            $result | Should -BeFalse
        }
    }

    Context 'When using DatabaseObjectSet parameter set' {
        BeforeAll {
            $mockExistingDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version150' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'sa' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'AutoClose' -Value $false -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'AutoShrink' -Value $false -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'ReadOnly' -Value $false -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Trustworthy' -Value $false -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force
        }

        It 'Should return true when no properties specified' {
            $result = Test-SqlDscDatabaseProperty -DatabaseObject $mockExistingDatabase

            $result | Should -BeTrue
        }

        It 'Should return true when single property matches' {
            $result = Test-SqlDscDatabaseProperty -DatabaseObject $mockExistingDatabase -Collation 'SQL_Latin1_General_CP1_CI_AS'

            $result | Should -BeTrue
        }

        It 'Should return false when single property does not match' {
            $result = Test-SqlDscDatabaseProperty -DatabaseObject $mockExistingDatabase -Collation 'Different_Collation'

            $result | Should -BeFalse
        }

        It 'Should return true when multiple properties match' {
            $result = Test-SqlDscDatabaseProperty -DatabaseObject $mockExistingDatabase -Collation 'SQL_Latin1_General_CP1_CI_AS' -CompatibilityLevel 'Version150' -Owner 'sa'

            $result | Should -BeTrue
        }

        It 'Should return false when one of multiple properties does not match' {
            $result = Test-SqlDscDatabaseProperty -DatabaseObject $mockExistingDatabase -Collation 'SQL_Latin1_General_CP1_CI_AS' -CompatibilityLevel 'Version140' -Owner 'sa'

            $result | Should -BeFalse
        }

        It 'Should accept pipeline input' {
            $result = $mockExistingDatabase | Test-SqlDscDatabaseProperty -Collation 'SQL_Latin1_General_CP1_CI_AS'

            $result | Should -BeTrue
        }
    }

    Context 'When testing string properties that may come from enums' {
        BeforeAll {
            $mockExistingDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockExistingDatabase
                }
            } -Force
        }

        It 'Should handle string properties correctly when they match' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -RecoveryModel 'Full'

            $result | Should -BeTrue
        }

        It 'Should handle string properties correctly when they do not match' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -RecoveryModel 'Simple'

            $result | Should -BeFalse
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObjectSet' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSet'
                # Note: Dynamic parameters cannot be easily tested in this format, so we focus on core parameters
            }
        ) {
            $parameterSets = (Get-Command -Name 'Test-SqlDscDatabaseProperty').ParameterSets
            $serverObjectSet = $parameterSets | Where-Object -FilterScript { $_.Name -eq 'ServerObjectSet' }

            $serverObjectSet | Should -Not -BeNullOrEmpty
            $serverObjectSet.Parameters.Name | Should -Contain 'ServerObject'
            $serverObjectSet.Parameters.Name | Should -Contain 'Name'
        }

        It 'Should have the correct parameters in parameter set DatabaseObjectSet' -ForEach @(
            @{
                ExpectedParameterSetName = 'DatabaseObjectSet'
            }
        ) {
            $parameterSets = (Get-Command -Name 'Test-SqlDscDatabaseProperty').ParameterSets
            $databaseObjectSet = $parameterSets | Where-Object -FilterScript { $_.Name -eq 'DatabaseObjectSet' }

            $databaseObjectSet | Should -Not -BeNullOrEmpty
            $databaseObjectSet.Parameters.Name | Should -Contain 'DatabaseObject'
        }

        It 'Should have ServerObject as a mandatory parameter in ServerObjectSet' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscDatabaseProperty').Parameters['ServerObject']

            # Check if mandatory in ServerObjectSet
            $serverObjectSetAttribute = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'ServerObjectSet' }
            $serverObjectSetAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ServerObjectSet' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscDatabaseProperty').Parameters['Name']

            # Check if mandatory in ServerObjectSet
            $serverObjectSetAttribute = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'ServerObjectSet' }
            $serverObjectSetAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseObject as a mandatory parameter in DatabaseObjectSet' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscDatabaseProperty').Parameters['DatabaseObject']

            # Check if mandatory in DatabaseObjectSet
            $databaseObjectSetAttribute = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'DatabaseObjectSet' }
            $databaseObjectSetAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseObject support ValueFromPipeline' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscDatabaseProperty').Parameters['DatabaseObject']

            # Check if it accepts pipeline input
            $pipelineAttribute = $parameterInfo.Attributes | Where-Object { $_.ValueFromPipeline -eq $true }
            $pipelineAttribute | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Database property parameters' {
        BeforeAll {
            # Create mock database using the SMO stub - properties are already set to expected values
            $mockDatabaseWithAllProperties = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseWithAllProperties.Name = 'TestDatabase'

            $mockServerObjectForAll = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectForAll.InstanceName = 'TestInstance'
            $mockServerObjectForAll | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockDatabaseWithAllProperties
                }
            } -Force
        }

        It 'Should support all database property parameters' {
            $command = Get-Command -Name 'Test-SqlDscDatabaseProperty'

            # Test that all expected parameters are available (using the testPropertyData from BeforeDiscovery)
            $expectedParameters = @(
                'AcceleratedRecoveryEnabled', 'ActiveDirectory', 'AnsiNullDefault', 'AnsiNullsEnabled', 'AnsiPaddingEnabled',
                'AnsiWarningsEnabled', 'ArithmeticAbortEnabled', 'AutoClose', 'AutoCreateIncrementalStatisticsEnabled',
                'AutoCreateStatisticsEnabled', 'AutoShrink', 'AutoUpdateStatisticsAsync', 'AutoUpdateStatisticsEnabled',
                'BrokerEnabled', 'CaseSensitive', 'ChangeTrackingAutoCleanUp', 'ChangeTrackingEnabled',
                'CloseCursorsOnCommitEnabled', 'ConcatenateNullYieldsNull', 'DatabaseOwnershipChaining',
                'DataRetentionEnabled', 'DateCorrelationOptimization', 'DelayedDurability', 'EncryptionEnabled',
                'HasDatabaseEncryptionKey', 'HasFileInCloud', 'HasMemoryOptimizedObjects', 'HonorBrokerPriority',
                'IsAccessible', 'IsDatabaseSnapshot', 'IsDatabaseSnapshotBase', 'IsDbAccessAdmin', 'IsDbBackupOperator',
                'IsDbDatareader', 'IsDbDatawriter', 'IsDbDdlAdmin', 'IsDbDenyDatareader', 'IsDbDenyDatawriter',
                'IsDbManager', 'IsDbOwner', 'IsDbSecurityAdmin', 'IsFabricDatabase', 'IsFullTextEnabled',
                'IsLedger', 'IsLoginManager', 'IsMailHost', 'IsManagementDataWarehouse', 'IsMaxSizeApplicable',
                'IsMirroringEnabled', 'IsParameterizationForced', 'IsReadCommittedSnapshotOn', 'IsSqlDw',
                'IsSqlDwEdition', 'IsSystemObject', 'IsVarDecimalStorageFormatEnabled', 'IsVarDecimalStorageFormatSupported',
                'LegacyCardinalityEstimation', 'LegacyCardinalityEstimationForSecondary', 'LocalCursorsDefault',
                'NestedTriggersEnabled', 'NumericRoundAbortEnabled', 'ParameterSniffing', 'ParameterSniffingForSecondary',
                'QueryOptimizerHotfixes', 'QueryOptimizerHotfixesForSecondary', 'QuotedIdentifiersEnabled', 'ReadOnly',
                'RecursiveTriggersEnabled', 'RemoteDataArchiveEnabled', 'RemoteDataArchiveUseFederatedServiceAccount',
                'TemporalHistoryRetentionEnabled', 'TransformNoiseWords', 'Trustworthy', 'WarnOnRename',
                'AvailabilityGroupName', 'AzureServiceObjective', 'CatalogCollation', 'Collation', 'DboLogin',
                'DefaultFileGroup', 'DefaultFileStreamFileGroup', 'DefaultFullTextCatalog', 'DefaultSchema',
                'FilestreamDirectoryName', 'MirroringPartner', 'MirroringPartnerInstance', 'MirroringWitness',
                'Name', 'Owner', 'PersistentVersionStoreFileGroup', 'PrimaryFilePath', 'RemoteDataArchiveCredential',
                'RemoteDataArchiveEndpoint', 'RemoteDataArchiveLinkedServer', 'RemoteDatabaseName', 'UserName',
                'ActiveConnections', 'ChangeTrackingRetentionPeriod', 'DefaultFullTextLanguage', 'DefaultLanguage',
                'ID', 'MaxDop', 'MaxDopForSecondary', 'MirroringRedoQueueMaxSize', 'MirroringRoleSequence',
                'MirroringSafetySequence', 'MirroringTimeout', 'TargetRecoveryTime', 'TwoDigitYearCutoff', 'Version',
                'AvailabilityDatabaseSynchronizationState', 'ChangeTrackingRetentionPeriodUnits', 'CompatibilityLevel', 'ContainmentType', 'FilestreamNonTransactedAccess', 'PageVerify', 'RecoveryModel', 'UserAccess'
            )

            foreach ($parameterName in $expectedParameters) {
                $command.Parameters.Keys | Should -Contain $parameterName -Because "Parameter '$parameterName' should be available"
            }
        }

        It 'Should return true when property <PropertyName> matches expected value' -ForEach $script:testCases {
            # Create parameter hashtable
            $params = @{
                ServerObject = $mockServerObjectForAll
                Name = 'TestDatabase'
                $PropertyName = $TestValue
            }

            $result = Test-SqlDscDatabaseProperty @params
            $result | Should -BeTrue -Because "Property '$PropertyName' with value '$TestValue' should match"
        }

        It 'Should return false when property <PropertyName> does not match expected value' -ForEach $script:mismatchTestCases {
            # Create parameter hashtable with different value
            $params = @{
                ServerObject = $mockServerObjectForAll
                Name = 'TestDatabase'
                $PropertyName = $DifferentValue
            }

            $result = Test-SqlDscDatabaseProperty @params
            $result | Should -BeFalse -Because "Property '$PropertyName' with different value should not match"
        }

        It 'Should test multiple properties together and return true when all match' {
            # Test a combination of different property types
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObjectForAll -Name 'TestDatabase' `
                -Collation 'SQL_Latin1_General_CP1_CI_AS' `
                -AutoClose $false `
                -MaxDop 0 `
                -RecoveryModel 'Full' `
                -Owner 'sa'

            $result | Should -BeTrue
        }

        It 'Should test multiple properties together and return false when one does not match' {
            # Test a combination where one property doesn't match
            $result = Test-SqlDscDatabaseProperty -ServerObject $mockServerObjectForAll -Name 'TestDatabase' `
                -Collation 'SQL_Latin1_General_CP1_CI_AS' `
                -AutoClose $true `
                -MaxDop 0 `
                -RecoveryModel 'Full' `
                -Owner 'sa'

            $result | Should -BeFalse
        }
    }
}
