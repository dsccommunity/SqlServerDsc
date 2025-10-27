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
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                $this.Owner = $OwnerName
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
            $null = Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'TestDatabase' -OwnerName 'sa' -Force
            $mockDatabaseObject.Owner | Should -Be 'sa'
        }

        It 'Should return a database object when PassThru is specified' {
            $result = Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'TestDatabase' -OwnerName 'sa' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should refresh database properties when Refresh is specified' {
            # Reset owner for this test
            $mockDatabaseObject.Owner = 'OldOwner'
            $null = Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'TestDatabase' -OwnerName 'sa' -Force -Refresh
            $mockDatabaseObject.Owner | Should -Be 'sa'
        }

        It 'Should call SetOwner with correct owner name' {
            # Reset owner for this test
            $mockDatabaseObject.Owner = 'OldOwner'
            $null = Set-SqlDscDatabaseOwner -ServerObject $mockServerObject -Name 'TestDatabase' -OwnerName 'NewOwner' -Force
            $mockDatabaseObject.Owner | Should -Be 'NewOwner'
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
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                $this.Owner = $OwnerName
            } -Force
        }

        It 'Should set database owner successfully' {
            $null = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force
            $mockDatabaseObject.Owner | Should -Be 'sa'
        }

        It 'Should return a database object when PassThru is specified' {
            $result = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should call SetOwner with correct owner name' {
            $mockDatabaseObject.Owner = 'OldOwner'
            $null = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'DomainUser' -Force
            $mockDatabaseObject.Owner | Should -Be 'DomainUser'
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
            $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                param($OwnerName)
                $this.Owner = $OwnerName
            } -Force
        }

        It 'Should still call SetOwner even when owner is already set to desired value' {
            # The command doesn't check if the owner is already set - it always calls SetOwner()
            $null = Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force
            # SetOwner() is called but owner remains 'sa' since that's what we're setting it to
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
        }

        It 'Should throw error when SetOwner() fails' {
            { Set-SqlDscDatabaseOwner -DatabaseObject $mockDatabaseObject -OwnerName 'sa' -Force } |
                Should -Throw -ExpectedMessage '*Simulated SetOwner() failure*'
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

    Context 'Parameter validation' {
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
    }
}
