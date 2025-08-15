---
description: Guidelines for DSC community contributions.
applyTo: "**"
---

# DSC Community Guidelines

Assume that the word "command" refers to a public command, the word
"function" refers to a private function, and the word "resource"
refers to a Desired State Configuration (DSC) class-based resource.

## Project scripts

Always run project scripts in PowerShell.
The build script is located in the root of the repository and is named
`build.ps1`.
- Always run the build script from the repository root.

### Build project

- Always run the build script after code changes in ./source to build the module: `.\build.ps1 -Tasks build`.

### Run tests

- Always use PowerShell or Windows PowerShell to run tests.
- Always build the project before running tests: `.\build.ps1 -Tasks build`
- Always run `Invoke-Pester` from the repository root: `Invoke-Pester -Path @('<test paths>') -Output Detailed`
- After adding or changing classes, always run tests in a new session.
- To get code coverage (this can take a while for large codebases):
  ```powershell
  .\build.ps1 -Tasks noop
  $config = New-PesterConfiguration
  $config.Run.Path = @('<test paths>')
  $config.CodeCoverage.Enabled = $true
  $config.CodeCoverage.Path = @('./output/builtModule/<ModuleName>')
  $config.CodeCoverage.CoveragePercentTarget = 0
  $config.Output.Verbosity = 'None'
  $config.Run.PassThru = $true
  $result = Invoke-Pester -Configuration $config
  # After running above, list missed commands; no output means no missed lines.
  $result.CodeCoverage.CommandsMissed | Where-Object { $_.Function -eq 'FunctionName' -or $_.Class -eq 'ClassName' } | Convert-LineNumber -PassThru | Select-Object Class, Function, Command, SourceLineNumber, SourceFile
  ```

## Change log

Always update the Unreleased section in CHANGELOG.md with every change.

## Public commands

Public commands must each have their own script file named after
the command (with the .ps1 extension). These files must be placed in
source/Public.

Public commands may use private functions to separate logic that can be
reused by other public commands. Separate any logic that can be deemed
reusable.

## Private functions

Before creating a private function, check if it there is an available command in
the module [DscResource.Common](https://raw.githubusercontent.com/wiki/dsccommunity/DscResource.Common/_Sidebar.md) that can be used.

Private functions (helper functions) must each have their own script file,
named after the function (with the .ps1 extension). These files must be
placed in source/Private

## Localization

All strings in public commands, private functions, and class-based resources
must be localized using string keys.

## Unit tests

Unit tests should be added for all public commands, private functions, and
class-based resources.

Place unit tests for class-based resources in tests/Unit/Classes,
for public commands in tests/Unit/Public, and
for private functions in tests/Unit/Private.

### Integration tests

All public commands must have an integration test in tests/Integration/Commands.
