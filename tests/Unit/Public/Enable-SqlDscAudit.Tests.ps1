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

Describe 'Enable-SqlDscAudit' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'ServerObject'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'AuditObject'
            MockExpectedParameters = '-AuditObject <Audit> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Enable-SqlDscAudit').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When enabling an audit by ServerObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            Mock -CommandName Get-SqlDscAudit -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $mockServerObject,
                    'Log1'
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Enable' -Value {
                        $script:mockMethodEnableCallCount += 1
                    } -PassThru -Force
            }

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
            }
        }

        BeforeEach {
            $script:mockMethodEnableCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                Enable-SqlDscAudit -Confirm:$false @mockDefaultParameters

                $mockMethodEnableCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                Enable-SqlDscAudit -Force @mockDefaultParameters

                $mockMethodEnableCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                Enable-SqlDscAudit -WhatIf @mockDefaultParameters

                $mockMethodEnableCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockServerObject | Enable-SqlDscAudit -Name 'Log1' -Force

                $mockMethodEnableCallCount | Should -Be 1
            }
        }
    }

    Context 'When removing an audit by AuditObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Enable' -Value {
                    $script:mockMethodEnableCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
            }
        }

        BeforeEach {
            $script:mockMethodEnableCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                Enable-SqlDscAudit -Confirm:$false @mockDefaultParameters

                $mockMethodEnableCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                Enable-SqlDscAudit -Force @mockDefaultParameters

                $mockMethodEnableCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                Enable-SqlDscAudit -WhatIf @mockDefaultParameters

                $mockMethodEnableCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockAuditObject | Enable-SqlDscAudit -Force

                $mockMethodEnableCallCount | Should -Be 1
            }
        }
    }
}
