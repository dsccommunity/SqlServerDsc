<#
    .SYNOPSIS
        Retrieves a SQL Server Agent Operator object and throws a terminating error if not found.

    .DESCRIPTION
        This private function retrieves a SQL Server Agent Operator object using the provided
        parameters. If the operator is not found, it throws a terminating error with a 
        localized error message.

    .PARAMETER ServerObject
        Specifies the server object on which to retrieve the operator.

    .PARAMETER Name
        Specifies the name of the operator to retrieve.

    .PARAMETER ErrorMessage
        Specifies the localized error message to use if the operator is not found.

    .PARAMETER ErrorId
        Specifies the error ID to use if the operator is not found.

    .INPUTS
        None.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator

        Returns the operator object if found.
#>
function Assert-SqlDscAgentOperatorExists
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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorMessage,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorId
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
        $exception = [System.InvalidOperationException]::new($ErrorMessage)
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            $ErrorId,
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Name
        )

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    return $operatorObject
}