<#
    .SYNOPSIS
        Unit test for DSC_SqlScriptQuery DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
    $script:dscResourceName = 'DSC_SqlScriptQuery'

    $env:SqlServerDscCI = $true

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Loading mocked exception class
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SqlPowerShellSqlExecutionException.cs')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlScriptQuery\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                GetQuery     = "GetQuery;"
                TestQuery    = "TestQuery;"
                SetQuery     = "SetQuery;"
                Encrypt      = 'Optional'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When Get-TargetResource returns script results successfully' {
        BeforeAll {
            Mock -CommandName Invoke-SqlScript -MockWith {
                return ''
            }
        }

        It 'Should return the expected results' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.ServerInstance | Should -Be $mockGetTargetResourceParameters.ServerInstance
                $result.GetQuery | Should -Be $mockGetTargetResourceParameters.GetQuery
                $result.SetQuery | Should -Be $mockGetTargetResourceParameters.SetQuery
                $result.TestQuery | Should -Be $mockGetTargetResourceParameters.TestQuery
            }
        }
    }

    Context 'When Get-TargetResource returns script results successfully with query timeout' {
        BeforeAll {
            Mock -CommandName Invoke-SqlScript -MockWith {
                return ''
            }
        }

        It 'Should return the expected results' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParametersTimeout = @{
                    ServerName   = 'localhost'
                    InstanceName = 'MSSQLSERVER'
                    GetQuery     = "GetQuery;"
                    TestQuery    = "TestQuery;"
                    SetQuery     = "SetQuery;"
                    QueryTimeout = 30
                }

                $result = Get-TargetResource @mockTestParametersTimeout

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.ServerInstance | Should -Be $mockTestParametersTimeout.ServerInstance
                $result.GetQuery | Should -Be $mockTestParametersTimeout.GetQuery
                $result.SetQuery | Should -Be $mockTestParametersTimeout.SetQuery
                $result.TestQuery | Should -Be $mockTestParametersTimeout.TestQuery
            }
        }
    }

    Context 'When Get-TargetResource throws an error when running the script in the GetFilePath parameter' {
        BeforeAll {
            Mock -CommandName Invoke-SqlScript -MockWith {
                throw 'Failed to run SQL Script'
            }
        }

        It 'Should throw the correct error from Invoke-Sqlcmd' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = 'Failed to run SQL Script'

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }
}

Describe 'SqlScriptQuery\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                GetQuery     = "GetQuery;"
                TestQuery    = "TestQuery;"
                SetQuery     = "SetQuery;"
                Encrypt      = 'Optional'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When Set-TargetResource runs script without issue' {
        BeforeAll {
            Mock -CommandName Invoke-SqlScript -MockWith {
                return ''
            }
        }

        It 'Should return the expected results' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }
    }

    Context 'When Set-TargetResource runs script without issue using timeout' {
        BeforeAll {
            Mock -CommandName Invoke-SqlScript -MockWith {
                return ''
            }
        }

        It 'Should return the expected results' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }
    }

    Context 'When Set-TargetResource throws an error when running the script in the SetFilePath parameter' {
        BeforeAll {
            Mock -CommandName Invoke-SqlScript -MockWith {
                throw 'Failed to run SQL Script'
            }
        }


        It 'Should throw the correct error from Invoke-Sqlcmd' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = 'Failed to run SQL Script'

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }
}

Describe 'SqlScriptQuery\Test-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                GetQuery     = "GetQuery;"
                TestQuery    = "TestQuery;"
                SetQuery     = "SetQuery;"
                Encrypt      = 'Optional'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When Test-TargetResource runs script without issue' {
            BeforeAll {
                Mock -CommandName Invoke-SqlScript
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When Test-TargetResource runs script without issue with timeout' {
            BeforeAll {
                Mock -CommandName Invoke-SqlScript
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParametersTimeout = @{
                        ServerName   = 'localhost'
                        InstanceName = 'MSSQLSERVER'
                        GetQuery     = "GetQuery;"
                        TestQuery    = "TestQuery;"
                        SetQuery     = "SetQuery;"
                        QueryTimeout = 30
                    }

                    $result = Test-TargetResource @mockTestParametersTimeout

                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When Invoke-SqlScript returns an SQL error code from the script that was ran' {
            BeforeAll {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return 1
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParametersTimeout = @{
                        ServerName   = 'localhost'
                        InstanceName = 'MSSQLSERVER'
                        GetQuery     = "GetQuery;"
                        TestQuery    = "TestQuery;"
                        SetQuery     = "SetQuery;"
                        QueryTimeout = 30
                    }

                    $result = Test-TargetResource @mockTestParametersTimeout

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When Test-TargetResource throws the exception SqlPowerShellSqlExecutionException when running the script in the TestFilePath parameter' {
            BeforeAll {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    throw New-Object -TypeName Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When Test-TargetResource throws an unexpected error when running the script in the TestFilePath parameter' {
            BeforeAll {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    throw 'Failed to run SQL Script'
                }
            }

            It 'Should throw the correct error from Invoke-Sqlcmd' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = 'Failed to run SQL Script'

                    { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }
    }
}
