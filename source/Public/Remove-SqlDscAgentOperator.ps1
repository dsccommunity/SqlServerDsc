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
        $Name
    )

    # cSpell: ignore RSAO
    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            Write-Verbose -Message ($script:localizedData.Remove_SqlDscAgentOperator_RefreshingServerObject)
            
            $ServerObject.JobServer.Operators.Refresh()
            
            $OperatorObject = Get-SqlDscAgentOperator -ServerObject $ServerObject -Name $Name

            if (-not $OperatorObject)
            {
                Write-Verbose -Message ($script:localizedData.Remove_SqlDscAgentOperator_OperatorNotFound -f $Name)
                return
            }
        }

        $verboseDescriptionMessage = $script:localizedData.Remove_SqlDscAgentOperator_RemoveShouldProcessVerboseDescription -f $OperatorObject.Name, $OperatorObject.Parent.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Remove_SqlDscAgentOperator_RemoveShouldProcessVerboseWarning -f $OperatorObject.Name
        $captionMessage = $script:localizedData.Remove_SqlDscAgentOperator_RemoveShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.Remove_SqlDscAgentOperator_RemovingOperator -f $OperatorObject.Name)

                $OperatorObject.Drop()

                Write-Verbose -Message ($script:localizedData.Remove_SqlDscAgentOperator_OperatorRemoved -f $OperatorObject.Name)
            }
            catch
            {
                $errorMessage = $script:localizedData.Remove_SqlDscAgentOperator_RemoveFailed -f $OperatorObject.Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}

