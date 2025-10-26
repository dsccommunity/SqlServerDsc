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

    # Persistent test database created by New-SqlDscDatabase integration tests
    $script:persistentTestDatabase = 'SqlDscIntegrationTestDatabase_Persistent'

    # Define comprehensive test cases for database properties that can be tested with the persistent test database
    $script:testDatabaseTestCases = @(
        # Boolean properties - test with expected values for the persistent test database
        @{ PropertyName = 'AutoClose'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AutoShrink'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AnsiNullsEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AnsiPaddingEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AnsiWarningsEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'ArithmeticAbortEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'BrokerEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'CaseSensitive'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'CloseCursorsOnCommitEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'ConcatenateNullYieldsNull'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'DatabaseOwnershipChaining'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'DateCorrelationOptimization'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'EncryptionEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        # TODO: HasDatabaseEncryptionKey - Commented out because this property requires specific database configuration or SQL Server edition that is not available in the persistent test database
        # @{ PropertyName = 'HasDatabaseEncryptionKey'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'HasFileInCloud'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'HasMemoryOptimizedObjects'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsAccessible'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbAccessAdmin'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbBackupOperator'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbDataReader'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbDataWriter'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbDdlAdmin'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbDenyDataReader'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbDenyDataWriter'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbManager'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbOwner'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDbSecurityAdmin'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDatabaseSnapshot'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsDatabaseSnapshotBase'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        # TODO: IsFabricDatabase - Commented out because this property requires specific database configuration or SQL Server edition that is not available in the persistent test database
        # @{ PropertyName = 'IsFabricDatabase'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsFullTextEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        # TODO: IsLedger - Commented out because this property requires specific database configuration or SQL Server edition that is not available in the persistent test database
        # @{ PropertyName = 'IsLedger'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsLoginManager'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsMailHost'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsManagementDataWarehouse'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        # TODO: IsMaxSizeApplicable - Commented out because this property requires specific database configuration or SQL Server edition that is not available in the persistent test database
        # @{ PropertyName = 'IsMaxSizeApplicable'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsMirroringEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsParameterizationForced'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsReadCommittedSnapshotOn'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsSqlDw'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsSqlDwEdition'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsSystemObject'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsVarDecimalStorageFormatEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'IsVarDecimalStorageFormatSupported'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'LocalCursorsDefault'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'NestedTriggersEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'NumericRoundAbortEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'QuotedIdentifiersEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'ReadOnly'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'RecursiveTriggersEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'Trustworthy'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AutoCreateStatisticsEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AutoUpdateStatisticsEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AutoUpdateStatisticsAsync'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AutoCreateIncrementalStatisticsEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'ParameterSniffing'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'LegacyCardinalityEstimation'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'QueryOptimizerHotfixes'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'AnsiNullDefault'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'ChangeTrackingEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'ChangeTrackingAutoCleanUp'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        # TODO: DataRetentionEnabled - Commented out because this property requires specific database configuration or SQL Server edition that is not available in the persistent test database
        # @{ PropertyName = 'DataRetentionEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'TemporalHistoryRetentionEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        # TODO: AcceleratedRecoveryEnabled - Commented out because this property requires specific database configuration or SQL Server edition that is not available in the persistent test database
        # @{ PropertyName = 'AcceleratedRecoveryEnabled'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'DelayedDurability'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'HonorBrokerPriority'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }
        @{ PropertyName = 'TransformNoiseWords'; DatabaseName = $script:persistentTestDatabase; TestValue = $true }

        # String properties - test with actual values from the persistent test database
        @{ PropertyName = 'Collation'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'Owner'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'DefaultFileGroup'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'DefaultSchema'; DatabaseName = $script:persistentTestDatabase }

        # Numeric properties - test with actual values from the persistent test database
        @{ PropertyName = 'ID'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'ActiveConnections'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'MaxDop'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'TargetRecoveryTime'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'Version'; DatabaseName = $script:persistentTestDatabase }

        # Enum properties - test with actual values from the persistent test database
        @{ PropertyName = 'CompatibilityLevel'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'ContainmentType'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'PageVerify'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'RecoveryModel'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'SnapshotIsolationState'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'State'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'Status'; DatabaseName = $script:persistentTestDatabase }
        @{ PropertyName = 'UserAccess'; DatabaseName = $script:persistentTestDatabase }
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
            $result = Test-SqlDscDatabaseProperty -ServerObject $script:serverObject -Name $DatabaseName -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }

    Context 'When testing all database properties with persistent test database' {
        Context 'When testing Boolean properties' {
            It 'Should return expected result when property <PropertyName> is tested with value $true' -ForEach ($script:testDatabaseTestCases | Where-Object { $_.TestValue }) {
                $databaseObject = $script:serverObject.Databases[$DatabaseName]
                $actualValue = $databaseObject.$PropertyName

                $testParameters = @{
                    ServerObject  = $script:serverObject
                    Name          = $DatabaseName
                    $PropertyName = $TestValue
                    ErrorAction   = 'Stop'
                }

                $result = Test-SqlDscDatabaseProperty @testParameters

                $expectedResult = $actualValue -eq $TestValue

                $result | Should -Be $expectedResult -Because "Property '$PropertyName' should return $expectedResult when testing value '$TestValue' against actual value '$actualValue' for database '$DatabaseName'"
            }

            It 'Should return expected result when property <PropertyName> is tested with value $false' -ForEach ($script:testDatabaseTestCases | Where-Object { $_.TestValue }) {
                $databaseObject = $script:serverObject.Databases[$DatabaseName]
                $actualValue = $databaseObject.$PropertyName
                $testValue = $false

                $testParameters = @{
                    ServerObject  = $script:serverObject
                    Name          = $DatabaseName
                    $PropertyName = $testValue
                    ErrorAction   = 'Stop'
                }

                $result = Test-SqlDscDatabaseProperty @testParameters

                $expectedResult = $actualValue -eq $testValue

                $result | Should -Be $expectedResult -Because "Property '$PropertyName' should return $expectedResult when testing value '$testValue' against actual value '$actualValue' for database '$DatabaseName'"
            }
        }

        Context 'When testing non-Boolean properties' {
            It 'Should return true when property <PropertyName> matches actual value' -ForEach ($script:testDatabaseTestCases | Where-Object { -not $_.TestValue }) {
                $databaseObject = $script:serverObject.Databases[$DatabaseName]
                $actualValue = $databaseObject.$PropertyName

                $testParameters = @{
                    ServerObject  = $script:serverObject
                    Name          = $DatabaseName
                    $PropertyName = $actualValue
                    ErrorAction   = 'Stop'
                }

                if ($actualValue -is [System.Enum])
                {
                    $testParameters[$PropertyName] = $actualValue.ToString()
                }

                $result = Test-SqlDscDatabaseProperty @testParameters

                $result | Should -BeTrue -Because "Property '$PropertyName' should return true when testing value '$actualValue' against actual value '$actualValue' for database '$DatabaseName'"
            }

            It 'Should return false when property <PropertyName> does not match actual value' -ForEach ($script:testDatabaseTestCases | Where-Object { -not $_.TestValue }) {
                $databaseObject = $script:serverObject.Databases[$DatabaseName]
                $actualValue = $databaseObject.$PropertyName

                $testValue = if ($actualValue -is [System.Enum])
                {
                    $enumType = $actualValue.GetType()
                    $enumValues = [System.Enum]::GetValues($enumType)
                    $differentEnum = $enumValues |
                        Where-Object { $_ -ne $actualValue } | Select-Object -First 1

                    if ($differentEnum)
                    {
                        $differentEnum.ToString()
                    }
                    else
                    {
                        # Could not find a different enum value, skip this test
                        $null
                    }
                }
                else
                {
                    if ($null -eq $actualValue)
                    {
                        'DifferentValue'
                    }
                    else
                    {
                        switch ($actualValue.GetType().Name)
                        {
                            'String'
                            {
                                'DifferentTestValue'
                            }

                            'Int32'
                            {
                                if ($actualValue -eq 0)
                                {
                                    999
                                }
                                else
                                {
                                    0
                                }
                            }

                            'Int64'
                            {
                                if ($actualValue -eq 0)
                                {
                                    999
                                }
                                else
                                {
                                    0
                                }
                            }

                            default
                            {
                                'DifferentValue'
                            }
                        }
                    }
                }

                if ($null -eq $testValue -or $testValue -eq $actualValue)
                {
                    Set-ItResult -Skipped -Because "Could not determine a different value for property '$PropertyName' with value '$actualValue'"
                    return
                }

                $testParameters = @{
                    ServerObject  = $script:serverObject
                    Name          = $DatabaseName
                    $PropertyName = $testValue
                    ErrorAction   = 'Stop'
                }

                $result = Test-SqlDscDatabaseProperty @testParameters

                $result | Should -BeFalse -Because "Property '$PropertyName' should return false when testing value '$testValue' against actual value '$actualValue' for database '$DatabaseName'"
            }
        }
    }

    Context 'When testing comprehensive database property combinations' {
        It 'Should return true when testing multiple properties together with correct values' {
            # Get actual values from persistent test database
            $testDb = $script:serverObject.Databases['SqlDscIntegrationTestDatabase_Persistent']
            $actualCollation = $testDb.Collation
            $actualCompatibilityLevel = $testDb.CompatibilityLevel.ToString()
            $actualRecoveryModel = $testDb.RecoveryModel.ToString()
            $actualOwner = $testDb.Owner

            $testParameters = @{
                ServerObject   = $script:serverObject
                Name           = 'SqlDscIntegrationTestDatabase_Persistent'
                Collation      = $actualCollation
                RecoveryModel  = $actualRecoveryModel
                Owner          = $actualOwner
                ErrorAction    = 'Stop'
            }

            $result = Test-SqlDscDatabaseProperty @testParameters

            $result | Should -BeTrue
        }

        It 'Should return false when testing multiple properties with one incorrect value' {
            # Get actual values from persistent test database
            $testDb = $script:serverObject.Databases['SqlDscIntegrationTestDatabase_Persistent']
            $actualCollation = $testDb.Collation
            $actualOwner = $testDb.Owner

            # Use wrong recovery model
            $wrongRecoveryModel = if ($testDb.RecoveryModel.ToString() -eq 'Simple')
            {
                'Full'
            }
            else
            {
                'Simple'
            }

            $testParameters = @{
                ServerObject   = $script:serverObject
                Name           = 'SqlDscIntegrationTestDatabase_Persistent'
                Collation      = $actualCollation
                RecoveryModel  = $wrongRecoveryModel
                Owner          = $actualOwner
                ErrorAction    = 'Stop'
            }

            $result = Test-SqlDscDatabaseProperty @testParameters

            $result | Should -BeFalse
        }
    }
}
