# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    $testCase = @(
        @{
            FunctionName = 'Get-TargetResource'
        }
        @{
            FunctionName = 'Test-TargetResource'
        }
        @{
            FunctionName = 'Set-TargetResource'
        }
    )
}

BeforeAll {
    $customAnalyzerRulesModulePath = Join-Path -Path $PSScriptRoot -ChildPath '\..\QA\AnalyzerRules\SqlServerDsc.AnalyzerRules.psm1'

    Import-Module -Name $customAnalyzerRulesModulePath -Force

    <#
    .SYNOPSIS
        Helper function to return Ast objects,
        to be able to test custom rules.

    .PARAMETER ScriptDefinition
        The script definition to return ast for.

    .PARAMETER AstType
        The Ast type to return;
        System.Management.Automation.Language.ParameterAst,
        System.Management.Automation.Language.NamedAttributeArgumentAst,
        etc.

    .NOTES
        This is a helper function for the tests.

        Run the custom rules directly bu running:

        Invoke-ScriptAnalyzer `
            -Path .\source\DSCResources\**\*.psm1 `
            -CustomRulePath .\tests\QA\AnalyzerRules\SqlServerDsc.AnalyzerRules.psm1 `
            -IncludeRule @('Measure-*')
    #>
    function Get-AstFromDefinition
    {
        [CmdletBinding()]
        [OutputType([System.Management.Automation.Language.Ast[]])]
        param
        (
            [Parameter(Mandatory = $true)]
            [System.String]
            $ScriptDefinition,

            [Parameter(Mandatory = $true)]
            [System.String]
            $AstType
        )

        $parseErrors = $null

        $definitionAst = [System.Management.Automation.Language.Parser]::ParseInput($ScriptDefinition, [ref] $null, [ref] $parseErrors)

        if ($parseErrors)
        {
            throw $parseErrors
        }

        $astFilter = {
            $args[0] -is $AstType
        }

        $foundAsts = $definitionAst.FindAll($astFilter, $true)

        return $foundAsts
    }
}

Describe 'Measure-CommandsNeededToLoadSMO' {
    BeforeAll {
        <#
            Must import the PSScriptAnalyzer module so the the tests can use the type
            [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]
        #>
        Import-Module -Name 'PSScriptAnalyzer'

        $expectedErrorRecordMessage = 'The function is not calling Import-SqlDscPreferredModule or Connect-SQL. If it is meant not to, then suppress the rule ''SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO'' with a justification. See https://github.com/PowerShell/PSScriptAnalyzer#suppressing-rules for more information.'
    }

    Context 'When calling the function directly' {
        BeforeAll {
            $astType = 'System.Management.Automation.Language.FunctionDefinitionAst'
            $ruleName = 'Measure-CommandsNeededToLoadSMO'
        }

        Context 'When a function do not have a call to neither Import-SqlDscPreferredModule or Connect-SQL' {
            It 'Should write the correct error record for function <FunctionName>' -ForEach $testCase {
                $definition = "
                    function Get-Something {}

                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Get-Something

                        return @{}
                    }
                "

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                $mockAst | Should -Not -BeNullOrEmpty

                # We should evaluate the second function in the script definition.
                $record = Measure-CommandsNeededToLoadSMO -FunctionAst $mockAst[1]

                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $expectedErrorRecordMessage
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When a function have a call to Import-SqlDscPreferredModule' {
            It 'Should not return an error record for function <FunctionName>' -ForEach $testCase {
                $definition = "
                    function Import-SqlDscPreferredModule {}

                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Import-SqlDscPreferredModule

                        return @{}
                    }
                "

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                $mockAst | Should -Not -BeNullOrEmpty

                # We should evaluate the second function in the script definition.
                $record = Measure-CommandsNeededToLoadSMO -FunctionAst $mockAst[1]

                $record | Should -BeNullOrEmpty
            }
        }

        Context 'When a function have a call to Connect-SQL' {
            It 'Should not return an error record for function <FunctionName>' -ForEach $testCase {
                $definition = "
                    function Connect-SQL {}

                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Connect-SQL

                        return @{}
                    }
                "

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                $mockAst | Should -Not -BeNullOrEmpty

                # We should evaluate the second function in the script definition.
                $record = Measure-CommandsNeededToLoadSMO -FunctionAst $mockAst[1]

                $record | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When using PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $customAnalyzerRulesModulePath
            }

            $ruleName = 'SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO'
        }

        Context 'When a function do not have a call to neither Import-SqlDscPreferredModule or Connect-SQL' {
            It 'Should write the correct error record for function <FunctionName>' -ForEach $testCase {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = "
                    function Get-Something {}

                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Get-Something

                        return @{}
                    }
                "

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be $expectedErrorRecordMessage
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When a function is not calling any commands at all' {
            It 'Should write the correct error record for function <FunctionName>' -ForEach $testCase {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = "
                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        return @{}
                    }
                "

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be $expectedErrorRecordMessage
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When a function have a call to Import-SqlDscPreferredModule' {
            It 'Should not write an error record for function <FunctionName>' -ForEach $testCase {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = "
                    function Import-SqlDscPreferredModule {}

                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Import-SqlDscPreferredModule

                        return @{}
                    }
                "

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record | Should -BeNullOrEmpty
            }
        }

        Context 'When a function have a call to Connect-SQL' {
            It 'Should not write an error record for function <FunctionName>' -ForEach $testCase {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = "
                    function Connect-SQL {}

                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Connect-SQL

                        return @{}
                    }
                "

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record | Should -BeNullOrEmpty
            }
        }
    }
}
