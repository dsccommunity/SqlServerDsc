cd C:\source\HelpUsers\johlju\SqlServerDsc
# Invoke-ScriptAnalyzer `
#     -Path .\output\SqlServerDsc\15.0.1\DSCResources\DSC_SqlTraceFlag\*.psm1 `
#     -CustomRulePath C:\source\HelpUsers\johlju\SqlServerDsc\tests\QA\AnalyzerRules\Measure-ImportSQLPSModuleCommand.psm1 `
#     -IncludeRule @('Measure-*')

Invoke-ScriptAnalyzer `
    -CustomRulePath C:\source\HelpUsers\johlju\SqlServerDsc\tests\QA\AnalyzerRules\Measure-ImportSQLPSModuleCommand.psm1 `
    -IncludeRule @('Measure-*') `
    -ScriptDefinition @'
function Get-Something {}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param ()

    Get-Something

    return @{}
}
'@
