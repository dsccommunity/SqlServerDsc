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
        @{ PropertyName = 'AutoClose'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'AutoShrink'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'AnsiNullsEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'AnsiPaddingEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'AnsiWarningsEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'ArithmeticAbortEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'BrokerEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'CaseSensitive'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'CloseCursorsOnCommitEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'ConcatenateNullYieldsNull'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'DatabaseOwnershipChaining'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'DateCorrelationOptimization'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'EncryptionEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'HasDatabaseEncryptionKey'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'HasFileInCloud'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'HasMemoryOptimizedObjects'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsAccessible'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbAccessAdmin'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbBackupOperator'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbDataReader'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbDataWriter'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbDdlAdmin'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbDenyDataReader'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbDenyDataWriter'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbManager'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbOwner'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDbSecurityAdmin'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDatabaseSnapshot'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsDatabaseSnapshotBase'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsFabricDatabase'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsFullTextEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsLedger'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsLoginManager'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsMailHost'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsManagementDataWarehouse'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsMaxSizeApplicable'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsMirroringEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsParameterizationForced'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsReadCommittedSnapshotOn'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsSqlDw'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsSqlDwEdition'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsSystemObject'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsVarDecimalStorageFormatEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'IsVarDecimalStorageFormatSupported'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'LocalCursorsDefault'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'NestedTriggersEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'NumericRoundAbortEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'QuotedIdentifiersEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'ReadOnly'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'RecursiveTriggersEnabled'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'Trustworthy'; DatabaseName = 'master'; TestValue = $true }
        @{ PropertyName = 'WarnOnRename'; DatabaseName = 'master'; TestValue = $true }

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
        @{ PropertyName = 'AutoCreateStatisticsEnabled'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'AutoUpdateStatisticsEnabled'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'AutoUpdateStatisticsAsync'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'AutoCreateIncrementalStatisticsEnabled'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'ParameterSniffing'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'LegacyCardinalityEstimation'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'QueryOptimizerHotfixes'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'AnsiNullDefault'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'ChangeTrackingEnabled'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'ChangeTrackingAutoCleanUp'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'DataRetentionEnabled'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'TemporalHistoryRetentionEnabled'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'AcceleratedRecoveryEnabled'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'DelayedDurability'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'HonorBrokerPriority'; DatabaseName = 'model'; TestValue = $true }
        @{ PropertyName = 'TransformNoiseWords'; DatabaseName = 'model'; TestValue = $true }
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
            It 'Should return expected result when property <PropertyName> is tested with value $true' -ForEach ($script:masterDatabaseTestCases | Where-Object { $_.TestValue }) {
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

            It 'Should return expected result when property <PropertyName> is tested with value $false' -ForEach ($script:masterDatabaseTestCases | Where-Object { $_.TestValue }) {
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
            $expectedResult = ($actualValue -eq $TestValue)

            $result | Should -Be $expectedResult -Because "Property '$PropertyName' should return $expectedResult when testing value '$TestValue' against actual value '$actualValue' for database '$DatabaseName'"
        }

        It 'Should return false when property <PropertyName> does not match expected value' -ForEach $script:modelDatabaseTestCases {
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

            # All model database test cases are Boolean properties with TestValue
            $expectedResult = ($actualValue -eq $testValue)

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
