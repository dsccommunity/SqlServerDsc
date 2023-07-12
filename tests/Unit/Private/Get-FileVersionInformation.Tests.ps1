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

Describe 'Get-FileVersionInformation' -Tag 'Private' {
    Context 'When passing path as string' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockFilePath = (New-Item -Path $TestDrive -Name 'setup.exe' -ItemType 'File' -Force).FullName
            }

            Mock -CommandName Get-Item -MockWith {
                return @{
                    VersionInfo = @{
                        ProductVersion = '16.0.1000.6'
                    }
                }
            }
        }

        Context 'When passing as a named parameter' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-FileVersionInformation -FilePath $mockFilePath

                    $result.ProductVersion | Should -Be '16.0.1000.6'
                }
            }
        }

        Context 'When passing over the pipeline' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = $mockFilePath | Get-FileVersionInformation

                    $result.ProductVersion | Should -Be '16.0.1000.6'
                }
            }
        }
    }

    Context 'When passing path as the type FileInfo' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockFilePath = (New-Item -Path $TestDrive -Name 'setup.exe' -ItemType 'File' -Force).FullName
            }

            Mock -CommandName Get-Item -MockWith {
                return @{
                    VersionInfo = @{
                        ProductVersion = '16.0.1000.6'
                    }
                }
            }
        }

        Context 'When passing as a named parameter' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-FileVersionInformation -FilePath $mockFilePath

                    $result.ProductVersion | Should -Be '16.0.1000.6'
                }
            }
        }

        Context 'When passing over the pipeline' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = $mockFilePath | Get-FileVersionInformation

                    $result.ProductVersion | Should -Be '16.0.1000.6'
                }
            }
        }
    }

    Context 'When passing in a [System.IO.FileInfo] that represents a directory' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { [System.IO.FileInfo] $TestDrive | Get-FileVersionInformation } |
                    Should -Throw -ExpectedMessage $script:localizedData.FileVersionInformation_Get_FilePathIsNotFile
            }
        }
    }

    Context 'When passing in a directory that was access from Get-Item' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-Item -Path $TestDrive | Get-FileVersionInformation -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage 'The input object cannot be bound to any parameters for the command*'
            }
        }
    }
}
