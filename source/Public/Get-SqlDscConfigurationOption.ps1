<#
    .SYNOPSIS
        Get server configuration option.

    .DESCRIPTION
        This command gets the available configuration options from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the configuration option to get.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s configuration property should be
        refreshed before trying get the available configuration options. This is
        helpful when run values or configuration values have been modified outside
        of the specified **ServerObject**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $sqlServerObject | Get-SqlDscConfigurationOption

        Get all the available configuration options.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $sqlServerObject | Get-SqlDscConfigurationOption -Name '*threshold*'

        Get the configuration options that contains the word **threshold**.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.ConfigProperty[]]`
#>
function Get-SqlDscConfigurationOption
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Because the rule does not understands that the command returns [System.String[]] when using , (comma) in the return statement')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.ConfigProperty[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        if ($Refresh.IsPresent)
        {
            # Make sure the configuration option values are up-to-date.
            $serverObject.Configuration.Refresh()
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $configurationOption = $serverObject.Configuration.Properties |
                Where-Object -FilterScript {
                    $_.DisplayName -like $Name
                }

            if (-not $configurationOption)
            {
                $missingConfigurationOptionMessage = $script:localizedData.ConfigurationOption_Get_Missing -f $Name

                $writeErrorParameters = @{
                    Message = $missingConfigurationOptionMessage
                    Category = 'InvalidOperation'
                    ErrorId = 'GSDCO0001' # cspell: disable-line
                    TargetObject = $Name
                }

                Write-Error @writeErrorParameters
            }
        }
        else
        {
            $configurationOption = $serverObject.Configuration.Properties.ForEach({ $_ })
        }

        return , [Microsoft.SqlServer.Management.Smo.ConfigProperty[]] (
            $configurationOption |
                Sort-Object -Property 'DisplayName'
        )
    }
}
