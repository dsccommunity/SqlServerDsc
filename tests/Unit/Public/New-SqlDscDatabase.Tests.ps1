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
            { New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDB' -CompatibilityLevel 'Version80' -Force } |
                Should -Throw -ExpectedMessage '*not a valid compatibility level*'
        }

        It 'Should throw error when Collation is invalid' {
            { New-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDB' -Collation 'InvalidCollation' -Force } |
                Should -Throw -ExpectedMessage '*not a valid collation*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [[-Collation] <String>] [[-CompatibilityLevel] <String>] [[-RecoveryModel] <String>] [[-OwnerName] <String>] [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
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
    }
}
