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
to each other. Dependencies are made to speed up the testing. The tests are
organized by Azure Pipeline job.**

### Integration_Test_Commands_SqlServer

Tests for SQL Server Database Engine commands.

<!-- markdownlint-disable MD013 -->
Command | Run order # | Depends on # | Use instance | Creates persistent objects
--- | --- | --- | --- | ---
Prerequisites | 0 | - | - | Sets up dependencies
Get-SqlDscPreferredModule | 1 | 0 (Prerequisites) | - | -
Save-SqlDscSqlServerMediaFile | 0 | - | - | Downloads SQL Server media files
ConvertTo-SqlDscEditionName | 0 | - | - | -
Import-SqlDscPreferredModule | 0 | - | - | -
Install-SqlDscServer | 1 | 0 (Prerequisites) | - | DSCSQLTEST instance
PostInstallationConfiguration | 2 | 1 (Install-SqlDscServer) | DSCSQLTEST | SSL certificate configuration
Connect-SqlDscDatabaseEngine | 3 | 2 (PostInstallationConfiguration), 0 (Prerequisites) | DSCSQLTEST | -
Disconnect-SqlDscDatabaseEngine | 3 | 2 (PostInstallationConfiguration), 0 (Prerequisites) | DSCSQLTEST | -
Invoke-SqlDscQuery | 3 | 2 (PostInstallationConfiguration), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Test database and table
Assert-SqlDscLogin | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscLogin | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | IntegrationTestSqlLogin, SqlIntegrationTestGroup login
Get-SqlDscLogin | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscConfigurationOption | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscConfigurationOption | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsSupportedFeature | 4 | 0 (Prerequisites) | - | -
Get-SqlDscInstalledInstance | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsInstalledInstance | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscManagedComputer | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscManagedComputerInstance | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscManagedComputerService | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscServerProtocolName | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscServerProtocol | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscTraceFlag | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscConfigurationOption | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscStartupParameter | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscTraceFlag | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Disable-SqlDscLogin | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Enable-SqlDscLogin | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Enable-SqlDscAudit | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsLogin | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsLoginEnabled | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscRole | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | SqlDscIntegrationTestRole_Persistent role
Get-SqlDscRole | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscStartupParameter | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsRole | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsDatabasePrincipal | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Test database and database principals
Grant-SqlDscServerPermission | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Grants CreateEndpoint permission to role
Get-SqlDscServerPermission | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscServerPermission | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
ConvertTo-SqlDscServerPermission | 2 | 2 (Grant-SqlDscServerPermission), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
ConvertFrom-SqlDscServerPermission | 4 | 0 (Prerequisites) | - | -
Test-SqlDscServerPermission | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Deny-SqlDscServerPermission | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Denies AlterTrace permission to login (persistent)
Revoke-SqlDscServerPermission | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscDatabase | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
ConvertFrom-SqlDscDatabasePermission | 4 | 0 (Prerequisites) | - | -
New-SqlDscDatabase | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | SqlDscIntegrationTestDatabase_Persistent database
New-SqlDscDatabaseSnapshot | 5 | 4 (New-SqlDscDatabase), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Backup-SqlDscDatabase | 5 | 4 (New-SqlDscDatabase), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscCompatibilityLevel | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscDatabaseProperty | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscDatabaseOwner | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsDatabase | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscDatabaseProperty | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscDatabasePermission | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Test database, Test user
ConvertTo-SqlDscDatabasePermission | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Set-SqlDscDatabasePermission | 4 | 4 (New-SqlDscLogin), 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscAgentAlert | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscAgentAlert | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Test alerts
New-SqlDscAudit | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | Test audits
Set-SqlDscAgentAlert | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscAgentAlertProperty | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsAgentAlert | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscAgentOperator | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
New-SqlDscAgentOperator | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | SqlDscIntegrationTestOperator_Persistent operator
Set-SqlDscAgentOperator | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Test-SqlDscIsAgentOperator | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Assert-SqlDscAgentOperator | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Enable-SqlDscAgentOperator | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Disable-SqlDscAgentOperator | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Get-SqlDscAudit | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Disable-SqlDscAudit | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Add-SqlDscTraceFlag | 4 | 1 (Install-SqlDscServer), 0 (Prerequisites) | DSCSQLTEST | -
Remove-SqlDscAgentAlert | 7 | 4 (New-SqlDscAgentAlert) | DSCSQLTEST | -
Remove-SqlDscAgentOperator | 7 | 4 (New-SqlDscAgentOperator) | DSCSQLTEST | -
Remove-SqlDscAudit | 7 | - | DSCSQLTEST | -
Set-SqlDscAudit | 7 | - | DSCSQLTEST | -
Remove-SqlDscDatabase | 7 | 4 (New-SqlDscDatabase) | DSCSQLTEST | -
Remove-SqlDscRole | 7 | 4 (New-SqlDscRole) | DSCSQLTEST | -
Remove-SqlDscLogin | 7 | 4 (New-SqlDscLogin) | DSCSQLTEST | -
Remove-SqlDscTraceFlag | 7 | 1 (Install-SqlDscServer) | DSCSQLTEST | -
Repair-SqlDscServer | 8 | 1 (Install-SqlDscServer) | DSCSQLTEST | -
Initialize-SqlDscRebuildDatabase | 8 | 1 (Install-SqlDscServer) | DSCSQLTEST | -
Uninstall-SqlDscServer | 9 | 8 (Repair-SqlDscServer), 8 (Initialize-SqlDscRebuildDatabase) | - | -
<!-- markdownlint-enable MD013 -->

### Integration_Test_Commands_SqlServer_PreparedImage

Tests for SQL Server Database Engine commands using the prepared image installation
workflow. This test suite runs in a separate job with its own CI worker, testing
`Install-SqlDscServer` with `-PrepareImage` followed by `Complete-SqlDscImage`.

<!-- markdownlint-disable MD013 -->
Command | Run order # | Depends on # | Use instance | Creates persistent objects
--- | --- | --- | --- | ---
Prerequisites | 0 | - | - | Sets up dependencies
Save-SqlDscSqlServerMediaFile | 0 | - | - | Downloads SQL Server media files
Import-SqlDscPreferredModule | 0 | - | - | -
Install-SqlDscServer (PrepareImage) | 1 | 0 (Prerequisites) | - | DSCSQLTEST instance prepared
Complete-SqlDscImage | 2 | 1 (Install-SqlDscServer) | DSCSQLTEST | Completes prepared image installation
Uninstall-SqlDscServer | 9 | 2 (Complete-SqlDscImage) | - | -
<!-- markdownlint-enable MD013 -->

### Integration_Test_Commands_ReportingServices

Tests for SQL Server Reporting Services commands.

<!-- markdownlint-disable MD013 -->
Command | Run order # | Depends on # | Use instance | Creates persistent objects
--- | --- | --- | --- | ---
Prerequisites | 0 | - | - | Sets up dependencies
Save-SqlDscSqlServerMediaFile | 0 | - | - | Downloads SQL Server media files
Import-SqlDscPreferredModule | 0 | - | - | -
Install-SqlDscReportingService | 1 | 0 (Prerequisites) | - | SSRS instance
Get-SqlDscInstalledInstance | 2 | 1 (Install-SqlDscReportingService), 0 (Prerequisites) | SSRS | -
Get-SqlDscRSSetupConfiguration | 2 | 1 (Install-SqlDscReportingService), 0 (Prerequisites) | SSRS | -
Test-SqlDscIsInstalledInstance | 2 | 1 (Install-SqlDscReportingService), 0 (Prerequisites) | SSRS | -
Test-SqlDscRSInstalled | 2 | 1 (Install-SqlDscReportingService), 0 (Prerequisites) | SSRS | -
Repair-SqlDscReportingService | 8 | 1 (Install-SqlDscReportingService) | SSRS | -
Uninstall-SqlDscReportingService | 9 | 8 (Repair-SqlDscReportingService) | - | -
<!-- markdownlint-enable MD013 -->

### Integration_Test_Commands_BIReportServer

Tests for Power BI Report Server commands.

<!-- markdownlint-disable MD013 -->
Command | Run order # | Depends on # | Use instance | Creates persistent objects
--- | --- | --- | --- | ---
Prerequisites | 0 | - | - | Sets up dependencies
Save-SqlDscSqlServerMediaFile | 0 | - | - | Downloads SQL Server media files
Import-SqlDscPreferredModule | 0 | - | - | -
Install-SqlDscPowerBIReportServer | 1 | 0 (Prerequisites) | - | PBIRS instance
Get-SqlDscInstalledInstance | 2 | 1 (Install-SqlDscPowerBIReportServer), 0 (Prerequisites) | PBIRS | -
Get-SqlDscRSSetupConfiguration | 2 | 1 (Install-SqlDscPowerBIReportServer), 0 (Prerequisites) | PBIRS | -
Test-SqlDscIsInstalledInstance | 2 | 1 (Install-SqlDscPowerBIReportServer), 0 (Prerequisites) | PBIRS | -
Test-SqlDscRSInstalled | 2 | 1 (Install-SqlDscPowerBIReportServer), 0 (Prerequisites) | PBIRS | -
Repair-SqlDscPowerBIReportServer | 8 | 1 (Install-SqlDscPowerBIReportServer) | PBIRS | -
Uninstall-SqlDscPowerBIReportServer | 9 | 8 (Repair-SqlDscPowerBIReportServer) | - | -
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

### `New-SqlDscDatabase`

Creates a persistent database `SqlDscIntegrationTestDatabase_Persistent`
with Simple recovery model that remains on the instance for other tests to use.

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

### SQL Server Databases

Database | Recovery Model | Description
--- | --- | ---
SqlDscIntegrationTestDatabase_Persistent | Simple | Database created by New-SqlDscDatabase integration tests for use by other integration tests.
<!-- markdownlint-enable MD013 -->

### Image media (ISO)

The environment variable `$env:IsoDriveLetter` contains the drive letter
(e.g. G, H, I) where the image media is mounted. The environment variable
`$env:IsoDrivePath` contains the drive root path
(e.g. G:\\, H:\\, I:\\) where the image media is mounted.

This information can be used by integration tests that depends on
the image media.
