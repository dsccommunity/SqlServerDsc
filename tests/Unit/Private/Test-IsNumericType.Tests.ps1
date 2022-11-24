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

Describe 'Test-IsNumericType' -Tag 'Private' {
    Context 'When passing value with named parameter' {
        Context 'When type is numeric' {
            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Test-IsNumericType -Object ([System.UInt32] 3)

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When type is not numeric' {
            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Test-IsNumericType -Object ([System.String] 'a')

                    $result | Should -BeFalse
                }
            }
        }
    }

    Context 'When passing value in pipeline' {
        Context 'When type is numeric' {
            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = ([System.UInt32] 3) | Test-IsNumericType

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When type is not numeric' {
            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = ([System.String] 'a') | Test-IsNumericType

                    $result | Should -BeFalse
                }
            }
        }
    }
}
