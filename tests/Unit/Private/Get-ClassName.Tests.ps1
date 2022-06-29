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
}

Describe 'Get-ClassName' -Tag 'Private' {
    Context 'When getting the class name' {
        Context 'When passing value with named parameter' {
            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Get-ClassName -InputObject ([System.UInt32] 3)

                    $result.GetType().FullName | Should -Be 'System.Object[]'

                    $result | Should -HaveCount 1
                    $result | Should -Contain 'System.UInt32'
                }
            }
        }

        Context 'When passing value in pipeline' {
            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = ([System.UInt32] 3) | Get-ClassName

                    $result.GetType().FullName | Should -Be 'System.Object[]'

                    $result | Should -HaveCount 1
                    $result | Should -Contain 'System.UInt32'
                }
            }
        }
    }

    Context 'When getting the class name and all inherited class names (base classes)' {
        Context 'When passing value with named parameter' {
            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Get-ClassName -InputObject ([System.UInt32] 3) -Recurse

                    $result.GetType().FullName | Should -Be 'System.Object[]'

                    $result | Should -HaveCount 2
                    $result | Should -Contain 'System.UInt32'
                    $result | Should -Contain 'System.ValueType'

                    $result[0] | Should -Be 'System.UInt32'
                    $result[1] | Should -Be 'System.ValueType'
                }
            }
        }

        Context 'When passing value in pipeline' {
            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = ([System.UInt32] 3) | Get-ClassName -Recurse

                    $result.GetType().FullName | Should -Be 'System.Object[]'

                    $result | Should -HaveCount 2
                    $result | Should -Contain 'System.UInt32'
                    $result | Should -Contain 'System.ValueType'

                    $result[0] | Should -Be 'System.UInt32'
                    $result[1] | Should -Be 'System.ValueType'
                }
            }
        }
    }
}
