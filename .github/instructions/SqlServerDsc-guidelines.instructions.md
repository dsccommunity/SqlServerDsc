---
description: SqlServerDsc-specific guidelines for AI development.
applyTo: "**"
---

# SqlServerDsc Requirements

## Build & Test Workflow Requirements
- Never use VS Code task, always use PowerShell scripts via terminal, from repository root
- Setup build and test environment (once per `pwsh` session): `./build.ps1 -Tasks noop`
- Build project before running tests: `./build.ps1 -Tasks build`
- Run tests without coverage (wildcards allowed): `Invoke-PesterJob -Path '{tests filepath}' -SkipCodeCoverage`
- Run tests with coverage (wildcards allowed): `Invoke-PesterJob -Path '{tests filepath}' -EnableSourceLineMapping -FilterCodeCoverageResult '{pattern}'`
- Run QA tests: `Invoke-PesterJob -Path 'tests/QA' -SkipCodeCoverage`
- Never run integration tests locally

## Naming
- Public commands: `{Verb}-SqlDsc{Noun}` format
- Private function: `{Verb}-{Noun}` format

## Resources
- Database Engine resources: inherit `SqlResourceBase`
  - Add any DSC properties whose values cannot be enforced as desired state to `$this.ExcludeDscProperties`
  - `SqlResourceBase` provides: `InstanceName`, `ServerName`, `Port`, `Protocol`, `Credential`, `Reasons`, `GetServerObject()`
  - Constructor: `MyResourceName() : base () { }` (no $PSScriptRoot parameter)

## SQL Server Interaction
- Always prefer SMO over T-SQL
- Unit tests: Use SMO stub types from SMO.cs, never mock SMO types

## Testing CI Environment
- Database Engine: instance `DSCSQLTEST`
- Reporting Services: instance `SSRS`
- Power BI Report Server: instance `PBIRS`

## Tests Requirements
- Unit tests: Add `$env:SqlServerDscCI = $true` in `BeforeAll`, remove in `AfterAll`
- Integration tests:
  - Use `Connect-SqlDscDatabaseEngine` for SQL Server DB session, and always with correct CI credentials
  - Use `Disconnect-SqlDscDatabaseEngine` after `Connect-SqlDscDatabaseEngine`
  - Test config: tests/Integration/Commands/README.md and tests/Integration/Resources/README.md
  - Integration test script files must be added to a group within the test stage in ./azure-pipelines.yml.
    - Choose the appropriate group number based on the required dependencies

## Unit tests
- When unit test tests classes or commands that contain SMO types, e.g. `[Microsoft.SqlServer.Management.Smo.*]`
  - Ensure they are properly stubbed in SMO.cs
  - Load SMO stub types from SMO.cs in unit test files, e.g. `Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"`
  - After changing SMO stub types, run tests in a new PowerShell session for changes to take effect.
