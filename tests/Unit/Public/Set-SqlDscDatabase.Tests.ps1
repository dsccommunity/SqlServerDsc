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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe 'Set-SqlDscDatabase' -Tag 'Public' {
    Context 'When modifying a database using ServerObject and Name' {
        BeforeAll {
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
                # Mock implementation
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                # Mock implementation
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
            Mock -CommandName 'Write-Verbose'

            { Set-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -RecoveryModel 'Simple' -Force } | Should -Not -Throw
        }

        It 'Should return database object when PassThru is specified' {
            Mock -CommandName 'Write-Verbose'

            $result = Set-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -RecoveryModel 'Simple' -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should throw error when database does not exist' {
            Mock -CommandName 'Write-Verbose'

            { Set-SqlDscDatabase -ServerObject $mockServerObject -Name 'NonExistentDatabase' -RecoveryModel 'Simple' -Force } |
                Should -Throw -ExpectedMessage '*not found*'
        }
    }

    Context 'When modifying a database using DatabaseObject' {
        BeforeAll {
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
                # Mock implementation
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                # Mock implementation
            } -Force
        }

        It 'Should modify database using database object' {
            Mock -CommandName 'Write-Verbose'

            { Set-SqlDscDatabase -DatabaseObject $mockDatabaseObject -RecoveryModel 'Simple' -Force } | Should -Not -Throw
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Collation <string>] [-CompatibilityLevel <string>] [-RecoveryModel <string>] [-OwnerName <string>] [-Force] [-Refresh] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabase').ParameterSets |
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
                ExpectedParameters = '-DatabaseObject <Database> [-Collation <string>] [-CompatibilityLevel <string>] [-RecoveryModel <string>] [-OwnerName <string>] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }
}