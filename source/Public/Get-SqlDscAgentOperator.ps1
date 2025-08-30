<#
    .SYNOPSIS
        Returns SQL Agent Operator information.

    .DESCRIPTION
        Returns SQL Agent Operator information from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to retrieve. If not specified,
        all operators are returned.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator

        When using the ByName parameter set, returns a single SQL Agent Operator object.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator[]

        When using the All parameter set, returns an array of SQL Agent Operator objects.

    .OUTPUTS
        None
        Returns nothing when no operators are found for the specified criteria.
    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Get-SqlDscAgentOperator -ServerObject $serverObject

        Returns all SQL Agent Operators from the server.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Get-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator'

        Returns the SQL Agent Operator named 'MyOperator'.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        $serverObject | Get-SqlDscAgentOperator -Name 'MyOperator'

        Returns the SQL Agent Operator named 'MyOperator' using pipeline input.
#>
function Get-SqlDscAgentOperator
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Operator], ParameterSetName = 'ByName')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Operator[]], ParameterSetName = 'All')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'All')]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    # cSpell: ignore GSAO
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'ByName'
            {
                Write-Verbose -Message ($script:localizedData.Get_SqlDscAgentOperator_GettingOperator -f $Name)

                $operatorObject = $ServerObject.JobServer.Operators | Where-Object -FilterScript { $_.Name -eq $Name }

                return $operatorObject
            }

            'All'
            {
                Write-Verbose -Message ($script:localizedData.Get_SqlDscAgentOperator_GettingOperators -f $ServerObject.InstanceName)

                $operatorCollection = $ServerObject.JobServer.Operators

                Write-Verbose -Message ($script:localizedData.Get_SqlDscAgentOperator_ReturningAllOperators -f $operatorCollection.Count)

                return [Microsoft.SqlServer.Management.Smo.Agent.Operator[]] $operatorCollection
            }
        }
    }
}
