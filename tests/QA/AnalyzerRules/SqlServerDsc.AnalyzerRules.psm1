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
        [System.Management.Automation.Language.FunctionDefinitionAst]
        $FunctionAst
    )

    $applyRuleToFunction = @(
        'Get-TargetResource',
        'Test-TargetResource',
        'Set-TargetResource'
    )

    try
    {
        if ($FunctionAst.Name -in $applyRuleToFunction)
        {
            $diagnosticRecordType = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]
            $diagnosticRecord = @{
                Message  = ''
                Extent   = $null
                RuleName = $null
                Severity = 'Warning'
            }

            $diagnosticRecord['Extent'] = $FunctionAst.Extent
            $diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

            $astFilter = {
                $args[0] -is [System.Management.Automation.Language.CommandAst] `
                -and $args[0].CommandElements.Value -eq 'Import-SQLPSModule'
            }

            # Find all command calls of Import-SQLPSModule in the function.
            $commandAsts = $FunctionAst.FindAll($astFilter, $true)

            # If no calls was found then an error record should be returned.
            if (-not $commandAsts)
            {
                $diagnosticRecord['Message'] = 'The function is not calling Import-SQLPSModule'
                $diagnosticRecord -as $diagnosticRecordType
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

Export-ModuleMember -Function 'Measure-*'
