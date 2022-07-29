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

Describe 'ConvertFrom-CompareResult' -Tag 'Private' {
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
                        ExpectedValue = 'MyNewValue2'
                        ActualValue   = 'MyValue2'
                    }
                )

                $result = ConvertFrom-CompareResult -CompareResult $mockProperties

                $result | Should -BeOfType [System.Collections.Hashtable]

                $result.Keys | Should -HaveCount 2
                $result.Keys | Should -Contain 'MyResourceProperty1'
                $result.Keys | Should -Contain 'MyResourceProperty2'

                $result.MyResourceProperty1 | Should -Be 'MyNewValue1'
                $result.MyResourceProperty2 | Should -Be 'MyNewValue2'
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
                        ExpectedValue = 'MyNewValue2'
                        ActualValue   = 'MyValue2'
                    }
                )

                $result = $mockProperties | ConvertFrom-CompareResult

                $result | Should -BeOfType [System.Collections.Hashtable]

                $result.Keys | Should -HaveCount 2
                $result.Keys | Should -Contain 'MyResourceProperty1'
                $result.Keys | Should -Contain 'MyResourceProperty2'

                $result.MyResourceProperty1 | Should -Be 'MyNewValue1'
                $result.MyResourceProperty2 | Should -Be 'MyNewValue2'
            }
        }
    }
}
