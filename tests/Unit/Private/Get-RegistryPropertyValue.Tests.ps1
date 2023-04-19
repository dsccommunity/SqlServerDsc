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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-RegistryPropertyValue' -Tag 'Private' {
    Context 'When there are no property in the registry' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                return @{
                    'UnknownProperty' = 'AnyValue'
                }
            }
        }

        It 'Should return $null' {
            InModuleScope -ScriptBlock {
                $result = Get-RegistryPropertyValue -Path 'HKLM:\SOFTWARE\MockAnyPath' -Name 'InstanceName'
                $result | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the call to Get-ItemProperty with ErrorAction set to ''Stop''' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                { Get-RegistryPropertyValue -Path 'HKLM:\SOFTWARE\MockAnyPath' -Name 'InstanceName' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Cannot find path 'HKLM:\SOFTWARE\MockAnyPath' because it does not exist."
            }
        }
    }

    Context 'When the call to Get-ItemProperty with ErrorAction set to ''SilentlyContinue''' {
        It 'Should not throw an exception and return $null' {
            InModuleScope -ScriptBlock {
                $result = Get-RegistryPropertyValue -Path 'HKLM:\SOFTWARE\MockAnyPath' -Name 'InstanceName' -ErrorAction 'SilentlyContinue'
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When there are a property in the registry' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                return @{
                    'InstanceName' = 'AnyValue'
                }
            }
        }

        It 'Should return the correct value' {
            InModuleScope -ScriptBlock {
                $result = Get-RegistryPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' -Name 'InstanceName'
                $result | Should -Be 'AnyValue'
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
        }
    }
}
