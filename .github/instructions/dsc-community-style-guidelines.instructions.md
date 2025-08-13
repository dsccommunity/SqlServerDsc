---
applyTo: "**"
---

# DSC Community Guidelines

Assume that the word "command" references to a public command, the word
"function" references to a private function, and the word "resource"
references a Desired State Configuration (DSC) class-based resource.

## Project scripts

Always run project scripts in PowerShell.
The build script is located in the root of the repository and is named
`build.ps1`.
Always run build script from root path.

### Build project

- Always run the build script after code changes in ./source to build the module: `.\build.ps1 -Tasks build`.

### Run tests

- Always use PowerShell or Windows PowerShell to run tests.
- Always build project prior to running tests: `.\build.ps1 -Tasks build`
- Always run `Invoke-Pester` from root path: `Invoke-Pester -Path @('<test paths>') -Output Detailed`
- After adding or changing classes, always run tests in new session.
- To run a test file with code coverage (this can takes a while for large codebases):
  ```powershell
  $config = New-PesterConfiguration
  $config.Run.Path = @('<test paths>')
  $config.CodeCoverage.Enabled = $true
  $config.CodeCoverage.Path = @('./output/builtModule/<ModuleName>')
  $config.CodeCoverage.CoveragePercentTarget = 0
  $config.Output.Verbosity = 'Detailed'
  $config.Run.PassThru = $true
  $result = Invoke-Pester -Configuration $config
  # After running above, get all commands that was missed with a reference to the SourceLineNumber in SourceFile.
  $result.CodeCoverage.CommandsMissed | Where-Object { $_.Function -eq '<FunctionName>' -or $_.Class -eq '<ClassName>' } | Convert-LineNumber -PassThru | Select-Object Class, Function, Command, SourceLineNumber, SourceFile
  ```

## Change log

Always update the Unreleased section in CHANGELOG.md when making changes to the codebase.

## Public commands

PowerShell commands that should be public should always have its separate
script file and the command name as the file name with the .ps1 extension,
these files shall always be placed in the folder source/Public.

Public commands may use private functions to separate logic that can be
reused by other public commands. Separate any logic that can be deemed
reusable.

## Private functions

Private functions (also known as helper functions) should always have its
separate script file and the function name as the file name with the .ps1
extension. These files shall always be placed in the folder source/Private.

## Localization

All strings in public commands, private functions and classes should be localized
using localized string keys.

## Unit tests

Unit tests should be added for all public commands, private functions and
class-based resources.

The unit tests for class-based resources should be
placed in the folder tests/Unit/Classes.
The unit tests for public command should be placed in the folder tests/Unit/Public.
The unit tests for private functions should be placed in the folder tests/Unit/Private.

### Integration tests

All public commands must have an integration test in the folder "tests/Integration/Commands"
