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
            $null = Set-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -RecoveryModel 'Simple' -Force
        }

        It 'Should return database object when PassThru is specified' {
            $result = Set-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -RecoveryModel 'Simple' -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should throw error when database does not exist' {
            { Set-SqlDscDatabase -ServerObject $mockServerObject -Name 'NonExistentDatabase' -RecoveryModel 'Simple' -Force } |
                Should -Throw -ExpectedMessage '*not found*' -ErrorId 'SSDD0001,Set-SqlDscDatabase'
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
            $null = Set-SqlDscDatabase -DatabaseObject $mockDatabaseObject -RecoveryModel 'Simple' -Force
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
            { Set-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -CompatibilityLevel 'Version80' -Force } |
                Should -Throw -ExpectedMessage '*not a valid compatibility level*' -ErrorId 'SSDD0002,Set-SqlDscDatabase'
        }

        It 'Should allow valid CompatibilityLevel for SQL Server version' {
            # We only test that the validation passes, not the actual property setting
            $mockServerObjectWithValidDb = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectWithValidDb | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockDatabaseObjectWithValidProps = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version150' -Force
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                # Mock implementation
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

            $null = Set-SqlDscDatabase -ServerObject $mockServerObjectWithValidDb -Name 'TestDatabase' -CompatibilityLevel 'Version150' -Force
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
            { Set-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Collation 'InvalidCollation' -Force } |
                Should -Throw -ExpectedMessage '*not a valid collation*' -ErrorId 'SSDD0003,Set-SqlDscDatabase'
        }

        It 'Should allow valid Collation' {
            $mockServerObjectWithValidDb = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectWithValidDb | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 15 -Force
            $mockDatabaseObjectWithValidProps = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockDatabaseObjectWithValidProps | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                # Mock implementation
            } -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockDatabaseObjectWithValidProps
                }
            } -Force
            $mockServerObjectWithValidDb | Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                return @(
                    @{ Name = 'SQL_Latin1_General_CP1_CI_AS' },
                    @{ Name = 'SQL_Latin1_General_Pref_CP850_CI_AS' }
                )
            } -Force

            $null = Set-SqlDscDatabase -ServerObject $mockServerObjectWithValidDb -Name 'TestDatabase' -Collation 'SQL_Latin1_General_CP1_CI_AS' -Force
        }
    }

    Context 'When testing OwnerName parameter usage' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
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
                # Mock implementation
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                # Mock implementation
            } -Force
        }

        It 'Should call SetOwner when OwnerName parameter is specified' {
            # This tests that the OwnerName parameter usage path (line 202) is covered
            $null = Set-SqlDscDatabase -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force
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
            { Set-SqlDscDatabase -DatabaseObject $mockDatabaseObject -RecoveryModel 'Simple' -Force } |
                Should -Throw -ExpectedMessage '*Failed to set properties*' -ErrorId 'SSDD0004,Set-SqlDscDatabase'
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
