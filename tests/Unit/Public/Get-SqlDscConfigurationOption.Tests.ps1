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

    Context 'When the specified configuration option does not exist' {
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

    Context 'When testing argument completers through PowerShell tab completion system' {
        BeforeAll {
            # Import module to ensure tab completion is registered
            Import-Module -Name $script:dscModuleName -Force

            # Create mock server object for testing
            $script:mockServerForTabCompletion = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerForTabCompletion.Name = 'TestServer'

            # Create test configuration properties
            $mockConfigProperty1 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $mockConfigProperty1.DisplayName = 'max server memory (MB)'
            $mockConfigProperty1.ConfigValue = 2048
            $mockConfigProperty1.RunValue = 2048
            $mockConfigProperty1.Minimum = 0
            $mockConfigProperty1.Maximum = 2147483647

            $mockConfigProperty2 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $mockConfigProperty2.DisplayName = 'cost threshold for parallelism'
            $mockConfigProperty2.ConfigValue = 5
            $mockConfigProperty2.RunValue = 5
            $mockConfigProperty2.Minimum = 0
            $mockConfigProperty2.Maximum = 32767

            $mockConfigProperty3 = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $mockConfigProperty3.DisplayName = 'max degree of parallelism'
            $mockConfigProperty3.ConfigValue = 0
            $mockConfigProperty3.RunValue = 0
            $mockConfigProperty3.Minimum = 0
            $mockConfigProperty3.Maximum = 32767

            # Create configuration properties collection
            $mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $mockConfigurationProperties.Add($mockConfigProperty1)
            $mockConfigurationProperties.Add($mockConfigProperty2)
            $mockConfigurationProperties.Add($mockConfigProperty3)

            # Create configuration object
            $mockConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $mockConfiguration.Properties = $mockConfigurationProperties

            $script:mockServerForTabCompletion.Configuration = $mockConfiguration

            # Store the server object in a script variable that can be accessed by tab completion
            $global:TestServerObject = $script:mockServerForTabCompletion
        }

        AfterAll {
            # Clean up global variable
            if (Get-Variable -Name 'TestServerObject' -Scope Global -ErrorAction SilentlyContinue) {
                Remove-Variable -Name 'TestServerObject' -Scope Global -Force
            }
        }

        It 'Should provide Name parameter completions through TabExpansion2' {
            # This actually exercises the argument completer code through PowerShell's tab completion system
            $inputScript = 'Get-SqlDscConfigurationOption -ServerObject $global:TestServerObject -Name max'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            $result | Should -Not -BeNullOrEmpty
            $result.CompletionMatches | Should -Not -BeNullOrEmpty

            # Should find configuration options containing "max"
            $maxMemoryMatch = $result.CompletionMatches | Where-Object {
                $_.CompletionText -eq "'max server memory (MB)'"
            }
            $maxMemoryMatch | Should -Not -BeNullOrEmpty
            $maxMemoryMatch.ToolTip | Should -Match "Current: 2048"

            $maxDegreeMatch = $result.CompletionMatches | Where-Object {
                $_.CompletionText -eq "'max degree of parallelism'"
            }
            $maxDegreeMatch | Should -Not -BeNullOrEmpty
            $maxDegreeMatch.ToolTip | Should -Match "Current: 0"
        }

        It 'Should handle partial Name completions through TabExpansion2' {
            $inputScript = 'Get-SqlDscConfigurationOption -ServerObject $global:TestServerObject -Name cost'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            $result.CompletionMatches | Should -HaveCount 1
            $result.CompletionMatches[0].CompletionText | Should -Be "'cost threshold for parallelism'"
            $result.CompletionMatches[0].ToolTip | Should -Match "Current: 5"
        }

        It 'Should execute Name argument completer code when retrieving command metadata' {
            # This approach actually executes the argument completer code during command introspection
            $command = Get-Command -Name 'Get-SqlDscConfigurationOption'

            # Create a mock parameter set to trigger argument completer execution
            $parameterInfo = $command.Parameters['Name']
            $completerAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }

            # This executes the completer in the module's context
            $completions = & $completerAttribute.ScriptBlock 'Get-SqlDscConfigurationOption' 'Name' 'max' $null @{
                ServerObject = $script:mockServerForTabCompletion
            }

            $completions | Should -Not -BeNullOrEmpty
            $completions | Should -HaveCount 2

            $completions[0].CompletionText | Should -Be "'max degree of parallelism'"
            $completions[1].CompletionText | Should -Be "'max server memory (MB)'"
        }

        It 'Should return sorted completions' {
            $command = Get-Command -Name 'Get-SqlDscConfigurationOption'
            $parameterInfo = $command.Parameters['Name']
            $completerAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }

            $completions = & $completerAttribute.ScriptBlock 'Get-SqlDscConfigurationOption' 'Name' '' $null @{
                ServerObject = $script:mockServerForTabCompletion
            }

            $completions | Should -HaveCount 3
            # Should be sorted alphabetically by DisplayName
            $completions[0].CompletionText | Should -Be "'cost threshold for parallelism'"
            $completions[1].CompletionText | Should -Be "'max degree of parallelism'"
            $completions[2].CompletionText | Should -Be "'max server memory (MB)'"
        }

        It 'Should provide detailed tooltip information' {
            $command = Get-Command -Name 'Get-SqlDscConfigurationOption'
            $parameterInfo = $command.Parameters['Name']
            $completerAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }

            $completions = & $completerAttribute.ScriptBlock 'Get-SqlDscConfigurationOption' 'Name' 'max server' $null @{
                ServerObject = $script:mockServerForTabCompletion
            }

            $completions | Should -HaveCount 1
            $completion = $completions[0]
            $completion.ToolTip | Should -Match "Current: 2048"
            $completion.ToolTip | Should -Match "Run: 2048"
            $completion.ToolTip | Should -Match "Range: 0-2147483647"
        }

        It 'Should handle wildcard patterns in completions' {
            $command = Get-Command -Name 'Get-SqlDscConfigurationOption'
            $parameterInfo = $command.Parameters['Name']
            $completerAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }

            # Test with partial word that should match multiple options
            $completions = & $completerAttribute.ScriptBlock 'Get-SqlDscConfigurationOption' 'Name' 'parallel' $null @{
                ServerObject = $script:mockServerForTabCompletion
            }

            $completions | Should -HaveCount 2
            $completions[0].CompletionText | Should -Be "'cost threshold for parallelism'"
            $completions[1].CompletionText | Should -Be "'max degree of parallelism'"
        }

        It 'Should handle tab completion errors gracefully' {
            # Create a server object that will cause an error
            $badServer = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $badServer.Name = 'BadServer'
            Add-Member -InputObject $badServer -MemberType ScriptProperty -Name 'Configuration' -Value {
                throw 'Connection failed'
            } -Force
            $global:BadTestServerObject = $badServer

            $inputScript = 'Get-SqlDscConfigurationOption -ServerObject $global:BadTestServerObject -Name test'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            <#
                Should not throw an error and should return empty from argument completer, but then
                TabExpansion2 itself returns some default completions (like filesystem paths).
            #>
            $result | Should -BeOfType ([System.Management.Automation.CommandCompletion])
            $result.CompletionMatches.ListItemText | Should -Be 'tests'
        }

        It 'Should handle missing ServerObject in tab completion gracefully' {
            # Test tab completion without a ServerObject
            $inputScript = 'Get-SqlDscConfigurationOption -Name test'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            <#
                Should not throw an error and should return empty from argument completer, but then
                TabExpansion2 itself returns some default completions (like filesystem paths).
            #>
            $result | Should -BeOfType ([System.Management.Automation.CommandCompletion])
            $result.CompletionMatches.ListItemText | Should -Be 'tests'
        }

        It 'Should handle invalid ServerObject type gracefully' {
            # Test with wrong type of object
            $invalidServer = 'Not a server object'
            $global:InvalidTestServerObject = $invalidServer

            $inputScript = 'Get-SqlDscConfigurationOption -ServerObject $global:InvalidTestServerObject -Name test'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            <#
                Should not throw an error and should return empty from argument completer, but then
                TabExpansion2 itself returns some default completions (like filesystem paths).
            #>
            $result | Should -BeOfType ([System.Management.Automation.CommandCompletion])
            $result.CompletionMatches.ListItemText | Should -Be 'tests'
        }
    }
}
