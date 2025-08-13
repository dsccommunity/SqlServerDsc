---
description: Guidelines for working with the SqlServerDsc PowerShell module.
applyTo: "**/*.psm1,**/*.psd1,**/*.ps1"
---

# SqlServerDsc Module Guidelines

This file contains specific guidelines for working with SqlServerDsc PowerShell module project.

## Public Command Naming

All public command names must have the noun prefixed with 'SqlDsc', e.g.
{Verb}-SqlDsc{Noun}.

## DSC Resource Base Classes

### SqlResourceBase

A derived class should inherit the parent class `SqlResourceBase` (which inherits `ResourceBase`)
if the class-based resource needs to connect to a SQL Server Database Engine.

The parent class `SqlResourceBase` provides the DSC properties `InstanceName`,
`ServerName`, `Credential` and `Reasons` and the method `GetServerObject`
which is used to connect to a SQL Server Database Engine instance.

## SQL Server

### SQL Server Management Objects (SMO)

When developing commands, private functions, class-based resources, or making
modifications to existing functionality, always prefer using SQL Server
Management Objects (SMO) as the primary method for interacting with SQL Server.
Only use T-SQL when it is not possible to achieve the desired functionality
with SMO.

Do not mock SMO types in unit tests, use SMO stub types from SMO.cs.
Always run tests in new session after changing stub types in SMO.cs.

## Integration Testing Environment

### SQL Server Database Engine

Integration tests that depend on an SQL Server Database Engine instance
will run in environments in CI/CD pipelines where an instance DSCSQLTEST
is already installed. Each environment will have SQL Server 2016, 2017,
2019, or 2022.

### SQL Server Reporting Services

Integration tests that depend on an SQL Server Reporting Services instance
will run in environments in CI/CD pipelines where an instance SSRS is already
installed. Each environment will have SQL Server Reporting Services 2016,
2017, 2019, or 2022.

### Power BI Report Server

Integration tests that depend on a Power BI Report Server instance
will run in one environment in CI/CD pipeline where an instance PBIRS is
already installed. The environment will always have the latest Power BI
Report Server version.

## Integration Test Configuration

Integration test script files for public commands must be added to a group
within the 'Integration_Test_Commands_SqlServer' stage in ./azure-pipelines.yml.
Choose the appropriate group number based on the dependencies of the command
being tested (e.g., commands that require Database Engine should be in Group 2
or later, after the Database Engine installation tests).

For integration testing commands use the information in the
tests/Integration/Commands/README.md, which describes the testing environment
including available instances, users, credentials, and other configuration
details.

## Testing

### Unit Tests

For every unit test the following must be added to the top level `BeforeAll`- and `AfterAll`-blocks in the test file:

```powershell
BeforeAll {
    $env:SqlServerDscCI = $true
}

AfterAll {
    Remove-Item -Path 'env:SqlServerDscCI'
}
```

### Integration tests

When using command `Connect-SqlDscDatabaseEngine` always use `Disconnect-SqlDscDatabaseEngine` when connection is no longer needed
