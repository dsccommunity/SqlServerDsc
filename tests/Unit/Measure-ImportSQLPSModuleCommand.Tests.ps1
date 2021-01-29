$customAnalyzerRulesPath = Join-Path -Path $PSScriptRoot -ChildPath '\..\..\source\AnalyzerRules'

. $customAnalyzerRulesPath\Measure-ImportSQLPSModuleCommand.ps1

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
    Context 'When calling the function directly' {
        BeforeAll {
            $astType = 'System.Management.Automation.Language.CommandAst'
            $ruleName = 'Measure-ImportSQLPSModuleCommand'
        }

        Context 'When Get-TargetResource is missing call to Import-SQLPSModule' {
            It 'Should write the correct error record' {
                $definition = '
                    function Get-Something {}

                    function Get-TargetResource
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Get-Something

                        return @{}
                    }
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                $mockAst | Should -Not -BeNullOrEmpty

                $record = Measure-ImportSQLPSModuleCommand -CommandAst $mockAst[0]

                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be 'The function is not calling Import-SQLPSModule'
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When Get-TargetResource have a call to Import-SQLPSModule' {
            It 'Should not return an error record' {
                $definition = '
                    function Import-SQLPSModule {}

                    function Get-TargetResource
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Import-SQLPSModule

                        return @{}
                    }
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                $mockAst | Should -Not -BeNullOrEmpty

                $record = Measure-ImportSQLPSModuleCommand -CommandAst $mockAst[0]

                $record | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $customAnalyzerRulesPath
            }

            $ruleName = "ModuleName\Measure-ImportSQLPSModuleCommand"
        }

        Context 'When Get-TargetResource is missing call to Import-SQLPSModule' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something {}

                    function Get-TargetResource
                    {
                        [CmdletBinding()]
                        [OutputType([System.Collections.Hashtable])]
                        param ()

                        Get-Something

                        return @{}
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be 'The function is not calling Import-SQLPSModule'
                $record.RuleName | Should -Be $ruleName
            }
        }

        # Context 'When While-statement follows style guideline' {
        #     It 'Should not write an error record' {
        #         $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
        #             function Get-Something
        #             {
        #                 $i = 10

        #                 while ($i -gt 0)
        #                 {
        #                     $i--
        #                 }
        #             }
        #         '

        #         $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
        #         $record | Should -BeNullOrEmpty
        #     }
        # }
    }
}
