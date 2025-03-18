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

Describe 'Get-FileProductVersion' {
    Context 'When the file exists and has a product version' {
        BeforeAll {
            Mock -CommandName Get-Item -MockWith {
                return [PSCustomObject] @{
                    Exists      = $true
                    VersionInfo = [PSCustomObject] @{
                        ProductVersion = '15.0.2000.5'
                    }
                }
            }
        }

        It 'Should return the correct product version as a System.Version object' {
            InModuleScope -ScriptBlock {
                $result = Get-FileProductVersion -Path (Join-Path -Path $TestDrive -ChildPath 'testfile.dll')
                $result | Should -BeOfType [System.Version]
                $result.Major | Should -Be 15
                $result.Minor | Should -Be 0
                $result.Build | Should -Be 2000
                $result.Revision | Should -Be 5
            }
        }
    }

    Context 'When Get-Item throws an exception' {
        BeforeAll {
            Mock -CommandName Get-Item -MockWith {
                throw 'Mock exception message'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockFilePath = Join-Path -Path $TestDrive -ChildPath 'testfile.dll'
                $mockGetFileProductVersionErrorMessage = $script:localizedData.Get_FileProductVersion_GetFileProductVersionError -f $mockFilePath, 'Mock exception message'

                {
                    Get-FileProductVersion -Path $mockFilePath
                } | Should -Throw $mockGetFileProductVersionErrorMessage
            }
        }
    }
}
