[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Assert-ManagedServiceType' -Tag 'Private' {
    Context 'When types match' {
        BeforeAll {
            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.Type = 'SqlServer'

            Mock -CommandName ConvertFrom-ManagedServiceType -MockWith {
                return 'DatabaseEngine'
            }
        }

        It 'Should not throw an exception' {
            $_.MockServiceObject = $mockServiceObject

            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $null = $MockServiceObject |
                    Assert-ManagedServiceType -ServiceType 'DatabaseEngine' -ErrorAction 'Stop'
            }
        }
    }

    Context 'When the types mismatch' {
        BeforeAll {
            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.Type = 'SqlServer'

            Mock -CommandName ConvertFrom-ManagedServiceType -MockWith {
                return 'DatabaseEngine'
            }
        }

        Context 'When passing Stop for parameter ErrorAction' {
            It 'Should throw the correct error' {
                $_.MockServiceObject = $mockServiceObject

                InModuleScope -Parameter $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.ManagedServiceType_Assert_WrongServiceType -f 'SqlServerAgent', 'DatabaseEngine'

                    {
                        $MockServiceObject |
                            Assert-ManagedServiceType -ServiceType 'SqlServerAgent' -ErrorAction 'Stop'
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When passing SilentlyContinue for parameter ErrorAction' {
            It 'Should still throw a termination error' {
                $_.MockServiceObject = $mockServiceObject

                InModuleScope -Parameter $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.ManagedServiceType_Assert_WrongServiceType -f 'SqlServerAgent', 'DatabaseEngine'

                    {
                        $MockServiceObject |
                            Assert-ManagedServiceType -ServiceType 'SqlServerAgent' -ErrorAction 'SilentlyContinue'
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }
    }
}
