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

Describe 'Get-SqlDscRSUrlReservation' {
    BeforeAll {
        $mockCimInstance = [PSCustomObject] @{
            InstanceName = 'SSRS'
        }
    }

    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSUrlReservation').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting URL reservations successfully' {
        BeforeAll {
            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebService', 'ReportServerWebApp')
                    UrlString   = @('http://+:80', 'http://+:80')
                }
            }
        }

        It 'Should return URL reservations without errors' {
            $result = $mockCimInstance | Get-SqlDscRSUrlReservation

            $result | Should -Not -BeNullOrEmpty
            $result.Application | Should -HaveCount 2
            $result.UrlString | Should -HaveCount 2

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ListReservedUrls'
            } -Exactly -Times 1
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebService')
                    UrlString   = @('http://+:80')
                }
            }
        }

        It 'Should get URL reservations' {
            $result = Get-SqlDscRSUrlReservation -Configuration $mockCimInstance

            $result | Should -Not -BeNullOrEmpty
            $result.Application | Should -Contain 'ReportServerWebService'

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails with ExtendedErrors' {
        BeforeAll {
            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method ListReservedUrls() failed with an error. Error: Access denied;Permission error (HRESULT:-2147024891)'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Get-SqlDscRSUrlReservation } | Should -Throw -ErrorId 'GSRUR0001,Get-SqlDscRSUrlReservation'
        }
    }

    Context 'When CIM method fails with Error property' {
        BeforeAll {
            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method ListReservedUrls() failed with an error. Error: Access denied (HRESULT:-2147024891)'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Get-SqlDscRSUrlReservation } | Should -Throw -ErrorId 'GSRUR0001,Get-SqlDscRSUrlReservation'
        }
    }
}
