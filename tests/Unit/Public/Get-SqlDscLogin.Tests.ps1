[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force

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

Describe 'Get-SqlDscLogin' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            MockExpectedParameters = '[-ServerObject] <Server> [[-Name] <string>] [-Refresh] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Get-SqlDscLogin').ParameterSets |
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

    It 'Should have the correct parameter metadata for ServerObject, Name, and Refresh' {
        $cmd = Get-Command -Name 'Get-SqlDscLogin'
        
        # Test ServerObject parameter
        $cmd.Parameters['ServerObject'].ParameterType.FullName | Should -Be 'Microsoft.SqlServer.Management.Smo.Server'
        $cmd.Parameters['ServerObject'].Attributes.Mandatory | Should -BeTrue
        $cmd.Parameters['ServerObject'].Attributes.ValueFromPipeline | Should -BeTrue
        
        # Test Name parameter
        $cmd.Parameters['Name'].ParameterType.FullName | Should -Be 'System.String'
        $cmd.Parameters['Name'].Attributes.Mandatory | Should -BeFalse
        
        # Test Refresh parameter
        $cmd.Parameters['Refresh'].ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter'
        $cmd.Parameters['Refresh'].Attributes.Mandatory | Should -BeFalse
    }

    Context 'When no login exists' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Logins' -Value {
                    return @{}
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'TestLogin'
            }
        }

        Context 'When specifying to throw on error' {
            BeforeAll {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Login_Get_Missing
                }
            }

            It 'Should throw the correct error' {
                { Get-SqlDscLogin @mockDefaultParameters -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'TestLogin')
            }
        }

        Context 'When ignoring the error' {
            It 'Should not throw an exception and return $null' {
                Get-SqlDscLogin @mockDefaultParameters -ErrorAction 'SilentlyContinue' |
                    Should -BeNullOrEmpty
            }
        }
    }

    Context 'When getting a specific login' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockServerObject = $mockServerObject |
                Add-Member -MemberType 'ScriptProperty' -Name 'Logins' -Value {
                    return @{
                        'TestLogin' = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @(
                            $mockServerObject,
                            'TestLogin'
                        )
                    }
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'TestLogin'
            }
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscLogin @mockDefaultParameters

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Login'
            $result.Name | Should -Be 'TestLogin'
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should return the correct values' {
                $result = $mockServerObject | Get-SqlDscLogin -Name 'TestLogin'

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Login'
                $result.Name | Should -Be 'TestLogin'
            }
        }
    }

    Context 'When getting all current logins' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockServerObject = $mockServerObject |
                Add-Member -MemberType 'ScriptProperty' -Name 'Logins' -Value {
                    return @(
                        (
                            New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @(
                                $mockServerObject,
                                'TestLogin1'
                            )
                        ),
                        (
                            New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @(
                                $mockServerObject,
                                'TestLogin2'
                            )
                        )
                    )
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
            }
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscLogin @mockDefaultParameters

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Login'
            $result | Should -HaveCount 2
            $result.Name | Should -Contain 'TestLogin1'
            $result.Name | Should -Contain 'TestLogin2'
        }
    }

    Context 'When using the Refresh parameter' {
        BeforeAll {
            $script:mockRefreshCallCount = 0

            $mockLoginsCollection = @{
                'TestLogin' = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @(
                    $null,
                    'TestLogin'
                )
            } |
                Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    $script:mockRefreshCallCount++
                } -PassThru -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockServerObject = $mockServerObject |
                Add-Member -MemberType 'ScriptProperty' -Name 'Logins' -Value {
                    return $mockLoginsCollection
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'TestLogin'
                Refresh = $true
            }
        }

        It 'Should call the Refresh method on the Logins collection' {
            Get-SqlDscLogin @mockDefaultParameters

            $script:mockRefreshCallCount | Should -Be 1
        }
    }
}
