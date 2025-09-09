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
        [Microsoft.SqlServer.Management.Smo.Server]

    .OUTPUTS
        None.

        This command does not return anything if the operator exists.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Assert-SqlDscAgentOperator -Name 'TestOperator'

        Asserts that the SQL Agent Operator 'TestOperator' exists, throws error if not found.

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
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    process
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        # This will throw a terminating error if the operator is not found
        $null = Get-AgentOperatorObject -ServerObject $ServerObject -Name $Name -ErrorAction 'Stop'

        $ErrorActionPreference = $originalErrorActionPreference

        # This command does not return anything if the operator exists
    }
}
