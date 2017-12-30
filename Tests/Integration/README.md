# Integration tests for SqlServerDsc

For it to be easier to write integration tests for a resource that depends on
other resources, this will list the run order of the integration tests that keep
their configuration on the AppVeyor build worker. For example, the integration
tests for SqlAlwaysOnService enables and then disables the AlwaysOn functionality,
so that integration test is not listed here.

If a integration test should use one or more of these previous integration test
configurations then the run order for the new integration test should be set to
a higher run order number than the highest run order of the dependent integration
tests.

## SqlSetup

**Run order:** 1

The integration tests will install the following instances and leave them on the
AppVeyor build worker for other integration tests to use.

Instance | Feature | AS server mode
--- | --- | ---
DSCSQL2016 | SQLENGINE,AS,CONN,BC,SDK | MULTIDIMENSIONAL
DSCTABULAR | AS,CONN,BC,SDK | TABULAR
MSSQLSERVER | SQLENGINE,CONN,BC,SDK | -

### Properties for all instances

- **Collation:** Finnish\_Swedish\_CI\_AS
- **InstallSharedDir:** C:\Program Files\Microsoft SQL Server
- **InstallSharedWOWDir:** C:\Program Files (x86)\Microsoft SQL Server

### Users

The following local users are created on the AppVeyor build worker and can
be used by other integration tests.

User | Password | Permission | Description
--- | --- | --- | ---
.\SqlInstall | P@ssw0rd1 | Local administrator | Runs Setup for the default instance
.\SqlAdmin | P@ssw0rd1 | Administrator on all SQL Server instances |
.\svc-Sql | yig-C^Equ3 | Local user | Runs the SQL Server service.
.\svc-SqlAgent | yig-C^Equ3 | Local user | Runs the SQL Server Agent service.

## SqlRS

**Run order:** 2

The integration tests will install the following instances and leave it on the
AppVeyor build worker for other integration tests to use.

Instance | Feature | Description
--- | --- | ---
DSCRS2016 | RS | The Reporting Services is left initialized, and in working state.

### Properties for the instance

- **Collation:** Finnish\_Swedish\_CI\_AS
- **InstallSharedDir:** C:\Program Files\Microsoft SQL Server
- **InstallSharedWOWDir:** C:\Program Files (x86)\Microsoft SQL Server
- **DatabaseServerName:** `$env:COMPUTERNAME`
- **DatabaseInstanceName:** DSCSQL2016

## SqlDatabaseDefaultLocation

**Run order:** 2

The integration test will change the data, log and backup path of instance
DSCSQL2016 to the following.

Data | Log | Backup
--- | --- | ---
C:\SQLData | C:\SQLLog | C:\Backups
