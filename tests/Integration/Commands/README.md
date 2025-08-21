# Integration tests for SqlServerDsc

## Debugging

There is a build worker that runs on the service Appveyor. Appveyor allows
you to use RDP to access the build worker which can be helpful when debugging
integration test.

What images is used, what SQL Server version that is installed, and what
integration tests is run is controlled by the file `appveyor.yml` in the
project folder.

For debug purpose every contributor is allowed to change the file `appveyor.yml`
on a PR for debug purpose. But before a PR will be merged the file `appveyor.yml`
must be reverted so that is looks like it does on the **main** branch (unless
an issue is being fixed or a maintainer says otherwise).

On each build run Appveyor outputs the IP address, account, and password
for the connection. This information is at the top of each builds output
log and can be found here: https://ci.appveyor.com/project/dsccommunity/sqlserverdsc

By default the build worker is terminated once the build finishes, to keep
the build worker online after the build finishes uncomment the required line
in the file `appveyor.yml`. The build worker will always be terminated after
60 minutes for open source projects.

## Depends On

For it to be easier to write integration tests for a command that depends
on other command, each commands integration test should have run order number.

If an integration test is dependent on one or more integration test
then the run order for the new integration tests should be set to
a higher run order number than the highest run order of the dependent
integration tests.

**Below are the integration tests listed in the run order, and with the dependency
to each other. Dependencies are made to speed up the testing.**

Command | Run order # | Depends on # | Use instance
--- | --- | --- | ---
Install-SqlDscServer | 1 | - | -
New-SqlDscLogin | 2 | 1 (Install-SqlDscServer), Prerequisites | DSCSQLTEST

## Integration Tests

### `Prerequisites`´

Makes sure all dependencies are in place. This integration test always runs
first.

### `Install-SqlDscServer`

Installs all the [instances](#instances).

### `New-SqlDscLogin`

Creates test logins on the DSCSQLTEST instance for use by other
integration tests. Tests SQL Server logins, Windows user logins,
and Windows group logins (using the local SqlIntegrationTestGroup).
The main test login `IntegrationTestSqlLogin` and the Windows group
login for `.\SqlIntegrationTestGroup` are left in place after the
test completes so other tests can use them for validation.

### `New-SqlDscRole`

Creates test server roles on the DSCSQLTEST instance for use by other
integration tests. Creates several shared roles:
- `SharedTestRole_ForIntegrationTests` (used by Get-SqlDscRole tests)
- `SharedTestRole_ForRemoval` (used by Remove-SqlDscRole tests)  
- `SqlDscIntegrationTestRole_Persistent` (persistent role with sa owner that remains on the instance)

The persistent role `SqlDscIntegrationTestRole_Persistent` is left in place after the
test completes so other tests can use it for validation.

### `Get-SqlDscRole`

Tests retrieving server roles from the DSCSQLTEST instance using both
system roles and the shared test roles created by New-SqlDscRole tests.

### `Remove-SqlDscRole`

Tests removing server roles from the DSCSQLTEST instance. Uses the shared
test roles created by New-SqlDscRole tests. The persistent role
`SqlDscIntegrationTestRole_Persistent` is intentionally not removed to
ensure it remains available for other integration tests.
## Dependencies

### SqlServer module

There is different module version of [_SqlServer_](https://www.powershellgallery.com/packages/SqlServer)
used depending on SQL Server release. The integration tests installs the
required module version according to the below table.

SQL Server release | SqlServer module version
--- | ---
SQL Server 2016 | 21.1.18256
SQL Server 2017 | 21.1.18256
SQL Server 2019 | 21.1.18256
SQL Server 2022 | 22.2.0

### Instances

These instances is available for integration tests.

<!-- cSpell:ignore DSCSQLTEST -->

Instance | Feature | State
--- | --- | ---
DSCSQLTEST | SQLENGINE |  Running
MSSQLSERVER | SQLENGINE | Stopped

All running Database Engine instances also have a SQL Server Agent that is started.

The instance DSCSQLTEST support mixed authentication mode, and will have
both Named Pipes and TCP/IP protocol enabled.

> [!NOTE]
> Some services are stopped to save memory on the build worker. See the
> column _State_.

#### Instance properties

- **Collation:** Finnish\_Swedish\_CI\_AS
- **InstallSharedDir:** C:\Program Files\Microsoft SQL Server
- **InstallSharedWOWDir:** C:\Program Files (x86)\Microsoft SQL Server

### Users

The following local users are created and can be used by integration tests.

<!-- markdownlint-disable MD013 -->
User | Password | Permission | Description
--- | --- | --- | ---
.\SqlInstall | P@ssw0rd1 | Local Windows administrator and sysadmin | Runs Setup for all the instances.
.\SqlAdmin | P@ssw0rd1 | Local Windows user and sysadmin | Administrator of all the SQL Server instances.
.\SqlIntegrationTest | P@ssw0rd1 | Local Windows user | User for SQL integration testing.
.\svc-SqlPrimary | yig-C^Equ3 | Local Windows user. | Runs the SQL Server service.
.\svc-SqlAgentPri | yig-C^Equ3 | Local Windows user. | Runs the SQL Server Agent service.
.\svc-SqlSecondary | yig-C^Equ3 | Local Windows user. | Runs the SQL Server service in multi node scenarios.
.\svc-SqlAgentSec | yig-C^Equ3 | Local Windows user. | Runs the SQL Server Agent service in multi node scenarios.

### Groups

The following local groups are created and can be used by integration tests.

Group | Description
--- | ---
.\SqlIntegrationTestGroup | Local Windows group for SQL integration testing.

### SQL Server Logins

Login | Password | Permission | Description
--- | --- | --- | ---
sa | P@ssw0rd1 | sysadmin | Administrator of all the Database Engine instances.
IntegrationTestSqlLogin | P@ssw0rd123! | - | SQL Server login created by New-SqlDscLogin integration tests for testing purposes.
.\SqlIntegrationTestGroup | - | - | Windows group login created by New-SqlDscLogin integration tests for testing purposes.

### SQL Server Roles

Role | Owner | Permission | Description
--- | --- | --- | ---
SqlDscIntegrationTestRole_Persistent | sa | - | Server role created by New-SqlDscRole integration tests that remains on the instance for testing purposes.
<!-- markdownlint-enable MD013 -->

### Image media (ISO)

The environment variable `$env:IsoDriveLetter` contains the drive letter
(e.g. G, H, I) where the image media is mounted. The environment variable
`$env:IsoDrivePath` contains the drive root path
(e.g. G:\\, H:\\, I:\\) where the image media is mounted.

This information can be used by integration tests that depends on
the image media.
