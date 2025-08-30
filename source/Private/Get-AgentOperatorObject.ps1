<#
    .SYNOPSIS
        Gets a SQL Agent Operator object from the JobServer.

    .DESCRIPTION
        Gets a SQL Agent Operator object from the JobServer based on the specified name.

    .PARAMETER ServerObject
        Specifies the SQL Server object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator

        Returns the SQL Agent Operator object when an operator with the specified name is found.

    .OUTPUTS
        None.

        When no operator with the specified name is found.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Get-AgentOperatorObject -ServerObject $serverObject -Name 'MyOperator'

        Gets the SQL Agent Operator named 'MyOperator'.
#>
function Get-AgentOperatorObject
{
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Operator])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message ($script:localizedData.Get_AgentOperatorObject_GettingOperator -f $Name)

    $operatorObject = $ServerObject.JobServer.Operators | Where-Object -FilterScript { $_.Name -eq $Name }

    return $operatorObject
}