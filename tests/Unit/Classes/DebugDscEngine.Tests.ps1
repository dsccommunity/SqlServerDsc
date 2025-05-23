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

Describe 'DebugDscEngine' -Tag 'DebugDscEngine' {
    Context 'When instantiating the class' {
        It 'Should be able to instantiate the resource from the class' {
            InModuleScope -ScriptBlock {
                $resource = [DebugDscEngine] @{
                    KeyProperty       = 'TestKey'
                    MandatoryProperty = 'TestMandatory'
                }

                $resource | Should -Not -BeNullOrEmpty
                $resource.GetType().Name | Should -Be 'DebugDscEngine'
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $resource = [DebugDscEngine]::new()
                $resource | Should -Not -BeNullOrEmpty
                $resource.GetType().Name | Should -Be 'DebugDscEngine'
            }
        }

        It 'Should inherit from the base class ResourceBase' {
            InModuleScope -ScriptBlock {
                $resource = [DebugDscEngine]::new()
                $resource.GetType().BaseType.Name | Should -Be 'ResourceBase'
            }
        }
    }

    Context 'When calling method Get()' {
        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                $script:mockDebugDscEngine = [DebugDscEngine] @{
                    KeyProperty       = 'TestKey'
                    MandatoryProperty = 'TestMandatory'
                    WriteProperty     = 'TestWrite'
                }

                $result = $script:mockDebugDscEngine.Get()

                $result.GetType().Name | Should -Be 'DebugDscEngine'
                $result.KeyProperty | Should -Be 'TestKey'
                $result.MandatoryProperty | Should -Be 'CurrentMandatoryStateValue'
                $result.WriteProperty | Should -Be 'CurrentStateValue'
                $result.ReadProperty | Should -Match '^ReadOnlyValue_\d{8}_\d{6}$'
            }
        }
    }

    Context 'When calling method Test()' {
        Context 'When the resource is in desired state' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $script:mockDebugDscEngine = [DebugDscEngine] @{
                        KeyProperty       = 'TestKey'
                        MandatoryProperty = 'TestMandatory'
                        WriteProperty     = 'CurrentStateValue'
                    }

                    $result = $script:mockDebugDscEngine.Test()
                    $result | Should -BeTrue
                }
            }
        }

        Context 'When the resource is not in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockDebugDscEngine = [DebugDscEngine] @{
                        KeyProperty       = 'TestKey'
                        MandatoryProperty = 'TestMandatory'
                        WriteProperty     = 'DifferentValue'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $result = $script:mockDebugDscEngine.Test()
                    $result | Should -BeFalse
                }
            }
        }
    }

    Context 'When calling method Set()' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockDebugDscEngine = [DebugDscEngine] @{
                    KeyProperty       = 'TestKey'
                    MandatoryProperty = 'TestMandatory'
                    WriteProperty     = 'DifferentValue'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { $script:mockDebugDscEngine.Set() } | Should -Not -Throw
            }
        }
    }

    Context 'When calling method GetCurrentState()' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockDebugDscEngine = [DebugDscEngine] @{
                    KeyProperty       = 'TestKey'
                    MandatoryProperty = 'TestMandatory'
                }

                $script:mockProperties = @{
                    KeyProperty = 'TestKey'
                }
            }
        }

        It 'Should return the correct current state' {
            InModuleScope -ScriptBlock {
                $result = $script:mockDebugDscEngine.GetCurrentState($script:mockProperties)

                $result | Should -BeOfType [hashtable]
                $result.KeyProperty | Should -Be 'TestKey'
                $result.WriteProperty | Should -Be 'CurrentStateValue'
                $result.ReadProperty | Should -Match '^ReadOnlyValue_\d{8}_\d{6}$'
            }
        }
    }

    Context 'When calling method Modify()' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockDebugDscEngine = [DebugDscEngine] @{
                    KeyProperty       = 'TestKey'
                    MandatoryProperty = 'TestMandatory'
                }

                $script:mockPropertiesToModify = @{
                    WriteProperty = 'NewValue'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { $script:mockDebugDscEngine.Modify($script:mockPropertiesToModify) } | Should -Not -Throw
            }
        }
    }

    Context 'When calling method AssertProperties()' {
        Context 'When properties are valid' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockDebugDscEngine = [DebugDscEngine] @{
                        KeyProperty       = 'TestKey'
                        MandatoryProperty = 'TestMandatory'
                    }

                    $script:mockValidProperties = @{
                        KeyProperty       = 'TestKey'
                        MandatoryProperty = 'TestMandatory'
                    }
                }
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    { $script:mockDebugDscEngine.AssertProperties($script:mockValidProperties) } | Should -Not -Throw
                }
            }
        }

        Context 'When KeyProperty is null or empty' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockDebugDscEngine = [DebugDscEngine] @{
                        KeyProperty       = 'TestKey'
                        MandatoryProperty = 'TestMandatory'
                    }

                    $script:mockInvalidProperties = @{
                        KeyProperty       = ''
                        MandatoryProperty = 'TestMandatory'
                    }
                }
            }

            It 'Should throw an exception' {
                InModuleScope -ScriptBlock {
                    { $script:mockDebugDscEngine.AssertProperties($script:mockInvalidProperties) } | Should -Throw -ExpectedMessage '*KeyProperty*'
                }
            }
        }

        Context 'When MandatoryProperty is null or empty' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockDebugDscEngine = [DebugDscEngine] @{
                        KeyProperty       = 'TestKey'
                        MandatoryProperty = 'TestMandatory'
                    }

                    $script:mockInvalidProperties = @{
                        KeyProperty       = 'TestKey'
                        MandatoryProperty = ''
                    }
                }
            }

            It 'Should throw an exception' {
                InModuleScope -ScriptBlock {
                    { $script:mockDebugDscEngine.AssertProperties($script:mockInvalidProperties) } | Should -Throw -ExpectedMessage '*MandatoryProperty*'
                }
            }
        }
    }

    Context 'When calling method NormalizeProperties()' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockDebugDscEngine = [DebugDscEngine] @{
                    KeyProperty       = 'TestKey'
                    MandatoryProperty = 'TestMandatory'
                }

                $script:mockProperties = @{
                    KeyProperty   = 'testkey'
                    WriteProperty = '  TestValue  '
                }
            }
        }

        It 'Should normalize properties correctly' {
            InModuleScope -ScriptBlock {
                $script:mockDebugDscEngine.NormalizeProperties($script:mockProperties)

                $script:mockDebugDscEngine.KeyProperty | Should -Be 'TESTKEY'
                $script:mockDebugDscEngine.WriteProperty | Should -Be 'TestValue'
            }
        }
    }
}
