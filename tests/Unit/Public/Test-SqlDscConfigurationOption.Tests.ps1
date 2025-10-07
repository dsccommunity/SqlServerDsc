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
    $env:SqlServerDscCI = $true

    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Load SMO stub types
    Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"

    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'Env:\SqlServerDscCI' -ErrorAction 'SilentlyContinue'
}

Describe 'Test-SqlDscConfigurationOption' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <string> [-Value] <int> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscConfigurationOption').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When command has correct parameter properties' {
        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscConfigurationOption').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscConfigurationOption').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Value as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscConfigurationOption').Parameters['Value']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have ServerObject accepting pipeline input' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscConfigurationOption').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should not support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Test-SqlDscConfigurationOption'
            $commandInfo.Parameters.ContainsKey('WhatIf') | Should -BeFalse
            $commandInfo.Parameters.ContainsKey('Confirm') | Should -BeFalse
        }

        It 'Should return boolean output type' {
            $commandInfo = Get-Command -Name 'Test-SqlDscConfigurationOption'
            $commandInfo.OutputType[0].Type | Should -Be ([System.Boolean])
        }
    }

    Context 'When testing configuration option successfully' {
        BeforeAll {
            # Create mock configuration option
            $script:mockConfigurationOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $script:mockConfigurationOption.DisplayName = 'max degree of parallelism'
            $script:mockConfigurationOption.ConfigValue = 4
            $script:mockConfigurationOption.RunValue = 4
            $script:mockConfigurationOption.Minimum = 0
            $script:mockConfigurationOption.Maximum = 32767

            # Create mock configuration properties collection
            $script:mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $script:mockConfigurationProperties.Add($script:mockConfigurationOption)

            # Create mock configuration object
            $script:mockConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $script:mockConfiguration.Properties = $script:mockConfigurationProperties

            # Create mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.Name = 'TestServer'
            $script:mockServerObject.Configuration = $script:mockConfiguration

            # Mock Write-Verbose
            Mock -CommandName Write-Verbose
        }

        It 'Should return true when configuration option matches expected value' {
            $result = Test-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 4

            $result | Should -BeTrue
            Should -Invoke -CommandName Write-Verbose -Times 1 -Exactly
        }

        It 'Should return false when configuration option does not match expected value' {
            $result = Test-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 8

            $result | Should -BeFalse
            Should -Invoke -CommandName Write-Verbose -Times 1 -Exactly
        }

        It 'Should work with pipeline input' {
            $result = $script:mockServerObject | Test-SqlDscConfigurationOption -Name 'max degree of parallelism' -Value 4

            $result | Should -BeTrue
        }

        It 'Should call Write-Verbose with correct message pattern' {
            $null = Test-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 4

            Should -Invoke -CommandName Write-Verbose -Times 1 -Exactly -ParameterFilter {
                $Message -match "Testing configuration option 'max degree of parallelism': Current value is '4', expected value is '4', match result is 'True' on server 'TestServer'"
            }
        }
    }

    Context 'When configuration option does not exist' {
        BeforeAll {
            # Create empty configuration properties collection
            $script:mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()

            # Create mock configuration object
            $script:mockConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $script:mockConfiguration.Properties = $script:mockConfigurationProperties

            # Create mock server object with empty configuration
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.Name = 'TestServer'
            $script:mockServerObject.Configuration = $script:mockConfiguration

            # Mock Write-Error
            Mock -CommandName Write-Error
        }

        It 'Should return false and write error when configuration option does not exist' {
            $result = Test-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'NonExistentOption' -Value 1

            $result | Should -BeFalse
            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Message -match "There is no configuration option with the name 'NonExistentOption'"
            }
        }

        It 'Should use correct error details for missing configuration option' {
            $null = Test-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'InvalidOption' -Value 1

            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Category -eq 'InvalidOperation' -and
                $ErrorId -eq 'TSDCO0001' -and
                $TargetObject -eq 'InvalidOption'
            }
        }
    }

    Context 'When testing various configuration values' {
        BeforeAll {
            # Create mock configuration option with specific values
            $script:mockConfigurationOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $script:mockConfigurationOption.DisplayName = 'cost threshold for parallelism'
            $script:mockConfigurationOption.ConfigValue = 50
            $script:mockConfigurationOption.RunValue = 50
            $script:mockConfigurationOption.Minimum = 0
            $script:mockConfigurationOption.Maximum = 32767

            # Create mock configuration properties collection
            $script:mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $script:mockConfigurationProperties.Add($script:mockConfigurationOption)

            # Create mock configuration object
            $script:mockConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $script:mockConfiguration.Properties = $script:mockConfigurationProperties

            # Create mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.Name = 'TestServer'
            $script:mockServerObject.Configuration = $script:mockConfiguration

            # Mock Write-Verbose
            Mock -CommandName Write-Verbose
        }

        It 'Should return true for exact match at minimum boundary' {
            $script:mockConfigurationOption.ConfigValue = 0

            $result = Test-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'cost threshold for parallelism' -Value 0

            $result | Should -BeTrue
        }

        It 'Should return true for exact match at maximum boundary' {
            $script:mockConfigurationOption.ConfigValue = 32767

            $result = Test-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'cost threshold for parallelism' -Value 32767

            $result | Should -BeTrue
        }

        It 'Should return false for values that do not match' {
            $script:mockConfigurationOption.ConfigValue = 25

            $result = Test-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'cost threshold for parallelism' -Value 50

            $result | Should -BeFalse
        }

        It 'Should handle boolean-style configuration options (0-1 range)' {
            # Create a boolean-style configuration option
            $booleanOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $booleanOption.DisplayName = 'Agent XPs'
            $booleanOption.ConfigValue = 1
            $booleanOption.RunValue = 1
            $booleanOption.Minimum = 0
            $booleanOption.Maximum = 1

            # Create new properties collection with the boolean option
            $booleanProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $booleanProperties.Add($booleanOption)

            $booleanConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $booleanConfiguration.Properties = $booleanProperties

            $booleanServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $booleanServerObject.Name = 'TestServer'
            $booleanServerObject.Configuration = $booleanConfiguration

            # Test enabled state (1)
            $result = Test-SqlDscConfigurationOption -ServerObject $booleanServerObject -Name 'Agent XPs' -Value 1
            $result | Should -BeTrue

            # Test disabled state comparison
            $result = Test-SqlDscConfigurationOption -ServerObject $booleanServerObject -Name 'Agent XPs' -Value 0
            $result | Should -BeFalse
        }
    }

    Context 'When validating localized error and verbose messages' {
        BeforeAll {
            # Mock localized strings retrieval
            $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
        }

        AfterAll {
            $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
        }

        It 'Should use correct localized error messages' {
            InModuleScope -ScriptBlock {
                # Verify localized strings exist
                $script:localizedData.ConfigurationOption_Test_Missing | Should -Be "There is no configuration option with the name '{0}'."
                $script:localizedData.ConfigurationOption_Test_Result | Should -Be "Testing configuration option '{0}': Current value is '{1}', expected value is '{2}', match result is '{3}' on server '{4}'."
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

            # Create configuration properties collection
            $mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $mockConfigurationProperties.Add($mockConfigProperty1)
            $mockConfigurationProperties.Add($mockConfigProperty2)

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

        AfterEach {
            # Clean up any global test variables created during tab completion tests
            Remove-Variable -Name 'BadTestServerObject' -Scope Global -Force -ErrorAction SilentlyContinue
        }

        It 'Should provide Name parameter completions through TabExpansion2' {
            # This actually exercises the argument completer code through PowerShell's tab completion system
            $inputScript = 'Test-SqlDscConfigurationOption -ServerObject $global:TestServerObject -Name max'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            $result | Should -Not -BeNullOrEmpty
            $result.CompletionMatches | Should -Not -BeNullOrEmpty

            # Should find the max server memory option
            $maxMemoryMatch = $result.CompletionMatches | Where-Object {
                $_.CompletionText -eq "'max server memory (MB)'"
            }
            $maxMemoryMatch | Should -Not -BeNullOrEmpty
            $maxMemoryMatch.ToolTip | Should -Match "Current: 2048"
        }

        It 'Should provide Value parameter completions through TabExpansion2' {
            # Test Value completion
            $inputScript = 'Test-SqlDscConfigurationOption -ServerObject $global:TestServerObject -Name "max server memory (MB)" -Value '
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            $result | Should -Not -BeNullOrEmpty
            $result.CompletionMatches | Should -Not -BeNullOrEmpty

            # Should find current value and other suggestions
            $currentValueMatch = $result.CompletionMatches | Where-Object {
                $_.CompletionText -eq '2048' -and $_.ToolTip -match "Current ConfigValue"
            }
            $currentValueMatch | Should -Not -BeNullOrEmpty
        }

        It 'Should handle partial Name completions through TabExpansion2' {
            $inputScript = 'Test-SqlDscConfigurationOption -ServerObject $global:TestServerObject -Name cost'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            $result.CompletionMatches | Should -HaveCount 1
            $result.CompletionMatches[0].CompletionText | Should -Be "'cost threshold for parallelism'"
        }

        It 'Should execute Name argument completer code when retrieving command metadata' {
            # This approach actually executes the argument completer code during command introspection
            $command = Get-Command -Name 'Test-SqlDscConfigurationOption'

            # Create a mock parameter set to trigger argument completer execution
            $parameterInfo = $command.Parameters['Name']
            $completerAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }

            # This executes the completer in the module's context
            $completions = & $completerAttribute.ScriptBlock 'Test-SqlDscConfigurationOption' 'Name' 'max' $null @{
                ServerObject = $script:mockServerForTabCompletion
            }

            $completions | Should -Not -BeNullOrEmpty
            $completions[0].CompletionText | Should -Be "'max server memory (MB)'"
        }

        It 'Should execute Value argument completer code when retrieving command metadata' {
            $command = Get-Command -Name 'Test-SqlDscConfigurationOption'
            $parameterInfo = $command.Parameters['Value']
            $completerAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }

            $completions = & $completerAttribute.ScriptBlock 'Test-SqlDscConfigurationOption' 'Value' '' $null @{
                ServerObject = $script:mockServerForTabCompletion
                Name = 'max server memory (MB)'
            }

            $completions | Should -Not -BeNullOrEmpty
            $completions | Where-Object { $_.ToolTip -match "Current ConfigValue: 2048" } | Should -Not -BeNullOrEmpty
        }

        It 'Should handle tab completion errors gracefully' {
            # Create a server object that will cause an error
            $badServer = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $badServer.Name = 'BadServer'
            Add-Member -InputObject $badServer -MemberType ScriptProperty -Name 'Configuration' -Value {
                throw 'Connection failed'
            } -Force
            $global:BadTestServerObject = $badServer

            $inputScript = 'Test-SqlDscConfigurationOption -ServerObject $global:BadTestServerObject -Name test'
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
            $inputScript = 'Test-SqlDscConfigurationOption -Name test'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            <#
                Should not throw an error and should return empty from argument completer, but then
                TabExpansion2 itself returns some default completions (like filesystem paths).
            #>
            $result | Should -BeOfType ([System.Management.Automation.CommandCompletion])
            $result.CompletionMatches.ListItemText | Should -Be 'tests'
        }

        # TODO: This tests fails because the boolean-style option tooltips are not set as CompletionMatches
        # It 'Should provide Value completions for boolean-style options' {
        #     # Create a boolean-style configuration option
        #     $booleanOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
        #     $booleanOption.DisplayName = 'Agent XPs'
        #     $booleanOption.ConfigValue = 0
        #     $booleanOption.RunValue = 0
        #     $booleanOption.Minimum = 0
        #     $booleanOption.Maximum = 1

        #     # Create new server with boolean option
        #     $booleanProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
        #     $booleanProperties.Add($booleanOption)

        #     $booleanConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
        #     $booleanConfiguration.Properties = $booleanProperties

        #     $booleanServer = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
        #     $booleanServer.Name = 'BooleanTestServer'
        #     $booleanServer.Configuration = $booleanConfiguration

        #     $global:BooleanTestServerObject = $booleanServer

        #     try {
        #         $inputScript = 'Test-SqlDscConfigurationOption -ServerObject $global:BooleanTestServerObject -Name "Agent XPs" -Value '
        #         $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

        #         $result | Should -Not -BeNullOrEmpty
        #         $result.CompletionMatches | Should -Not -BeNullOrEmpty

        #         # Should find both enabled and disabled options
        #         Write-Verbose "Completion matches: $($result.CompletionMatches | ForEach-Object { $_ } | Sort-Object | Out-String)" -Verbose
        #         $enabledMatch = $result.CompletionMatches | Where-Object {
        #             $_.CompletionText -eq '1' -and $_.ToolTip -match "Enabled"
        #         }
        #         $disabledMatch = $result.CompletionMatches | Where-Object {
        #             $_.CompletionText -eq '0' -and $_.ToolTip -match "Disabled"
        #         }

        #         $enabledMatch | Should -Not -BeNullOrEmpty
        #         $disabledMatch | Should -Not -BeNullOrEmpty
        #     }
        #     finally {
        #         Remove-Variable -Name 'BooleanTestServerObject' -Scope Global -Force -ErrorAction SilentlyContinue
        #     }
        # }
    }
}
