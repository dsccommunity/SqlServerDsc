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

Describe 'Get-LocalizedDataRecursive' -Tag 'Private' {
    BeforeAll {
        $getLocalizedData_ParameterFilter_Class = {
            $FileName -eq 'MyClassResource.strings.psd1'
        }

        $getLocalizedData_ParameterFilter_Base = {
            $FileName -eq 'MyBaseClass.strings.psd1'
        }

        Mock -CommandName Get-LocalizedData -MockWith {
            return @{
                ClassStringKey = 'My class string'
            }
        } -ParameterFilter $getLocalizedData_ParameterFilter_Class

        Mock -CommandName Get-LocalizedData -MockWith {
            return @{
                BaseStringKey = 'My base string'
            }
        } -ParameterFilter $getLocalizedData_ParameterFilter_Base
    }

    Context 'When getting localization string for class name' {
        Context 'When passing value with named parameter' {
            It 'Should return the correct localization strings' {
                InModuleScope -ScriptBlock {
                    $result = Get-LocalizedDataRecursive -ClassName 'MyClassResource'

                    $result.Keys | Should -HaveCount 1
                    $result.Keys | Should -Contain 'ClassStringKey'
                }

                Should -Invoke -CommandName Get-LocalizedData -ParameterFilter $getLocalizedData_ParameterFilter_Class -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing value in pipeline' {
            It 'Should return the correct localization strings' {
                InModuleScope -ScriptBlock {
                    $result = 'MyClassResource' | Get-LocalizedDataRecursive

                    $result.Keys | Should -HaveCount 1
                    $result.Keys | Should -Contain 'ClassStringKey'
                }

                Should -Invoke -CommandName Get-LocalizedData -ParameterFilter $getLocalizedData_ParameterFilter_Class -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When getting localization string for class and base name' {
        Context 'When passing value with named parameter' {
            It 'Should return the correct localization strings' {
                InModuleScope -ScriptBlock {
                    $result = Get-LocalizedDataRecursive -ClassName @('MyClassResource', 'MyBaseClass')

                    $result.Keys | Should -HaveCount 2
                    $result.Keys | Should -Contain 'ClassStringKey'
                    $result.Keys | Should -Contain 'BaseStringKey'
                }

                Should -Invoke -CommandName Get-LocalizedData -ParameterFilter $getLocalizedData_ParameterFilter_Class -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing value in pipeline' {
            It 'Should return the correct localization strings' {
                InModuleScope -ScriptBlock {
                    $result = @('MyClassResource', 'MyBaseClass') | Get-LocalizedDataRecursive

                    $result.Keys | Should -HaveCount 2
                    $result.Keys | Should -Contain 'ClassStringKey'
                    $result.Keys | Should -Contain 'BaseStringKey'
                }

                Should -Invoke -CommandName Get-LocalizedData -ParameterFilter $getLocalizedData_ParameterFilter_Class -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When getting localization string for class and base file name' {
        Context 'When passing value with named parameter' {
            It 'Should return the correct localization strings' {
                InModuleScope -ScriptBlock {
                    $result = Get-LocalizedDataRecursive -ClassName @(
                        'MyClassResource.strings.psd1'
                        'MyBaseClass.strings.psd1'
                    )

                    $result.Keys | Should -HaveCount 2
                    $result.Keys | Should -Contain 'ClassStringKey'
                    $result.Keys | Should -Contain 'BaseStringKey'
                }

                Should -Invoke -CommandName Get-LocalizedData -ParameterFilter $getLocalizedData_ParameterFilter_Class -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing value in pipeline' {
            It 'Should return the correct localization strings' {
                InModuleScope -ScriptBlock {
                    $result = @(
                        'MyClassResource.strings.psd1'
                        'MyBaseClass.strings.psd1'
                    ) | Get-LocalizedDataRecursive

                    $result.Keys | Should -HaveCount 2
                    $result.Keys | Should -Contain 'ClassStringKey'
                    $result.Keys | Should -Contain 'BaseStringKey'
                }

                Should -Invoke -CommandName Get-LocalizedData -ParameterFilter $getLocalizedData_ParameterFilter_Class -Exactly -Times 1 -Scope It
            }
        }
    }
}
