<#
    .SYNOPSIS
        Validates that each *-TargetResource calls Import-SQLPSModule.

    .DESCRIPTION
        Every *-TargetResource function should include a call to Import-SQLPSModule
        so that SMO assemblies are loaded into the PowerShell session.

    .EXAMPLE
        Measure-ImportSQLPSModuleCommand -WhileStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.CommandAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None.
#>
function Measure-ImportSQLPSModuleCommand
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]
        $CommandAst
    )

    try
    {
        $diagnosticRecordType = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]
        $diagnosticRecord = @{
            Message  = ''
            Extent   = $null
            RuleName = $null
            Severity = 'Warning'
        }

        $diagnosticRecord['Extent'] = $CommandAst.Extent
        $diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        if ($CommandAst.CommandElements.Value -ne 'Import-SQLPSModule')
        {
            $diagnosticRecord['Message'] = 'The function is not calling Import-SQLPSModule'
            $diagnosticRecord -as $diagnosticRecordType
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
