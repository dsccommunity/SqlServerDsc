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
        # Using string '1' which converts to both Boolean $true and Integer 1
        @{ PropertyName = 'AutoClose'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'AutoShrink'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'AnsiNullsEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'AnsiPaddingEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'AnsiWarningsEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'ArithmeticAbortEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'BrokerEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'CaseSensitive'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'CloseCursorsOnCommitEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'ConcatenateNullYieldsNull'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'DatabaseOwnershipChaining'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'DateCorrelationOptimization'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'EncryptionEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'HasDatabaseEncryptionKey'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'HasFileInCloud'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'HasMemoryOptimizedObjects'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsAccessible'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbAccessAdmin'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbBackupOperator'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbDataReader'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbDataWriter'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbDdlAdmin'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbDenyDataReader'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbDenyDataWriter'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbManager'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbOwner'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDbSecurityAdmin'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDatabaseSnapshot'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsDatabaseSnapshotBase'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsFabricDatabase'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsFullTextEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsLedger'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsLoginManager'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsMailHost'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsManagementDataWarehouse'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsMaxSizeApplicable'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsMirroringEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsParameterizationForced'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsReadCommittedSnapshotOn'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsSqlDw'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsSqlDwEdition'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsSystemObject'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsVarDecimalStorageFormatEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'IsVarDecimalStorageFormatSupported'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'LocalCursorsDefault'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'NestedTriggersEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'NumericRoundAbortEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'QuotedIdentifiersEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'ReadOnly'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'RecursiveTriggersEnabled'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'Trustworthy'; DatabaseName = 'master'; TestValue = '1' }
        @{ PropertyName = 'WarnOnRename'; DatabaseName = 'master'; TestValue = '1' }

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
        @{ PropertyName = 'AutoCreateStatisticsEnabled'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'AutoUpdateStatisticsEnabled'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'AutoUpdateStatisticsAsync'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'AutoCreateIncrementalStatisticsEnabled'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'ParameterSniffing'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'LegacyCardinalityEstimation'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'QueryOptimizerHotfixes'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'AnsiNullDefault'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'ChangeTrackingEnabled'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'ChangeTrackingAutoCleanUp'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'DataRetentionEnabled'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'TemporalHistoryRetentionEnabled'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'AcceleratedRecoveryEnabled'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'DelayedDurability'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'HonorBrokerPriority'; DatabaseName = 'model'; TestValue = '1' }
        @{ PropertyName = 'TransformNoiseWords'; DatabaseName = 'model'; TestValue = '1' }
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

    Context 'When testing all database properties with master database' {
        Context 'When testing Boolean properties' {
            It 'Should return expected result when property <PropertyName> is tested with value 1' -ForEach ($script:masterDatabaseTestCases | Where-Object { $_.TestValue }) {
                $databaseObject = $script:serverObject.Databases[$DatabaseName]
                $actualValue = $databaseObject.$PropertyName

                $testParameters = @{
                    ServerObject  = $script:serverObject
                    Name          = $DatabaseName
                    $PropertyName = $TestValue
                    ErrorAction   = 'Stop'
                }

                $result = Test-SqlDscDatabaseProperty @testParameters

                $expectedResult = $actualValue.ToString() -eq $TestValue.ToString()

                $result | Should -Be $expectedResult -Because "Property '$PropertyName' should return $expectedResult when testing value '$TestValue' against actual value '$actualValue' for database '$DatabaseName'"
            }

            It 'Should return expected result when property <PropertyName> is tested with value 0' -ForEach ($script:masterDatabaseTestCases | Where-Object { $_.TestValue }) {
                $databaseObject = $script:serverObject.Databases[$DatabaseName]
                $actualValue = $databaseObject.$PropertyName
                $testValue = '0'

                $testParameters = @{
                    ServerObject  = $script:serverObject
                    Name          = $DatabaseName
                    $PropertyName = $testValue
                    ErrorAction   = 'Stop'
                }

                $result = Test-SqlDscDatabaseProperty @testParameters

                $expectedResult = $actualValue.ToString() -eq $testValue.ToString()

                $result | Should -Be $expectedResult -Because "Property '$PropertyName' should return $expectedResult when testing value '$testValue' against actual value '$actualValue' for database '$DatabaseName'"
            }
        }

        Context 'When testing non-Boolean properties' {
            It 'Should return true when property <PropertyName> matches actual value' -ForEach ($script:masterDatabaseTestCases | Where-Object { -not $_.TestValue }) {
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

            It 'Should return false when property <PropertyName> does not match actual value' -ForEach ($script:masterDatabaseTestCases | Where-Object { -not $_.TestValue }) {
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
                        'DifferentEnumValue'
                    }
                }
                else
                {
                    if ($actualValue -eq $null)
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

                if ($testValue -eq $actualValue)
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

    Context 'When testing all database properties with model database' {
        It 'Should return true when property <PropertyName> matches expected value' -ForEach $script:modelDatabaseTestCases {
            $databaseObject = $script:serverObject.Databases[$DatabaseName]
            $actualValue = $databaseObject.$PropertyName

            $testParameters = @{
                ServerObject  = $script:serverObject
                Name          = $DatabaseName
                $PropertyName = $TestValue
                ErrorAction   = 'Stop'
            }

            $result = Test-SqlDscDatabaseProperty @testParameters

            # All model database test cases have TestValue for Boolean properties
            $expectedResult = ($actualValue -eq [System.Convert]::ToBoolean($TestValue))

            $result | Should -Be $expectedResult -Because "Property '$PropertyName' should return $expectedResult when testing value '$TestValue' against actual value '$actualValue' for database '$DatabaseName'"
        }

        It 'Should return false when property <PropertyName> does not match expected value' -ForEach $script:modelDatabaseTestCases {
            $databaseObject = $script:serverObject.Databases[$DatabaseName]
            $actualValue = $databaseObject.$PropertyName

            $testValue = '0'

            $testParameters = @{
                ServerObject  = $script:serverObject
                Name          = $DatabaseName
                $PropertyName = $testValue
                ErrorAction   = 'Stop'
            }

            $result = Test-SqlDscDatabaseProperty @testParameters

            # All model database test cases are Boolean properties with TestValue
            $expectedResult = ($actualValue -eq [System.Convert]::ToBoolean($testValue))

            $result | Should -Be $expectedResult -Because "Property '$PropertyName' should return $expectedResult when testing value '$testValue' against actual value '$actualValue' for database '$DatabaseName'"
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
            $wrongRecoveryModel = if ($masterDb.RecoveryModel.ToString() -eq 'Simple')
            {
                'Full'
            }
            else
            {
                'Simple'
            }

            $result = Test-SqlDscDatabaseProperty -ServerObject $script:serverObject -Name 'master' `
                -Collation $actualCollation `
                -RecoveryModel $wrongRecoveryModel `
                -Owner $actualOwner `
                -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }
}
