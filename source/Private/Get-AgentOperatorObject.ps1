<#
    .SYNOPSIS
        Retrieves a SQL Server Agent Operator object and throws a terminating error if not found.

    .DESCRIPTION
        This private function retrieves a SQL Server Agent Operator object using the provided
        parameters. If the operator is not found, it throws a terminating error with a 
        generic localized error message.

    .PARAMETER ServerObject
        Specifies the server object on which to retrieve the operator.

    .PARAMETER Name
        Specifies the name of the operator to retrieve.

    .INPUTS
        None.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator

        Returns the operator object if found.

    .EXAMPLE
        $operatorObject = Get-AgentOperatorObject -ServerObject $serverObject -Name 'TestOperator'

        Returns the SQL Agent Operator object for 'TestOperator'.
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

    $getSqlDscAgentOperatorParameters = @{
        ServerObject = $ServerObject
        Name         = $Name
        ErrorAction  = 'Stop'
    }

    # If this command does not find the operator it will return $null.
    $operatorObject = Get-SqlDscAgentOperator @getSqlDscAgentOperatorParameters

    if (-not $operatorObject)
    {
        $errorMessage = $script:localizedData.AgentOperator_NotFound -f $Name
        $exception = [System.InvalidOperationException]::new($errorMessage)
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            'GAOO0001',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $Name
        )

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    return $operatorObject
}
