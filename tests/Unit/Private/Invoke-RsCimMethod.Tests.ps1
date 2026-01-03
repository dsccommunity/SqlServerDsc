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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    $env:SqlServerDscCI = $true

    InModuleScope -ScriptBlock {
        <#
            Stub for Invoke-CimMethod since it doesn't exist on macOS and
            we need to be able to mock it.
        #>
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
                $Arguments,

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
    $env:SqlServerDscCI = $null

    InModuleScope -ScriptBlock {
        Remove-Item -Path 'function:script:Invoke-CimMethod' -Force -ErrorAction SilentlyContinue
    }

    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}

Describe 'Invoke-RsCimMethod' -Tag 'Private' {
    Context 'When invoking a CIM method successfully' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }
        }

        It 'Should invoke the method without errors' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod'

                $result | Should -Not -BeNullOrEmpty
                $result.HRESULT | Should -Be 0
            }

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'TestMethod'
            } -Exactly -Times 1
        }

        It 'Should pass arguments to the CIM method' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'SetSecureConnectionLevel' -Arguments @{ Level = 1 }

                $result | Should -Not -BeNullOrEmpty
            }

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'SetSecureConnectionLevel' -and
                $Arguments.Level -eq 1
            } -Exactly -Times 1
        }
    }

    Context 'When CIM method fails with ExtendedErrors' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                $result = [PSCustomObject] @{
                    HRESULT = 1
                }
                $result | Add-Member -MemberType NoteProperty -Name 'ExtendedErrors' -Value @('Extended error message')
                return $result
            }
        }

        It 'Should throw with extended error message' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*TestMethod*Extended error message*HRESULT:1*'
            }
        }
    }

    Context 'When CIM method fails with Error property' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 2
                    Error   = 'Error property message'
                }
            }
        }

        It 'Should throw with error property message' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*TestMethod*Error property message*HRESULT:2*'
            }
        }
    }

    Context 'When CIM method returns a result with properties' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebService', 'ReportServerWebApp')
                    UrlString   = @('http://+:80/ReportServer', 'http://+:80/Reports')
                }
            }
        }

        It 'Should return the full result object' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'ListReservedUrls'

                $result | Should -Not -BeNullOrEmpty
                $result.Application | Should -HaveCount 2
                $result.Application[0] | Should -Be 'ReportServerWebService'
                $result.UrlString[0] | Should -Be 'http://+:80/ReportServer'
            }
        }
    }

    Context 'When CIM method fails with empty ExtendedErrors but has Error property' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                $result = [PSCustomObject] @{
                    HRESULT = 3
                    Error   = 'Fallback error message'
                }
                $result | Add-Member -MemberType NoteProperty -Name 'ExtendedErrors' -Value @()
                return $result
            }
        }

        It 'Should fall back to Error property message' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*TestMethod*Fallback error message*HRESULT:3*'
            }
        }
    }

    Context 'When CIM method fails with no error details available' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                $result = [PSCustomObject] @{
                    HRESULT = 4
                    Error   = ''
                }
                $result | Add-Member -MemberType NoteProperty -Name 'ExtendedErrors' -Value @()
                return $result
            }
        }

        It 'Should use fallback message when neither ExtendedErrors nor Error have content' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*TestMethod*No error details were returned*HRESULT:4*'
            }
        }
    }
}
