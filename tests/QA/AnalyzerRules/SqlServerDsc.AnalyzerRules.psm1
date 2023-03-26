<#
    .SYNOPSIS
        Validates that each *-TargetResource calls Import-SqlDscPreferredModule.

    .DESCRIPTION
        Every *-TargetResource function should include a call to Import-SqlDscPreferredModule
        so that SMO assemblies are loaded into the PowerShell session.

    .EXAMPLE
        Measure-CommandsNeededToLoadSMO -FunctionAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.CommandAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None.
#>
function Measure-CommandsNeededToLoadSMO
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
                -and (
                    $args[0].CommandElements.Value -eq 'Import-SqlDscPreferredModule' `
                    -or $args[0].CommandElements.Value -eq 'Connect-SQL'
                )
            }

            # Find all command calls of Import-SqlDscPreferredModule in the function.
            $commandAsts = $FunctionAst.FindAll($astFilter, $true)

            # If no calls was found then an error record should be returned.
            if (-not $commandAsts)
            {
                $diagnosticRecord['Message'] = 'The function is not calling Import-SqlDscPreferredModule or Connect-SQL. If it is meant not to, then suppress the rule ''SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO'' with a justification. See https://github.com/PowerShell/PSScriptAnalyzer#suppressing-rules for more information.'
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
