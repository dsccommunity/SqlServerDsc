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
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Set-SqlDscDatabaseProperty' -Tag 'Public' {
    Context 'When modifying a database using ServerObject and Name' {
        BeforeAll {
            $script:mockAlterCalled = $false

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version150' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'AutoClose' -Value $false -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'AutoShrink' -Value $false -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'PageVerify' -Value 'Checksum' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
                $mockParent | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                    return @(
                        @{ Name = 'SQL_Latin1_General_CP1_CI_AS' },
                        @{ Name = 'SQL_Latin1_General_Pref_CP850_CI_AS' }
                    )
                } -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                $script:mockAlterCalled = $true
            } -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockDatabaseObject
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
            $mockServerObject | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                return @(
                    @{ Name = 'SQL_Latin1_General_CP1_CI_AS' },
                    @{ Name = 'SQL_Latin1_General_Pref_CP850_CI_AS' }
                )
            } -Force
        }

        It 'Should modify database properties successfully' {
            $script:mockAlterCalled = $false
            $mockDatabaseObject.RecoveryModel = 'Full' # Reset to initial value

            $null = Set-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -RecoveryModel 'Simple' -Force

            $mockDatabaseObject.RecoveryModel | Should -Be 'Simple'
            $script:mockAlterCalled | Should -BeTrue -Because 'Alter() should have been called'
        }

        It 'Should modify multiple properties at once' {
            $script:mockAlterCalled = $false
            $mockDatabaseObject.AutoClose = $false # Reset to initial value
            $mockDatabaseObject.AutoShrink = $false # Reset to initial value
            $mockDatabaseObject.PageVerify = 'Checksum' # Reset to initial value

            $null = Set-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -AutoClose $true -AutoShrink $true -PageVerify 'None' -Force

            $mockDatabaseObject.AutoClose | Should -BeTrue
            $mockDatabaseObject.AutoShrink | Should -BeTrue
            $mockDatabaseObject.PageVerify | Should -Be 'None'
            $script:mockAlterCalled | Should -BeTrue -Because 'Alter() should have been called'
        }

        It 'Should return database object when PassThru is specified' {
            $script:mockAlterCalled = $false
            $mockDatabaseObject.RecoveryModel = 'Full' # Reset to initial value

            $result = Set-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -RecoveryModel 'Simple' -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
            $mockDatabaseObject.RecoveryModel | Should -Be 'Simple'
            $script:mockAlterCalled | Should -BeTrue -Because 'Alter() should have been called'
        }

        It 'Should throw error when database does not exist' {
            $script:mockAlterCalled = $false

            { Set-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'NonExistentDatabase' -RecoveryModel 'Simple' -Force -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*not found*' -ErrorId 'GSDD0001,Get-SqlDscDatabase'

            $script:mockAlterCalled | Should -BeFalse -Because 'Alter() should not have been called when database does not exist'
        }
    }

    Context 'When modifying a database using DatabaseObject' {
        BeforeAll {
            $script:mockAlterCalled = $false

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version150' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
                $mockParent | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                    return @(
                        @{ Name = 'SQL_Latin1_General_CP1_CI_AS' },
                        @{ Name = 'SQL_Latin1_General_Pref_CP850_CI_AS' }
                    )
                } -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                $script:mockAlterCalled = $true
            } -Force
        }

        It 'Should modify database using database object' {
            $script:mockAlterCalled = $false

            $null = Set-SqlDscDatabaseProperty -DatabaseObject $mockDatabaseObject -RecoveryModel 'Simple' -Force

            $mockDatabaseObject.RecoveryModel | Should -Be 'Simple'
            $script:mockAlterCalled | Should -BeTrue -Because 'Alter() should have been called'
        }
    }

    Context 'When testing CompatibilityLevel parameter validation' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                return @{
                    'TestDatabase' = $mockDatabaseObject
                }
            } -Force
            $mockServerObject | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                return @(
                    @{ Name = 'SQL_Latin1_General_CP1_CI_AS' }
                )
            } -Force
        }

        It 'Should throw error when CompatibilityLevel is invalid for SQL Server version' {
            { Set-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -CompatibilityLevel 'Version80' -Force } |
                Should -Throw -ExpectedMessage '*not a valid compatibility level*' -ErrorId 'SSDD0002,Set-SqlDscDatabaseProperty'
        }

        It 'Should allow valid CompatibilityLevel for SQL Server version' {
            $script:mockAlterCalled = $false

            $mockServerObjectWithValidDb = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectWithValidDb | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockDatabaseObjectWithValidProps = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version140' -Force
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                $script:mockAlterCalled = $true
            } -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockDatabaseObjectWithValidProps
                }
            } -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                return @(
                    @{ Name = 'SQL_Latin1_General_CP1_CI_AS' }
                )
            } -Force

            $null = Set-SqlDscDatabaseProperty -ServerObject $mockServerObjectWithValidDb -Name 'TestDatabase' -CompatibilityLevel 'Version150' -Force

            $mockDatabaseObjectWithValidProps.CompatibilityLevel | Should -Be 'Version150'
            $script:mockAlterCalled | Should -BeTrue -Because 'Alter() should have been called'
        }
    }

    Context 'When testing Collation parameter validation' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    # Mock implementation
                } -Force
                return @{
                    'TestDatabase' = $mockDatabaseObject
                }
            } -Force
            $mockServerObject | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                return @(
                    @{ Name = 'SQL_Latin1_General_CP1_CI_AS' },
                    @{ Name = 'SQL_Latin1_General_Pref_CP850_CI_AS' }
                )
            } -Force
        }

        It 'Should throw error when Collation is invalid' {
            { Set-SqlDscDatabaseProperty -ServerObject $mockServerObject -Name 'TestDatabase' -Collation 'InvalidCollation' -Force } |
                Should -Throw -ExpectedMessage '*not a valid collation*' -ErrorId 'SSDD0003,Set-SqlDscDatabaseProperty'
        }

        It 'Should allow valid Collation' {
            $script:mockAlterCalled = $false

            $mockServerObjectWithValidDb = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectWithValidDb | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockDatabaseObjectWithValidProps = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                $script:mockAlterCalled = $true
            } -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                $databaseCollection = @{
                    'TestDatabase' = $mockDatabaseObjectWithValidProps
                }
                return $databaseCollection | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                return @(
                    @{ Name = 'SQL_Latin1_General_CP1_CI_AS' },
                    @{ Name = 'SQL_Latin1_General_Pref_CP850_CI_AS' }
                )
            } -Force

            $null = Set-SqlDscDatabaseProperty -ServerObject $mockServerObjectWithValidDb -Refresh -Name 'TestDatabase' -Collation 'SQL_Latin1_General_Pref_CP850_CI_AS' -Force

            $mockDatabaseObjectWithValidProps.Collation | Should -Be 'SQL_Latin1_General_Pref_CP850_CI_AS'
            $script:mockAlterCalled | Should -BeTrue -Because 'Alter() should have been called'
        }
    }

    Context 'When property is already set to desired value' {
        BeforeAll {
            $script:mockAlterCalled = $false

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Simple' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'AutoClose' -Value $true -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
                $mockParent | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                    return @(
                        @{ Name = 'SQL_Latin1_General_CP1_CI_AS' }
                    )
                } -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                $script:mockAlterCalled = $true
            } -Force
        }

        It 'Should not call Alter() when property is already set to desired value' {
            $script:mockAlterCalled = $false

            $null = Set-SqlDscDatabaseProperty -DatabaseObject $mockDatabaseObject -RecoveryModel 'Simple' -Force

            $script:mockAlterCalled | Should -BeFalse -Because 'Alter() should not be called when property is already set'
        }

        It 'Should not call Alter() when all properties are already set' {
            $script:mockAlterCalled = $false

            $null = Set-SqlDscDatabaseProperty -DatabaseObject $mockDatabaseObject -RecoveryModel 'Simple' -AutoClose $true -Force

            $script:mockAlterCalled | Should -BeFalse -Because 'Alter() should not be called when all properties are already set'
        }
    }

    Context 'When database modification fails' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
                $mockParent | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                    return @(
                        @{ Name = 'SQL_Latin1_General_CP1_CI_AS' }
                    )
                } -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                throw 'Simulated Alter() failure'
            } -Force
        }

        It 'Should throw terminating error when Alter() fails' {
            { Set-SqlDscDatabaseProperty -DatabaseObject $mockDatabaseObject -RecoveryModel 'Simple' -Force } |
                Should -Throw -ExpectedMessage '*Failed to set properties*' -ErrorId 'SSDD0004,Set-SqlDscDatabaseProperty'
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObjectSet' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSet'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Refresh] [-AcceleratedRecoveryEnabled <bool>] [-AnsiNullDefault <bool>] [-AnsiNullsEnabled <bool>] [-AnsiPaddingEnabled <bool>] [-AnsiWarningsEnabled <bool>] [-ArithmeticAbortEnabled <bool>] [-AutoClose <bool>] [-AutoCreateIncrementalStatisticsEnabled <bool>] [-AutoCreateStatisticsEnabled <bool>] [-AutoShrink <bool>] [-AutoUpdateStatisticsAsync <bool>] [-AutoUpdateStatisticsEnabled <bool>] [-BrokerEnabled <bool>] [-ChangeTrackingAutoCleanUp <bool>] [-ChangeTrackingEnabled <bool>] [-CloseCursorsOnCommitEnabled <bool>] [-ConcatenateNullYieldsNull <bool>] [-DatabaseOwnershipChaining <bool>] [-DataRetentionEnabled <bool>] [-DateCorrelationOptimization <bool>] [-DelayedDurability <bool>] [-EncryptionEnabled <bool>] [-HonorBrokerPriority <bool>] [-IsFullTextEnabled <bool>] [-IsLedger <bool>] [-IsParameterizationForced <bool>] [-IsReadCommittedSnapshotOn <bool>] [-IsSqlDw <bool>] [-IsVarDecimalStorageFormatEnabled <bool>] [-LegacyCardinalityEstimation <bool>] [-LegacyCardinalityEstimationForSecondary <bool>] [-LocalCursorsDefault <bool>] [-NestedTriggersEnabled <bool>] [-NumericRoundAbortEnabled <bool>] [-ParameterSniffing <bool>] [-ParameterSniffingForSecondary <bool>] [-QueryOptimizerHotfixes <bool>] [-QueryOptimizerHotfixesForSecondary <bool>] [-QuotedIdentifiersEnabled <bool>] [-ReadOnly <bool>] [-RecursiveTriggersEnabled <bool>] [-RemoteDataArchiveEnabled <bool>] [-RemoteDataArchiveUseFederatedServiceAccount <bool>] [-TemporalHistoryRetentionEnabled <bool>] [-TransformNoiseWords <bool>] [-Trustworthy <bool>] [-ChangeTrackingRetentionPeriod <int>] [-DefaultFullTextLanguage <int>] [-DefaultLanguage <int>] [-MaxDop <int>] [-MaxDopForSecondary <int>] [-MirroringRedoQueueMaxSize <int>] [-MirroringTimeout <int>] [-TargetRecoveryTime <int>] [-TwoDigitYearCutoff <int>] [-MaxSizeInBytes <double>] [-AzureServiceObjective <string>] [-Collation <string>] [-DatabaseSnapshotBaseName <string>] [-DefaultSchema <string>] [-FilestreamDirectoryName <string>] [-MirroringPartner <string>] [-MirroringPartnerInstance <string>] [-MirroringWitness <string>] [-PersistentVersionStoreFileGroup <string>] [-PrimaryFilePath <string>] [-RemoteDataArchiveCredential <string>] [-RemoteDataArchiveEndpoint <string>] [-RemoteDataArchiveLinkedServer <string>] [-RemoteDatabaseName <string>] [-AzureEdition <string>] [-ChangeTrackingRetentionPeriodUnits <RetentionPeriodUnits>] [-CompatibilityLevel <CompatibilityLevel>] [-ContainmentType <ContainmentType>] [-FilestreamNonTransactedAccess <FilestreamNonTransactedAccessType>] [-MirroringSafetyLevel <MirroringSafetyLevel>] [-PageVerify <PageVerify>] [-RecoveryModel <RecoveryModel>] [-UserAccess <DatabaseUserAccess>] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabaseProperty').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set DatabaseObjectSet' -ForEach @(
            @{
                ExpectedParameterSetName = 'DatabaseObjectSet'
                ExpectedParameters = '-DatabaseObject <Database> [-AcceleratedRecoveryEnabled <bool>] [-AnsiNullDefault <bool>] [-AnsiNullsEnabled <bool>] [-AnsiPaddingEnabled <bool>] [-AnsiWarningsEnabled <bool>] [-ArithmeticAbortEnabled <bool>] [-AutoClose <bool>] [-AutoCreateIncrementalStatisticsEnabled <bool>] [-AutoCreateStatisticsEnabled <bool>] [-AutoShrink <bool>] [-AutoUpdateStatisticsAsync <bool>] [-AutoUpdateStatisticsEnabled <bool>] [-BrokerEnabled <bool>] [-ChangeTrackingAutoCleanUp <bool>] [-ChangeTrackingEnabled <bool>] [-CloseCursorsOnCommitEnabled <bool>] [-ConcatenateNullYieldsNull <bool>] [-DatabaseOwnershipChaining <bool>] [-DataRetentionEnabled <bool>] [-DateCorrelationOptimization <bool>] [-DelayedDurability <bool>] [-EncryptionEnabled <bool>] [-HonorBrokerPriority <bool>] [-IsFullTextEnabled <bool>] [-IsLedger <bool>] [-IsParameterizationForced <bool>] [-IsReadCommittedSnapshotOn <bool>] [-IsSqlDw <bool>] [-IsVarDecimalStorageFormatEnabled <bool>] [-LegacyCardinalityEstimation <bool>] [-LegacyCardinalityEstimationForSecondary <bool>] [-LocalCursorsDefault <bool>] [-NestedTriggersEnabled <bool>] [-NumericRoundAbortEnabled <bool>] [-ParameterSniffing <bool>] [-ParameterSniffingForSecondary <bool>] [-QueryOptimizerHotfixes <bool>] [-QueryOptimizerHotfixesForSecondary <bool>] [-QuotedIdentifiersEnabled <bool>] [-ReadOnly <bool>] [-RecursiveTriggersEnabled <bool>] [-RemoteDataArchiveEnabled <bool>] [-RemoteDataArchiveUseFederatedServiceAccount <bool>] [-TemporalHistoryRetentionEnabled <bool>] [-TransformNoiseWords <bool>] [-Trustworthy <bool>] [-ChangeTrackingRetentionPeriod <int>] [-DefaultFullTextLanguage <int>] [-DefaultLanguage <int>] [-MaxDop <int>] [-MaxDopForSecondary <int>] [-MirroringRedoQueueMaxSize <int>] [-MirroringTimeout <int>] [-TargetRecoveryTime <int>] [-TwoDigitYearCutoff <int>] [-MaxSizeInBytes <double>] [-AzureServiceObjective <string>] [-Collation <string>] [-DatabaseSnapshotBaseName <string>] [-DefaultSchema <string>] [-FilestreamDirectoryName <string>] [-MirroringPartner <string>] [-MirroringPartnerInstance <string>] [-MirroringWitness <string>] [-PersistentVersionStoreFileGroup <string>] [-PrimaryFilePath <string>] [-RemoteDataArchiveCredential <string>] [-RemoteDataArchiveEndpoint <string>] [-RemoteDataArchiveLinkedServer <string>] [-RemoteDatabaseName <string>] [-AzureEdition <string>] [-ChangeTrackingRetentionPeriodUnits <RetentionPeriodUnits>] [-CompatibilityLevel <CompatibilityLevel>] [-ContainmentType <ContainmentType>] [-FilestreamNonTransactedAccess <FilestreamNonTransactedAccessType>] [-MirroringSafetyLevel <MirroringSafetyLevel>] [-PageVerify <PageVerify>] [-RecoveryModel <RecoveryModel>] [-UserAccess <DatabaseUserAccess>] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabaseProperty').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have many settable SMO properties available as parameters' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseProperty'

            # Verify some key properties are available
            $command.Parameters.Keys | Should -Contain 'Collation'
            $command.Parameters.Keys | Should -Contain 'CompatibilityLevel'
            $command.Parameters.Keys | Should -Contain 'RecoveryModel'
            $command.Parameters.Keys | Should -Contain 'AutoClose'
            $command.Parameters.Keys | Should -Contain 'AutoShrink'
            $command.Parameters.Keys | Should -Contain 'PageVerify'
            $command.Parameters.Keys | Should -Contain 'AnsiNullDefault'
            $command.Parameters.Keys | Should -Contain 'TargetRecoveryTime'
        }
    }
}
