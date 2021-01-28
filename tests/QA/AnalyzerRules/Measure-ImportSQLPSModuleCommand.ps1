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
        None
#>
function Measure-ImportSQLPSModuleCommand
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.CommandAst]
        $ImportSQLPSModuleCommandAst
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

        Write-Verbose 'eh' -verbose
        $diagnosticRecord['Extent'] = $ImportSQLPSModuleCommandAst.Extent
        $diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        if ($ImportSQLPSModuleCommandAst.CommandElements.Value -eq 'Get-ComputerName')
        {
            $script:diagnosticRecord['Message'] = 'The function is not calling Import-SQLPSModule'
            $script:diagnosticRecord -as $diagnosticRecordType
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
