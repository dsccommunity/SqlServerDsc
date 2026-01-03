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

Describe 'Add-SqlDscRSUrlReservation' {
    BeforeAll {
        Mock -CommandName Get-OperatingSystem -MockWith {
            return [PSCustomObject] @{
                OSLanguage = 1033
            }
        }
    }

    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-Application] <string> [-UrlString] <string> [[-Lcid] <int>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Add-SqlDscRSUrlReservation').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When adding URL reservation successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should add URL reservation without errors' {
            { $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ReserveUrl' -and
                $Arguments.Application -eq 'ReportServerWebService' -and
                $Arguments.UrlString -eq 'http://+:80' -and
                $Arguments.Lcid -eq 1033
            } -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When adding URL reservation with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When adding URL reservation with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should add URL reservation without confirmation' {
            { $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When adding URL reservation with custom Lcid' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should use the specified Lcid' {
            { $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Lcid 1031 -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.Lcid -eq 1031
            } -Exactly -Times 1
        }

        It 'Should not call Get-OperatingSystem when Lcid is specified' {
            $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Lcid 1031 -Confirm:$false

            Should -Invoke -CommandName Get-OperatingSystem -Exactly -Times 0
        }
    }

    Context 'When CIM method fails with ExtendedErrors' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method ReserveUrl() failed with an error. Error: Access denied;Permission error (HRESULT:-2147024891)'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Confirm:$false } | Should -Throw -ErrorId 'ASRUR0001,Add-SqlDscRSUrlReservation'
        }
    }

    Context 'When CIM method fails with Error property' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method ReserveUrl() failed with an error. Error: Access denied (HRESULT:-2147024891)'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Confirm:$false } | Should -Throw -ErrorId 'ASRUR0001,Add-SqlDscRSUrlReservation'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should not call Invoke-RsCimMethod' {
            $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should add URL reservation' {
            { Add-SqlDscRSUrlReservation -Configuration $mockCimInstance -Application 'ReportServerWebService' -UrlString 'http://+:80' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When using different application types' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should accept ReportServerWebApp application' {
            { $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportServerWebApp' -UrlString 'http://+:80' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.Application -eq 'ReportServerWebApp'
            } -Exactly -Times 1
        }

        It 'Should accept ReportManager application' {
            { $mockCimInstance | Add-SqlDscRSUrlReservation -Application 'ReportManager' -UrlString 'http://+:80' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.Application -eq 'ReportManager'
            } -Exactly -Times 1
        }
    }
}
