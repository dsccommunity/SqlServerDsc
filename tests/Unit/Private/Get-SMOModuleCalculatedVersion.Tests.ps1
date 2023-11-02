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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Get-SMOModuleCalculatedVersion' -Tag 'Private' {
    Context 'When passing in SQLServer module' {
        It 'Should return the correct version' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $sqlServerModule = New-MockObject -Type 'PSModuleInfo' -Properties @{
                    Name = 'SqlServer'
                    Version = [Version]::new(21, 1, 18068)
                }

                $sqlServerModule | Get-SMOModuleCalculatedVersion | Should -Be '21.1.18068'
            }
        }

        Context 'When module is in pre-release' {
            It 'Should return the correct version' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $sqlServerModule = New-MockObject -Type 'PSModuleInfo' -Properties @{
                        Name = 'SqlServer'
                        Version = [Version]::new(22, 0, 49)
                        PrivateData = @{
                            PSData = @{
                                PreRelease = 'preview1'
                            }
                        }
                    }

                    $sqlServerModule | Get-SMOModuleCalculatedVersion | Should -Be '22.0.49-preview1'
                }
            }
        }
    }

    Context 'When passing in SQLPS module' {
        It 'Should return the correct version' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $sqlServerModule = New-MockObject -Type 'PSModuleInfo' -Properties @{
                    Name = 'SQLPS'
                    Path = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                }

                $sqlServerModule | Get-SMOModuleCalculatedVersion | Should -Be '13.0'
            }
        }
    }

    Context 'When passing in any other module' {
        It 'Should return the correct version' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $sqlServerModule = New-MockObject -Type 'PSModuleInfo' -Properties @{
                    Name = 'OtherModule'
                    Version = [Version]::new(1, 0, 0)
                }

                $sqlServerModule | Get-SMOModuleCalculatedVersion | Should -Be '1.0.0'
            }
        }

        Context 'When module is in pre-release' {
            It 'Should return the correct version' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $sqlServerModule = New-MockObject -Type 'PSModuleInfo' -Properties @{
                        Name = 'OtherModule'
                        Version = [Version]::new(1, 0, 0)
                        PrivateData = @{
                            PSData = @{
                                PreRelease = 'preview1'
                            }
                        }
                    }

                    $sqlServerModule | Get-SMOModuleCalculatedVersion | Should -Be '1.0.0-preview1'
                }
            }
        }
    }
}
