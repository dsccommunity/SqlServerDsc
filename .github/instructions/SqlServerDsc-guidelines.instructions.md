---
description: SqlServerDsc-specific guidelines for AI development.
applyTo: "**"
---

# SqlServerDsc Guidelines

## Naming
- Public commands: `{Verb}-SqlDsc{Noun}` format
- Private function: `{Verb}-{Noun}` format

## Resources
- Database Engine resources: inherit `SqlResourceBase`
  - Add `InstanceName`, `ServerName`, and `Credential` to `$this.ExcludeDscProperties`
  - `SqlResourceBase` provides: `InstanceName`, `ServerName`, `Credential`, `Reasons`, `GetServerObject()`
  - Constructor: `MyResourceName() : base () { }` (no $PSScriptRoot parameter)

## SQL Server Interaction
- Always prefer SMO over T-SQL
- Unit tests: Use SMO stub types from SMO.cs, never mock SMO types
- Run tests in new session after changing SMO.cs

## Testing CI Environment
- Database Engine: instance `DSCSQLTEST`
- Reporting Services: instance `SSRS`
- Power BI Report Server: instance `PBIRS`

## Test Requirements
- Unit tests: Add `$env:SqlServerDscCI = $true` in `BeforeAll`, remove in `AfterAll`
- Integration tests:
  - If requiring SQL Server DB, start the Windows service in `BeforeAll`, stop it in `AfterAll`.
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
