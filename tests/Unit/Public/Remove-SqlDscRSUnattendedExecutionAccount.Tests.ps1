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

Describe 'Remove-SqlDscRSUnattendedExecutionAccount' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscRSUnattendedExecutionAccount').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When removing unattended execution account successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should remove unattended execution account without errors' {
            $mockCimInstance | Remove-SqlDscRSUnattendedExecutionAccount -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'RemoveUnattendedExecutionAccount'
            } -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Remove-SqlDscRSUnattendedExecutionAccount -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When removing unattended execution account with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Remove-SqlDscRSUnattendedExecutionAccount -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When removing unattended execution account with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should remove unattended execution account without confirmation' {
            $mockCimInstance | Remove-SqlDscRSUnattendedExecutionAccount -Force

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method SetUnattendedExecutionAccount() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Remove-SqlDscRSUnattendedExecutionAccount -Confirm:$false } | Should -Throw -ErrorId 'RSRUEA0001,Remove-SqlDscRSUnattendedExecutionAccount'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should not call Invoke-RsCimMethod' {
            $mockCimInstance | Remove-SqlDscRSUnattendedExecutionAccount -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should remove unattended execution account' {
            Remove-SqlDscRSUnattendedExecutionAccount -Configuration $mockCimInstance -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }
}
