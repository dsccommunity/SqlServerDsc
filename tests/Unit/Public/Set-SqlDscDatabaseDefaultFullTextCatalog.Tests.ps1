<#
    .SYNOPSIS
        Unit tests for Set-SqlDscDatabaseDefaultFullTextCatalog.

    .DESCRIPTION
        Unit tests for Set-SqlDscDatabaseDefaultFullTextCatalog.
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

Describe 'Set-SqlDscDatabaseDefaultFullTextCatalog' -Tag 'Public' {
    Context 'When setting default full-text catalog using ServerObject and Name' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFullTextCatalog' -Value 'OldCatalog' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $script:setDefaultFullTextCatalogCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFullTextCatalog' -Value {
                param($CatalogName)
                $script:setDefaultFullTextCatalogCalled = $true
                $this.DefaultFullTextCatalog = $CatalogName
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

        It 'Should set default full-text catalog successfully' {
            $script:setDefaultFullTextCatalogCalled = $false
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $mockServerObject -Name 'TestDatabase' -CatalogName 'MyCatalog' -Force
            $mockDatabaseObject.DefaultFullTextCatalog | Should -Be 'MyCatalog'
            $script:setDefaultFullTextCatalogCalled | Should -BeTrue -Because 'SetDefaultFullTextCatalog should be called to change the catalog'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset catalog to ensure the test starts with a different catalog
            $mockDatabaseObject.DefaultFullTextCatalog = 'OldCatalog'
            $script:setDefaultFullTextCatalogCalled = $false
            $result = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $mockServerObject -Name 'TestDatabase' -CatalogName 'MyCatalog' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should refresh database properties when Refresh is specified' {
            # Reset catalog for this test
            $mockDatabaseObject.DefaultFullTextCatalog = 'OldCatalog'
            $script:setDefaultFullTextCatalogCalled = $false
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $mockServerObject -Name 'TestDatabase' -CatalogName 'MyCatalog' -Force -Refresh
            $mockDatabaseObject.DefaultFullTextCatalog | Should -Be 'MyCatalog'
        }

        It 'Should call SetDefaultFullTextCatalog with correct catalog name' {
            # Reset catalog for this test
            $mockDatabaseObject.DefaultFullTextCatalog = 'OldCatalog'
            $script:setDefaultFullTextCatalogCalled = $false
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $mockServerObject -Name 'TestDatabase' -CatalogName 'NewCatalog' -Force
            $mockDatabaseObject.DefaultFullTextCatalog | Should -Be 'NewCatalog'
            $script:setDefaultFullTextCatalogCalled | Should -BeTrue -Because 'SetDefaultFullTextCatalog should be called to change the catalog'
        }
    }

    Context 'When setting default full-text catalog using DatabaseObject' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFullTextCatalog' -Value 'OldCatalog' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $script:setDefaultFullTextCatalogCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFullTextCatalog' -Value {
                param($CatalogName)
                $script:setDefaultFullTextCatalogCalled = $true
                $this.DefaultFullTextCatalog = $CatalogName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should set default full-text catalog successfully' {
            $script:setDefaultFullTextCatalogCalled = $false
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -DatabaseObject $mockDatabaseObject -CatalogName 'MyCatalog' -Force
            $mockDatabaseObject.DefaultFullTextCatalog | Should -Be 'MyCatalog'
            $script:setDefaultFullTextCatalogCalled | Should -BeTrue -Because 'SetDefaultFullTextCatalog should be called to change the catalog'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset catalog to ensure the test starts with a different catalog
            $mockDatabaseObject.DefaultFullTextCatalog = 'OldCatalog'
            $script:setDefaultFullTextCatalogCalled = $false
            $result = Set-SqlDscDatabaseDefaultFullTextCatalog -DatabaseObject $mockDatabaseObject -CatalogName 'MyCatalog' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should call SetDefaultFullTextCatalog with correct catalog name' {
            $mockDatabaseObject.DefaultFullTextCatalog = 'OldCatalog'
            $script:setDefaultFullTextCatalogCalled = $false
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -DatabaseObject $mockDatabaseObject -CatalogName 'NewCatalog' -Force
            $mockDatabaseObject.DefaultFullTextCatalog | Should -Be 'NewCatalog'
            $script:setDefaultFullTextCatalogCalled | Should -BeTrue -Because 'SetDefaultFullTextCatalog should be called to change the catalog'
        }
    }

    Context 'When default full-text catalog is already set to desired value' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFullTextCatalog' -Value 'MyCatalog' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            # Track whether SetDefaultFullTextCatalog was called using script-scoped variables
            $script:setDefaultFullTextCatalogCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFullTextCatalog' -Value {
                param($CatalogName)
                $script:setDefaultFullTextCatalogCalled = $true
                $this.DefaultFullTextCatalog = $CatalogName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should not call SetDefaultFullTextCatalog when catalog already matches the desired value' {
            # Reset the flags before the test
            $script:setDefaultFullTextCatalogCalled = $false

            # The command should skip calling SetDefaultFullTextCatalog when the catalog already matches
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -DatabaseObject $mockDatabaseObject -CatalogName 'MyCatalog' -Force

            # Verify SetDefaultFullTextCatalog was not called (idempotent behavior)
            $script:setDefaultFullTextCatalogCalled | Should -BeFalse -Because 'SetDefaultFullTextCatalog should not be called when the catalog already matches'
            $mockDatabaseObject.DefaultFullTextCatalog | Should -Be 'MyCatalog'
        }
    }

    Context 'When database modification fails' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFullTextCatalog' -Value 'OldCatalog' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFullTextCatalog' -Value {
                param($CatalogName)
                throw 'Simulated SetDefaultFullTextCatalog() failure'
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should throw error when SetDefaultFullTextCatalog() fails' {
            { Set-SqlDscDatabaseDefaultFullTextCatalog -DatabaseObject $mockDatabaseObject -CatalogName 'MyCatalog' -Force } |
                Should -Throw -ExpectedMessage '*Failed to set default full-text catalog of database*'
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
            { Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $mockServerObject -Name 'NonExistentDatabase' -CatalogName 'MyCatalog' -Force } |
                Should -Throw -ExpectedMessage '*Database * was not found*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObjectSet' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSet'
                ExpectedParameters = '-ServerObject <Server> -Name <string> -CatalogName <string> [-Refresh] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabaseDefaultFullTextCatalog').ParameterSets |
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
                ExpectedParameters = '-DatabaseObject <Database> -CatalogName <string> [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabaseDefaultFullTextCatalog').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have CatalogName as a mandatory parameter' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseDefaultFullTextCatalog'
            $catalogNameParam = $command.Parameters['CatalogName']

            $catalogNameParam | Should -Not -BeNullOrEmpty
            $catalogNameParam.ParameterType.Name | Should -Be 'String'

            # Check if parameter is mandatory in at least one parameter set
            $mandatoryInAnySets = $catalogNameParam.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Where-Object { $_.Mandatory -eq $true }

            $mandatoryInAnySets | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess (WhatIf and Confirm)' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseDefaultFullTextCatalog'
            $command.Parameters.Keys | Should -Contain 'WhatIf'
            $command.Parameters.Keys | Should -Contain 'Confirm'
        }

        It 'Should have Force parameter to bypass confirmation' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseDefaultFullTextCatalog'
            $command.Parameters.Keys | Should -Contain 'Force'
        }

        It 'Should have PassThru parameter to return the database object' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseDefaultFullTextCatalog'
            $command.Parameters.Keys | Should -Contain 'PassThru'
        }

        It 'Should have ServerObject as a mandatory parameter in ServerObjectSet' {
            $param = (Get-Command -Name 'Set-SqlDscDatabaseDefaultFullTextCatalog').Parameters['ServerObject']
            ($param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'ServerObjectSet' }).Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseObject as a mandatory parameter in DatabaseObjectSet' {
            $param = (Get-Command -Name 'Set-SqlDscDatabaseDefaultFullTextCatalog').Parameters['DatabaseObject']
            ($param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'DatabaseObjectSet' }).Mandatory | Should -BeTrue
        }
    }
}
