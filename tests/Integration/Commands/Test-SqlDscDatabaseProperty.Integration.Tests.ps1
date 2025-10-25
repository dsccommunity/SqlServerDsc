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

    # Define comprehensive test cases for database properties that can be tested with master database
    $script:masterDatabaseTestCases = @(
        # Boolean properties - test with expected values for master database
        @{ PropertyName = 'AutoClose'; DatabaseName = 'master' }
        @{ PropertyName = 'AutoShrink'; DatabaseName = 'master' }
        @{ PropertyName = 'AnsiNullsEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'AnsiPaddingEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'AnsiWarningsEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'ArithmeticAbortEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'BrokerEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'CaseSensitive'; DatabaseName = 'master' }
        @{ PropertyName = 'CloseCursorsOnCommitEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'ConcatenateNullYieldsNull'; DatabaseName = 'master' }
        @{ PropertyName = 'DatabaseOwnershipChaining'; DatabaseName = 'master' }
        @{ PropertyName = 'DateCorrelationOptimization'; DatabaseName = 'master' }
        @{ PropertyName = 'EncryptionEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'HasDatabaseEncryptionKey'; DatabaseName = 'master' }
        @{ PropertyName = 'HasFileInCloud'; DatabaseName = 'master' }
        @{ PropertyName = 'HasMemoryOptimizedObjects'; DatabaseName = 'master' }
        @{ PropertyName = 'IsAccessible'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbAccessAdmin'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbBackupOperator'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbDataReader'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbDataWriter'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbDdlAdmin'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbDenyDataReader'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbDenyDataWriter'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbManager'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbOwner'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDbSecurityAdmin'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDatabaseSnapshot'; DatabaseName = 'master' }
        @{ PropertyName = 'IsDatabaseSnapshotBase'; DatabaseName = 'master' }
        @{ PropertyName = 'IsFabricDatabase'; DatabaseName = 'master' }
        @{ PropertyName = 'IsFullTextEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'IsLedger'; DatabaseName = 'master' }
        @{ PropertyName = 'IsLoginManager'; DatabaseName = 'master' }
        @{ PropertyName = 'IsMailHost'; DatabaseName = 'master' }
        @{ PropertyName = 'IsManagementDataWarehouse'; DatabaseName = 'master' }
        @{ PropertyName = 'IsMaxSizeApplicable'; DatabaseName = 'master' }
        @{ PropertyName = 'IsMirroringEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'IsParameterizationForced'; DatabaseName = 'master' }
        @{ PropertyName = 'IsReadCommittedSnapshotOn'; DatabaseName = 'master' }
        @{ PropertyName = 'IsSqlDw'; DatabaseName = 'master' }
        @{ PropertyName = 'IsSqlDwEdition'; DatabaseName = 'master' }
        @{ PropertyName = 'IsSystemObject'; DatabaseName = 'master' }
        @{ PropertyName = 'IsVarDecimalStorageFormatEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'IsVarDecimalStorageFormatSupported'; DatabaseName = 'master' }
        @{ PropertyName = 'LocalCursorsDefault'; DatabaseName = 'master' }
        @{ PropertyName = 'NestedTriggersEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'NumericRoundAbortEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'QuotedIdentifiersEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'ReadOnly'; DatabaseName = 'master' }
        @{ PropertyName = 'RecursiveTriggersEnabled'; DatabaseName = 'master' }
        @{ PropertyName = 'Trustworthy'; DatabaseName = 'master' }
        @{ PropertyName = 'WarnOnRename'; DatabaseName = 'master' }

        # String properties - test with actual values from master database
        @{ PropertyName = 'Collation'; DatabaseName = 'master' }
        @{ PropertyName = 'Owner'; DatabaseName = 'master' }
        @{ PropertyName = 'DefaultFileGroup'; DatabaseName = 'master' }
        @{ PropertyName = 'DefaultSchema'; DatabaseName = 'master' }

        # Numeric properties - test with actual values from master database
        @{ PropertyName = 'ID'; DatabaseName = 'master' }
        @{ PropertyName = 'ActiveConnections'; DatabaseName = 'master' }
        @{ PropertyName = 'MaxDop'; DatabaseName = 'master' }
        @{ PropertyName = 'TargetRecoveryTime'; DatabaseName = 'master' }
        @{ PropertyName = 'Version'; DatabaseName = 'master' }

        # Enum properties - test with actual values from master database
        @{ PropertyName = 'CompatibilityLevel'; DatabaseName = 'master' }
        @{ PropertyName = 'ContainmentType'; DatabaseName = 'master' }
        @{ PropertyName = 'PageVerify'; DatabaseName = 'master' }
        @{ PropertyName = 'RecoveryModel'; DatabaseName = 'master' }
        @{ PropertyName = 'SnapshotIsolationState'; DatabaseName = 'master' }
        @{ PropertyName = 'State'; DatabaseName = 'master' }
        @{ PropertyName = 'Status'; DatabaseName = 'master' }
        @{ PropertyName = 'UserAccess'; DatabaseName = 'master' }
    )

    # Define properties that should be tested with model database (as it's more configurable)
    $script:modelDatabaseTestCases = @(
        @{ PropertyName = 'AutoCreateStatisticsEnabled'; DatabaseName = 'model' }
        @{ PropertyName = 'AutoUpdateStatisticsEnabled'; DatabaseName = 'model' }
        @{ PropertyName = 'AutoUpdateStatisticsAsync'; DatabaseName = 'model' }
        @{ PropertyName = 'AutoCreateIncrementalStatisticsEnabled'; DatabaseName = 'model' }
        @{ PropertyName = 'ParameterSniffing'; DatabaseName = 'model' }
        @{ PropertyName = 'LegacyCardinalityEstimation'; DatabaseName = 'model' }
        @{ PropertyName = 'QueryOptimizerHotfixes'; DatabaseName = 'model' }
        @{ PropertyName = 'AnsiNullDefault'; DatabaseName = 'model' }
        @{ PropertyName = 'ChangeTrackingEnabled'; DatabaseName = 'model' }
        @{ PropertyName = 'ChangeTrackingAutoCleanUp'; DatabaseName = 'model' }
        @{ PropertyName = 'DataRetentionEnabled'; DatabaseName = 'model' }
        @{ PropertyName = 'TemporalHistoryRetentionEnabled'; DatabaseName = 'model' }
        @{ PropertyName = 'AcceleratedRecoveryEnabled'; DatabaseName = 'model' }
        @{ PropertyName = 'DelayedDurability'; DatabaseName = 'model' }
        @{ PropertyName = 'HonorBrokerPriority'; DatabaseName = 'model' }
        @{ PropertyName = 'TransformNoiseWords'; DatabaseName = 'model' }
    )
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Test-SqlDscDatabaseProperty' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -ErrorAction 'Stop'
    }

    Context 'When using ServerObjectSet parameter set' {
        It 'Should return true when testing master database with no properties specified' {
            $result = Test-SqlDscDatabaseProperty -ServerObject $script:serverObject -Name 'master' -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should throw an error when testing non-existent database' {
            { Test-SqlDscDatabaseProperty -ServerObject $script:serverObject -Name 'NonExistentDatabase' -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When using DatabaseObjectSet parameter set' {
        It 'Should return true when testing database object with no properties specified' {
            $databaseObject = $script:serverObject | Get-SqlDscDatabase -Name 'master' -ErrorAction 'Stop'

            $result = Test-SqlDscDatabaseProperty -DatabaseObject $databaseObject -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should accept database object via pipeline' {
            $result = $script:serverObject | Get-SqlDscDatabase -Name 'master' -ErrorAction 'Stop' | Test-SqlDscDatabaseProperty -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }

    Context 'When testing different database types' {
        It 'Should work correctly with system databases' -ForEach @(
            @{ DatabaseName = 'tempdb' }
            @{ DatabaseName = 'model' }
            @{ DatabaseName = 'msdb' }
        ) {
            param($DatabaseName)

            $result = Test-SqlDscDatabaseProperty -ServerObject $script:serverObject -Name $DatabaseName -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }

    Context 'When testing all database properties with master database' {
        It 'Should return true when property <PropertyName> matches expected value' -ForEach $script:masterDatabaseTestCases {
            # Get the database object
            $databaseObject = $script:serverObject.Databases[$DatabaseName]

            # Get the actual value from the database
            $actualValue = $databaseObject.$PropertyName

            # Create parameter splat for the test
            $testParameters = @{
                ServerObject = $script:serverObject
                Name = $DatabaseName
                $PropertyName = $actualValue
                ErrorAction = 'Stop'
            }

            # For enum properties, convert to string if needed
            if ($actualValue -is [System.Enum])
            {
                $testParameters[$PropertyName] = $actualValue.ToString()
            }

            $result = Test-SqlDscDatabaseProperty @testParameters

            $result | Should -BeTrue -Because "Property '$PropertyName' should match the actual value '$actualValue' for database '$DatabaseName'"
        }

        It 'Should return false when property <PropertyName> does not match expected value' -ForEach $script:masterDatabaseTestCases {
            # Get the database object
            $databaseObject = $script:serverObject.Databases[$DatabaseName]

            # Get the actual value from the database
            $actualValue = $databaseObject.$PropertyName

            # Create a different test value based on the property type
            $differentValue = switch ($actualValue.GetType().Name)
            {
                'Boolean' { -not $actualValue }
                'String' { 'DifferentTestValue' }
                'Int32' { if ($actualValue -eq 0) { 999 } else { 0 } }
                'Int64' { if ($actualValue -eq 0) { 999 } else { 0 } }
                default {
                    if ($actualValue -is [System.Enum])
                    {
                        # For enum types, try to get a different enum value
                        $enumType = $actualValue.GetType()
                        $enumValues = [System.Enum]::GetValues($enumType)
                        $differentEnum = $enumValues | Where-Object { $_ -ne $actualValue } | Select-Object -First 1
                        if ($differentEnum)
                        {
                            $differentEnum.ToString()
                        }
                        else
                        {
                            'DifferentEnumValue'
                        }
                    }
                    else
                    {
                        'DifferentValue'
                    }
                }
            }

            # Skip test if we couldn't determine a different value
            if ($differentValue -eq $actualValue)
            {
                Set-ItResult -Skipped -Because "Could not determine a different value for property '$PropertyName' with value '$actualValue'"
                return
            }

            # Create parameter splat for the test
            $testParameters = @{
                ServerObject = $script:serverObject
                Name = $DatabaseName
                $PropertyName = $differentValue
                ErrorAction = 'Stop'
            }

            $result = Test-SqlDscDatabaseProperty @testParameters

            $result | Should -BeFalse -Because "Property '$PropertyName' should not match when testing different value '$differentValue' (actual: '$actualValue') for database '$DatabaseName'"
        }
    }

    Context 'When testing all database properties with model database' {
        It 'Should return true when property <PropertyName> matches expected value' -ForEach $script:modelDatabaseTestCases {
            # Get the database object
            $databaseObject = $script:serverObject.Databases[$DatabaseName]

            # Get the actual value from the database
            $actualValue = $databaseObject.$PropertyName

            # Create parameter splat for the test
            $testParameters = @{
                ServerObject = $script:serverObject
                Name = $DatabaseName
                $PropertyName = $actualValue
                ErrorAction = 'Stop'
            }

            # For enum properties, convert to string if needed
            if ($actualValue -is [System.Enum])
            {
                $testParameters[$PropertyName] = $actualValue.ToString()
            }

            $result = Test-SqlDscDatabaseProperty @testParameters

            $result | Should -BeTrue -Because "Property '$PropertyName' should match the actual value '$actualValue' for database '$DatabaseName'"
        }

        It 'Should return false when property <PropertyName> does not match expected value' -ForEach $script:modelDatabaseTestCases {
            # Get the database object
            $databaseObject = $script:serverObject.Databases[$DatabaseName]

            # Get the actual value from the database
            $actualValue = $databaseObject.$PropertyName

            # Create a different test value based on the property type
            $differentValue = switch ($actualValue.GetType().Name)
            {
                'Boolean' { -not $actualValue }
                'String' { 'DifferentTestValue' }
                'Int32' { if ($actualValue -eq 0) { 999 } else { 0 } }
                'Int64' { if ($actualValue -eq 0) { 999 } else { 0 } }
                default {
                    if ($actualValue -is [System.Enum])
                    {
                        # For enum types, try to get a different enum value
                        $enumType = $actualValue.GetType()
                        $enumValues = [System.Enum]::GetValues($enumType)
                        $differentEnum = $enumValues | Where-Object { $_ -ne $actualValue } | Select-Object -First 1
                        if ($differentEnum)
                        {
                            $differentEnum.ToString()
                        }
                        else
                        {
                            'DifferentEnumValue'
                        }
                    }
                    else
                    {
                        'DifferentValue'
                    }
                }
            }

            # Skip test if we couldn't determine a different value
            if ($differentValue -eq $actualValue)
            {
                Set-ItResult -Skipped -Because "Could not determine a different value for property '$PropertyName' with value '$actualValue'"
                return
            }

            # Create parameter splat for the test
            $testParameters = @{
                ServerObject = $script:serverObject
                Name = $DatabaseName
                $PropertyName = $differentValue
                ErrorAction = 'Stop'
            }

            $result = Test-SqlDscDatabaseProperty @testParameters

            $result | Should -BeFalse -Because "Property '$PropertyName' should not match when testing different value '$differentValue' (actual: '$actualValue') for database '$DatabaseName'"
        }
    }

    Context 'When testing comprehensive database property combinations' {
        It 'Should return true when testing multiple properties together with correct values' {
            # Get actual values from master database
            $masterDb = $script:serverObject.Databases['master']
            $actualCollation = $masterDb.Collation
            $actualCompatibilityLevel = $masterDb.CompatibilityLevel.ToString()
            $actualRecoveryModel = $masterDb.RecoveryModel.ToString()
            $actualOwner = $masterDb.Owner

            $result = Test-SqlDscDatabaseProperty -ServerObject $script:serverObject -Name 'master' `
                -Collation $actualCollation `
                -RecoveryModel $actualRecoveryModel `
                -Owner $actualOwner `
                -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when testing multiple properties with one incorrect value' {
            # Get actual values from master database
            $masterDb = $script:serverObject.Databases['master']
            $actualCollation = $masterDb.Collation
            $actualOwner = $masterDb.Owner

            # Use wrong recovery model
            $wrongRecoveryModel = if ($masterDb.RecoveryModel.ToString() -eq 'Simple') { 'Full' } else { 'Simple' }

            $result = Test-SqlDscDatabaseProperty -ServerObject $script:serverObject -Name 'master' `
                -Collation $actualCollation `
                -RecoveryModel $wrongRecoveryModel `
                -Owner $actualOwner `
                -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }
}
