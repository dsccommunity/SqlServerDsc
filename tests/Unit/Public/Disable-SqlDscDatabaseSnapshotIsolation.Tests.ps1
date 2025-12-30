<#
    .SYNOPSIS
        Unit tests for Disable-SqlDscDatabaseSnapshotIsolation.

    .DESCRIPTION
        Unit tests for Disable-SqlDscDatabaseSnapshotIsolation.
#>

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

Describe 'Disable-SqlDscDatabaseSnapshotIsolation' -Tag 'Public' {
    Context 'When the command has proper parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSet'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Refresh] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'DatabaseObjectSet'
                ExpectedParameters = '-DatabaseObject <Database> [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Disable-SqlDscDatabaseSnapshotIsolation').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When verifying parameter properties' {
        BeforeAll {
            $command = Get-Command -Name 'Disable-SqlDscDatabaseSnapshotIsolation'
        }

        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = $command.Parameters['ServerObject']

            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = $command.Parameters['Name']

            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseObject as a mandatory parameter' {
            $parameterInfo = $command.Parameters['DatabaseObject']

            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When disabling snapshot isolation using ServerObject and Name' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'SnapshotIsolationState' -Value 'Enabled' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

                return $mockParent
            } -Force

            $script:setSnapshotIsolationCalled = $false
            $script:setSnapshotIsolationValue = $null
            $script:refreshCalled = $false

            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetSnapshotIsolation' -Value {
                param($Enable)

                $script:setSnapshotIsolationCalled = $true
                $script:setSnapshotIsolationValue = $Enable

                if ($Enable)
                {
                    $this.SnapshotIsolationState = 'Enabled'
                }
                else
                {
                    $this.SnapshotIsolationState = 'Disabled'
                }
            } -Force

            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
                $script:refreshCalled = $true
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

        It 'Should call SetSnapshotIsolation with false and change state to Disabled' {
            $script:setSnapshotIsolationCalled = $false
            $script:setSnapshotIsolationValue = $null

            $null = Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $mockServerObject -Name 'TestDatabase' -Force

            $mockDatabaseObject.SnapshotIsolationState | Should -Be 'Disabled'
            $script:setSnapshotIsolationCalled | Should -BeTrue -Because 'SetSnapshotIsolation should be called to disable snapshot isolation'
            $script:setSnapshotIsolationValue | Should -BeFalse -Because 'SetSnapshotIsolation should be called with $false'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset state to ensure the test starts with snapshot isolation enabled
            $mockDatabaseObject.SnapshotIsolationState = 'Enabled'
            $script:setSnapshotIsolationCalled = $false

            $result = Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $mockServerObject -Name 'TestDatabase' -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should disable snapshot isolation when Refresh is specified' {
            # Reset state for this test
            $mockDatabaseObject.SnapshotIsolationState = 'Enabled'
            $script:setSnapshotIsolationCalled = $false
            $script:refreshCalled = $false

            $null = Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $mockServerObject -Name 'TestDatabase' -Force -Refresh

            $mockDatabaseObject.SnapshotIsolationState | Should -Be 'Disabled'
            $script:refreshCalled | Should -BeTrue -Because 'Refresh should be called when -Refresh is specified'
        }
    }

    Context 'When disabling snapshot isolation using DatabaseObject' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'SnapshotIsolationState' -Value 'Enabled' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

                return $mockParent
            } -Force

            $script:setSnapshotIsolationCalled = $false
            $script:setSnapshotIsolationValue = $null

            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetSnapshotIsolation' -Value {
                param($Enable)

                $script:setSnapshotIsolationCalled = $true
                $script:setSnapshotIsolationValue = $Enable

                if ($Enable)
                {
                    $this.SnapshotIsolationState = 'Enabled'
                }
                else
                {
                    $this.SnapshotIsolationState = 'Disabled'
                }
            } -Force

            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should call SetSnapshotIsolation with false and change state to Disabled' {
            $script:setSnapshotIsolationCalled = $false
            $script:setSnapshotIsolationValue = $null

            $null = Disable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $mockDatabaseObject -Force

            $mockDatabaseObject.SnapshotIsolationState | Should -Be 'Disabled'
            $script:setSnapshotIsolationCalled | Should -BeTrue -Because 'SetSnapshotIsolation should be called'
            $script:setSnapshotIsolationValue | Should -BeFalse -Because 'SetSnapshotIsolation should be called with $false'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset state to ensure the test starts with snapshot isolation enabled
            $mockDatabaseObject.SnapshotIsolationState = 'Enabled'
            $script:setSnapshotIsolationCalled = $false

            $result = Disable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $mockDatabaseObject -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }
    }

    Context 'When snapshot isolation is already disabled' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'SnapshotIsolationState' -Value 'Disabled' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

                return $mockParent
            } -Force

            # Track whether SetSnapshotIsolation was called using script-scoped variables
            $script:setSnapshotIsolationCalled = $false

            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetSnapshotIsolation' -Value {
                param($Enable)

                $script:setSnapshotIsolationCalled = $true

                if ($Enable)
                {
                    $this.SnapshotIsolationState = 'Enabled'
                }
                else
                {
                    $this.SnapshotIsolationState = 'Disabled'
                }
            } -Force

            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should not call SetSnapshotIsolation when snapshot isolation is already disabled' {
            # Reset the flags before the test
            $script:setSnapshotIsolationCalled = $false

            $null = Disable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $mockDatabaseObject -Force

            $script:setSnapshotIsolationCalled | Should -BeFalse -Because 'SetSnapshotIsolation should not be called when snapshot isolation is already disabled'
            $mockDatabaseObject.SnapshotIsolationState | Should -Be 'Disabled'
        }
    }

    Context 'When database modification fails' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'SnapshotIsolationState' -Value 'Enabled' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

                return $mockParent
            } -Force

            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetSnapshotIsolation' -Value {
                param($Enable)

                throw 'Simulated SetSnapshotIsolation() failure'
            } -Force

            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should throw error when SetSnapshotIsolation() fails' {
            { Disable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $mockDatabaseObject -Force } |
                Should -Throw -ExpectedMessage '*Failed to disable snapshot isolation for database*'
        }
    }

    Context 'When database does not exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{} | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should throw error when database does not exist' {
            { Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $mockServerObject -Name 'NonExistentDatabase' -Force } |
                Should -Throw -ExpectedMessage '*Database * was not found*'
        }
    }
}
