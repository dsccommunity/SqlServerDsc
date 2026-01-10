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
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Remove-SqlDscDatabase' -Tag 'Public' {
    Context 'When removing a database using ServerObject and Name' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                # Mock implementation
            } -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockDatabaseObject
                    'master' = $mockDatabaseObject
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should remove database successfully' {
            $null = Remove-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force
        }

        It 'Should throw error when database does not exist' {
            $expectedMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Remove_SqlDscDatabase_NotFound -f 'NonExistentDatabase'
            }

            { Remove-SqlDscDatabase -ServerObject $mockServerObject -Name 'NonExistentDatabase' -Force } |
                Should -Throw -ExpectedMessage ('*{0}*' -f $expectedMessage) -ErrorId 'RSDD0002,Remove-SqlDscDatabase'
        }

        It 'Should throw error when trying to remove system database' {
            $expectedMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Database_CannotRemoveSystem -f 'master'
            }

            { Remove-SqlDscDatabase -ServerObject $mockServerObject -Name 'master' -Force } |
                Should -Throw -ExpectedMessage ('*{0}*' -f $expectedMessage) -ErrorId 'RSDD0001,Remove-SqlDscDatabase'
        }
    }

    Context 'When removing a database using DatabaseObject' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                # Mock implementation
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'UserAccess' -Value 'Multiple' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                # Mock implementation
            } -Force
        }

        It 'Should remove database successfully using database object' {
            $null = Remove-SqlDscDatabase -DatabaseObject $mockDatabaseObject -Force
        }

        It 'Should throw error when trying to remove system database using DatabaseObject' {
            $mockSystemDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockSystemDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'master' -Force
            $mockSystemDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force

            $expectedMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Database_CannotRemoveSystem -f 'master'
            }

            { Remove-SqlDscDatabase -DatabaseObject $mockSystemDatabaseObject -Force } |
                Should -Throw -ExpectedMessage ('*{0}*' -f $expectedMessage) -ErrorId 'RSDD0001,Remove-SqlDscDatabase'
        }
    }

    Context 'When using DropConnections parameter' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'UserAccess' -Value 'Multiple' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            
            $script:alterCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                $script:alterCalled = $true
                if ($this.UserAccess -ne 'Single') {
                    throw 'UserAccess should be set to Single before calling Alter'
                }
            } -Force
            
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                if (-not $script:alterCalled) {
                    throw 'Alter should be called before Drop when DropConnections is specified'
                }
            } -Force

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

        It 'Should drop all active connections before removing database with ServerObject' {
            $script:alterCalled = $false
            $mockDatabaseObject.UserAccess = 'Multiple'
            
            $null = Remove-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -DropConnections -Force
            
            $script:alterCalled | Should -BeTrue
            $mockDatabaseObject.UserAccess | Should -Be 'Single'
        }

        It 'Should drop all active connections before removing database with DatabaseObject' {
            $script:alterCalled = $false
            $mockDatabaseObject.UserAccess = 'Multiple'
            
            $null = Remove-SqlDscDatabase -DatabaseObject $mockDatabaseObject -DropConnections -Force
            
            $script:alterCalled | Should -BeTrue
            $mockDatabaseObject.UserAccess | Should -Be 'Single'
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Force] [-Refresh] [-DropConnections] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscDatabase').ParameterSets |
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
                ExpectedParameters = '-DatabaseObject <Database> [-Force] [-DropConnections] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscDatabase').ParameterSets |
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
