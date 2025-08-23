<#
    .SYNOPSIS
        Returns SQL Agent Alert information.

    .DESCRIPTION
        Returns SQL Agent Alert information from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Alert to retrieve. If not specified,
        all alerts are returned.

    .OUTPUTS
        [Microsoft.SqlServer.Management.Smo.Agent.Alert]
        Returns one or more alert objects.

    .OUTPUTS
        None
        Returns nothing when no alerts are found for the specified criteria.
    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Get-SqlDscAgentAlert -ServerObject $serverObject

        Returns all SQL Agent Alerts from the server.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Get-SqlDscAgentAlert -ServerObject $serverObject -Name 'MyAlert'

        Returns the SQL Agent Alert named 'MyAlert'.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        $serverObject | Get-SqlDscAgentAlert -Name 'MyAlert'

        Returns the SQL Agent Alert named 'MyAlert' using pipeline input.
#>
function Get-SqlDscAgentAlert
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Alert[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    # cSpell: ignore GSAA
    process
    {
        if ($PSBoundParameters.ContainsKey('Name'))
        {
            return Get-AgentAlertObject -ServerObject $ServerObject -Name $Name
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.Get_SqlDscAgentAlert_GettingAlerts -f $ServerObject.InstanceName)

            $alertCollection = $ServerObject.JobServer.Alerts

            Write-Verbose -Message ($script:localizedData.Get_SqlDscAgentAlert_ReturningAllAlerts -f $alertCollection.Count)

            return $alertCollection
        }
    }
}
