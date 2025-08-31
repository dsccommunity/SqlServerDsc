<#
    .SYNOPSIS
        Disconnect from a SQL Server Database Engine instance.

    .DESCRIPTION
        Disconnect from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies a current server connection object.

    .PARAMETER Force
        Specifies that there is no confirmation before disconnect.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject

        Connects and then disconnects from the default instance on the local server.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine | Disconnect-SqlDscDatabaseEngine

        Connects and then disconnects from the default instance on the local server.

    .OUTPUTS
        None.
#>
function Disconnect-SqlDscDatabaseEngine
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.Data.DataSet])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        $verboseDescriptionMessage = $script:localizedData.DatabaseEngine_Disconnect_ShouldProcessVerboseDescription -f $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.DatabaseEngine_Disconnect_ShouldProcessVerboseWarning -f $ServerObject.InstanceName
        $captionMessage = $script:localizedData.DatabaseEngine_Disconnect_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            $ServerObject.ConnectionContext.Disconnect()
        }
    }
}
