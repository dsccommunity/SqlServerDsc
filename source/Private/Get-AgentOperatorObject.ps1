<#
    .SYNOPSIS
        Retrieves a SQL Server Agent Operator object.

    .DESCRIPTION
        This private function retrieves a SQL Server Agent Operator object using the provided
        parameters. By default, if the operator is not found, it throws a terminating error with a
        generic localized error message. If IgnoreNotFound is specified, it returns $null.

    .PARAMETER ServerObject
        Specifies the server object on which to retrieve the operator.

    .PARAMETER Name
        Specifies the name of the operator to retrieve.

    .PARAMETER IgnoreNotFound
        Specifies whether to ignore the error if the operator is not found.
        When specified, the function returns $null if the operator doesn't exist.
        When not specified (default), the function throws an error if the operator doesn't exist.

    .PARAMETER Refresh
        Specifies whether to refresh the operators collection before retrieving the operator.
        When specified, the function calls Refresh() on the JobServer.Operators collection.

    .INPUTS
        None.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator

        Returns the operator object if found.

    .OUTPUTS
        None

        Returns nothing when IgnoreNotFound is specified and the operator is not found.

    .EXAMPLE
        $operatorObject = Get-AgentOperatorObject -ServerObject $serverObject -Name 'TestOperator'

        Returns the SQL Agent Operator object for 'TestOperator', throws error if not found.

    .EXAMPLE
        $operatorObject = Get-AgentOperatorObject -ServerObject $serverObject -Name 'TestOperator' -IgnoreNotFound

        Returns the SQL Agent Operator object for 'TestOperator', returns $null if not found.

    .EXAMPLE
        $operatorObject = Get-AgentOperatorObject -ServerObject $serverObject -Name 'TestOperator' -Refresh

        Returns the SQL Agent Operator object for 'TestOperator' after refreshing the operators collection.
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
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IgnoreNotFound,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    Write-Verbose -Message ($script:localizedData.Get_AgentOperatorObject_GettingOperator -f $Name)

    if ($Refresh)
    {
        Write-Verbose -Message $script:localizedData.Get_AgentOperatorObject_RefreshingOperators
        $ServerObject.JobServer.Operators.Refresh()
    }

    $operatorObject = $ServerObject.JobServer.Operators | Where-Object -FilterScript { $_.Name -eq $Name }

    if (-not $operatorObject -and -not $IgnoreNotFound)
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
