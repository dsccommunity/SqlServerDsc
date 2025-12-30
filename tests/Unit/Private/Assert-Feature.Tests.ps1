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

Describe 'Assert-Feature' -Tag 'Private' {
    Context 'When feature is supported' {
        BeforeAll {
            Mock -CommandName Test-SqlDscIsSupportedFeature -MockWith {
                return $true
            }
        }

        It 'Should not throw an exception for a single feature' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $null = Assert-Feature -Feature 'RS' -ProductVersion '14' -ErrorAction 'Stop'
            }
        }

        It 'Should not throw an exception for multiple features' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $null = Assert-Feature -Feature 'RS', 'SQLENGINE' -ProductVersion '14' -ErrorAction 'Stop'
            }
        }
    }

    Context 'When feature is not supported' {
        BeforeAll {
            Mock -CommandName Test-SqlDscIsSupportedFeature -MockWith {
                return $false
            }
        }

        Context 'When passing a single feature' {
            Context 'When passing as a named parameter' {
                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        {
                            Assert-Feature -Feature 'RS' -ProductVersion 14
                        } | Should -Throw -ExpectedMessage ($script:localizedData.Feature_Assert_NotSupportedFeature -f 'RS', 14)
                    }
                }
            }

            Context 'When passing over the pipeline' {
                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        {
                            'RS' | Assert-Feature -ProductVersion 14
                        } | Should -Throw -ExpectedMessage ($script:localizedData.Feature_Assert_NotSupportedFeature -f 'RS', 14)
                    }
                }
            }
        }

        Context 'When passing multiple features' {
            Context 'When passing as a named parameter' {
                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        {
                            Assert-Feature -Feature @('RS', 'SQLENGINE') -ProductVersion 14
                        } | Should -Throw -ExpectedMessage ($script:localizedData.Feature_Assert_NotSupportedFeature -f 'RS', 14)
                    }
                }
            }

            Context 'When passing over the pipeline' {
                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        {
                            'RS', 'SQLENGINE' | Assert-Feature -ProductVersion 14
                        } | Should -Throw -ExpectedMessage ($script:localizedData.Feature_Assert_NotSupportedFeature -f 'RS', 14)
                    }
                }
            }
        }
    }
}
