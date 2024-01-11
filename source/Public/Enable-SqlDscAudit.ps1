<#
    .SYNOPSIS
        Enables a server audit.

    .DESCRIPTION
        This command enables a server audit in a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER AuditObject
        Specifies an audit object to enable.

    .PARAMETER Name
        Specifies the name of the server audit to be enabled.

    .PARAMETER Force
        Specifies that the audit should be enabled without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s audits should be refreshed before
        trying to enable the audit object. This is helpful when audits could have
        been modified outside of the **ServerObject**, for example through T-SQL.
        But on instances with a large amount of audits it might be better to make
        sure the **ServerObject** is recent enough, or pass in **AuditObject**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $auditObject = $sqlServerObject | Get-SqlDscAudit -Name 'MyFileAudit'
        $auditObject | Enable-SqlDscAudit

        Enables the audit named **MyFileAudit**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $sqlServerObject | Enable-SqlDscAudit -Name 'MyFileAudit'

        Enables the audit named **MyFileAudit**.

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

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            $getSqlDscAuditParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                Refresh      = $Refresh
                ErrorAction  = 'Stop'
            }

            # If this command does not find the audit it will throw an exception.
            $auditObjectArray = Get-SqlDscAudit @getSqlDscAuditParameters

            # Pick the only object in the array.
            $AuditObject = $auditObjectArray | Select-Object -First 1
        }

        $verboseDescriptionMessage = $script:localizedData.Audit_Enable_ShouldProcessVerboseDescription -f $AuditObject.Name, $AuditObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Audit_Enable_ShouldProcessVerboseWarning -f $AuditObject.Name
        $captionMessage = $script:localizedData.Audit_Enable_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            $AuditObject.Enable()
        }
    }
}
