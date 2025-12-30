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

Describe 'Get-SqlDscAudit' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            MockExpectedParameters = '[-ServerObject] <Server> [[-Name] <string>] [-Refresh] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Get-SqlDscAudit').ParameterSets |
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

    Context 'When no audit exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Audits' -Value {
                    return @{}
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
            }
        }

        Context 'When specifying to throw on error' {
            BeforeAll {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Audit_Missing
                }
            }

            It 'Should throw the correct error' {
                { Get-SqlDscAudit @mockDefaultParameters -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'Log1')
            }
        }

        Context 'When ignoring the error' {
            It 'Should not throw an exception and return $null' {
                Get-SqlDscAudit @mockDefaultParameters -ErrorAction 'SilentlyContinue' |
                    Should -BeNullOrEmpty
            }
        }
    }

    Context 'When getting a specific audit' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockServerObject = $mockServerObject |
                Add-Member -MemberType 'ScriptProperty' -Name 'Audits' -Value {
                    return @{
                        'Log1' = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                            $mockServerObject,
                            'Log1'
                        )
                    }
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
            }
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscAudit @mockDefaultParameters

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
            $result.Name | Should -Be 'Log1'
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should return the correct values' {
                $result = $mockServerObject | Get-SqlDscAudit -Name 'Log1'

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
                $result.Name | Should -Be 'Log1'
            }
        }
    }

    Context 'When getting all current audits' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockServerObject = $mockServerObject |
                Add-Member -MemberType 'ScriptProperty' -Name 'Audits' -Value {
                    return @(
                        (
                            New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                                $mockServerObject,
                                'Log1'
                            )
                        ),
                        (
                            New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                                $mockServerObject,
                                'Log2'
                            )
                        )
                    )
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
            }
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscAudit @mockDefaultParameters

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
            $result | Should -HaveCount 2
            $result.Name | Should -Contain 'Log1'
            $result.Name | Should -Contain 'Log2'
        }
    }
}
