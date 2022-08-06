<#
    .SYNOPSIS
        Enables a server audit.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER AuditObject
        Specifies a audit object to enable.

    .PARAMETER Name
        Specifies the name of the server audit to be enabled.

    .PARAMETER Force
        Specifies that the audit should be enabled with out any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s audits should be refreshed before
        trying to enable the audit object. This is helpful when audits could have
        been modified outside of the **ServerObject**, for example through T-SQL.
        But on instances with a large amount of audits it might be better to make
        sure the **ServerObject** is recent enough, or pass in **AuditObject**.

    .OUTPUTS
        None.
#>
function Enable-SqlDscAudit
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'AuditObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Audit]
        $AuditObject,

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

    if ($Force.IsPresent)
    {
        $ConfirmPreference = 'None'
    }

    # TODO: this should use Get-SqlDscAudit
    if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
    {
        if ($Refresh.IsPresent)
        {
            # Make sure the audits are up-to-date to get any newly created audits.
            $ServerObject.Audits.Refresh()
        }

        $AuditObject = $ServerObject.Audits[$Name]

        if (-not $AuditObject)
        {
            $missingDatabaseMessage = $script:localizedData.Audit_Missing -f $Name

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $missingDatabaseMessage,
                    'ESDA0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DatabaseName
                )
            )
        }
    }

    $verboseDescriptionMessage = $script:localizedData.Audit_Enable_ShouldProcessVerboseDescription -f $AuditObject.Name, $AuditObject.Parent.InstanceName
    $verboseWarningMessage = $script:localizedData.Audit_Enable_ShouldProcessVerboseWarning -f $AuditObject.Name
    $captionMessage = $script:localizedData.Audit_Enable_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $AuditObject.Enable()
    }
}
