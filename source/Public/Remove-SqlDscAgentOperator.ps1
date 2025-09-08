<#
    .SYNOPSIS
        Removes a SQL Agent Operator.

    .DESCRIPTION
        This command removes a SQL Agent Operator from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER OperatorObject
        Specifies the SQL Agent Operator object to remove.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to remove.

    .PARAMETER Force
        Specifies that the operator should be removed without any confirmation.

    .PARAMETER Refresh
        Specifies that the SQL Agent Operator object should be refreshed before removal.
        This is only used when specifying the operator by name.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator

        SQL Agent Operator object.

    .OUTPUTS
        None.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Remove-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator'

        Removes the SQL Agent Operator named 'MyOperator'.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscAgentOperator -Name 'MyOperator'

        Removes the SQL Agent Operator using pipeline input.

    .EXAMPLE
        $operatorObject = Get-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator'
        $operatorObject | Remove-SqlDscAgentOperator

        Removes the SQL Agent Operator using operator object pipeline input.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Remove-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator' -Refresh

        Removes the SQL Agent Operator named 'MyOperator' with explicit refresh of the operator object.
#>
function Remove-SqlDscAgentOperator
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'ByName')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByName')]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByObject')]
        [Microsoft.SqlServer.Management.Smo.Agent.Operator]
        $OperatorObject,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'ByName')]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    # cSpell: ignore RSAO
    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $OperatorObject = Get-AgentOperatorObject -ServerObject $ServerObject -Name $Name -Refresh:$Refresh -ErrorAction $ErrorActionPreference
        }

        $verboseDescriptionMessage = $script:localizedData.Remove_SqlDscAgentOperator_RemoveShouldProcessVerboseDescription -f $OperatorObject.Name, $OperatorObject.Parent.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Remove_SqlDscAgentOperator_RemoveShouldProcessVerboseWarning -f $OperatorObject.Name
        $captionMessage = $script:localizedData.Remove_SqlDscAgentOperator_RemoveShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                $OperatorObject.Drop()
            }
            catch
            {
                $errorMessage = $script:localizedData.Remove_SqlDscAgentOperator_RemoveFailed -f $OperatorObject.Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'RSAO0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $OperatorObject
                    )
                )
            }
        }
    }
}
