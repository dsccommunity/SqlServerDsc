cd C:\source\HelpUsers\johlju\SqlServerDsc
Invoke-ScriptAnalyzer `
    -Path .\output\SqlServerDsc\15.0.1\DSCResources\DSC_SqlTraceFlag\*.psm1 `
    -CustomRulePath C:\source\HelpUsers\johlju\SqlServerDsc\source\AnalyzerRules `
    -IncludeRule @('Measure-*', 'PSDSCDscTestsPresent') `
    -IncludeDefaultRules
