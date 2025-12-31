<#
    .SYNOPSIS
        Unit tests for Set-SqlDscDatabaseOwner.

    .DESCRIPTION
        Unit tests for Set-SqlDscDatabaseOwner.
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

Describe 'Set-SqlDscDatabaseOwner' -Tag 'Public' {
    Context 'When setting database owner using ServerObject and Name' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'OldOwner' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $script:setOwnerCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                $script:setOwnerCalled = $true
                $this.Owner = $OwnerName
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

        It 'Should set database owner successfully' {
            $script:setOwnerCalled = $false
            $null = Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'TestDatabase' -OwnerName 'sa' -Force
            $mockDatabaseObject.Owner | Should -Be 'sa'
            $script:setOwnerCalled | Should -BeTrue -Because 'SetOwner should be called to change the owner'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset owner to ensure the test starts with a different owner
            $mockDatabaseObject.Owner = 'OldOwner'
            $script:setOwnerCalled = $false
            $result = Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'TestDatabase' -OwnerName 'sa' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should refresh database properties when Refresh is specified' {
            # Reset owner for this test
            $mockDatabaseObject.Owner = 'OldOwner'
            $script:setOwnerCalled = $false
            $null = Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'TestDatabase' -OwnerName 'sa' -Force -Refresh
            $mockDatabaseObject.Owner | Should -Be 'sa'
        }

        It 'Should call SetOwner with correct owner name' {
            # Reset owner for this test
            $mockDatabaseObject.Owner = 'OldOwner'
            $script:setOwnerCalled = $false
            $null = Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'TestDatabase' -OwnerName 'NewOwner' -Force
            $mockDatabaseObject.Owner | Should -Be 'NewOwner'
            $script:setOwnerCalled | Should -BeTrue -Because 'SetOwner should be called to change the owner'
        }
    }

    Context 'When setting database owner using DatabaseObject' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'OldOwner' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $script:setOwnerCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                $script:setOwnerCalled = $true
                $this.Owner = $OwnerName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should set database owner successfully' {
            $script:setOwnerCalled = $false
            $null = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force
            $mockDatabaseObject.Owner | Should -Be 'sa'
            $script:setOwnerCalled | Should -BeTrue -Because 'SetOwner should be called to change the owner'
        }

        It 'Should return a database object when PassThru is specified' {
            # Reset owner to ensure the test starts with a different owner
            $mockDatabaseObject.Owner = 'OldOwner'
            $script:setOwnerCalled = $false
            $result = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should call SetOwner with correct owner name' {
            $mockDatabaseObject.Owner = 'OldOwner'
            $script:setOwnerCalled = $false
            $null = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'DomainUser' -Force
            $mockDatabaseObject.Owner | Should -Be 'DomainUser'
            $script:setOwnerCalled | Should -BeTrue -Because 'SetOwner should be called to change the owner'
        }
    }

    Context 'When owner is already set to desired value' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'sa' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            # Track whether SetOwner was called using script-scoped variables
            $script:setOwnerCalled = $false
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                $script:setOwnerCalled = $true
                $this.Owner = $OwnerName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should not call SetOwner when owner already matches the desired value' {
            # Reset the flags before the test
            $script:setOwnerCalled = $false

            # The command should skip calling SetOwner when the owner already matches
            $null = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force

            # Verify SetOwner was not called (idempotent behavior)
            $script:setOwnerCalled | Should -BeFalse -Because 'SetOwner should not be called when the owner already matches'
            $mockDatabaseObject.Owner | Should -Be 'sa'
        }
    }

    Context 'When database modification fails' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'OldOwner' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                throw 'Simulated SetOwner() failure'
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should throw error when SetOwner() fails' {
            { Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force } |
                Should -Throw -ExpectedMessage '*Failed to set owner of database*'
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
            { Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'NonExistentDatabase' -OwnerName 'sa' -Force } |
                Should -Throw -ExpectedMessage '*Database * was not found*'
        }
    }

    Context 'When using DropExistingUser parameter' {
        BeforeAll {
            $script:setOwnerParameters = $null

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'OldOwner' -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                return $mockParent
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param(
                    [Parameter(Position = 0)]
                    [string]$OwnerName,
                    [Parameter(Position = 1)]
                    [bool]$DropExistingUser = $false
                )
                $script:setOwnerParameters = @{
                    OwnerName = $OwnerName
                    DropExistingUser = $DropExistingUser
                }
                $this.Owner = $OwnerName
            } -Force
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                # Mock implementation - in real SMO this updates properties from server
            } -Force
        }

        It 'Should call SetOwner with dropExistingUser set to true when DropExistingUser is specified' {
            $script:setOwnerParameters = $null
            $null = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -DropExistingUser -Force

            $script:setOwnerParameters | Should -Not -BeNullOrEmpty
            $script:setOwnerParameters.OwnerName | Should -Be 'sa'
            $script:setOwnerParameters.DropExistingUser | Should -BeTrue
        }

        It 'Should call SetOwner with only ownerName parameter when DropExistingUser is not specified' {
            # Reset owner for this test
            $mockDatabaseObject.Owner = 'OldOwner'
            $script:setOwnerParameters = $null
            $null = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force

            $script:setOwnerParameters | Should -Not -BeNullOrEmpty
            $script:setOwnerParameters.OwnerName | Should -Be 'sa'
            $script:setOwnerParameters.DropExistingUser | Should -BeFalse
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObjectSet' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSet'
                ExpectedParameters = '-ServerObject <Server> -Name <string> -OwnerName <string> [-Refresh] [-DropExistingUser] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabaseOwner').ParameterSets |
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
                ExpectedParameters = '-DatabaseObject <Database> -OwnerName <string> [-DropExistingUser] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabaseOwner').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have OwnerName as a mandatory parameter' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseOwner'
            $ownerNameParam = $command.Parameters['OwnerName']

            $ownerNameParam | Should -Not -BeNullOrEmpty
            $ownerNameParam.ParameterType.Name | Should -Be 'String'

            # Check if parameter is mandatory in at least one parameter set
            $mandatoryInAnySets = $ownerNameParam.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Where-Object { $_.Mandatory -eq $true }

            $mandatoryInAnySets | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess (WhatIf and Confirm)' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseOwner'
            $command.Parameters.Keys | Should -Contain 'WhatIf'
            $command.Parameters.Keys | Should -Contain 'Confirm'
        }

        It 'Should have Force parameter to bypass confirmation' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseOwner'
            $command.Parameters.Keys | Should -Contain 'Force'
        }

        It 'Should have PassThru parameter to return the database object' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseOwner'
            $command.Parameters.Keys | Should -Contain 'PassThru'
        }

        It 'Should have DropExistingUser parameter as a switch' {
            $command = Get-Command -Name 'Set-SqlDscDatabaseOwner'
            $dropExistingUserParam = $command.Parameters['DropExistingUser']

            $dropExistingUserParam | Should -Not -BeNullOrEmpty
            $dropExistingUserParam.ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It 'Should have ServerObject as a mandatory parameter in ServerObjectSet' {
            $param = (Get-Command -Name 'Set-SqlDscDatabaseOwner').Parameters['ServerObject']
            ($param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'ServerObjectSet' }).Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseObject as a mandatory parameter in DatabaseObjectSet' {
            $param = (Get-Command -Name 'Set-SqlDscDatabaseOwner').Parameters['DatabaseObject']
            ($param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'DatabaseObjectSet' }).Mandatory | Should -BeTrue
        }
    }
}
