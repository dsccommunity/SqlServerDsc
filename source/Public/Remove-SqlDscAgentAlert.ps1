<#
    .SYNOPSIS
        Removes a SQL Agent Alert.

    .DESCRIPTION
        This command removes a SQL Agent Alert from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER AlertObject
        Specifies an alert object to remove.

    .PARAMETER Name
        Specifies the name of the SQL Agent Alert to remove.

    .PARAMETER Force
        Specifies that the alert should be removed without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s alerts should be refreshed before
        trying to remove the alert object. This is helpful when alerts could have
        been modified outside of the **ServerObject**, for example through T-SQL.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $alertObject = $serverObject | Get-SqlDscAgentAlert -Name 'MyAlert'
        $alertObject | Remove-SqlDscAgentAlert

        Removes the alert named **MyAlert**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscAgentAlert -Name 'MyAlert'

        Removes the alert named **MyAlert**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscAgentAlert -Name 'MyAlert' -Force

        Removes the alert named **MyAlert** without confirmation.

    .OUTPUTS
        None.
#>
function Remove-SqlDscAgentAlert
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'AlertObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Agent.Alert]
        $AlertObject,

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

    # cSpell: ignore RSAA
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
                Write-Verbose -Message ($script:localizedData.Remove_SqlDscAgentAlert_RefreshingServerObject)
                $ServerObject.JobServer.Alerts.Refresh()
            }

            $alertObjectToRemove = Get-AgentAlertObject -ServerObject $ServerObject -Name $Name

            if (-not $alertObjectToRemove)
            {
                Write-Verbose -Message ($script:localizedData.Remove_SqlDscAgentAlert_AlertNotFound -f $Name)
                return
            }
        }
        else
        {
            $alertObjectToRemove = $AlertObject
        }

        $verboseDescriptionMessage = $script:localizedData.Remove_SqlDscAgentAlert_RemoveShouldProcessVerboseDescription -f $alertObjectToRemove.Name, $alertObjectToRemove.Parent.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Remove_SqlDscAgentAlert_RemoveShouldProcessVerboseWarning -f $alertObjectToRemove.Name
        $captionMessage = $script:localizedData.Remove_SqlDscAgentAlert_RemoveShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.Remove_SqlDscAgentAlert_RemovingAlert -f $alertObjectToRemove.Name)

                $alertObjectToRemove.Drop()

                Write-Verbose -Message ($script:localizedData.Remove_SqlDscAgentAlert_AlertRemoved -f $alertObjectToRemove.Name)
            }
            catch
            {
                $errorMessage = $script:localizedData.Remove_SqlDscAgentAlert_RemoveFailed -f $alertObjectToRemove.Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}
