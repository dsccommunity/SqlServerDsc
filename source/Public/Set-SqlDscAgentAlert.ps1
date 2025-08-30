<#
    .SYNOPSIS
        Updates a SQL Agent Alert.

    .DESCRIPTION
        This command updates an existing SQL Agent Alert on a SQL Server Database Engine
        instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER AlertObject
        Specifies an alert object to update.

    .PARAMETER Name
        Specifies the name of the SQL Agent Alert to update.

    .PARAMETER Severity
        Specifies the severity level for the SQL Agent Alert. Valid range is 0 to 25.
        Cannot be used together with MessageId.

    .PARAMETER MessageId
        Specifies the message ID for the SQL Agent Alert. Valid range is 0 to 2147483647.
        Cannot be used together with Severity.

    .PARAMETER PassThru
        If specified, the updated alert object will be returned.

    .PARAMETER Refresh
        Specifies that the alert object should be refreshed before updating. This
        is helpful when alerts could have been modified outside of the **ServerObject**,
        for example through T-SQL.

    .PARAMETER Force
        Specifies that the alert should be updated without prompting for confirmation.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

        Microsoft.SqlServer.Management.Smo.Agent.Alert

        SQL Agent Alert object to update.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Alert
            Returned when parameter **PassThru** is specified.

        None
            No output is returned unless **PassThru** is specified.
    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscAgentAlert -ServerObject $serverObject -Name 'MyAlert' -Severity 16

        Updates the SQL Agent Alert named 'MyAlert' to severity level 16.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $alertObject = $serverObject | Get-SqlDscAgentAlert -Name 'MyAlert'
        $alertObject | Set-SqlDscAgentAlert -MessageId 50001

        Updates the SQL Agent Alert using pipeline input with alert object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $updatedAlert = $serverObject | Set-SqlDscAgentAlert -Name 'MyAlert' -Severity 16 -PassThru

        Updates the alert and returns the updated object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscAgentAlert -ServerObject $serverObject -Name 'MyAlert' -Severity 16 -Force

        Updates the SQL Agent Alert named 'MyAlert' to severity level 16 without prompting for confirmation.
#>
function Set-SqlDscAgentAlert
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Alert])]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'AlertObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Agent.Alert]
        $AlertObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateRange(0, 25)]
        [System.Int32]
        $Severity,

        [Parameter()]
        [ValidateRange(0, 2147483647)]
        [System.Int32]
        $MessageId,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter(ParameterSetName = 'ServerObject')]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        $ErrorActionPreference = 'Stop'
    }

    # cSpell: ignore SSAA
    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        # Validate that both Severity and MessageId are not specified
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -MutuallyExclusiveList1 @('Severity') -MutuallyExclusiveList2 @('MessageId')

        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            if ($Refresh.IsPresent)
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentAlert_RefreshingServerObject)
                $ServerObject.JobServer.Alerts.Refresh()
            }

            $alertObjectToUpdate = Get-AgentAlertObject -ServerObject $ServerObject -Name $Name

            if ($null -eq $alertObjectToUpdate)
            {
                $errorMessage = $script:localizedData.Set_SqlDscAgentAlert_AlertNotFound -f $Name
                New-ObjectNotFoundException -Message $errorMessage
            }
        }
        else
        {
            $alertObjectToUpdate = $AlertObject
        }

        $verboseDescriptionMessage = $script:localizedData.Set_SqlDscAgentAlert_UpdateShouldProcessVerboseDescription -f $alertObjectToUpdate.Name, $alertObjectToUpdate.Parent.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Set_SqlDscAgentAlert_UpdateShouldProcessVerboseWarning -f $alertObjectToUpdate.Name
        $captionMessage = $script:localizedData.Set_SqlDscAgentAlert_UpdateShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentAlert_UpdatingAlert -f $alertObjectToUpdate.Name)

                $hasChanges = $false

                if ($PSBoundParameters.ContainsKey('Severity'))
                {
                    if ($alertObjectToUpdate.Severity -ne $Severity)
                    {
                        Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentAlert_SettingSeverity -f $Severity, $alertObjectToUpdate.Name)
                        $alertObjectToUpdate.Severity = $Severity
                        $alertObjectToUpdate.MessageId = 0 # Must set any conflicting properties to 0
                        $hasChanges = $true
                    }
                    else
                    {
                        Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentAlert_SeverityAlreadyCorrect -f $Severity, $alertObjectToUpdate.Name)
                    }
                }

                if ($PSBoundParameters.ContainsKey('MessageId'))
                {
                    if ($alertObjectToUpdate.MessageId -ne $MessageId)
                    {
                        Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentAlert_SettingMessageId -f $MessageId, $alertObjectToUpdate.Name)
                        $alertObjectToUpdate.MessageId = $MessageId
                        $alertObjectToUpdate.Severity = 0 # Must set any conflicting properties to 0
                        $hasChanges = $true
                    }
                    else
                    {
                        Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentAlert_MessageIdAlreadyCorrect -f $MessageId, $alertObjectToUpdate.Name)
                    }
                }

                if ($hasChanges)
                {
                    $alertObjectToUpdate.Alter()
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentAlert_AlertUpdated -f $alertObjectToUpdate.Name)
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentAlert_NoChangesNeeded -f $alertObjectToUpdate.Name)
                }

                if ($PassThru.IsPresent)
                {
                    return $alertObjectToUpdate
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.Set_SqlDscAgentAlert_UpdateFailed -f $alertObjectToUpdate.Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}
