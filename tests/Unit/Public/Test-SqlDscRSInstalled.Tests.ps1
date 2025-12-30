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
