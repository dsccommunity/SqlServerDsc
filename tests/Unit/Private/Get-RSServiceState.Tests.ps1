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

Describe 'Get-RSServiceState' {
    Context 'When getting service state with EnableWindowsService' {
        It 'Should return EnableWindowsService as $true and preserve current web service state' {
            InModuleScope -ScriptBlock {
                $mockConfiguration = [PSCustomObject] @{
                    InstanceName            = 'SSRS'
                    IsWindowsServiceEnabled = $false
                    IsWebServiceEnabled     = $true
                }

                $result = Get-RSServiceState -Configuration $mockConfiguration -EnableWindowsService

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.EnableWindowsService | Should -BeTrue
                $result.EnableWebService | Should -BeTrue
                $result.EnableReportManager | Should -BeTrue
            }
        }
    }

    Context 'When getting service state with DisableWindowsService' {
        It 'Should return EnableWindowsService as $false and preserve current web service state' {
            InModuleScope -ScriptBlock {
                $mockConfiguration = [PSCustomObject] @{
                    InstanceName            = 'SSRS'
                    IsWindowsServiceEnabled = $true
                    IsWebServiceEnabled     = $true
                }

                $result = Get-RSServiceState -Configuration $mockConfiguration -DisableWindowsService

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.EnableWindowsService | Should -BeFalse
                $result.EnableWebService | Should -BeTrue
                $result.EnableReportManager | Should -BeTrue
            }
        }
    }

    Context 'When getting service state with EnableWebService' {
        It 'Should return EnableWebService as $true and preserve current Windows service state' {
            InModuleScope -ScriptBlock {
                $mockConfiguration = [PSCustomObject] @{
                    InstanceName            = 'SSRS'
                    IsWindowsServiceEnabled = $true
                    IsWebServiceEnabled     = $false
                }

                $result = Get-RSServiceState -Configuration $mockConfiguration -EnableWebService

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.EnableWindowsService | Should -BeTrue
                $result.EnableWebService | Should -BeTrue
                $result.EnableReportManager | Should -BeTrue
            }
        }
    }

    Context 'When getting service state with DisableWebService' {
        It 'Should return EnableWebService as $false and preserve current Windows service state' {
            InModuleScope -ScriptBlock {
                $mockConfiguration = [PSCustomObject] @{
                    InstanceName            = 'SSRS'
                    IsWindowsServiceEnabled = $true
                    IsWebServiceEnabled     = $true
                }

                $result = Get-RSServiceState -Configuration $mockConfiguration -DisableWebService

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.EnableWindowsService | Should -BeTrue
                $result.EnableWebService | Should -BeFalse
                $result.EnableReportManager | Should -BeFalse
            }
        }
    }

    Context 'When getting service state without any switch parameters' {
        It 'Should preserve all current states' {
            InModuleScope -ScriptBlock {
                $mockConfiguration = [PSCustomObject] @{
                    InstanceName            = 'SSRS'
                    IsWindowsServiceEnabled = $true
                    IsWebServiceEnabled     = $false
                }

                $result = Get-RSServiceState -Configuration $mockConfiguration

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.EnableWindowsService | Should -BeTrue
                $result.EnableWebService | Should -BeFalse
                $result.EnableReportManager | Should -BeFalse
            }
        }
    }

    Context 'When both services are disabled and enabling Windows service' {
        It 'Should only enable Windows service' {
            InModuleScope -ScriptBlock {
                $mockConfiguration = [PSCustomObject] @{
                    InstanceName            = 'SSRS'
                    IsWindowsServiceEnabled = $false
                    IsWebServiceEnabled     = $false
                }

                $result = Get-RSServiceState -Configuration $mockConfiguration -EnableWindowsService

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.EnableWindowsService | Should -BeTrue
                $result.EnableWebService | Should -BeFalse
                $result.EnableReportManager | Should -BeFalse
            }
        }
    }

    Context 'When both services are enabled and disabling web service' {
        It 'Should only disable web service' {
            InModuleScope -ScriptBlock {
                $mockConfiguration = [PSCustomObject] @{
                    InstanceName            = 'SSRS'
                    IsWindowsServiceEnabled = $true
                    IsWebServiceEnabled     = $true
                }

                $result = Get-RSServiceState -Configuration $mockConfiguration -DisableWebService

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.EnableWindowsService | Should -BeTrue
                $result.EnableWebService | Should -BeFalse
                $result.EnableReportManager | Should -BeFalse
            }
        }
    }
}
