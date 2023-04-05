[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
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

Describe 'Get-SqlDscPreferredModule' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[[-Name] <string[]>] [-Refresh] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Get-SqlDscPreferredModule').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name       = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name       = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When no parameters are specified' {
        Context 'When none of the default preferred modules are installed' {
            Context 'When ErrorAction is set to SilentlyContinue' {
                BeforeAll {
                    Mock -CommandName Get-Module
                }

                It 'Should return $null' {
                    Get-SqlDscPreferredModule -ErrorAction 'SilentlyContinue' -ErrorVariable mockError | Should -BeNullOrEmpty

                    $mockError | Should -HaveCount 1
                }
            }

            Context 'When ErrorAction is set to Ignore' {
                BeforeAll {
                    Mock -CommandName Get-Module
                }

                It 'Should return $null' {
                    Get-SqlDscPreferredModule -ErrorAction 'Ignore' -ErrorVariable mockError | Should -BeNullOrEmpty

                    $mockError | Should -BeNullOrEmpty
                }
            }

            Context 'When ErrorAction is set to Stop' {
                BeforeAll {
                    Mock -CommandName Get-Module
                }

                It 'Should throw the correct error' {
                    $errorMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.PreferredModule_ModuleNotFound
                    }

                    { Get-SqlDscPreferredModule -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage $errorMessage
                }
            }
        }

        Context 'When only first default preferred module is installed' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'SqlServer'
                    }
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule | Should -Be 'SqlServer'
            }
        }

        Context 'When only second default preferred module is installed' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'SQLPS'
                        Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                    }
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS'
            }
        }

        Context 'When both default preferred modules are installed' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name = 'SqlServer'
                        }
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                    )
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule | Should -Be 'SqlServer'
            }
        }

        Context 'When there are several installed versions of all default preferred modules' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name    = 'SqlServer'
                            Version = '1.0.0'
                        }
                        @{
                            Name    = 'SqlServer'
                            Version = '2.0.0'
                        }
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\160\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                    )
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule | Should -Be 'SqlServer'
            }
        }

        Context 'When there are several installed versions of the first default preferred module' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name    = 'SqlServer'
                            Version = '1.0.0'
                        }
                        @{
                            Name    = 'SqlServer'
                            Version = '2.0.0'
                        }
                    )
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule | Should -Be 'SqlServer'
            }
        }

        Context 'When there are several installed versions of the second default preferred module' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\160\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                    )
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server\160\Tools\PowerShell\Modules\SQLPS'
            }
        }
    }

    Context 'When specifying preferred module' {
        Context 'When none of the preferred modules are installed' {
            Context 'When ErrorAction is set to SilentlyContinue' {
                BeforeAll {
                    Mock -CommandName Get-Module
                }

                It 'Should return $null' {
                    Get-SqlDscPreferredModule -Name 'SqlServer' -ErrorAction 'SilentlyContinue' -ErrorVariable mockError | Should -BeNullOrEmpty

                    $mockError | Should -HaveCount 1
                }
            }

            Context 'When ErrorAction is set to Ignore' {
                BeforeAll {
                    Mock -CommandName Get-Module
                }

                It 'Should return $null' {
                    Get-SqlDscPreferredModule -Name 'SqlServer' -ErrorAction 'Ignore' -ErrorVariable mockError | Should -BeNullOrEmpty

                    $mockError | Should -BeNullOrEmpty
                }
            }

            Context 'When ErrorAction is set to Stop' {
                BeforeAll {
                    Mock -CommandName Get-Module
                }

                It 'Should throw the correct error' {
                    $errorMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.PreferredModule_ModuleNotFound
                    }

                    { Get-SqlDscPreferredModule -Name 'SqlServer' -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage $errorMessage
                }
            }
        }

        Context 'When only first preferred module is installed' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'SqlServer'
                    }
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule -Name 'SqlServer' | Should -Be 'SqlServer'
            }
        }

        Context 'When only second preferred module is installed' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'SQLPS'
                        Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                    }
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule -Name @('SqlServer', 'SQLPS') | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS'
            }
        }

        Context 'When both preferred modules are installed' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name = 'SqlServer'
                        }
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                    )
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule -Name @('SqlServer', 'SQLPS') | Should -Be 'SqlServer'
            }
        }

        Context 'When there are several installed versions of all preferred modules' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name    = 'SqlServer'
                            Version = '1.0.0'
                        }
                        @{
                            Name    = 'SqlServer'
                            Version = '2.0.0'
                            PrivateData = @{
                                PSData = @{
                                    PreRelease = 'preview1'
                                }
                            }
                        }
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\160\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                    )
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule -Name @('SqlServer', 'SQLPS') | Should -Be 'SqlServer'
            }
        }

        Context 'When there are several installed versions of the first preferred module' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name    = 'SqlServer'
                            Version = '1.0.0'
                        }
                        @{
                            Name    = 'SqlServer'
                            Version = '2.0.0'
                        }
                    )
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule -Name @('SqlServer', 'SQLPS') | Should -Be 'SqlServer'
            }
        }

        Context 'When there are several installed versions of the second preferred module' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                        @{
                            Name = 'SQLPS'
                            Path = 'C:\Program Files (x86)\Microsoft SQL Server\160\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                        }
                    )
                }
            }

            It 'Should return the correct module name' {
                Get-SqlDscPreferredModule -Name @('SqlServer', 'SQLPS') | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server\160\Tools\PowerShell\Modules\SQLPS'
            }
        }
    }

    Context 'When specifying the parameter Refresh' {
        BeforeAll {
            Mock -CommandName Set-PSModulePath
            Mock -CommandName Get-Module -MockWith {
                return @{
                    Name = 'SqlServer'
                }
            }
        }

        It 'Should return the correct module name' {
            Get-SqlDscPreferredModule -Refresh | Should -Be 'SqlServer'

            Should -Invoke -CommandName Set-PSModulePath -Exactly -Times 1 -Scope It
        }
    }
}
