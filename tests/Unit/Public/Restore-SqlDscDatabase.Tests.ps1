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

Describe 'Restore-SqlDscDatabase' -Tag 'Public' {
    Context 'When restoring a database that already exists without ReplaceDatabase' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockDatabaseObject
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should throw error when database already exists' {
            $expectedMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Restore_SqlDscDatabase_DatabaseExists -f 'TestDatabase'
            }

            { Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -BackupFile 'C:\Backups\Test.bak' -Force } |
                Should -Throw -ExpectedMessage ('*{0}*' -f $expectedMessage) -ErrorId 'RSDD0001,Restore-SqlDscDatabase'
        }
    }

    Context 'When using NoRecovery and Standby together' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{} | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should throw error when NoRecovery and Standby are both specified' {
            $expectedMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Restore_SqlDscDatabase_StandbyConflict
            }

            { Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -BackupFile 'C:\Backups\Test.bak' -NoRecovery -Standby 'C:\Standby\undo.ldf' -Force } |
                Should -Throw -ExpectedMessage ('*{0}*' -f $expectedMessage) -ErrorId 'RSDD0006,Restore-SqlDscDatabase'
        }
    }

    Context 'When performing successful restores' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{} | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should perform full restore successfully' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform differential restore successfully' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase_Diff.bak' -RestoreType 'Differential' -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform log restore successfully' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.trn' -RestoreType 'Log' -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform files restore successfully' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -RestoreType 'Files' -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with NoRecovery option' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -NoRecovery -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with Standby option' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -Standby 'C:\Standby\undo.ldf' -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with ReplaceDatabase option' {
            # Add existing database for this test
            $mockServerWithDb = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerWithDb | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $existingDb = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $existingDb | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'ExistingDatabase' -Force
            $mockServerWithDb | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'ExistingDatabase' = $existingDb
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force

            $result = Restore-SqlDscDatabase -ServerObject $mockServerWithDb -Name 'ExistingDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -ReplaceDatabase -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with Checksum option' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -Checksum -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with RestrictedUser option' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -RestrictedUser -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with KeepReplication option' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -KeepReplication -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with FileNumber option' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -FileNumber 2 -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with point-in-time recovery' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.trn' -RestoreType 'Log' -ToPointInTime (Get-Date '2024-01-15T14:30:00') -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with StopAtMarkName option' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.trn' -RestoreType 'Log' -StopAtMarkName 'MyMark' -Force

            $result | Should -BeNullOrEmpty
        }

        It 'Should perform restore with performance options' {
            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -BlockSize 65536 -BufferCount 10 -MaxTransferSize 4194304 -Force

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using RelocateFile parameter' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{} | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should perform restore with RelocateFile objects' {
            $relocateFiles = @(
                [Microsoft.SqlServer.Management.Smo.RelocateFile]::new('MyDatabase', 'D:\SQLData\MyDatabase.mdf')
                [Microsoft.SqlServer.Management.Smo.RelocateFile]::new('MyDatabase_log', 'L:\SQLLogs\MyDatabase_log.ldf')
            )

            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'NewDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -RelocateFile $relocateFiles -Force

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When restoring using ServerObject and Name with Refresh' {
        BeforeAll {
            $script:refreshCalled = $false

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{} | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    $script:refreshCalled = $true
                } -PassThru -Force
            } -Force
        }

        It 'Should call Refresh when -Refresh parameter is specified' {
            $script:refreshCalled = $false

            $result = Restore-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -BackupFile 'C:\Backups\TestDatabase.bak' -Refresh -Force

            $result | Should -BeNullOrEmpty
            $script:refreshCalled | Should -BeTrue
        }
    }

    Context 'When using DatabaseObject parameter set' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'ExistingDatabase' = $mockDatabaseObject
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'ExistingDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force
        }

        It 'Should perform restore using database object with ReplaceDatabase' {
            $result = Restore-SqlDscDatabase -DatabaseObject $mockDatabaseObject -BackupFile 'C:\Backups\TestDatabase.bak' -ReplaceDatabase -Force

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters       = '-ServerObject <Server> -Name <string> -BackupFile <string> [-RestoreType <string>] [-NoRecovery] [-Standby <string>] [-ReplaceDatabase] [-RelocateFile <RelocateFile[]>] [-Checksum] [-RestrictedUser] [-KeepReplication] [-FileNumber <int>] [-ToPointInTime <datetime>] [-StopAtMarkName <string>] [-StopAtMarkAfterDate <datetime>] [-StopBeforeMarkName <string>] [-StopBeforeMarkAfterDate <datetime>] [-BlockSize <int>] [-BufferCount <int>] [-MaxTransferSize <int>] [-Refresh] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Restore-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set ServerObjectSimpleRelocate' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSimpleRelocate'
                ExpectedParameters       = '-ServerObject <Server> -Name <string> -BackupFile <string> -DataFilePath <string> -LogFilePath <string> [-RestoreType <string>] [-NoRecovery] [-Standby <string>] [-ReplaceDatabase] [-Checksum] [-RestrictedUser] [-KeepReplication] [-FileNumber <int>] [-ToPointInTime <datetime>] [-StopAtMarkName <string>] [-StopAtMarkAfterDate <datetime>] [-StopBeforeMarkName <string>] [-StopBeforeMarkAfterDate <datetime>] [-BlockSize <int>] [-BufferCount <int>] [-MaxTransferSize <int>] [-Refresh] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Restore-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set DatabaseObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'DatabaseObject'
                ExpectedParameters       = '-DatabaseObject <Database> -BackupFile <string> [-RestoreType <string>] [-NoRecovery] [-Standby <string>] [-ReplaceDatabase] [-RelocateFile <RelocateFile[]>] [-Checksum] [-RestrictedUser] [-KeepReplication] [-FileNumber <int>] [-ToPointInTime <datetime>] [-StopAtMarkName <string>] [-StopAtMarkAfterDate <datetime>] [-StopBeforeMarkName <string>] [-StopBeforeMarkAfterDate <datetime>] [-BlockSize <int>] [-BufferCount <int>] [-MaxTransferSize <int>] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Restore-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set DatabaseObjectSimpleRelocate' -ForEach @(
            @{
                ExpectedParameterSetName = 'DatabaseObjectSimpleRelocate'
                ExpectedParameters       = '-DatabaseObject <Database> -BackupFile <string> -DataFilePath <string> -LogFilePath <string> [-RestoreType <string>] [-NoRecovery] [-Standby <string>] [-ReplaceDatabase] [-Checksum] [-RestrictedUser] [-KeepReplication] [-FileNumber <int>] [-ToPointInTime <datetime>] [-StopAtMarkName <string>] [-StopAtMarkAfterDate <datetime>] [-StopBeforeMarkName <string>] [-StopBeforeMarkAfterDate <datetime>] [-BlockSize <int>] [-BufferCount <int>] [-MaxTransferSize <int>] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Restore-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have default parameter set as ServerObject' {
            $result = Get-Command -Name 'Restore-SqlDscDatabase'
            $result.DefaultParameterSet | Should -Be 'ServerObject'
        }

        It 'Should have RestoreType parameter with valid values' {
            $result = (Get-Command -Name 'Restore-SqlDscDatabase').Parameters['RestoreType']
            $result.Attributes.ValidValues | Should -Contain 'Full'
            $result.Attributes.ValidValues | Should -Contain 'Differential'
            $result.Attributes.ValidValues | Should -Contain 'Log'
            $result.Attributes.ValidValues | Should -Contain 'Files'
        }

        It 'Should have BlockSize parameter with valid values' {
            $result = (Get-Command -Name 'Restore-SqlDscDatabase').Parameters['BlockSize']
            $result.Attributes.ValidValues | Should -Contain 512
            $result.Attributes.ValidValues | Should -Contain 1024
            $result.Attributes.ValidValues | Should -Contain 65536
        }
    }
}
