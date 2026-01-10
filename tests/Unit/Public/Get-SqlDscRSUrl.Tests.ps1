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

Describe 'Get-SqlDscRSUrl' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            function script:Get-CimInstance
            {
                param
                (
                    [System.String]
                    $ClassName,

                    [System.String]
                    $Namespace,

                    [System.String]
                    $Filter,

                    [System.String]
                    $ErrorAction
                )

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        'StubNotImplemented',
                        'StubCalledError',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $MyInvocation.MyCommand
                    )
                )
            }
        }
    }

    AfterAll {
        InModuleScope -ScriptBlock {
            Remove-Item -Path 'function:script:Get-CimInstance' -Force
        }
    }

    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-SetupConfiguration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSUrl').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting Report Server URLs successfully' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject] @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                CurrentVersion = '15.0.1100.0'
            }

            $mockCimMethodResult = [PSCustomObject] @{
                ApplicationName = @('ReportServerWebService', 'ReportServerWebApp')
                URLs            = @('http://localhost:80/ReportServer', 'http://localhost:80/Reports')
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    InstanceId = 'SSRS'
                }
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return $mockCimMethodResult
            }
        }

        It 'Should return Report Server URLs' {
            $result = $mockSetupConfiguration | Get-SqlDscRSUrl

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $Namespace -eq 'root\Microsoft\SqlServer\ReportServer\RS_SSRS\v15' -and
                $ClassName -eq 'MSReportServer_Instance'
            } -Exactly -Times 1

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'GetReportServerUrls'
            } -Exactly -Times 1
        }

        It 'Should return ReportServerUri objects with correct properties' {
            $result = $mockSetupConfiguration | Get-SqlDscRSUrl

            $result[0].InstanceName | Should -Be 'SSRS'
            $result[0].ApplicationName | Should -Be 'ReportServerWebService'
            $result[0].Uri | Should -Be 'http://localhost:80/ReportServer'

            $result[1].InstanceName | Should -Be 'SSRS'
            $result[1].ApplicationName | Should -Be 'ReportServerWebApp'
            $result[1].Uri | Should -Be 'http://localhost:80/Reports'
        }
    }

    Context 'When an application has multiple URLs' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject] @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                CurrentVersion = '15.0.1100.0'
            }

            # When an application has multiple URLs, the ApplicationName appears multiple times
            # in the array with corresponding URLs at the same index
            $mockCimMethodResult = [PSCustomObject] @{
                ApplicationName = @('ReportServerWebService', 'ReportServerWebService')
                URLs            = @('http://localhost:80/ReportServer', 'https://localhost:443/ReportServer')
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    InstanceId = 'SSRS'
                }
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return $mockCimMethodResult
            }
        }

        It 'Should return all URLs for the application' {
            $result = $mockSetupConfiguration | Get-SqlDscRSUrl

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].Uri | Should -Be 'http://localhost:80/ReportServer'
            $result[1].Uri | Should -Be 'https://localhost:443/ReportServer'
            $result[0].ApplicationName | Should -Be 'ReportServerWebService'
            $result[1].ApplicationName | Should -Be 'ReportServerWebService'
        }
    }

    Context 'When no URLs are configured' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject] @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                CurrentVersion = '15.0.1100.0'
            }

            $mockCimMethodResult = [PSCustomObject] @{
                ApplicationName = @()
                URLs            = @()
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    InstanceId = 'SSRS'
                }
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return $mockCimMethodResult
            }
        }

        It 'Should return $null' {
            $result = $mockSetupConfiguration | Get-SqlDscRSUrl

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When CurrentVersion is null or empty' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject] @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                CurrentVersion = $null
            }
        }

        It 'Should throw a terminating error' {
            { $mockSetupConfiguration | Get-SqlDscRSUrl } | Should -Throw -ErrorId 'GSRSU0001,Get-SqlDscRSUrl'
        }
    }

    Context 'When Get-CimInstance fails' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject] @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                CurrentVersion = '15.0.1100.0'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                throw 'CIM instance not found'
            }
        }

        It 'Should throw a terminating error' {
            { $mockSetupConfiguration | Get-SqlDscRSUrl } | Should -Throw -ErrorId 'GSRSU0002,Get-SqlDscRSUrl'
        }
    }

    Context 'When Get-CimInstance returns null' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject] @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                CurrentVersion = '15.0.1100.0'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return $null
            }
        }

        It 'Should throw a terminating error' {
            { $mockSetupConfiguration | Get-SqlDscRSUrl } | Should -Throw -ErrorId 'GSRSU0003,Get-SqlDscRSUrl'
        }
    }

    Context 'When Invoke-RsCimMethod fails' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject] @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                CurrentVersion = '15.0.1100.0'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    InstanceId = 'SSRS'
                }
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method GetReportServerUrls() failed'
            }
        }

        It 'Should throw a terminating error' {
            { $mockSetupConfiguration | Get-SqlDscRSUrl } | Should -Throw -ErrorId 'GSRSU0004,Get-SqlDscRSUrl'
        }
    }

    Context 'When passing SetupConfiguration as parameter' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject] @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                CurrentVersion = '15.0.1100.0'
            }

            $mockCimMethodResult = [PSCustomObject] @{
                ApplicationName = @('ReportServerWebService')
                URLs            = @('http://localhost:80/ReportServer')
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    InstanceId = 'SSRS'
                }
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return $mockCimMethodResult
            }
        }

        It 'Should get Report Server URLs' {
            $result = Get-SqlDscRSUrl -SetupConfiguration $mockSetupConfiguration

            $result | Should -Not -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When processing multiple SetupConfigurations via pipeline' {
        BeforeAll {
            $mockSetupConfigurations = @(
                [PSCustomObject] @{
                    InstanceName   = 'SSRS'
                    InstanceId     = 'SSRS'
                    CurrentVersion = '15.0.1100.0'
                },
                [PSCustomObject] @{
                    InstanceName   = 'PBIRS'
                    InstanceId     = 'PBIRS'
                    CurrentVersion = '15.0.1100.0'
                }
            )

            $script:callCount = 0

            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    InstanceId = $Filter -replace "InstanceId='([^']+)'", '$1'
                }
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                $script:callCount++

                if ($script:callCount -eq 1)
                {
                    return [PSCustomObject] @{
                        ApplicationName = @('ReportServerWebService')
                        URLs            = @('http://localhost:80/ReportServer_SSRS')
                    }
                }
                else
                {
                    return [PSCustomObject] @{
                        ApplicationName = @('ReportServerWebService')
                        URLs            = @('http://localhost:80/ReportServer_PBIRS')
                    }
                }
            }
        }

        It 'Should return URLs for all instances' {
            $result = $mockSetupConfigurations | Get-SqlDscRSUrl

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2

            $result[0].InstanceName | Should -Be 'SSRS'
            $result[0].Uri | Should -Be 'http://localhost:80/ReportServer_SSRS'

            $result[1].InstanceName | Should -Be 'PBIRS'
            $result[1].Uri | Should -Be 'http://localhost:80/ReportServer_PBIRS'

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 2
            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 2
        }
    }
}
