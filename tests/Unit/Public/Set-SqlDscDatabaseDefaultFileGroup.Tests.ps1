<#
    .SYNOPSIS
        Unit tests for Set-SqlDscDatabaseDefaultFileGroup.

    .DESCRIPTION
        Unit tests for Set-SqlDscDatabaseDefaultFileGroup.
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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

Describe 'Set-SqlDscDatabaseDefaultFileGroup' -Tag 'Public' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSet'
                ExpectedParameters = '-ServerObject <Server> -Name <string> -DefaultFileGroup <string> [-Refresh] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ServerObjectSetFileStream'
                ExpectedParameters = '-ServerObject <Server> -Name <string> -DefaultFileStreamFileGroup <string> [-Refresh] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'DatabaseObjectSet'
                ExpectedParameters = '-DatabaseObject <Database> -DefaultFileGroup <string> [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'DatabaseObjectSetFileStream'
                ExpectedParameters = '-DatabaseObject <Database> -DefaultFileStreamFileGroup <string> [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabaseDefaultFileGroup').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When setting default filegroup using ServerObject and Name' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value '' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $script:setDefaultFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileGroupCalled = $true
                $this.DefaultFileGroup = $FileGroupName
            } -Force
            $script:setDefaultFileStreamFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileStreamFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileStreamFileGroupCalled = $true
                $this.DefaultFileStreamFileGroup = $FileGroupName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
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

        It 'Should set default filegroup successfully' {
            $script:setDefaultFileGroupCalled = $false
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileGroup 'UserData' -Force
            $mockDatabaseObject.DefaultFileGroup | Should -Be 'UserData'
            $script:setDefaultFileGroupCalled | Should -BeTrue -Because 'SetDefaultFileGroup should be called to change the default filegroup'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset default filegroup to ensure the test starts with a different filegroup
            $mockDatabaseObject.DefaultFileGroup = 'PRIMARY'
            $script:setDefaultFileGroupCalled = $false
            $result = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileGroup 'UserData' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should refresh database properties when Refresh is specified' {
            # Reset default filegroup for this test
            $mockDatabaseObject.DefaultFileGroup = 'PRIMARY'
            $script:setDefaultFileGroupCalled = $false
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileGroup 'UserData' -Force -Refresh
            $mockDatabaseObject.DefaultFileGroup | Should -Be 'UserData'
        }

        It 'Should call SetDefaultFileGroup with correct filegroup name' {
            # Reset default filegroup for this test
            $mockDatabaseObject.DefaultFileGroup = 'PRIMARY'
            $script:setDefaultFileGroupCalled = $false
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileGroup 'NewFileGroup' -Force
            $mockDatabaseObject.DefaultFileGroup | Should -Be 'NewFileGroup'
            $script:setDefaultFileGroupCalled | Should -BeTrue -Because 'SetDefaultFileGroup should be called to change the default filegroup'
        }
    }

    Context 'When setting default FILESTREAM filegroup using ServerObject and Name' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value '' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $script:setDefaultFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileGroupCalled = $true
                $this.DefaultFileGroup = $FileGroupName
            } -Force
            $script:setDefaultFileStreamFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileStreamFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileStreamFileGroupCalled = $true
                $this.DefaultFileStreamFileGroup = $FileGroupName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
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

        It 'Should set default FILESTREAM filegroup successfully' {
            $script:setDefaultFileStreamFileGroupCalled = $false
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileStreamFileGroup 'FileStreamData' -Force
            $mockDatabaseObject.DefaultFileStreamFileGroup | Should -Be 'FileStreamData'
            $script:setDefaultFileStreamFileGroupCalled | Should -BeTrue -Because 'SetDefaultFileStreamFileGroup should be called to change the default FILESTREAM filegroup'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset default FILESTREAM filegroup to ensure the test starts with a different filegroup
            $mockDatabaseObject.DefaultFileStreamFileGroup = ''
            $script:setDefaultFileStreamFileGroupCalled = $false
            $result = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileStreamFileGroup 'FileStreamData' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }
    }

    Context 'When setting default filegroup using DatabaseObject' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value '' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $script:setDefaultFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileGroupCalled = $true
                $this.DefaultFileGroup = $FileGroupName
            } -Force
            $script:setDefaultFileStreamFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileStreamFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileStreamFileGroupCalled = $true
                $this.DefaultFileStreamFileGroup = $FileGroupName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should set default filegroup successfully' {
            $script:setDefaultFileGroupCalled = $false
            $null = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileGroup 'UserData' -Force
            $mockDatabaseObject.DefaultFileGroup | Should -Be 'UserData'
            $script:setDefaultFileGroupCalled | Should -BeTrue -Because 'SetDefaultFileGroup should be called to change the default filegroup'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset default filegroup to ensure the test starts with a different filegroup
            $mockDatabaseObject.DefaultFileGroup = 'PRIMARY'
            $script:setDefaultFileGroupCalled = $false
            $result = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileGroup 'UserData' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should call SetDefaultFileGroup with correct filegroup name' {
            $mockDatabaseObject.DefaultFileGroup = 'PRIMARY'
            $script:setDefaultFileGroupCalled = $false
            $null = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileGroup 'CustomFileGroup' -Force
            $mockDatabaseObject.DefaultFileGroup | Should -Be 'CustomFileGroup'
            $script:setDefaultFileGroupCalled | Should -BeTrue -Because 'SetDefaultFileGroup should be called to change the default filegroup'
        }
    }

    Context 'When setting default FILESTREAM filegroup using DatabaseObject' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value '' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $script:setDefaultFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileGroupCalled = $true
                $this.DefaultFileGroup = $FileGroupName
            } -Force
            $script:setDefaultFileStreamFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileStreamFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileStreamFileGroupCalled = $true
                $this.DefaultFileStreamFileGroup = $FileGroupName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should set default FILESTREAM filegroup successfully' {
            $script:setDefaultFileStreamFileGroupCalled = $false
            $null = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileStreamFileGroup 'FileStreamData' -Force
            $mockDatabaseObject.DefaultFileStreamFileGroup | Should -Be 'FileStreamData'
            $script:setDefaultFileStreamFileGroupCalled | Should -BeTrue -Because 'SetDefaultFileStreamFileGroup should be called to change the default FILESTREAM filegroup'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset default FILESTREAM filegroup to ensure the test starts with a different filegroup
            $mockDatabaseObject.DefaultFileStreamFileGroup = ''
            $script:setDefaultFileStreamFileGroupCalled = $false
            $result = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileStreamFileGroup 'FileStreamData' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }
    }

    Context 'When default filegroup is already set to desired value' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'UserData' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value '' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            # Track whether SetDefaultFileGroup was called using script-scoped variables
            $script:setDefaultFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileGroupCalled = $true
                $this.DefaultFileGroup = $FileGroupName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should not call SetDefaultFileGroup when default filegroup already matches the desired value' {
            # Reset the flags before the test
            $script:setDefaultFileGroupCalled = $false

            # The command should skip calling SetDefaultFileGroup when the default filegroup already matches
            $null = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileGroup 'UserData' -Force

            # Verify SetDefaultFileGroup was not called (idempotent behavior)
            $script:setDefaultFileGroupCalled | Should -BeFalse -Because 'SetDefaultFileGroup should not be called when the default filegroup already matches'
            $mockDatabaseObject.DefaultFileGroup | Should -Be 'UserData'
        }
    }

    Context 'When default FILESTREAM filegroup is already set to desired value' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value 'FileStreamData' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            # Track whether SetDefaultFileStreamFileGroup was called using script-scoped variables
            $script:setDefaultFileStreamFileGroupCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileStreamFileGroup' -Value {
                param($FileGroupName)
                $script:setDefaultFileStreamFileGroupCalled = $true
                $this.DefaultFileStreamFileGroup = $FileGroupName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should not call SetDefaultFileStreamFileGroup when default FILESTREAM filegroup already matches the desired value' {
            # Reset the flags before the test
            $script:setDefaultFileStreamFileGroupCalled = $false

            # The command should skip calling SetDefaultFileStreamFileGroup when the default FILESTREAM filegroup already matches
            $null = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileStreamFileGroup 'FileStreamData' -Force

            # Verify SetDefaultFileStreamFileGroup was not called (idempotent behavior)
            $script:setDefaultFileStreamFileGroupCalled | Should -BeFalse -Because 'SetDefaultFileStreamFileGroup should not be called when the default FILESTREAM filegroup already matches'
            $mockDatabaseObject.DefaultFileStreamFileGroup | Should -Be 'FileStreamData'
        }
    }

    Context 'When database modification fails' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value '' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                param($FileGroupName)
                throw 'Simulated SetDefaultFileGroup() failure'
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileStreamFileGroup' -Value {
                param($FileGroupName)
                throw 'Simulated SetDefaultFileStreamFileGroup() failure'
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should throw error when SetDefaultFileGroup() fails' {
            { Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileGroup 'UserData' -Force } |
                Should -Throw -ExpectedMessage '*Failed to set default filegroup of database*'
        }

        It 'Should throw error when SetDefaultFileStreamFileGroup() fails' {
            { Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $mockDatabaseObject -DefaultFileStreamFileGroup 'FileStreamData' -Force } |
                Should -Throw -ExpectedMessage '*Failed to set default FILESTREAM filegroup of database*'
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

        It 'Should throw error when database does not exist for DefaultFileGroup' {
            { Set-SqlDscDatabaseDefaultFileGroup -ServerObject $mockServerObject -Name 'NonExistentDatabase' -DefaultFileGroup 'UserData' -Force } |
                Should -Throw -ExpectedMessage '*Database * was not found*'
        }

        It 'Should throw error when database does not exist for DefaultFileStreamFileGroup' {
            { Set-SqlDscDatabaseDefaultFileGroup -ServerObject $mockServerObject -Name 'NonExistentDatabase' -DefaultFileStreamFileGroup 'FileStreamData' -Force } |
                Should -Throw -ExpectedMessage '*Database * was not found*'
        }
    }
}
