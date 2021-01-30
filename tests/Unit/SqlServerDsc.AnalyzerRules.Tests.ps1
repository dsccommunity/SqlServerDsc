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

Describe 'Measure-ImportSQLPSModuleCommand' {
    BeforeAll {
        $expectedErrorRecordMessage = 'The function is not calling Import-SQLPSModule or Connect-SQL.'
    }

    Context 'When calling the function directly' {
        BeforeAll {
            $astType = 'System.Management.Automation.Language.FunctionDefinitionAst'
            $ruleName = 'Measure-ImportSQLPSModuleCommand'

            $testCases = @(
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

        Context 'When function is missing call to Import-SQLPSModule' {
            It 'Should write the correct error record for function <FunctionName>' -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $FunctionName
                )

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
                $record = Measure-ImportSQLPSModuleCommand -FunctionAst $mockAst[1]

                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $expectedErrorRecordMessage
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When function have a call to Import-SQLPSModule' {
            It 'Should not return an error record for function <FunctionName>' -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $FunctionName
                )

                $definition = "
                    function Import-SQLPSModule {}

                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Import-SQLPSModule

                        return @{}
                    }
                "

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                $mockAst | Should -Not -BeNullOrEmpty

                # We should evaluate the second function in the script definition.
                $record = Measure-ImportSQLPSModuleCommand -FunctionAst $mockAst[1]

                $record | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $customAnalyzerRulesModulePath
            }

            $ruleName = 'SqlServerDsc.AnalyzerRules\Measure-ImportSQLPSModuleCommand'
        }

        Context 'When function is missing call to Import-SQLPSModule' {
            It 'Should write the correct error record for function <FunctionName>' -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $FunctionName
                )

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

        Context 'When function is not calling any commands' {
            It 'Should write the correct error record for function <FunctionName>' -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $FunctionName
                )

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

        Context 'When function is missing call to Import-SQLPSModule' {
            It 'Should not write an error record for function <FunctionName>' -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $FunctionName
                )

                $invokeScriptAnalyzerParameters['ScriptDefinition'] = "
                    function Import-SQLPSModule {}

                    function $FunctionName
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Import-SQLPSModule

                        return @{}
                    }
                "

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record | Should -BeNullOrEmpty
            }
        }
    }
}
