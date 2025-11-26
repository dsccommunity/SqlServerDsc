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

Describe 'New-SqlDscDatabase' -Tag 'Public' {
    Context 'When creating a new database' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{} | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
            $mockServerObject | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                return @(
                    @{ Name = 'SQL_Latin1_General_CP1_CI_AS' },
                    @{ Name = 'SQL_Latin1_General_Pref_CP850_CI_AS' }
                )
            } -Force

            Mock -CommandName 'New-Object' -ParameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database' } -MockWith {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $ArgumentList[1] -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value $null -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value $null -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value $null -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'IsLedger' -Value $false -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    # Mock implementation
                } -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                    param($OwnerName)
                    # Mock implementation
                } -Force
                return $mockDatabaseObject
            }
        }

        It 'Should create a database successfully with minimal parameters' {
            $result = New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
            Should -Invoke -CommandName 'New-Object' -ParameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database' } -Exactly -Times 1
        }

        It 'Should create a database with specified properties' {
            $result = New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase2' -Collation 'SQL_Latin1_General_CP1_CI_AS' -RecoveryModel 'Simple' -CompatibilityLevel 'Version150' -OwnerName 'sa' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase2'
            $result.RecoveryModel | Should -Be 'Simple'
            $result.Collation | Should -Be 'SQL_Latin1_General_CP1_CI_AS'
            $result.CompatibilityLevel | Should -Be 'Version150'
        }

        It 'Should create a ledger database with IsLedger set to true' {
            $result = New-SqlDscDatabase -ServerObject $mockServerObject -Name 'LedgerDatabase' -IsLedger $true -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'LedgerDatabase'
            $result.IsLedger | Should -BeTrue
        }

        It 'Should throw error when database already exists' {
            $mockServerObjectWithExistingDb = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectWithExistingDb | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectWithExistingDb | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'ExistingDatabase' = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                }
            } -Force

            { New-SqlDscDatabase -ServerObject $mockServerObjectWithExistingDb -Name 'ExistingDatabase' -Force } |
                Should -Throw -ExpectedMessage '*already exists*'
        }
    }

    Context 'When testing parameter validation errors' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{}
            } -Force
            $mockServerObject | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                return @(
                    @{ Name = 'SQL_Latin1_General_CP1_CI_AS' },
                    @{ Name = 'SQL_Latin1_General_Pref_CP850_CI_AS' }
                )
            } -Force
        }

        It 'Should throw error when CompatibilityLevel is invalid for SQL Server version' {
            $errorRecord = { New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDB' -CompatibilityLevel 'Version80' -Force } |
                Should -Throw -ExpectedMessage '*not a valid compatibility level*' -PassThru

            $errorRecord.Exception.Message | Should -BeLike '*not a valid compatibility level*'
            $errorRecord.FullyQualifiedErrorId | Should -Be 'NSD0003,New-SqlDscDatabase'
            $errorRecord.CategoryInfo.Category | Should -Be 'InvalidArgument'
            $errorRecord.CategoryInfo.TargetName | Should -Be 'Version80'
        }

        It 'Should throw error when Collation is invalid' {
            $errorRecord = { New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDB' -Collation 'InvalidCollation' -Force } |
                Should -Throw -ExpectedMessage '*not a valid collation*' -PassThru

            $errorRecord.Exception.Message | Should -BeLike '*not a valid collation*'
            $errorRecord.FullyQualifiedErrorId | Should -Be 'NSD0004,New-SqlDscDatabase'
            $errorRecord.CategoryInfo.Category | Should -Be 'InvalidArgument'
            $errorRecord.CategoryInfo.TargetName | Should -Be 'InvalidCollation'
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set Database' -ForEach @(
            @{
                ExpectedParameterSetName = 'Database'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Collation <string>] [-CatalogCollation <CatalogCollationType>] [-CompatibilityLevel <string>] [-RecoveryModel <string>] [-OwnerName <string>] [-IsLedger <bool>] [-FileGroup <DatabaseFileGroupSpec[]>] [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set Snapshot' -ForEach @(
            @{
                ExpectedParameterSetName = 'Snapshot'
                ExpectedParameters = '-ServerObject <Server> -Name <string> -DatabaseSnapshotBaseName <string> [-FileGroup <DatabaseFileGroupSpec[]>] [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscDatabase').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscDatabase').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseSnapshotBaseName as a mandatory parameter in Snapshot parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscDatabase').Parameters['DatabaseSnapshotBaseName']
            $snapshotSetAttribute = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'Snapshot' }
            $snapshotSetAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have IsLedger as a parameter in Database parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscDatabase').Parameters['IsLedger']
            $databaseSetAttribute = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'Database' }
            $databaseSetAttribute | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When creating a database snapshot' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force

            # Mock source database
            $mockSourceDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockSourceDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'SourceDatabase' -Force

            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'SourceDatabase' = $mockSourceDatabase
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force

            Mock -CommandName 'New-Object' -ParameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database' } -MockWith {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $ArgumentList[1] -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DatabaseSnapshotBaseName' -Value $null -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    # Mock implementation
                } -Force
                return $mockDatabaseObject
            }
        }

        It 'Should create a database snapshot successfully' {
            $result = New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestSnapshot' -DatabaseSnapshotBaseName 'SourceDatabase' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestSnapshot'
            $result.DatabaseSnapshotBaseName | Should -Be 'SourceDatabase'
            Should -Invoke -CommandName 'New-Object' -ParameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database' } -Exactly -Times 1
        }

        It 'Should throw error when source database does not exist' {
            $mockServerObjectNoSourceDb = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectNoSourceDb | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectNoSourceDb | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{}
            } -Force

            { New-SqlDscDatabase -ServerObject $mockServerObjectNoSourceDb -Name 'TestSnapshot' -DatabaseSnapshotBaseName 'NonExistentDatabase' -Force } |
                Should -Throw -ExpectedMessage '*does not exist*'
        }
    }

    Context 'When creating a database snapshot with FileGroup' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force

            # Mock source database
            $mockSourceDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockSourceDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'SourceDatabase' -Force

            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'SourceDatabase' = $mockSourceDatabase
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force

            Mock -CommandName 'New-Object' -ParameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database' } -MockWith {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject.Name = $ArgumentList[1]
                $mockDatabaseObject.DatabaseSnapshotBaseName = $null

                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    # Mock implementation
                } -Force
                return $mockDatabaseObject
            }

            # Mock the helper commands used by New-SqlDscDatabase
            Mock -CommandName 'New-SqlDscFileGroup' -ParameterFilter { $null -ne $FileGroupSpec } -MockWith {
                $mockFileGroup = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup'
                $mockFileGroup | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $FileGroupSpec.Name -Force
                return $mockFileGroup
            }

            Mock -CommandName 'Add-SqlDscFileGroup'

            # Mock helper commands used in tests
            Mock -CommandName 'New-SqlDscDataFile' -MockWith {
                return [DatabaseFileSpec]@{
                    Name = $Name
                    FileName = $FileName
                }
            }

            Mock -CommandName 'New-SqlDscFileGroup' -ParameterFilter { $null -eq $FileGroupSpec } -MockWith {
                return [DatabaseFileGroupSpec]@{
                    Name = $Name
                    Files = $Files
                }
            }
        }

        It 'Should create a database snapshot with FileGroup spec successfully' {
            # Create file spec using New-SqlDscDataFile with -AsSpec
            $fileSpec = New-SqlDscDataFile -Name 'TestSnapshot_Data' -FileName 'C:\Snapshots\TestSnapshot_Data.ss' -AsSpec

            # Create filegroup spec using New-SqlDscFileGroup with -AsSpec
            $fileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($fileSpec) -AsSpec

            $result = New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestSnapshot' -DatabaseSnapshotBaseName 'SourceDatabase' -FileGroup @($fileGroupSpec) -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestSnapshot'
            $result.DatabaseSnapshotBaseName | Should -Be 'SourceDatabase'
            Should -Invoke -CommandName 'New-SqlDscFileGroup' -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName 'Add-SqlDscFileGroup' -Exactly -Times 1 -Scope It
        }
    }

    Context 'When creating a database with custom file groups using spec objects' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{} | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force

            Mock -CommandName 'New-Object' -ParameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database' } -MockWith {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $ArgumentList[1] -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value $null -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    # Mock implementation
                } -Force
                return $mockDatabaseObject
            }

            Mock -CommandName 'New-SqlDscFileGroup' -ParameterFilter { $null -ne $FileGroupSpec } -MockWith {
                $mockFileGroup = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup'
                $mockFileGroup | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $FileGroupSpec.Name -Force
                return $mockFileGroup
            }

            Mock -CommandName 'Add-SqlDscFileGroup'

            # Mock helper commands used in tests
            Mock -CommandName 'New-SqlDscDataFile' -MockWith {
                return [DatabaseFileSpec]@{
                    Name = $Name
                    FileName = $FileName
                    Size = $Size
                    Growth = $Growth
                    GrowthType = $GrowthType
                    IsPrimaryFile = $IsPrimaryFile.IsPresent
                }
            }

            Mock -CommandName 'New-SqlDscFileGroup' -ParameterFilter { $null -eq $FileGroupSpec } -MockWith {
                return [DatabaseFileGroupSpec]@{
                    Name = $Name
                    Files = $Files
                    IsDefault = $IsDefault.IsPresent
                }
            }
        }

        It 'Should create a database with custom PRIMARY filegroup using -AsSpec parameters' {
            # Create file spec with parameters using -AsSpec
            $primaryFile = New-SqlDscDataFile -Name 'TestDB_Primary' -FileName 'D:\SQLData\TestDB.mdf' -Size 102400 -Growth 10240 -GrowthType 'KB' -IsPrimaryFile -AsSpec

            # Create filegroup spec with parameters using -AsSpec
            $primaryFileGroup = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($primaryFile) -IsDefault -AsSpec

            $result = New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDB' -FileGroup @($primaryFileGroup) -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDB'
            Should -Invoke -CommandName 'New-SqlDscFileGroup' -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName 'Add-SqlDscFileGroup' -Exactly -Times 1 -Scope It
        }

        It 'Should create a database with multiple filegroups using -AsSpec parameters' {
            # Create PRIMARY filegroup
            $primaryFile = New-SqlDscDataFile -Name 'TestDB_Primary' -FileName 'D:\SQLData\TestDB.mdf' -Size 102400 -IsPrimaryFile -AsSpec
            $primaryFileGroup = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($primaryFile) -IsDefault -AsSpec

            # Create secondary filegroup
            $secondaryFile = New-SqlDscDataFile -Name 'TestDB_Secondary' -FileName 'E:\SQLData\TestDB.ndf' -Size 204800 -AsSpec
            $secondaryFileGroup = New-SqlDscFileGroup -Name 'SECONDARY' -Files @($secondaryFile) -AsSpec

            $result = New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDB' -FileGroup @($primaryFileGroup, $secondaryFileGroup) -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDB'
            Should -Invoke -CommandName 'New-SqlDscFileGroup' -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName 'Add-SqlDscFileGroup' -Exactly -Times 2 -Scope It
        }
    }
}
