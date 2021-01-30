cd C:\source\HelpUsers\johlju\SqlServerDsc
Invoke-ScriptAnalyzer `
    -Path .\output\SqlServerDsc\15.0.1\DSCResources\DSC_SqlTraceFlag\*.psm1 `
    -CustomRulePath .\tests\QA\AnalyzerRules\SqlServerDsc.AnalyzerRules.psm1 `
    -IncludeRule @('Measure-*')

Invoke-ScriptAnalyzer `
    -CustomRulePath @(
        '.\output\RequiredModules\DscResource.AnalyzerRules'
        '.\tests\QA\AnalyzerRules\SqlServerDsc.AnalyzerRules.psm1'
    ) `
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
