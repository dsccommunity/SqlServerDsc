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

Describe 'ConvertTo-Reason' -Tag 'Private' {
    Context 'When passing an empty collection' {
        It 'Should return an empty collection' {
            InModuleScope -ScriptBlock {
                $mockProperties = @()

                $result = ConvertTo-Reason -Property $mockProperties -ResourceName 'MyResource'

                $result | Should -HaveCount 0
            }
        }
    }

    Context 'When passing a null value' {
        It 'Should return an empty collection' {
            InModuleScope -ScriptBlock {
                $mockProperties = @()

                $result = ConvertTo-Reason -Property $null -ResourceName 'MyResource'

                $result | Should -HaveCount 0
            }
        }
    }

    Context 'When passing as named parameter' {
        It 'Should return the correct values in a hashtable' {
            InModuleScope -ScriptBlock {
                $mockProperties = @(
                    @{
                        Property      = 'MyResourceProperty1'
                        ExpectedValue = 'MyNewValue1'
                        ActualValue   = 'MyValue1'
                    },
                    @{
                        Property      = 'MyResourceProperty2'
                        ExpectedValue = @('MyNewValue2', 'MyNewValue3')
                        ActualValue   = @('MyValue2', 'MyValue3')
                    }
                )

                $result = ConvertTo-Reason -Property $mockProperties -ResourceName 'MyResource'

                $result | Should -HaveCount 2

                $result.Code | Should -Contain 'MyResource:MyResource:MyResourceProperty1'
                $result.Phrase | Should -Contain 'The property MyResourceProperty1 should be "MyNewValue1", but was "MyValue1"'

                $result.Code | Should -Contain 'MyResource:MyResource:MyResourceProperty2'
                $result.Phrase | Should -Contain 'The property MyResourceProperty2 should be ["MyNewValue2","MyNewValue3"], but was ["MyValue2","MyValue3"]'
            }
        }
    }

    Context 'When passing in the pipeline' {
        It 'Should return the correct values in a hashtable' {
            InModuleScope -ScriptBlock {
                $mockProperties = @(
                    @{
                        Property      = 'MyResourceProperty1'
                        ExpectedValue = 'MyNewValue1'
                        ActualValue   = 'MyValue1'
                    },
                    @{
                        Property      = 'MyResourceProperty2'
                        ExpectedValue = @('MyNewValue2', 'MyNewValue3')
                        ActualValue   = @('MyValue2', 'MyValue3')
                    }
                )

                $result = $mockProperties | ConvertTo-Reason -ResourceName 'MyResource'

                $result | Should -HaveCount 2

                $result.Code | Should -Contain 'MyResource:MyResource:MyResourceProperty1'
                $result.Phrase | Should -Contain 'The property MyResourceProperty1 should be "MyNewValue1", but was "MyValue1"'

                $result.Code | Should -Contain 'MyResource:MyResource:MyResourceProperty2'
                $result.Phrase | Should -Contain 'The property MyResourceProperty2 should be ["MyNewValue2","MyNewValue3"], but was ["MyValue2","MyValue3"]'
            }
        }
    }

    Context 'When ExpectedValue has $null for a property' {
        Context 'When on Windows PowerShell' {
            BeforeAll {
                $script:originalPSEdition = $PSVersionTable.PSEdition

                $PSVersionTable.PSEdition = 'Desktop'
            }

            AfterAll {
                $PSVersionTable.PSEdition = $script:originalPSEdition
            }
            It 'Should return the correct values in a hashtable' {
                InModuleScope -ScriptBlock {
                    $mockProperties = @(
                        @{
                            Property      = 'MyResourceProperty1'
                            ExpectedValue = $null
                            ActualValue   = 'MyValue1'
                        }
                    )

                    $result = ConvertTo-Reason -Property $mockProperties -ResourceName 'MyResource'

                    $result | Should -HaveCount 1

                    $result.Code | Should -Contain 'MyResource:MyResource:MyResourceProperty1'
                    $result.Phrase | Should -Contain 'The property MyResourceProperty1 should be "", but was "MyValue1"'
                }
            }
        }
    }

    Context 'When ActualValue has $null for a property' {
        Context 'When on Windows PowerShell' {
            BeforeAll {
                $script:originalPSEdition = $PSVersionTable.PSEdition

                $PSVersionTable.PSEdition = 'Desktop'
            }

            AfterAll {
                $PSVersionTable.PSEdition = $script:originalPSEdition
            }
            It 'Should return the correct values in a hashtable' {
                InModuleScope -ScriptBlock {
                    $mockProperties = @(
                        @{
                            Property      = 'MyResourceProperty1'
                            ExpectedValue = 'MyValue1'
                            ActualValue   = $null
                        }
                    )

                    $result = ConvertTo-Reason -Property $mockProperties -ResourceName 'MyResource'

                    $result | Should -HaveCount 1

                    $result.Code | Should -Contain 'MyResource:MyResource:MyResourceProperty1'
                    $result.Phrase | Should -Contain 'The property MyResourceProperty1 should be "MyValue1", but was ""'
                }
            }
        }
    }
}
