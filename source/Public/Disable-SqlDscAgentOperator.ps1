<#
    .SYNOPSIS
        Disables a SQL Agent Operator.

    .DESCRIPTION
        This command disables a SQL Agent Operator on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER OperatorObject
        Specifies a SQL Agent Operator object to disable.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to be disabled.

    .PARAMETER Force
        Specifies that the operator should be disabled without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s operators should be refreshed before
        trying to disable the operator object. This is helpful when operators could have
        been modified outside of the **ServerObject**, for example through T-SQL.
        But on instances with a large amount of operators it might be better to make
        sure the **ServerObject** is recent enough, or pass in **OperatorObject**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $operatorObject = $serverObject | Get-SqlDscAgentOperator -Name 'MyOperator'
        $operatorObject | Disable-SqlDscAgentOperator

        Disables the operator named **MyOperator**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Disable-SqlDscAgentOperator -Name 'MyOperator'

        Disables the operator named **MyOperator**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Disable-SqlDscAgentOperator -Name 'MyOperator' -Force

        Disables the operator without confirmation using **-Force**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Disable-SqlDscAgentOperator -Name 'MyOperator' -Refresh

        Refreshes the server operators collection before disabling **MyOperator**.

    .INPUTS
        [Microsoft.SqlServer.Management.Smo.Server]

        Server object accepted from the pipeline (ServerObject parameter set).

    .INPUTS
        [Microsoft.SqlServer.Management.Smo.Agent.Operator]

        Operator object accepted from the pipeline (OperatorObject parameter set).

    .OUTPUTS
        None.
#>
function Disable-SqlDscAgentOperator
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
                Write-Verbose -Message ($script:localizedData.Disable_SqlDscAgentOperator_RefreshingServerObject)
                $ServerObject.JobServer.Operators.Refresh()
            }

            $getSqlDscAgentOperatorParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                ErrorAction  = 'Stop'
            }

            # If this command does not find the operator it will return $null.
            $OperatorObject = Get-SqlDscAgentOperator @getSqlDscAgentOperatorParameters

            if (-not $OperatorObject)
            {
                $errorMessage = $script:localizedData.Disable_SqlDscAgentOperator_OperatorNotFound -f $Name
                New-ObjectNotFoundException -Message $errorMessage
            }
        }

        $verboseDescriptionMessage = $script:localizedData.Disable_SqlDscAgentOperator_ShouldProcessVerboseDescription -f $OperatorObject.Name, $OperatorObject.Parent.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Disable_SqlDscAgentOperator_ShouldProcessVerboseWarning -f $OperatorObject.Name
        $captionMessage = $script:localizedData.Disable_SqlDscAgentOperator_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.Disable_SqlDscAgentOperator_DisablingOperator -f $OperatorObject.Name)
                
                $OperatorObject.Enabled = $false
                $OperatorObject.Alter()
                
                Write-Verbose -Message ($script:localizedData.Disable_SqlDscAgentOperator_OperatorDisabled -f $OperatorObject.Name)
            }
            catch
            {
                $errorMessage = $script:localizedData.Disable_SqlDscAgentOperator_DisableFailed -f $OperatorObject.Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}