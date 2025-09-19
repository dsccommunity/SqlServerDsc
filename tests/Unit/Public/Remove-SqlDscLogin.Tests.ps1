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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Remove-SqlDscLogin' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'ServerObject'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'LoginObject'
            MockExpectedParameters = '-LoginObject <Login> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Remove-SqlDscLogin').ParameterSets |
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

    It 'Should have the correct command metadata' {
        $command = Get-Command -Name 'Remove-SqlDscLogin'

        $cmdletBindingAttribute = $command.ScriptBlock.Attributes |
            Where-Object -FilterScript { $_ -is [System.Management.Automation.CmdletBindingAttribute] }

        $cmdletBindingAttribute.SupportsShouldProcess | Should -BeTrue
        $cmdletBindingAttribute.ConfirmImpact | Should -Be 'High'
    }

    It 'Should have correct parameter attributes for parameter set <ParameterSetName>' -ForEach @(
        @{
            ParameterSetName = 'ServerObject'
            ExpectedParameterTests = @(
                @{ ParameterName = 'ServerObject'; IsMandatory = $true; ValueFromPipeline = $true }
                @{ ParameterName = 'Name'; IsMandatory = $true; ValueFromPipeline = $false }
                @{ ParameterName = 'Refresh'; IsMandatory = $false; ValueFromPipeline = $false; ShouldExist = $true }
            )
        }
        @{
            ParameterSetName = 'LoginObject'
            ExpectedParameterTests = @(
                @{ ParameterName = 'LoginObject'; IsMandatory = $true; ValueFromPipeline = $true }
                @{ ParameterName = 'Refresh'; IsMandatory = $false; ValueFromPipeline = $false; ShouldExist = $false }
            )
        }
    ) {
        $command = Get-Command -Name 'Remove-SqlDscLogin'

        # Helper function to get parameter attribute for a specific parameter set
        $getParameterAttribute = {
            param($ParameterName, $ParameterSetName)

            $parameter = $command.Parameters[$ParameterName]
            if ($null -eq $parameter) {
                return $null
            }

            $parameterAttribute = $parameter.Attributes |
                Where-Object -FilterScript {
                    $_ -is [System.Management.Automation.ParameterAttribute] -and
                    ($_.ParameterSetName -eq $ParameterSetName -or $_.ParameterSetName -eq '__AllParameterSets')
                } |
                Select-Object -First 1

            return $parameterAttribute
        }

        foreach ($parameterTest in $ExpectedParameterTests) {
            $parameterAttribute = & $getParameterAttribute -ParameterName $parameterTest.ParameterName -ParameterSetName $ParameterSetName

            if ($parameterTest.ContainsKey('ShouldExist') -and $parameterTest.ShouldExist -eq $false) {
                $parameterAttribute | Should -BeNullOrEmpty -Because "Parameter '$($parameterTest.ParameterName)' should not exist in parameter set '$ParameterSetName'"
            } else {
                $parameterAttribute | Should -Not -BeNullOrEmpty -Because "Parameter '$($parameterTest.ParameterName)' should exist in parameter set '$ParameterSetName'"
                $parameterAttribute.Mandatory | Should -Be $parameterTest.IsMandatory -Because "Parameter '$($parameterTest.ParameterName)' mandatory setting should be $($parameterTest.IsMandatory) in parameter set '$ParameterSetName'"
                $parameterAttribute.ValueFromPipeline | Should -Be $parameterTest.ValueFromPipeline -Because "Parameter '$($parameterTest.ParameterName)' ValueFromPipeline setting should be $($parameterTest.ValueFromPipeline) in parameter set '$ParameterSetName'"
            }
        }
    }

    Context 'When removing a login by ServerObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            Mock -CommandName Get-SqlDscLogin -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @(
                    $mockServerObject,
                    'TestLogin'
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                        $script:mockMethodDropCallCount += 1
                    } -PassThru -Force
            }

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'TestLogin'
            }
        }

        BeforeEach {
            $script:mockMethodDropCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                Remove-SqlDscLogin -Confirm:$false @mockDefaultParameters

                $mockMethodDropCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                Remove-SqlDscLogin -Force @mockDefaultParameters

                $mockMethodDropCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                Remove-SqlDscLogin -WhatIf @mockDefaultParameters

                $mockMethodDropCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockServerObject | Remove-SqlDscLogin -Name 'TestLogin' -Force

                $mockMethodDropCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Refresh' {
            It 'Should call Get-SqlDscLogin with Refresh parameter' {
                $mockServerObject | Remove-SqlDscLogin -Name 'TestLogin' -Refresh -Force

                Should -Invoke -CommandName Get-SqlDscLogin -ParameterFilter {
                    $Refresh -eq $true
                }
            }
        }
    }

    Context 'When removing a login by LoginObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @(
                $mockServerObject,
                'TestLogin'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                    $script:mockMethodDropCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                LoginObject = $mockLoginObject
            }
        }

        BeforeEach {
            $script:mockMethodDropCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                Remove-SqlDscLogin -Confirm:$false @mockDefaultParameters

                $mockMethodDropCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                Remove-SqlDscLogin -Force @mockDefaultParameters

                $mockMethodDropCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                Remove-SqlDscLogin -WhatIf @mockDefaultParameters

                $mockMethodDropCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter LoginObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockLoginObject | Remove-SqlDscLogin -Force

                $mockMethodDropCallCount | Should -Be 1
            }
        }
    }

    Context 'When Drop() method throws an exception' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @(
                $mockServerObject,
                'TestLogin'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                    throw 'Mock drop exception'
                } -PassThru -Force

            $mockDefaultParameters = @{
                LoginObject = $mockLoginObject
            }
        }

        It 'Should throw the correct error when Drop() method fails' {
            { Remove-SqlDscLogin -Force @mockDefaultParameters } | Should -Throw -ExpectedMessage '*Removal of the login ''TestLogin'' failed*'
        }
    }
}
