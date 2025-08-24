---
description: SqlServerDsc-specific guidelines for AI development.
applyTo: "**"
---

# SqlServerDsc Guidelines

## Naming
- Public commands: `{Verb}-SqlDsc{Noun}` format

## Resources
- Database Engine resources: inherit `SqlResourceBase`
- `SqlResourceBase` provides: `InstanceName`, `ServerName`, `Credential`, `Reasons`, `GetServerObject()`

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
- Integration tests: Use `Disconnect-SqlDscDatabaseEngine` after `Connect-SqlDscDatabaseEngine`
- Test config: tests/Integration/Commands/README.md and tests/Integration/Resources/README.md
- Integration test script files must be added to a group
within the test stage in ./azure-pipelines.yml.
- Choose the appropriate group number based on the required dependencies

## Unit tests
- When unit test tests classes or commands that contain SMO types, e.g. `[Microsoft.SqlServer.Management.Smo.*]`
  - Ensure they are properly stubbed in SMO.cs
  - Load SMO stub types from SMO.cs in unit test files, e.g. `Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"`
  - After changing SMO stub types, run tests in a new PowerShell session for changes to take effect.
