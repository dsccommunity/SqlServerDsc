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

Describe 'New-SqlDscDatabaseSnapshot' -Tag 'Public' {
    Context 'When creating a database snapshot using ServerObject parameter set' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'EngineEdition' -Value 'Enterprise' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'Edition' -Value 'Enterprise Edition' -Force
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

            Mock -CommandName 'New-SqlDscDatabase' -MockWith {
                $mockSnapshotDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockSnapshotDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $Name -Force
                $mockSnapshotDatabase | Add-Member -MemberType 'NoteProperty' -Name 'DatabaseSnapshotBaseName' -Value $DatabaseSnapshotBaseName -Force
                return $mockSnapshotDatabase
            }
        }

        It 'Should create a database snapshot successfully with minimal parameters' {
            $result = New-SqlDscDatabaseSnapshot -ServerObject $mockServerObject -Name 'TestSnapshot' -DatabaseName 'SourceDatabase' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestSnapshot'
            $result.DatabaseSnapshotBaseName | Should -Be 'SourceDatabase'
            Should -Invoke -CommandName 'New-SqlDscDatabase' -Exactly -Times 1
        }

        It 'Should pass the correct parameters to New-SqlDscDatabase' {
            $result = New-SqlDscDatabaseSnapshot -ServerObject $mockServerObject -Name 'MySnapshot' -DatabaseName 'SourceDatabase' -Force

            Should -Invoke -CommandName 'New-SqlDscDatabase' -ParameterFilter {
                $ServerObject.InstanceName -eq 'TestInstance' -and
                $Name -eq 'MySnapshot' -and
                $DatabaseSnapshotBaseName -eq 'SourceDatabase' -and
                $Force -eq $true
            } -Exactly -Times 1
        }

        It 'Should pass Refresh parameter when specified' {
            $result = New-SqlDscDatabaseSnapshot -ServerObject $mockServerObject -Name 'TestSnapshot' -DatabaseName 'SourceDatabase' -Refresh -Force

            Should -Invoke -CommandName 'New-SqlDscDatabase' -ParameterFilter {
                $Refresh -eq $true
            } -Exactly -Times 1
        }

        It 'Should pass FileGroup parameter when specified' {
            # Create a mock DatabaseFileGroupSpec using InModuleScope to access internal classes
            $mockFileGroupSpec = InModuleScope -ScriptBlock {
                $mockDataFileSpec = [DatabaseFileSpec]@{
                    Name = 'TestData'
                    FileName = 'C:\Snapshots\TestData.ss'
                }

                [DatabaseFileGroupSpec]@{
                    Name = 'PRIMARY'
                    Files = @($mockDataFileSpec)
                }
            }

            $result = New-SqlDscDatabaseSnapshot -ServerObject $mockServerObject -Name 'TestSnapshot' -DatabaseName 'SourceDatabase' -FileGroup @($mockFileGroupSpec) -Force

            Should -Invoke -CommandName 'New-SqlDscDatabase' -ParameterFilter {
                $FileGroup -and $FileGroup.Count -eq 1 -and $FileGroup[0].Name -eq 'PRIMARY'
            } -Exactly -Times 1
        }
    }

    Context 'When creating a database snapshot using DatabaseObject parameter set' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'EngineEdition' -Value 'Enterprise' -Force
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'Edition' -Value 'Enterprise Edition' -Force

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force

            Mock -CommandName 'New-SqlDscDatabase' -MockWith {
                $mockSnapshotDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockSnapshotDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $Name -Force
                $mockSnapshotDatabase | Add-Member -MemberType 'NoteProperty' -Name 'DatabaseSnapshotBaseName' -Value $DatabaseSnapshotBaseName -Force
                return $mockSnapshotDatabase
            }
        }

        It 'Should create a database snapshot from DatabaseObject successfully' {
            $result = New-SqlDscDatabaseSnapshot -DatabaseObject $mockDatabaseObject -Name 'TestSnapshot' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestSnapshot'
            $result.DatabaseSnapshotBaseName | Should -Be 'MyDatabase'
            Should -Invoke -CommandName 'New-SqlDscDatabase' -Exactly -Times 1
        }

        It 'Should pass the correct parameters to New-SqlDscDatabase from DatabaseObject' {
            $result = New-SqlDscDatabaseSnapshot -DatabaseObject $mockDatabaseObject -Name 'MySnapshot' -Force

            Should -Invoke -CommandName 'New-SqlDscDatabase' -ParameterFilter {
                $ServerObject.InstanceName -eq 'TestInstance' -and
                $Name -eq 'MySnapshot' -and
                $DatabaseSnapshotBaseName -eq 'MyDatabase' -and
                $Force -eq $true
            } -Exactly -Times 1
        }
    }

    Context 'When SQL Server edition does not support snapshots' {
        BeforeAll {
            $mockServerObjectStandard = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectStandard | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectStandard | Add-Member -MemberType 'NoteProperty' -Name 'EngineEdition' -Value 'Standard' -Force
            $mockServerObjectStandard | Add-Member -MemberType 'NoteProperty' -Name 'Edition' -Value 'Standard Edition' -Force

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObjectStandard -Force

            Mock -CommandName 'New-SqlDscDatabase'
        }

        It 'Should throw error when SQL Server edition does not support snapshots' {
            $errorRecord = { New-SqlDscDatabaseSnapshot -ServerObject $mockServerObjectStandard -Name 'TestSnapshot' -DatabaseName 'MyDatabase' -Force } |
                Should -Throw -ExpectedMessage '*not supported*' -PassThru

            $errorRecord.Exception.Message | Should -BeLike '*not supported*'
            $errorRecord.FullyQualifiedErrorId | Should -Be 'NSDS0001,New-SqlDscDatabaseSnapshot'
            $errorRecord.CategoryInfo.Category | Should -Be 'InvalidOperation'
        }

        It 'Should throw error when using DatabaseObject with unsupported edition' {
            { New-SqlDscDatabaseSnapshot -DatabaseObject $mockDatabaseObject -Name 'TestSnapshot' -Force } |
                Should -Throw -ExpectedMessage '*not supported*'
        }

        It 'Should not call New-SqlDscDatabase when edition is not supported' {
            { New-SqlDscDatabaseSnapshot -ServerObject $mockServerObjectStandard -Name 'TestSnapshot' -DatabaseName 'MyDatabase' -Force } |
                Should -Throw

            Should -Invoke -CommandName 'New-SqlDscDatabase' -Exactly -Times 0
        }
    }

    Context 'When SQL Server edition is Developer' {
        BeforeAll {
            $mockServerObjectDeveloper = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectDeveloper | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectDeveloper | Add-Member -MemberType 'NoteProperty' -Name 'EngineEdition' -Value 'Standard' -Force
            $mockServerObjectDeveloper | Add-Member -MemberType 'NoteProperty' -Name 'Edition' -Value 'Developer Edition' -Force

            Mock -CommandName 'New-SqlDscDatabase' -MockWith {
                $mockSnapshotDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockSnapshotDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $Name -Force
                $mockSnapshotDatabase | Add-Member -MemberType 'NoteProperty' -Name 'DatabaseSnapshotBaseName' -Value $DatabaseSnapshotBaseName -Force
                return $mockSnapshotDatabase
            }
        }

        It 'Should create a database snapshot on Developer edition' {
            $result = New-SqlDscDatabaseSnapshot -ServerObject $mockServerObjectDeveloper -Name 'TestSnapshot' -DatabaseName 'MyDatabase' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestSnapshot'
            Should -Invoke -CommandName 'New-SqlDscDatabase' -Exactly -Times 1
        }
    }

    Context 'When SQL Server edition is Evaluation' {
        BeforeAll {
            $mockServerObjectEvaluation = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectEvaluation | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectEvaluation | Add-Member -MemberType 'NoteProperty' -Name 'EngineEdition' -Value 'Standard' -Force
            $mockServerObjectEvaluation | Add-Member -MemberType 'NoteProperty' -Name 'Edition' -Value 'Evaluation Edition' -Force

            Mock -CommandName 'New-SqlDscDatabase' -MockWith {
                $mockSnapshotDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockSnapshotDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $Name -Force
                $mockSnapshotDatabase | Add-Member -MemberType 'NoteProperty' -Name 'DatabaseSnapshotBaseName' -Value $DatabaseSnapshotBaseName -Force
                return $mockSnapshotDatabase
            }
        }

        It 'Should create a database snapshot on Evaluation edition' {
            $result = New-SqlDscDatabaseSnapshot -ServerObject $mockServerObjectEvaluation -Name 'TestSnapshot' -DatabaseName 'MyDatabase' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestSnapshot'
            Should -Invoke -CommandName 'New-SqlDscDatabase' -Exactly -Times 1
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '-ServerObject <Server> -Name <string> -DatabaseName <string> [-FileGroup <DatabaseFileGroupSpec[]>] [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SqlDscDatabaseSnapshot').ParameterSets |
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
                ExpectedParameters = '-DatabaseObject <Database> -Name <string> [-FileGroup <DatabaseFileGroupSpec[]>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SqlDscDatabaseSnapshot').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscDatabaseSnapshot').Parameters['ServerObject']
            $serverObjectSetAttribute = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'ServerObject' }
            $serverObjectSetAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseObject as a mandatory parameter in DatabaseObject parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscDatabaseSnapshot').Parameters['DatabaseObject']
            $databaseObjectSetAttribute = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'DatabaseObject' }
            $databaseObjectSetAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscDatabaseSnapshot').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseName as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscDatabaseSnapshot').Parameters['DatabaseName']
            $serverObjectSetAttribute = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'ServerObject' }
            $serverObjectSetAttribute.Mandatory | Should -BeTrue
        }
    }
}
