<#
    .SYNOPSIS
        Test if server configuration option has the specified value.

    .DESCRIPTION
        This command tests whether a SQL Server Database Engine configuration option
        has the specified value using SQL Server Management Objects (SMO). The function
        validates that the option exists and compares the current value with the expected value.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the configuration option to test.

    .PARAMETER Value
        Specifies the expected value for the configuration option.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscConfigurationOption -Name "Agent XPs" -Value 1

        Tests if the "Agent XPs" configuration option is enabled (1).

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscConfigurationOption -ServerObject $serverObject -Name "cost threshold for parallelism" -Value 50

        Tests if the "cost threshold for parallelism" configuration option is set to 50.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscConfigurationOption -Name "max degree of parallelism" -Value 4

        Tests if the "max degree of parallelism" option is set to 4.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        SQL Server Management Objects (SMO) Server object representing a SQL Server instance.

    .OUTPUTS
        `System.Boolean`

        Returns $true if the configuration option has the specified value, $false otherwise.

    .NOTES
        This function does not support ShouldProcess as it is a read-only operation.
#>
function Test-SqlDscConfigurationOption
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Because we pass parameters in the argument completer that are not yet used.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [ArgumentCompleter({
                param
                (
                    [Parameter()]
                    $commandName,

                    [Parameter()]
                    $parameterName,

                    [Parameter()]
                    $wordToComplete,

                    [Parameter()]
                    $commandAst,

                    [Parameter()]
                    $fakeBoundParameters
                )

                # Get ServerObject from bound parameters only
                $serverObject = $null

                if ($FakeBoundParameters.ContainsKey('ServerObject'))
                {
                    $serverObject = $FakeBoundParameters['ServerObject']
                }

                if ($serverObject -and $serverObject -is [Microsoft.SqlServer.Management.Smo.Server])
                {
                    try
                    {
                        $options = $serverObject.Configuration.Properties | Where-Object {
                            $_.DisplayName -like "*$WordToComplete*"
                        } | Sort-Object DisplayName

                        foreach ($option in $options)
                        {
                            $tooltip = "Current: $($option.ConfigValue), Run: $($option.RunValue), Range: $($option.Minimum)-$($option.Maximum)"
                            [System.Management.Automation.CompletionResult]::new(
                                "'$($option.DisplayName)'",
                                $option.DisplayName,
                                'ParameterValue',
                                $tooltip
                            )
                        }
                    }
                    catch
                    {
                        # Return empty if there's an error accessing the server
                        @()
                    }
                }
                else
                {
                    # Return empty array if no server object available
                    @()
                }
            })]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ArgumentCompleter({
                param
                (
                    [Parameter()]
                    $commandName,

                    [Parameter()]
                    $parameterName,

                    [Parameter()]
                    $wordToComplete,

                    [Parameter()]
                    $commandAst,

                    [Parameter()]
                    $fakeBoundParameters
                )

                # Get ServerObject and Name from bound parameters
                $serverObject = $null
                $optionName = $null

                if ($FakeBoundParameters.ContainsKey('ServerObject'))
                {
                    $serverObject = $FakeBoundParameters['ServerObject']
                }

                if ($FakeBoundParameters.ContainsKey('Name'))
                {
                    $optionName = $FakeBoundParameters['Name']
                }

                if ($serverObject -and $serverObject -is [Microsoft.SqlServer.Management.Smo.Server] -and $optionName)
                {
                    try
                    {
                        $option = $serverObject.Configuration.Properties | Where-Object {
                            $_.DisplayName -eq $optionName
                        }

                        if ($option)
                        {
                            $suggestions = @()

                            # Add current values
                            $suggestions += [PSCustomObject]@{
                                Value   = $option.ConfigValue
                                Tooltip = "Current ConfigValue: $($option.ConfigValue)"
                            }

                            $suggestions += [PSCustomObject]@{
                                Value   = $option.RunValue
                                Tooltip = "Current RunValue: $($option.RunValue)"
                            }

                            # Add min/max values
                            $suggestions += [PSCustomObject]@{
                                Value   = $option.Minimum
                                Tooltip = "Minimum allowed value: $($option.Minimum)"
                            }

                            $suggestions += [PSCustomObject]@{
                                Value   = $option.Maximum
                                Tooltip = "Maximum allowed value: $($option.Maximum)"
                            }

                            # If it's a boolean option (0-1), suggest both values
                            if ($option.Minimum -eq 0 -and $option.Maximum -eq 1)
                            {
                                $suggestions += [PSCustomObject]@{
                                    Value   = 0
                                    Tooltip = 'Disabled (0)'
                                }

                                $suggestions += [PSCustomObject]@{
                                    Value   = 1
                                    Tooltip = 'Enabled (1)'
                                }
                            }

                            # Remove duplicates and filter by word to complete
                            $uniqueSuggestions = $suggestions | Group-Object Value | ForEach-Object { $_.Group[0] }
                            $filteredSuggestions = $uniqueSuggestions | Where-Object {
                                $_.Value -like "*$WordToComplete*"
                            } | Sort-Object Value

                            foreach ($suggestion in $filteredSuggestions)
                            {
                                [System.Management.Automation.CompletionResult]::new(
                                    $suggestion.Value.ToString(),
                                    $suggestion.Value.ToString(),
                                    'ParameterValue',
                                    $suggestion.Tooltip
                                )
                            }
                        }
                    }
                    catch
                    {
                        # Return empty if there's an error
                        @()
                    }
                }
                else
                {
                    # Return empty array if prerequisites not met
                    @()
                }
            })]
        [System.Int32]
        $Value
    )

    process
    {
        # Find the configuration option by name
        $configurationOption = $ServerObject.Configuration.Properties |
            Where-Object {
                $_.DisplayName -eq $Name
            }

        if (-not $configurationOption)
        {
            $missingConfigurationOptionMessage = $script:localizedData.ConfigurationOption_Test_Missing -f $Name

            $writeErrorParameters = @{
                Message      = $missingConfigurationOptionMessage
                Category     = 'InvalidOperation'
                ErrorId      = 'TSDCO0001' # cspell: disable-line
                TargetObject = $Name
            }

            Write-Error @writeErrorParameters
            return $false
        }

        # Compare the current configuration value with the expected value
        $currentValue = $configurationOption.ConfigValue
        $isMatch = $currentValue -eq $Value

        Write-Verbose -Message ($script:localizedData.ConfigurationOption_Test_Result -f $Name, $currentValue, $Value, $isMatch, $ServerObject.Name)

        return $isMatch
    }
}
