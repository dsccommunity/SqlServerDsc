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

Describe 'Set-SqlDscConfigurationOption' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <string> [-Value] <int> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscConfigurationOption').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Set-SqlDscConfigurationOption').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscConfigurationOption').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Value as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscConfigurationOption').Parameters['Value']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Force as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscConfigurationOption').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should have ServerObject accepting pipeline input' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscConfigurationOption').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Set-SqlDscConfigurationOption'
            $commandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $commandInfo.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should have ConfirmImpact set to High' {
            $commandInfo = Get-Command -Name 'Set-SqlDscConfigurationOption'
            # For functions with ShouldProcess, we check if CmdletBinding attribute has ConfirmImpact
            $function = Get-Item "Function:\Set-SqlDscConfigurationOption"
            $attributes = $function.ScriptBlock.Attributes
            $cmdletBindingAttribute = $attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $cmdletBindingAttribute.ConfirmImpact | Should -Be 'High'
        }
    }

    Context 'When setting configuration option successfully' {
        BeforeAll {
            # Create mock configuration option
            $script:mockConfigurationOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $script:mockConfigurationOption.DisplayName = 'max degree of parallelism'
            $script:mockConfigurationOption.ConfigValue = 0
            $script:mockConfigurationOption.RunValue = 0
            $script:mockConfigurationOption.Minimum = 0
            $script:mockConfigurationOption.Maximum = 32767

            # Create mock configuration properties collection
            $script:mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $script:mockConfigurationProperties.Add($script:mockConfigurationOption)

            # Create mock configuration object
            $script:mockConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $script:mockConfiguration.Properties = $script:mockConfigurationProperties
            $script:mockConfiguration | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { } -Force

            # Create mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.Name = 'TestServer'
            $script:mockServerObject.Configuration = $script:mockConfiguration

            # Mock Write-Information
            Mock -CommandName Write-Information
        }

        It 'Should set configuration option value successfully' {
            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 4 -Confirm:$false

            $script:mockConfigurationOption.ConfigValue | Should -Be 4
            Should -Invoke -CommandName Write-Information -Times 1 -Exactly
        }

        It 'Should call Configuration.Alter() method' {
            # Reset the mock
            $script:mockAlterCalled = $false
            $script:mockConfiguration | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { $script:mockAlterCalled = $true } -Force

            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 8 -Confirm:$false

            $script:mockAlterCalled | Should -BeTrue
        }

        It 'Should work with pipeline input' {
            $script:mockConfigurationOption.ConfigValue = 0

            $null = $script:mockServerObject | Set-SqlDscConfigurationOption -Name 'max degree of parallelism' -Value 16 -Confirm:$false

            $script:mockConfigurationOption.ConfigValue | Should -Be 16
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

        It 'Should throw error when configuration option does not exist' {
            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'NonExistentOption' -Value 1 -Confirm:$false

            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Message -match "There is no configuration option with the name 'NonExistentOption'"
            }
        }

        It 'Should use correct error details for missing configuration option' {
            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'InvalidOption' -Value 1 -Confirm:$false

            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Category -eq 'InvalidOperation' -and
                $ErrorId -eq 'SSDCO0001' -and
                $TargetObject -eq 'InvalidOption'
            }
        }
    }

    Context 'When option value is outside valid range' {
        BeforeAll {
            # Create mock configuration option with specific range
            $script:mockConfigurationOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $script:mockConfigurationOption.DisplayName = 'max degree of parallelism'
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

            # Mock Write-Error
            Mock -CommandName Write-Error
        }

        It 'Should throw error when value is below minimum' {
            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value -1 -Confirm:$false

            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Message -match "The value '-1' for configuration option 'max degree of parallelism' is outside the valid range of 0 to 32767"
            }
        }

        It 'Should throw error when value is above maximum' {
            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 40000 -Confirm:$false

            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Message -match "The value '40000' for configuration option 'max degree of parallelism' is outside the valid range of 0 to 32767"
            }
        }

        It 'Should use correct error details for invalid value' {
            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 50000 -Confirm:$false

            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Category -eq 'InvalidArgument' -and
                $ErrorId -eq 'SSDCO0002' -and
                $TargetObject -eq 50000
            }
        }

        It 'Should accept value at minimum boundary' {
            # Reset mocks for successful scenario
            Mock -CommandName Write-Error
            Mock -CommandName Write-Information

            $script:mockConfigurationOption.ConfigValue = 10
            $script:mockServerObject.Configuration | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { } -Force

            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 0 -Confirm:$false

            Should -Invoke -CommandName Write-Error -Times 0 -Exactly
            $script:mockConfigurationOption.ConfigValue | Should -Be 0
        }

        It 'Should accept value at maximum boundary' {
            # Reset mocks for successful scenario
            Mock -CommandName Write-Error
            Mock -CommandName Write-Information

            $script:mockConfigurationOption.ConfigValue = 10
            $script:mockServerObject.Configuration | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { } -Force

            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 32767 -Confirm:$false

            Should -Invoke -CommandName Write-Error -Times 0 -Exactly
            $script:mockConfigurationOption.ConfigValue | Should -Be 32767
        }
    }

    Context 'When Configuration.Alter() throws exception' {
        BeforeAll {
            # Create mock configuration option
            $script:mockConfigurationOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $script:mockConfigurationOption.DisplayName = 'max degree of parallelism'
            $script:mockConfigurationOption.Minimum = 0
            $script:mockConfigurationOption.Maximum = 32767

            # Create mock configuration that throws on Alter
            $script:mockConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $script:mockConfiguration | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                throw [System.Exception]::new('Database connection failed')
            } -Force

            # Create mock properties collection that returns our configuration option
            $script:mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $script:mockConfigurationProperties.Add($script:mockConfigurationOption)

            $script:mockConfiguration.Properties = $script:mockConfigurationProperties

            # Create mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.Name = 'TestServer'
            $script:mockServerObject.Configuration = $script:mockConfiguration
        }

        BeforeEach {
            # Reset mock for each test
            Mock -CommandName Write-Error
        }

        It 'Should handle exception from Configuration.Alter()' {
            # Test that the function handles exceptions gracefully
            $ErrorActionPreference = 'SilentlyContinue'
            $Global:Error.Clear()

            # This should not throw, but should generate an error record via Write-Error
            Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 4 -Confirm:$false -ErrorAction SilentlyContinue

            # Should -Invoke doesn't always work with Write-Error, so check error was generated another way
            Should -Invoke -CommandName Write-Error -Times 1 -Exactly
        }

        It 'Should use correct error details when Alter fails' {
            try {
                Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 4 -Confirm:$false -ErrorAction SilentlyContinue
            }
            catch {
                # Ignore any exceptions for this test
            }

            Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
                $Category -eq 'InvalidOperation' -and
                $ErrorId -eq 'SSDCO0003' -and
                $TargetObject -eq 'max degree of parallelism'
            }
        }
    }

    Context 'When using ShouldProcess with WhatIf' {
        BeforeAll {
            # Create mock configuration option
            $script:mockConfigurationOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $script:mockConfigurationOption.DisplayName = 'max degree of parallelism'
            $script:mockConfigurationOption.ConfigValue = 0
            $script:mockConfigurationOption.Minimum = 0
            $script:mockConfigurationOption.Maximum = 32767

            # Create mock configuration properties collection
            $script:mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $script:mockConfigurationProperties.Add($script:mockConfigurationOption)

            # Create mock configuration object
            $script:mockConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $script:mockConfiguration.Properties = $script:mockConfigurationProperties

            # Track if Alter was called
            $script:mockAlterCalled = $false
            $script:mockConfiguration | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                $script:mockAlterCalled = $true
            } -Force

            # Create mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.Name = 'TestServer'
            $script:mockServerObject.Configuration = $script:mockConfiguration
        }

        It 'Should not make changes when using WhatIf' {
            $script:mockAlterCalled = $false
            $originalValue = $script:mockConfigurationOption.ConfigValue

            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 4 -WhatIf

            $script:mockAlterCalled | Should -BeFalse
            $script:mockConfigurationOption.ConfigValue | Should -Be $originalValue
        }
    }

    Context 'When using Force parameter' {
        BeforeAll {
            # Create mock configuration option
            $script:mockConfigurationOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $script:mockConfigurationOption.DisplayName = 'max degree of parallelism'
            $script:mockConfigurationOption.ConfigValue = 0
            $script:mockConfigurationOption.Minimum = 0
            $script:mockConfigurationOption.Maximum = 32767

            # Create mock configuration properties collection
            $script:mockConfigurationProperties = [Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection]::CreateTypeInstance()
            $script:mockConfigurationProperties.Add($script:mockConfigurationOption)

            # Create mock configuration object
            $script:mockConfiguration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $script:mockConfiguration.Properties = $script:mockConfigurationProperties
            $script:mockConfiguration | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { } -Force

            # Create mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.Name = 'TestServer'
            $script:mockServerObject.Configuration = $script:mockConfiguration

            # Mock Write-Information
            Mock -CommandName Write-Information
        }

        It 'Should bypass confirmation when Force is specified' {
            # This test ensures Force parameter is handled correctly in the begin block
            $null = Set-SqlDscConfigurationOption -ServerObject $script:mockServerObject -Name 'max degree of parallelism' -Value 4 -Force

            $script:mockConfigurationOption.ConfigValue | Should -Be 4
            Should -Invoke -CommandName Write-Information -Times 1 -Exactly
        }
    }

    Context 'When validating ShouldProcess messages' {
        BeforeAll {
            # Create mock configuration option
            $script:mockConfigurationOption = [Microsoft.SqlServer.Management.Smo.ConfigProperty]::CreateTypeInstance()
            $script:mockConfigurationOption.DisplayName = 'cost threshold for parallelism'
            $script:mockConfigurationOption.ConfigValue = 5
            $script:mockConfigurationOption.Minimum = 0
            $script:mockConfigurationOption.Maximum = 32767

            # Create mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.Name = 'SQL2019'
            $script:mockServerObject.Configuration = [Microsoft.SqlServer.Management.Smo.Configuration]::CreateTypeInstance()
            $script:mockServerObject.Configuration | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { } -Force

            # Mock the Where-Object pipeline to return our mock configuration option
            Mock -CommandName Where-Object -MockWith {
                param($FilterScript)
                if ($FilterScript.ToString() -match 'DisplayName') {
                    return $script:mockConfigurationOption
                }
                return $null
            }

            # Mock localized strings retrieval
            $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
        }

        AfterAll {
            $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
        }

        It 'Should use correct ShouldProcess messages' {
            InModuleScope -ScriptBlock {
                # Verify localized strings exist for ShouldProcess
                $script:localizedData.ConfigurationOption_Set_ShouldProcessDescription | Should -Be "Set configuration option '{0}' to '{1}' on server '{2}'."
                $script:localizedData.ConfigurationOption_Set_ShouldProcessConfirmation | Should -Be "Are you sure you want to set configuration option '{0}' to '{1}'?"
                $script:localizedData.ConfigurationOption_Set_ShouldProcessCaption | Should -Be 'Set configuration option'
            }
        }
    }

    Context 'When validating error messages' {
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
                $script:localizedData.ConfigurationOption_Set_Missing | Should -Be "There is no configuration option with the name '{0}'."
                $script:localizedData.ConfigurationOption_Set_InvalidValue | Should -Be "The value '{1}' for configuration option '{0}' is outside the valid range of {2} to {3}."
                $script:localizedData.ConfigurationOption_Set_Failed | Should -Be "Failed to set configuration option '{0}' to '{1}'. {2}"
                $script:localizedData.ConfigurationOption_Set_Success | Should -Be "Successfully set configuration option '{0}' to '{1}' on server '{2}'."
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
            $inputScript = 'Set-SqlDscConfigurationOption -ServerObject $global:TestServerObject -Name max'
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
            $inputScript = 'Set-SqlDscConfigurationOption -ServerObject $global:TestServerObject -Name "max server memory (MB)" -Value '
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
            $inputScript = 'Set-SqlDscConfigurationOption -ServerObject $global:TestServerObject -Name cost'
            $result = TabExpansion2 -inputScript $inputScript -cursorColumn $inputScript.Length

            $result.CompletionMatches | Should -HaveCount 1
            $result.CompletionMatches[0].CompletionText | Should -Be "'cost threshold for parallelism'"
        }

        It 'Should execute Name argument completer code when retrieving command metadata' {
            # This approach actually executes the argument completer code during command introspection
            $command = Get-Command -Name 'Set-SqlDscConfigurationOption'

            # Create a mock parameter set to trigger argument completer execution
            $parameterInfo = $command.Parameters['Name']
            $completerAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }

            # This executes the completer in the module's context
            $completions = & $completerAttribute.ScriptBlock 'Set-SqlDscConfigurationOption' 'Name' 'max' $null @{
                ServerObject = $script:mockServerForTabCompletion
            }

            $completions | Should -Not -BeNullOrEmpty
            $completions[0].CompletionText | Should -Be "'max server memory (MB)'"
        }

        It 'Should execute Value argument completer code when retrieving command metadata' {
            $command = Get-Command -Name 'Set-SqlDscConfigurationOption'
            $parameterInfo = $command.Parameters['Value']
            $completerAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }

            $completions = & $completerAttribute.ScriptBlock 'Set-SqlDscConfigurationOption' 'Value' '' $null @{
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

            $inputScript = 'Set-SqlDscConfigurationOption -ServerObject $global:BadTestServerObject -Name test'
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
            $inputScript = 'Set-SqlDscConfigurationOption -Name test'
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
