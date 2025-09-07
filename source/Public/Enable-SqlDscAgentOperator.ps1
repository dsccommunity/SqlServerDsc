<#
    .SYNOPSIS
        Enables a SQL Agent Operator.

    .DESCRIPTION
        This command enables a SQL Agent Operator on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER OperatorObject
        Specifies a SQL Agent Operator object to enable.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to be enabled.

    .PARAMETER Force
        Specifies that the operator should be enabled without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s operators should be refreshed before
        trying to enable the operator object. This is helpful when operators could have
        been modified outside of the **ServerObject**, for example through T-SQL.
        But on instances with a large amount of operators it might be better to make
        sure the **ServerObject** is recent enough, or pass in **OperatorObject**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $operatorObject = $serverObject | Get-SqlDscAgentOperator -Name 'MyOperator'
        $operatorObject | Enable-SqlDscAgentOperator

        Enables the operator named **MyOperator**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Enable-SqlDscAgentOperator -Name 'MyOperator'

        Enables the operator named **MyOperator**.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        When using the ServerObject parameter set, a Server object can be piped in.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator

        When using the OperatorObject parameter set, an Operator object can be piped in.

    .OUTPUTS
        None.
#>
function Enable-SqlDscAgentOperator
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'OperatorObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Agent.Operator]
        $OperatorObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'ServerObject')]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            if ($Refresh.IsPresent)
            {
                Write-Verbose -Message ($script:localizedData.Enable_SqlDscAgentOperator_RefreshingServerObject)
                $ServerObject.JobServer.Operators.Refresh()
            }

            $errorMessage = $script:localizedData.Enable_SqlDscAgentOperator_OperatorNotFound -f $Name
            $OperatorObject = Assert-SqlDscAgentOperatorExists -ServerObject $ServerObject -Name $Name -ErrorMessage $errorMessage -ErrorId 'ESAO0002'
        }

        $verboseDescriptionMessage = $script:localizedData.Enable_SqlDscAgentOperator_ShouldProcessVerboseDescription -f $OperatorObject.Name, $OperatorObject.Parent.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Enable_SqlDscAgentOperator_ShouldProcessVerboseWarning -f $OperatorObject.Name
        $captionMessage = $script:localizedData.Enable_SqlDscAgentOperator_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                $OperatorObject.Enabled = $true
                $OperatorObject.Alter()
            }
            catch
            {
                $errorMessage = $script:localizedData.Enable_SqlDscAgentOperator_EnableFailed -f $OperatorObject.Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'ESAO0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $OperatorObject
                    )
                )
            }
        }
    }
}
