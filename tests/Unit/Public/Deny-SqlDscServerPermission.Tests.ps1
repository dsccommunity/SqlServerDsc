[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    # Loading stub types
    Add-Type -Path "$PSScriptRoot/../../Stubs/SMO.cs"
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Deny-SqlDscServerPermission' {
    Context 'When the command is called with valid parameters' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'
            
            $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $mockPermissionSet.ConnectSql = $true

            Mock -CommandName Invoke-SqlDscServerPermissionOperation
        }

        It 'Should have the correct parameters in parameter set __AllParameterSets' {
            $result = (Get-Command -Name 'Deny-SqlDscServerPermission').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq '__AllParameterSets' } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be '__AllParameterSets'
            $result.ParameterListAsString | Should -Be '[-ServerObject] <Server> [-Name] <String> [-Permission] <ServerPermissionSet> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }

        It 'Should call Invoke-SqlDscServerPermissionOperation with State Deny' {
            Deny-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission $mockPermissionSet -Force

            Should -Invoke -CommandName Invoke-SqlDscServerPermissionOperation -Times 1 -Exactly -ParameterFilter {
                $State -eq 'Deny' -and 
                $ServerObject -eq $mockServerObject -and 
                $Name -eq 'TestUser' -and 
                $Permission -eq $mockPermissionSet
            }
        }
    }
}