[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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

    Import-Module -Name $script:dscModuleName

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

Describe 'Get-SqlDscConfigurationOption' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            MockExpectedParameters = '[-ServerObject] <Server> [[-Name] <string>] [-Refresh] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Get-SqlDscConfigurationOption').ParameterSets |
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

    Context 'When the specified configuration option exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Configuration' -Value {
                    return @{
                        Properties = @()
                    }
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Unknown Option Name'
            }
        }

        Context 'When specifying to throw on error' {
            BeforeAll {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.ConfigurationOption_Get_Missing
                }
            }

            It 'Should throw the correct error' {
                { Get-SqlDscConfigurationOption @mockDefaultParameters -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'Unknown Option Name')
            }
        }

        Context 'When ignoring the error' {
            It 'Should not throw an exception and return $null' {
                Get-SqlDscConfigurationOption @mockDefaultParameters -ErrorAction 'SilentlyContinue' |
                    Should -BeNullOrEmpty
            }
        }
    }

    Context 'When getting a specific configuration option' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Configuration' -Value {
                    $configOption1 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
                    $configOption1.DisplayName = 'blocked process threshold (s)'

                    return @{
                        Properties = @($configOption1)
                    }
                } -PassThru -Force
        }

        It 'Should return the correct values' {
            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'blocked process threshold (s)'
            }

            $result = Get-SqlDscConfigurationOption @mockDefaultParameters

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'

            $result.DisplayName | Should -Be 'blocked process threshold (s)'
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should return the correct values' {
                $result = $mockServerObject | Get-SqlDscConfigurationOption -Name 'blocked process threshold (s)'

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'

                $result.DisplayName | Should -Be 'blocked process threshold (s)'
            }
        }
    }

    Context 'When getting all available configuration options' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Configuration' -Value {
                    $configOption1 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
                    $configOption1.DisplayName = 'blocked process threshold (s)'

                    $configOption2 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
                    $configOption2.DisplayName = 'show advanced options'

                    return @{
                        Properties = @($configOption1, $configOption2)
                    }
                } -PassThru -Force
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscConfigurationOption -ServerObject $mockServerObject

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'

            $result.DisplayName | Should -Contain 'show advanced options'
            $result.DisplayName | Should -Contain 'blocked process threshold (s)'
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should return the correct values' {
                $result = $mockServerObject | Get-SqlDscConfigurationOption

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'

                $result.DisplayName | Should -Contain 'show advanced options'
                $result.DisplayName | Should -Contain 'blocked process threshold (s)'
            }
        }
    }
}
