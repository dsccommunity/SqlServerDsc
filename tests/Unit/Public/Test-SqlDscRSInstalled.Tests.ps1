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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }    # Set environment variable to prevent loading real SQL Server assemblies during testing}}

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

    Import-Module -Name $script:dscModuleName

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

    if (Test-Path -Path 'env:SqlServerDscCI') { Remove-Item -Path 'env:SqlServerDscCI' }
}

Describe 'Test-SqlDscRSInstalled' {
    Context 'When the instance is found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @{
                    InstanceName = 'SSRS'
                    InstallFolder = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                }
            }
        }

        It 'Should return $true when the instance exists' {
            $result = Test-SqlDscRSInstalled -InstanceName 'SSRS'

            $result | Should -BeTrue

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -ParameterFilter {
                $InstanceName -eq 'SSRS'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the instance is not found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return $null
            }
        }

        It 'Should return $false when the instance does not exist' {
            $result = Test-SqlDscRSInstalled -InstanceName 'SSRS'

            $result | Should -BeFalse

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -ParameterFilter {
                $InstanceName -eq 'SSRS'
            } -Exactly -Times 1 -Scope It
        }
    }
}
