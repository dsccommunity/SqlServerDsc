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

Describe 'Get-SqlDscManagedComputer' -Tag 'Public' {
    Context 'When getting the current managed computer' {
        BeforeAll {
            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
            } -MockWith {
                return 'MockManagedComputer'
            }
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscManagedComputer

            $result | Should -Be 'MockManagedComputer'

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting the specified managed computer' {
        BeforeAll {
            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' `
                -and $ArgumentList -eq 'localhost'
            } -MockWith {
                return 'MockManagedComputer'
            }
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscManagedComputer -ServerName 'localhost'

            $result | Should -Be 'MockManagedComputer'

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
        }
    }
}
