<#
    .SYNOPSIS
        Retrieves a SQL Server Agent Operator object.

    .DESCRIPTION
        This private function retrieves a SQL Server Agent Operator object using the provided
        parameters. If the operator is not found, it throws a non-terminating error. Callers
        can use -ErrorAction to control error behavior.

    .PARAMETER ServerObject
        Specifies the server object on which to retrieve the operator.

    .PARAMETER Name
        Specifies the name of the operator to retrieve.

    .PARAMETER Refresh
        Specifies whether to refresh the operators collection before retrieving the operator.
        When specified, the function calls Refresh() on the JobServer.Operators collection.

    .INPUTS
        None.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Agent.Operator`

        Returns the operator object if found, or $null if not found.

    .EXAMPLE
        $operatorObject = Get-AgentOperatorObject -ServerObject $serverObject -Name 'TestOperator'

        Returns the SQL Agent Operator object for 'TestOperator', throws error if not found.

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
        $Refresh
    )

    Write-Verbose -Message ($script:localizedData.Get_AgentOperatorObject_GettingOperator -f $Name)

    if ($Refresh)
    {
        Write-Verbose -Message $script:localizedData.Get_AgentOperatorObject_RefreshingOperators
        $ServerObject.JobServer.Operators.Refresh()
    }

    $operatorObject = $ServerObject.JobServer.Operators[$Name]

    if ($null -eq $operatorObject)
    {
        $errorMessage = $script:localizedData.AgentOperator_NotFound -f $Name

        Write-Error -Message $errorMessage -Category 'ObjectNotFound' -ErrorId 'GAOO0001' -TargetObject $Name

        return $null
    }

    return $operatorObject
}
