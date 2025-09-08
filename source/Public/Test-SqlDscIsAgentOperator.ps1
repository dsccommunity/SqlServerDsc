<#
    .SYNOPSIS
        Tests for the existence of a SQL Agent Operator.

    .DESCRIPTION
        This command tests if a SQL Agent Operator exists on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to test.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s operators should be refreshed before
        testing the operator. This is helpful when operators could have
        been modified outside of the **ServerObject**, for example through T-SQL.
        But on instances with a large amount of operators it might be better to make
        sure the **ServerObject** is recent enough.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

    .OUTPUTS
        System.Boolean

        Returns $true if the operator exists, $false otherwise.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscIsAgentOperator -ServerObject $serverObject -Name 'MyOperator'

        Tests if the SQL Agent Operator named 'MyOperator' exists.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscIsAgentOperator -Name 'MyOperator'

        Tests if the SQL Agent Operator named 'MyOperator' exists using pipeline input.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscIsAgentOperator -Name 'MyOperator' -Refresh

        Refreshes the server operators collection before testing if **MyOperator** exists.
#>
function Test-SqlDscIsAgentOperator
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    # cSpell: ignore TISAO
    process
    {
        Write-Verbose -Message ($script:localizedData.Test_SqlDscIsAgentOperator_TestingOperator -f $Name)

        $operatorObject = Get-AgentOperatorObject -ServerObject $ServerObject -Name $Name -Refresh:$Refresh -ErrorAction 'SilentlyContinue'

        if (-not $operatorObject)
        {
            Write-Verbose -Message ($script:localizedData.Test_SqlDscIsAgentOperator_OperatorNotFound -f $Name)
            return $false
        }

        Write-Verbose -Message ($script:localizedData.Test_SqlDscIsAgentOperator_OperatorFound -f $Name)

        return $true
    }
}
