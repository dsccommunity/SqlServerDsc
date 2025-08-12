---
applyTo: "**"
---

# DSC Community Guidelines

## Project scripts

Always run project scripts in PowerShell.
The build script is located in the root of the repository and is named
`build.ps1`.

### Build project

- Always run the build script after code changes in ./source to build the module: `.\build.ps1 -Tasks build`.

### Run tests

- To run tests, always run `.\build.ps1 -Tasks noop` or `.\build.ps1 -Tasks noop` prior to running `Invoke-Pester`.
- To run single test file, always run `.\build.ps1 -Tasks noop` together with `Invoke-Pester`,
  e.g `.\build.ps1 -Tasks noop;Invoke-Pester -Path '<test path>' -Output Detailed`
- `.\build.ps1 -Tasks test` which will run all QA and unit tests in the project
  with code coverage. Add `-CodeCoverageThreshold 0` to disable code coverage, e.g.
  `.\build.ps1 -Tasks test -CodeCoverageThreshold 0`.

## Change log

Always update the Unreleased section in CHANGELOG.md when making changes to the codebase.
