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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe 'Get-SqlDscConfigurationOption' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'Metadata'
            MockExpectedParameters = '-ServerObject <Server> [-Name <string>] [-Refresh] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'Raw'
            MockExpectedParameters = '-ServerObject <Server> [-Name <string>] [-Raw] [-Refresh] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Get-SqlDscConfigurationOption').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $MockParameterSetName
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
            $configOption1 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $configOption1.DisplayName = 'blocked process threshold (s)'
            $configOption1.RunValue = 10
            $configOption1.ConfigValue = 10
            $configOption1.Minimum = 0
            $configOption1.Maximum = 86400
            $configOption1.IsDynamic = $true

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Configuration' -Value {
                    return [PSCustomObject]@{
                        Properties = @($configOption1)
                        Refresh = { }
                    }
                } -PassThru -Force
        }

        It 'Should return the correct metadata values by default' {
            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'blocked process threshold (s)'
            }

            $result = Get-SqlDscConfigurationOption @mockDefaultParameters

            $result | Should -BeOfType 'PSCustomObject'
            $result.PSTypeNames[0] | Should -Be 'SqlDsc.ConfigurationOption'

            $result.Name | Should -Be 'blocked process threshold (s)'
            $result.RunValue | Should -Be 10
            $result.ConfigValue | Should -Be 10
            $result.Minimum | Should -Be 0
            $result.Maximum | Should -Be 86400
            $result.IsDynamic | Should -BeTrue
        }

        It 'Should return raw ConfigProperty when using -Raw switch' {
            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'blocked process threshold (s)'
                Raw = $true
            }

            $result = Get-SqlDscConfigurationOption @mockDefaultParameters

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'
            $result.DisplayName | Should -Be 'blocked process threshold (s)'
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should return the correct metadata values' {
                $result = $mockServerObject | Get-SqlDscConfigurationOption -Name 'blocked process threshold (s)'

                $result | Should -BeOfType 'PSCustomObject'
                $result.PSTypeNames[0] | Should -Be 'SqlDsc.ConfigurationOption'
                $result.Name | Should -Be 'blocked process threshold (s)'
            }

            It 'Should return raw ConfigProperty when using -Raw switch' {
                $result = $mockServerObject | Get-SqlDscConfigurationOption -Name 'blocked process threshold (s)' -Raw

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'
                $result.DisplayName | Should -Be 'blocked process threshold (s)'
            }
        }
    }

    Context 'When getting all available configuration options' {
        BeforeAll {
            $configOption1 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $configOption1.DisplayName = 'blocked process threshold (s)'
            $configOption1.RunValue = 10
            $configOption1.ConfigValue = 10
            $configOption1.Minimum = 0
            $configOption1.Maximum = 86400
            $configOption1.IsDynamic = $true

            $configOption2 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $configOption2.DisplayName = 'show advanced options'
            $configOption2.RunValue = 1
            $configOption2.ConfigValue = 1
            $configOption2.Minimum = 0
            $configOption2.Maximum = 1
            $configOption2.IsDynamic = $true

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Configuration' -Value {
                    $properties = @($configOption1, $configOption2)
                    return [PSCustomObject]@{
                        Properties = $properties
                        Refresh = { }
                    } | Add-Member -MemberType ScriptMethod -Name 'ForEach' -Value { param($script) & $script } -PassThru
                } -PassThru -Force
        }

        It 'Should return the correct metadata values by default' {
            $result = Get-SqlDscConfigurationOption -ServerObject $mockServerObject

            $result | Should -BeOfType 'PSCustomObject'
            $result | Should -HaveCount 2
            $result[0].PSTypeNames[0] | Should -Be 'SqlDsc.ConfigurationOption'

            $result.Name | Should -Contain 'show advanced options'
            $result.Name | Should -Contain 'blocked process threshold (s)'
        }

        It 'Should return raw ConfigProperty objects when using -Raw switch' {
            $result = Get-SqlDscConfigurationOption -ServerObject $mockServerObject -Raw

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'
            $result | Should -HaveCount 2
            $result.DisplayName | Should -Contain 'show advanced options'
            $result.DisplayName | Should -Contain 'blocked process threshold (s)'
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should return the correct metadata values' {
                $result = $mockServerObject | Get-SqlDscConfigurationOption

                $result | Should -BeOfType 'PSCustomObject'
                $result | Should -HaveCount 2
                $result[0].PSTypeNames[0] | Should -Be 'SqlDsc.ConfigurationOption'

                $result.Name | Should -Contain 'show advanced options'
                $result.Name | Should -Contain 'blocked process threshold (s)'
            }

            It 'Should return raw ConfigProperty objects when using -Raw switch' {
                $result = $mockServerObject | Get-SqlDscConfigurationOption -Raw

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'
                $result | Should -HaveCount 2
                $result.DisplayName | Should -Contain 'show advanced options'
                $result.DisplayName | Should -Contain 'blocked process threshold (s)'
            }
        }
    }
}
