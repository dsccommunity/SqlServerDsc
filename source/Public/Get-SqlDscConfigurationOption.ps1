<#
    .SYNOPSIS
        Get server configuration option metadata or raw SMO objects.

    .DESCRIPTION
        This command gets configuration options from a SQL Server Database Engine instance.
        By default, it returns user-friendly metadata objects with current values, ranges,
        and dynamic properties. Use the -Raw switch to get the original SMO ConfigProperty objects.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the configuration option to get. Supports wildcards.
        If not specified, all configuration options are returned.

    .PARAMETER Raw
        Specifies that the original SMO ConfigProperty objects should be returned
        instead of the enhanced metadata objects.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s configuration property should be
        refreshed before trying get the available configuration options. This is
        helpful when run values or configuration values have been modified outside
        of the specified **ServerObject**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscConfigurationOption

        Get metadata for all available configuration options.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscConfigurationOption -Name '*threshold*'

        Get metadata for configuration options that contain the word "threshold".

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscConfigurationOption -Name "Agent XPs"

        Get metadata for the specific "Agent XPs" configuration option.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscConfigurationOption -Raw

        Get all configuration options as raw SMO ConfigProperty objects.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server
        SQL Server Management Objects (SMO) Server object representing a SQL Server instance.

    .OUTPUTS
        PSCustomObject[]
        Returns user-friendly metadata objects with configuration option details (default behavior).

        Microsoft.SqlServer.Management.Smo.ConfigProperty[]
        Returns raw SMO ConfigProperty objects when using the -Raw parameter.
#>
function Get-SqlDscConfigurationOption
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Because we pass parameters in the argument completer that are not yet used.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '', Justification = 'Because we need to handle errors gracefully in the argument completer without terminating the pipeline.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([PSCustomObject[]], ParameterSetName = 'Metadata')]
    [OutputType([Microsoft.SqlServer.Management.Smo.ConfigProperty[]], ParameterSetName = 'Raw')]
    [CmdletBinding(DefaultParameterSetName = 'Metadata')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

                # Get ServerObject from pipeline or bound parameters
                $serverObject = $null
                if ($FakeBoundParameters.ContainsKey('ServerObject'))
                {
                    $serverObject = $FakeBoundParameters['ServerObject']
                }
                else
                {
                    # Try to get from pipeline input
                    $pipelineInput = $CommandAst.Parent.Extent.Text
                    if ($pipelineInput -match '\$\w+\s*\|')
                    {
                        try
                        {
                            # This is a best-effort attempt to get server object for tab completion
                            # In practice, tab completion works best when ServerObject is explicitly bound
                            $variableName = ($matches[0] -replace '\s*\|', '').Trim('$')
                            $serverObject = Get-Variable -Name $variableName -ValueOnly -ErrorAction SilentlyContinue
                        }
                        catch
                        {
                            # Silently continue if we can't get the server object
                        }
                    }
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

        [Parameter(ParameterSetName = 'Raw')]
        [System.Management.Automation.SwitchParameter]
        $Raw,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        if ($Refresh.IsPresent)
        {
            # Make sure the configuration option values are up-to-date.
            $ServerObject.Configuration.Refresh()
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $configurationOptions = $ServerObject.Configuration.Properties |
                Where-Object -FilterScript {
                    $_.DisplayName -like $Name
                }

            if (-not $configurationOptions)
            {
                $missingConfigurationOptionMessage = $script:localizedData.ConfigurationOption_Get_Missing -f $Name

                $writeErrorParameters = @{
                    Message      = $missingConfigurationOptionMessage
                    Category     = 'InvalidOperation'
                    ErrorId      = 'GSDCO0001' # cspell: disable-line
                    TargetObject = $Name
                }

                Write-Error @writeErrorParameters
                return
            }
        }
        else
        {
            $configurationOptions = $ServerObject.Configuration.Properties.ForEach({ $_ })
        }

        # Sort the options by DisplayName
        $sortedOptions = $configurationOptions | Sort-Object -Property 'DisplayName'

        if ($Raw.IsPresent)
        {
            # Return raw SMO ConfigProperty objects
            return [Microsoft.SqlServer.Management.Smo.ConfigProperty[]] $sortedOptions
        }
        else
        {
            # Return enhanced metadata objects
            $metadataObjects = foreach ($option in $sortedOptions)
            {
                $metadata = [PSCustomObject]@{
                    Name        = $option.DisplayName
                    RunValue    = $option.RunValue
                    ConfigValue = $option.ConfigValue
                    Minimum     = $option.Minimum
                    Maximum     = $option.Maximum
                    IsDynamic   = $option.IsDynamic
                }

                # Add custom type name for formatting
                $metadata.PSTypeNames.Insert(0, 'SqlDsc.ConfigurationOption')
                $metadata
            }

            return $metadataObjects
        }
    }
}
