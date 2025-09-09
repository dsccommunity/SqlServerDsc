<#
    .SYNOPSIS
        Set server configuration option value.

    .DESCRIPTION
        This command sets the value of a SQL Server Database Engine configuration option
        using SQL Server Management Objects (SMO). The function validates that the option
        exists and that the provided value is within the option's minimum and maximum range.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the configuration option to set.

    .PARAMETER OptionValue
        Specifies the value to set for the configuration option.

    .PARAMETER Force
        Suppresses prompts and overrides restrictions that would normally prevent the command from completing.
        When specified, the command will not prompt for confirmation before making changes.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Set-SqlDscConfigurationOption -Name "Agent XPs" -OptionValue 1

        Sets the "Agent XPs" configuration option to enabled (1).

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscConfigurationOption -ServerObject $serverObject -Name "cost threshold for parallelism" -OptionValue 50

        Sets the "cost threshold for parallelism" configuration option to 50.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Set-SqlDscConfigurationOption -Name "max degree of parallelism" -OptionValue 4 -WhatIf

        Shows what would happen if the "max degree of parallelism" option was set to 4, without actually making the change.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Set-SqlDscConfigurationOption -Name "cost threshold for parallelism" -OptionValue 25 -Force

        Sets the "cost threshold for parallelism" configuration option to 25 without prompting for confirmation.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server
        SQL Server Management Objects (SMO) Server object representing a SQL Server instance.

    .NOTES
        This function supports ShouldProcess, allowing the use of -WhatIf and -Confirm parameters.
#>
function Set-SqlDscConfigurationOption
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Because we pass parameters in the argument completer that are not yet used.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '', Justification = 'Because we need to handle errors gracefully in the argument completer without terminating the pipeline.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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
        $OptionValue,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        # Find the configuration option by name
        $configurationOption = $ServerObject.Configuration.Properties |
            Where-Object {
                $_.DisplayName -eq $Name
            }

        if (-not $configurationOption)
        {
            $missingConfigurationOptionMessage = $script:localizedData.ConfigurationOption_Set_Missing -f $Name

            $writeErrorParameters = @{
                Message      = $missingConfigurationOptionMessage
                Category     = 'InvalidOperation'
                ErrorId      = 'SSDCO0001' # cspell: disable-line
                TargetObject = $Name
            }

            Write-Error @writeErrorParameters
            return
        }

        # Validate that the option value is within the allowed range
        if ($OptionValue -lt $configurationOption.Minimum -or $OptionValue -gt $configurationOption.Maximum)
        {
            $invalidValueMessage = $script:localizedData.ConfigurationOption_Set_InvalidValue -f $Name, $OptionValue, $configurationOption.Minimum, $configurationOption.Maximum

            $writeErrorParameters = @{
                Message      = $invalidValueMessage
                Category     = 'InvalidArgument'
                ErrorId      = 'SSDCO0002' # cspell: disable-line
                TargetObject = $OptionValue
            }

            Write-Error @writeErrorParameters
            return
        }

        # Prepare ShouldProcess messages
        $descriptionMessage = $script:localizedData.ConfigurationOption_Set_ShouldProcessDescription -f $Name, $OptionValue, $ServerObject.Name
        $confirmationMessage = $script:localizedData.ConfigurationOption_Set_ShouldProcessConfirmation -f $Name, $OptionValue
        $captionMessage = $script:localizedData.ConfigurationOption_Set_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            try
            {
                # Set the new configuration value
                $configurationOption.ConfigValue = $OptionValue

                # Apply the configuration change
                $ServerObject.Configuration.Alter()

                Write-Information -MessageData ($script:localizedData.ConfigurationOption_Set_Success -f $Name, $OptionValue, $ServerObject.Name)
            }
            catch
            {
                $setConfigurationOptionFailedMessage = $script:localizedData.ConfigurationOption_Set_Failed -f $Name, $OptionValue, $_.Exception.Message

                $writeErrorParameters = @{
                    Message      = $setConfigurationOptionFailedMessage
                    Category     = 'InvalidOperation'
                    ErrorId      = 'SSDCO0003' # cspell: disable-line
                    TargetObject = $Name
                    Exception    = $_.Exception
                }

                Write-Error @writeErrorParameters
            }
        }
    }
}
