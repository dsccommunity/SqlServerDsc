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

<!-- markdownlint-disable MD013 -->
Command | Run order # | Depends on # | Use instance | Creates persistent objects
--- | --- | --- | --- | ---
Prerequisites | 0 | - | - | Sets up dependencies
Save-SqlDscSqlServerMediaFile | 0 | - | - | Downloads SQL Server media files
ConvertTo-SqlDscEditionName | 0 | - | - | -
Import-SqlDscPreferredModule | 0 | - | - | -
Install-SqlDscServer | 1 | 0 (Prerequisites) | - | DSCSQLTEST instance
Connect-SqlDscDatabaseEngine | 1 | 0 (Prerequisites) | DSCSQLTEST | -
Assert-SqlDscLogin | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscLogin | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | IntegrationTestSqlLogin, SqlIntegrationTestGroup login
Get-SqlDscLogin | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscConfigurationOption | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscConfigurationOption | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsSupportedFeature | 2 | 0 (Prerequisites) | - | -
Get-SqlDscManagedComputer | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscManagedComputerInstance | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscManagedComputerService | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscServerProtocolName | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscServerProtocol | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscConfigurationOption | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscStartupParameter | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscTraceFlag | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Disable-SqlDscLogin | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsLoginEnabled | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscRole | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | SqlDscIntegrationTestRole_Persistent role
Get-SqlDscRole | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsRole | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Grant-SqlDscServerPermission | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Grants CreateEndpoint permission to role
Get-SqlDscServerPermission | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscServerPermission | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
ConvertFrom-SqlDscServerPermission | 2 | 0 (Prerequisites) | - | -
Test-SqlDscServerPermission | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Deny-SqlDscServerPermission | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Denies AlterTrace permission to login (persistent)
Revoke-SqlDscServerPermission | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscDatabase | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscDatabase | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Test databases
Set-SqlDscDatabase | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscDatabase | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
ConvertTo-SqlDscDatabasePermission | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscDatabasePermission | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscAgentAlert | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscAgentAlert | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Test alerts
Set-SqlDscAgentAlert | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscAgentAlertProperty | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsAgentAlert | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscAgentOperator | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscAgentOperator | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | SqlDscIntegrationTestOperator_Persistent operator
Set-SqlDscAgentOperator | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsAgentOperator | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Assert-SqlDscAgentOperator | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Enable-SqlDscAgentOperator | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Disable-SqlDscAgentOperator | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Disable-SqlDscAudit | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Add-SqlDscTraceFlag | 2 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Remove-SqlDscAgentAlert | 8 | 2 (New-SqlDscAgentAlert) | DSCSQLTEST | -
Remove-SqlDscAgentOperator | 8 | 2 (New-SqlDscAgentOperator) | DSCSQLTEST | -
Remove-SqlDscAudit | 8 | - | DSCSQLTEST | -
Remove-SqlDscDatabase | 8 | 2 (New-SqlDscDatabase) | DSCSQLTEST | -
Remove-SqlDscRole | 8 | 2 (New-SqlDscRole) | DSCSQLTEST | -
Remove-SqlDscLogin | 8 | 2 (New-SqlDscLogin) | DSCSQLTEST | -
Remove-SqlDscTraceFlag | 8 | 1 (Install-SqlDscServer) | DSCSQLTEST | -
Uninstall-SqlDscServer | 9 | 8 (Remove commands) | - | -
Install-SqlDscReportingService | 1 | 0 (Prerequisites) | - | SSRS instance
Get-SqlDscInstalledInstance | 2 | 1 (Install-SqlDscReportingService), 0 (Prerequisites) | SSRS | -
Get-SqlDscRSSetupConfiguration | 2 | 1 (Install-SqlDscReportingService), 0 (Prerequisites) | SSRS | -
Test-SqlDscRSInstalled | 2 | 1 (Install-SqlDscReportingService), 0 (Prerequisites) | SSRS | -
Repair-SqlDscReportingService | 8 | 1 (Install-SqlDscReportingService) | SSRS | -
Uninstall-SqlDscReportingService | 9 | 8 (Repair-SqlDscReportingService) | - | -
Install-SqlDscBIReportServer | 1 | 0 (Prerequisites) | - | PBIRS instance
Repair-SqlDscBIReportServer | 8 | 1 (Install-SqlDscBIReportServer) | PBIRS | -
Uninstall-SqlDscBIReportServer | 9 | 8 (Repair-SqlDscBIReportServer) | - | -
<!-- markdownlint-enable MD013 -->

## Integration Tests

### `Prerequisites`´

Makes sure all dependencies are in place. This integration test always runs
first.

### `Install-SqlDscServer`

Installs all the [instances](#instances).

### `New-SqlDscLogin`

Creates the test login `IntegrationTestSqlLogin` and the Windows group
login `.\SqlIntegrationTestGroup` that remains on the instance for other
tests to use.

### `New-SqlDscRole`

Creates a persistent role `SqlDscIntegrationTestRole_Persistent`
with sa owner that remains on the instance for other tests to use.

### `Grant-SqlDscServerPermission`

Grants `CreateEndpoint` permission to the role `SqlDscIntegrationTestRole_Persistent`

### `Deny-SqlDscServerPermission`

Creates a persistent `AlterTrace` denial on the persistent principals `IntegrationTestSqlLogin`
that remains for other tests to validate against.

### `New-SqlDscAgentOperator`

Creates a persistent agent operator `SqlDscIntegrationTestOperator_Persistent`
that remains on the instance for other tests to use.

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
IntegrationTestSqlLogin | P@ssw0rd123! | AlterTrace (Deny) | SQL Server login created by New-SqlDscLogin integration tests. AlterTrace permission denied by Deny-SqlDscServerPermission integration tests for server permission testing.
.\SqlIntegrationTestGroup | - | - | Windows group login created by New-SqlDscLogin integration tests for testing purposes.

### SQL Server Roles

Role | Owner | Permission | Description
--- | --- | --- | ---
SqlDscIntegrationTestRole_Persistent | sa | CreateEndpoint | Server role created by New-SqlDscRole integration tests. CreateEndpoint permission granted by Grant-SqlDscServerPermission integration tests for server permission testing.
<!-- markdownlint-enable MD013 -->

### Image media (ISO)

The environment variable `$env:IsoDriveLetter` contains the drive letter
(e.g. G, H, I) where the image media is mounted. The environment variable
`$env:IsoDrivePath` contains the drive root path
(e.g. G:\\, H:\\, I:\\) where the image media is mounted.

This information can be used by integration tests that depends on
the image media.
