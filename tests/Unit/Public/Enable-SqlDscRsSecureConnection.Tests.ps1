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

Describe 'Enable-SqlDscRsSecureConnection' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            function script:Invoke-CimMethod
            {
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    [System.Object]
                    $InputObject,

                    [System.String]
                    $MethodName,

                    [System.Collections.Hashtable]
                    $Arguments
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
            Remove-Item -Path 'function:script:Invoke-CimMethod' -Force
        }
    }

    Context 'When enabling secure connection successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'SSRS'
                SecureConnectionLevel = 0
            }

            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }
        }

        It 'Should enable secure connection without errors' {
            { $mockCimInstance | Enable-SqlDscRsSecureConnection -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'SetSecureConnectionLevel' -and
                $Arguments.Level -eq 1
            } -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Enable-SqlDscRsSecureConnection -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When enabling secure connection with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'SSRS'
                SecureConnectionLevel = 0
            }

            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Enable-SqlDscRsSecureConnection -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When enabling secure connection with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'SSRS'
                SecureConnectionLevel = 0
            }

            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }
        }

        It 'Should enable secure connection without confirmation' {
            { $mockCimInstance | Enable-SqlDscRsSecureConnection -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails with ExtendedErrors' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'SSRS'
                SecureConnectionLevel = 0
            }

            Mock -CommandName Invoke-CimMethod -MockWith {
                $result = [PSCustomObject] @{
                    HRESULT        = -2147024891
                    ExtendedErrors = @('Access denied', 'Permission error')
                }
                $result | Add-Member -MemberType ScriptMethod -Name 'GetType' -Value { return [PSCustomObject] @{ Name = 'CimMethodResult' } } -Force
                return $result
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Enable-SqlDscRsSecureConnection -Confirm:$false } | Should -Throw -ErrorId 'ESRSSC0001,Enable-SqlDscRsSecureConnection'
        }
    }

    Context 'When CIM method fails with Error property' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'SSRS'
                SecureConnectionLevel = 0
            }

            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = -2147024891
                    Error   = 'Access denied'
                }
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Enable-SqlDscRsSecureConnection -Confirm:$false } | Should -Throw -ErrorId 'ESRSSC0001,Enable-SqlDscRsSecureConnection'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'SSRS'
                SecureConnectionLevel = 0
            }

            Mock -CommandName Invoke-CimMethod
        }

        It 'Should not call Invoke-CimMethod' {
            $mockCimInstance | Enable-SqlDscRsSecureConnection -WhatIf

            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName          = 'SSRS'
                SecureConnectionLevel = 0
            }

            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }
        }

        It 'Should enable secure connection' {
            { Enable-SqlDscRsSecureConnection -Configuration $mockCimInstance -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1
        }
    }
}
