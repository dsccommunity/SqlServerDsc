# Integration tests for SqlServerDsc

## Debugging

Currently there are no possible to debug the commands on the service Appveyor
since it has not been configured in the `appveyor.yml`.

## SqlServer module

There is a difference what module version of [_SqlServer_](https://www.powershellgallery.com/packages/SqlServer)
is used for what SQL Server release. The integration tests for SqlSetup_
installs the required module version.

SQL Server release | SqlServer module version
--- | ---
SQL Server 2016 | 21.1.18256
SQL Server 2017 | 21.1.18256
SQL Server 2019 | 21.1.18256
SQL Server 2022 | 22.2.0

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

## Integration Tests

### `Install-SqlDscServer`

Installs all the [instances](#instances).

## Instances

These instances is available for integration tests.

Instance | Feature | State
--- | --- | ---
DSCSQLTEST | SQLENGINE | - | Running
MSSQLSERVER | SQLENGINE | - | Stopped

All running Database Engine instances also have a SQL Server Agent that is started.

The instance DSCSQLTEST support mixed authentication mode, and will have
both Named Pipes and TCP/IP protocol enabled.

> [!NOTE]
> Some services are stopped to save memory on the build worker. See the
> column *State*.

### Instance properties

- **Collation:** Finnish\_Swedish\_CI\_AS
- **InstallSharedDir:** C:\Program Files\Microsoft SQL Server
- **InstallSharedWOWDir:** C:\Program Files (x86)\Microsoft SQL Server

## Users

The following local users are created and can be used by integration tests.

<!-- markdownlint-disable MD013 -->
User | Password | Permission | Description
--- | --- | --- | ---
.\SqlInstall | P@ssw0rd1 | Local Windows administrator. Administrator of Database Engine instance DSCSQLTEST\*. | Runs Setup for the default instance.
.\SqlAdmin | P@ssw0rd1 | Administrator of all SQL Server instances. |
.\svc-SqlPrimary | yig-C^Equ3 | Local user. | Runs the SQL Server Agent service.
.\svc-SqlAgentPri | yig-C^Equ3 | Local user. | Runs the SQL Server Agent service.
.\svc-SqlSecondary | yig-C^Equ3 | Local user. | Used by other tests, but created here.
.\svc-SqlAgentSec | yig-C^Equ3 | Local user. | Used by other tests.

Login | Password | Permission | Description
--- | --- | --- | ---
sa | P@ssw0rd1 | sysadmin | Administrator of the Database Engine instances DSCSQLTEST. |
<!-- markdownlint-enable MD013 -->

## Image media (ISO)

The path to the image media is set in the environment variable `$env:IsoImagePath`
and the drive letter used to mount the image media is save in `$env:IsoDriveLetter`.

This information can be used by integration tests that depends on
the image media.
