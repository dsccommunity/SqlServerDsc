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

Describe 'Get-SqlDscRSConfiguration' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[-InstanceName] <string> [[-Version] <int>] [[-RetryCount] <int>] [[-RetryDelaySeconds] <int>] [-SkipRetry] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSConfiguration').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have RetryCount as a non-mandatory Int32 parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSConfiguration').Parameters['RetryCount']

            $parameterInfo.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeFalse

            $defaultValue = $parameterInfo.Attributes.Where({ $_ -is [System.Management.Automation.PSDefaultValueAttribute] }).Value

            # Check via reflection since default values are set in the param block
            $functionInfo = Get-Command -Name 'Get-SqlDscRSConfiguration'
            $functionInfo.Parameters['RetryCount'].ParameterType | Should -Be ([System.Int32])
        }

        It 'Should have RetryDelaySeconds as a non-mandatory Int32 parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSConfiguration').Parameters['RetryDelaySeconds']

            $parameterInfo.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeFalse
            $parameterInfo.ParameterType | Should -Be ([System.Int32])
        }

        It 'Should have SkipRetry as a switch parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSConfiguration').Parameters['SkipRetry']

            $parameterInfo.SwitchParameter | Should -BeTrue
        }
    }

    BeforeAll {
        InModuleScope -ScriptBlock {
            function script:Get-CimInstance
            {
                param
                (
                    [System.String]
                    $ClassName,

                    [System.String]
                    $Namespace
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

    Context 'When getting configuration with explicit version' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName                 = 'SSRS'
                DatabaseServerName           = 'localhost'
                SecureConnectionLevel        = 0
                VirtualDirectoryReportServer = 'ReportServer'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return $mockCimInstance
            }
        }

        It 'Should return the configuration CIM instance' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -Version 15

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'MSReportServer_ConfigurationSetting' -and
                $Namespace -eq 'root\Microsoft\SQLServer\ReportServer\RS_SSRS\v15\Admin'
            } -Exactly -Times 1
        }

        It 'Should not call Get-SqlDscRSSetupConfiguration' {
            Mock -CommandName Get-SqlDscRSSetupConfiguration

            $null = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -Version 15

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 0
        }
    }

    Context 'When getting configuration with auto-detected version' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'SSRS'
                DatabaseServerName    = 'localhost'
                SecureConnectionLevel = 1
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject] @{
                    InstanceName   = 'SSRS'
                    CurrentVersion = '15.0.1103.41'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return $mockCimInstance
            }
        }

        It 'Should auto-detect version and return configuration' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -ParameterFilter {
                $InstanceName -eq 'SSRS'
            } -Exactly -Times 1

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'MSReportServer_ConfigurationSetting' -and
                $Namespace -eq 'root\Microsoft\SQLServer\ReportServer\RS_SSRS\v15\Admin'
            } -Exactly -Times 1
        }
    }

    Context 'When instance is not found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return $null
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfiguration -InstanceName 'NonExistent' } | Should -Throw -ErrorId 'GSRSCD0001,Get-SqlDscRSConfiguration'
        }
    }

    Context 'When version cannot be determined' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject] @{
                    InstanceName   = 'SSRS'
                    CurrentVersion = $null
                }
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfiguration -InstanceName 'SSRS' } | Should -Throw -ErrorId 'GSRSCD0002,Get-SqlDscRSConfiguration'
        }
    }

    Context 'When Get-CimInstance fails' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject] @{
                    InstanceName   = 'SSRS'
                    CurrentVersion = '15.0.1103.41'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                throw 'CIM error'
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfiguration -InstanceName 'SSRS' } | Should -Throw -ErrorId 'GSRSCD0003,Get-SqlDscRSConfiguration'
        }
    }

    Context 'When configuration CIM instance is not found after filtering' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'OtherInstance'
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject] @{
                    InstanceName   = 'SSRS'
                    CurrentVersion = '15.0.1103.41'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return $mockCimInstance
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should throw a terminating error after retrying' {
            { Get-SqlDscRSConfiguration -InstanceName 'SSRS' } | Should -Throw -ErrorId 'GSRSCD0004,Get-SqlDscRSConfiguration'

            # Should retry once (default RetryCount = 1) plus initial attempt = 2 calls
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 2
            Should -Invoke -CommandName Start-Sleep -ParameterFilter {
                $Seconds -eq 30
            } -Exactly -Times 1
        }

        It 'Should throw immediately with -SkipRetry' {
            { Get-SqlDscRSConfiguration -InstanceName 'SSRS' -SkipRetry } | Should -Throw -ErrorId 'GSRSCD0004,Get-SqlDscRSConfiguration'

            # Should not retry
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0
        }
    }

    Context 'When configuration CIM instance is found on retry' {
        BeforeAll {
            $script:getCimInstanceCallCount = 0

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject] @{
                    InstanceName   = 'SSRS'
                    CurrentVersion = '15.0.1103.41'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                $script:getCimInstanceCallCount++

                if ($script:getCimInstanceCallCount -eq 1)
                {
                    # First call returns wrong instance
                    return [PSCustomObject] @{
                        InstanceName = 'OtherInstance'
                    }
                }

                # Second call returns correct instance
                return [PSCustomObject] @{
                    InstanceName          = 'SSRS'
                    DatabaseServerName    = 'localhost'
                    SecureConnectionLevel = 1
                }
            }

            Mock -CommandName Start-Sleep
        }

        AfterEach {
            $script:getCimInstanceCallCount = 0
        }

        It 'Should succeed on retry' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 2
            Should -Invoke -CommandName Start-Sleep -ParameterFilter {
                $Seconds -eq 30
            } -Exactly -Times 1
        }
    }

    Context 'When using custom retry parameters' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'OtherInstance'
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject] @{
                    InstanceName   = 'SSRS'
                    CurrentVersion = '15.0.1103.41'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return $mockCimInstance
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should retry the specified number of times with specified delay' {
            { Get-SqlDscRSConfiguration -InstanceName 'SSRS' -RetryCount 3 -RetryDelaySeconds 10 } | Should -Throw -ErrorId 'GSRSCD0004,Get-SqlDscRSConfiguration'

            # 1 initial + 3 retries = 4 calls
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 4
            Should -Invoke -CommandName Start-Sleep -ParameterFilter {
                $Seconds -eq 10
            } -Exactly -Times 3
        }
    }

    Context 'When getting PBIRS configuration' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'PBIRS'
                DatabaseServerName    = 'localhost\MSSQLSERVER'
                SecureConnectionLevel = 2
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return $mockCimInstance
            }
        }

        It 'Should return PBIRS configuration' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -Version 15

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $Namespace -eq 'root\Microsoft\SQLServer\ReportServer\RS_PBIRS\v15\Admin'
            } -Exactly -Times 1
        }
    }
}
