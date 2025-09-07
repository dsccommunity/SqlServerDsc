<#
    .SYNOPSIS
        Asserts that a SQL Server Agent Operator exists and throws a terminating error if not found.

    .DESCRIPTION
        This command asserts that a SQL Server Agent Operator exists using the provided
        parameters. If the operator is not found, it throws a terminating error with a
        generic localized error message.

    .PARAMETER ServerObject
        Specifies the server object on which to check for the operator.

    .PARAMETER Name
        Specifies the name of the operator to check for.

    .INPUTS
        None.

    .OUTPUTS
        None.

        This command does not return anything if the operator exists.

    .EXAMPLE
        Assert-SqlDscAgentOperator -ServerObject $serverObject -Name 'TestOperator'

        Asserts that the SQL Agent Operator 'TestOperator' exists, throws error if not found.
#>
function Assert-SqlDscAgentOperator
{
    [CmdletBinding()]
    [OutputType()]
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
            'ASAO0001',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $Name
        )

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    # This command does not return anything if the operator exists
}
