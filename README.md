# SqlServerDsc

The **SqlServerDsc** module contains DSC resources for deployment and
configuration of Microsoft SQL Server.

[![Build Status](https://dev.azure.com/dsccommunity/SqlServerDsc/_apis/build/status/dsccommunity.SqlServerDsc?branchName=master)](https://dev.azure.com/dsccommunity/SqlServerDsc/_build/latest?definitionId=11&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/SqlServerDsc/11/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/SqlServerDsc/11/master)](https://dsccommunity.visualstudio.com/SqlServerDsc/_test/analytics?definitionId=11&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/SqlServerDsc?label=SqlServerDsc%20Preview)](https://www.powershellgallery.com/packages/SqlServerDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/SqlServerDsc?label=SqlServerDsc)](https://www.powershellgallery.com/packages/SqlServerDsc/)

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing)
and the specific [Contributing to SqlServerDsc](https://github.com/dsccommunity/SqlServerDsc/blob/master/CONTRIBUTING.md)
guidelines.

## Installation

### From GitHub source code

To manually install the module, download the source code from GitHub and unzip
the contents to the '$env:ProgramFiles\WindowsPowerShell\Modules' folder.

### From PowerShell Gallery

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

```powershell
Find-Module -Name SqlServerDsc | Install-Module
```

To confirm installation, run the below command and ensure you see the SQL Server
DSC resources available:

```powershell
Get-DscResource -Module SqlServerDsc
```

## Requirements

The minimum Windows Management Framework (PowerShell) version required is 5.0
or higher, which ships with Windows 10 or Windows Server 2016,
but can also be installed on Windows 7 SP1, Windows 8.1, Windows Server 2012,
and Windows Server 2012 R2.

## Examples

You can review the [Examples](/source/Examples) directory in the SqlServerDsc module
for some general use scenarios for all of the resources that are in the module.

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

### Deprecated resources

The documentation, examples, unit test, and integration tests have been removed
for these deprecated resources. These resources will be removed
in a future release.

* SqlDatabaseOwner _(replaced by a property in [**SqlDatabase**](#sqldatabase))_.
* SqlDatabaseRecoveryModel _(replaced by a property in [**SqlDatabase**](#sqldatabase))_.
* SqlServerEndpointState _(replaced by a property in [**SqlEndpoint**](#sqlendpoint))_.
* SqlServerNetwork _(replaced by [**SqlProtocol**](#sqlprotocol) and_
  _[**SqlProtocolTcpIp**](#sqlprotocoltcpip))_.

## Resources

* [**SqlAG**](#sqlag)
  resource to ensure an availability group is present or absent.
* [**SqlAGDatabase**](#sqlagdatabase)
  to manage the database membership in Availability Groups.
* [**SqlAgentAlert**](#sqlagentalert)
  resource to manage SQL Agent Alerts.
* [**SqlAgentFailsafe**](#sqlagentfailsafe)
  resource to manage SQL Agent Failsafe Operator.
* [**SqlAgentOperator**](#sqlagentoperator)
  resource to manage SQL Agent Operators.
* [**SqlAGListener**](#sqlaglistener)
  Create or remove an availability group listener.
* [**SqlAGReplica**](#sqlagreplica)
  resource to ensure an availability group replica is present or absent.
* [**SqlAlias**](#sqlalias) resource to manage SQL Server client Aliases.
* [**SqlAlwaysOnService**](#sqlalwaysonservice) resource to enable
  always on on a SQL Server.
* [**SqlDatabase**](#sqldatabase) resource to manage ensure database
  is present or absent.
* [**SqlDatabaseDefaultLocation**](#sqldatabasedefaultlocation) resource
  to manage default locations for Data, Logs, and Backups for SQL Server
* [**SqlDatabaseObjectPermission**](#sqldatabaseobjectpermission) resource
  to manage the permissions of database objects in a database for a SQL
  Server instance.
* [**SqlDatabasePermission**](#sqldatabasepermission) resource to
  manage SQL database permissions.
* [**SqlDatabaseRole**](#sqldatabaserole) resource to manage SQL database roles.
* [**SqlDatabaseUser**](#sqldatabaseuser) resource to manage SQL database users.
* [**SqlRS**](#sqlrs) configures SQL Server Reporting.
  Services to use a database engine in another instance.
* [**SqlRSSetup**](#sqlrssetup) Installs the standalone
  [Microsoft SQL Server Reporting Services](https://docs.microsoft.com/en-us/sql/reporting-services/create-deploy-and-manage-mobile-and-paginated-reports).
* [**SqlScript**](#sqlscript) resource to extend DSC Get/Set/Test
  functionality to T-SQL.
* [**SqlScriptQuery**](#sqlscriptquery) resource to extend DSC Get/Set/Test
  functionality to T-SQL.
* [**SqlConfiguration**](#sqlconfiguration) resource to manage
  [SQL Server Configuration Options](https://msdn.microsoft.com/en-us/library/ms189631.aspx).
* [**SqlDatabaseMail**](#sqldatabasemail) resource
  to manage SQL Server Database Mail.
* [**SqlEndpoint**](#sqlendpoint) resource to ensure database endpoint
  is present or absent.
* [**SqlEndpointPermission**](#sqlendpointpermission) Grant or revoke
  permission on the endpoint.
* [**SqlLogin**](#sqllogin) resource to manage SQL logins.
* [**SqlMaxDop**](#sqlmaxdop) resource to manage MaxDegree of Parallelism
  for SQL Server.
* [**SqlMemory**](#sqlmemory) resource to manage Memory for SQL Server.
* [**SqlPermission**](#sqlpermission) Grant or revoke permission on
  the SQL Server.
* [**SqlProtocol**](#sqlprotocol) resource manage the SQL Server
  protocols for a SQL Server instance.
* [**SqlProtocolTcpIp**](#sqlprotocoltcpip) resource manage the TCP/IP
  protocol IP address groups for a SQL Server instance.
* [**SqlReplication**](#sqlreplication) resource to manage SQL Replication
  distribution and publishing.
* [**SqlRole**](#sqlrole) resource to manage SQL server roles.
* [**SqlSecureConnection**](#sqlsecureconnection) resource to
  enable encrypted SQL connections.
* [**SqlServiceAccount**](#sqlserviceaccount) Manage the service account
  for SQL Server services.
* [**SqlSetup**](#sqlsetup) installs a standalone SQL Server instance.
* [**SqlWaitForAG**](#sqlwaitforag) resource to
  wait until availability group is created on primary server.
* [**SqlWindowsFirewall**](#sqlwindowsfirewall) configures firewall settings to
  allow remote access to a SQL Server instance.

### SqlServiceAccount

Manage the service account for SQL Server services.

#### Requirements

* Target machine must have access to the SQLPS PowerShell module or the SqlServer
  PowerShell module.

#### Parameters

* **`[String]` ServerName** (Key): The host name of the SQL Server to be configured.
* **`[String]` ServiceType** (Key): The service type for **InstanceName**.
  { DatabaseEngine | SQLServerAgent | Search | IntegrationServices
  | AnalysisServices | ReportingServices | SQLServerBrowser
  | NotificationServices }
* **`[PSCredential]` ServiceAccount** (Required): The service account that should
  be used when running the service.
* **`[String]` InstanceName** (Write): The name of the SQL instance to be configured.
  Default value is `$env:COMPUTERNAME`.
* **`[Boolean]` RestartService** (Write): Determines whether the service is
  automatically restarted when a change to the configuration was needed.
* **`[Boolean]` Force** (Write): Forces the service account to be updated.
  Useful for password changes. This will cause `Set-TargetResource` to be run on
  each consecutive run.
* **`[String]` VersionNumber** (Write): The version number of the SQL Server,
  mandatory for when IntegrationServices is used as **ServiceType**.
  Eg. 130 for SQL 2016.

#### Read-Only Properties from Get-TargetResource

* **`[String]` ServiceAccountName** _(Read)_: Returns the service account username
  for the service.

#### Examples

* [Run service under a user account](/source/Examples/Resources/SqlServiceAccount/1-ConfigureServiceAccount-UserAccount.ps1)
* [Run service with a virtual account](/source/Examples/Resources/SqlServiceAccount/2-ConfigureServiceAccount-VirtualAccount.ps1)

#### Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlServiceAccount).

### SqlSetup

Installs SQL Server on the target node.

#### Requirements

* Target machine must be running Windows Server 2012 or later.
* For configurations that utilize the 'InstallFailoverCluster' action, the following
  parameters are required (beyond those required for the standalone installation).
  See the article [Install SQL Server from the Command Prompt](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
  under the section [Failover Cluster Parameters](https://msdn.microsoft.com/en-us/library/ms144259.aspx#Anchor_8)
  for more information.
  * InstanceName (can be MSSQLSERVER if you want to install a default clustered
    instance).
  * FailoverClusterNetworkName
  * FailoverClusterIPAddress
  * Additional parameters need when installing Database Engine.
    * InstallSQLDataDir
    * AgtSvcAccount
    * SQLSvcAccount
    * SQLSysAdminAccounts
  * Additional parameters need when installing Analysis Services.
    * ASSysAdminAccounts
    * AsSvcAccount
* The parameters below can only be used when installing SQL Server 2016 or
  later:
  * SqlTempdbFileCount
  * SqlTempdbFileSize
  * SqlTempdbFileGrowth
  * SqlTempdbLogFileSize
  * SqlTempdbLogFileGrowth
* Major version upgrades are supported if the action "upgrade" is specified.

> **Note:** It is not possible to add or remove features to a SQL Server failover
cluster. This is a limitation of SQL Server. See article
[You cannot add or remove features to a SQL Server 2008, SQL Server 2008 R2, or
SQL Server 2012 failover cluster](https://support.microsoft.com/en-us/help/2547273/you-cannot-add-or-remove-features-to-a-sql-server-2008,-sql-server-2008-r2,-or-sql-server-2012-failover-cluster).

#### Feature flags

Feature flags are used to toggle functionality on or off. One or more
feature flags can be added to the parameter `FeatureFlag`, i.e.
`FeatureFlag = @('DetectionSharedFeatures')`.

>**NOTE:** The functionality, exposed
with a feature flag, can be changed from one release to another, including
having breaking changes.

<!-- markdownlint-disable MD013 -->
Flag | Description
--- | ---
- | -
<!-- markdownlint-enable MD013 -->

#### Skip rules

The parameter `SkipRule` accept one or more skip rules with will be passed
to `setup.exe`. Using the parameter `SkipRule` is _not recommended_ in a
production environment unless there is a valid reason for it.

For more information about skip rules see the article [SQL 2012 Setup Rules – The 'Missing Reference'](https://deep.data.blog/2014/04/02/sql-2012-setup-rules-the-missing-reference/).

#### Credentials for running the resource

##### PsDscRunAsCredential

If PsDscRunAsCredential is set, the installation will be performed with those
credentials, and the user name will be used as the first system administrator.

##### SYSTEM

If PsDscRunAsCredential is not assigned credentials then installation will be
performed by the SYSTEM account. When installing as the SYSTEM account, then
parameter SQLSysAdminAccounts and ASSysAdminAccounts must be specified when
installing feature Database Engine and Analysis Services respectively.

#### Credentials for service accounts

##### Service Accounts

Service account username containing dollar sign ('$') is allowed, but if the
dollar sign is at the end of the username it will be considered a Managed Service
Account.

##### Managed Service Accounts

If a service account username has a dollar sign at the end of the name it will
be considered a Managed Service Account. Any password passed in
the credential object will be ignored, meaning the account is not expected to
need a '*SVCPASSWORD' argument in the setup arguments.

#### Note about 'tempdb' properties

The properties `SqlTempdbFileSize` and `SqlTempdbFileGrowth` that are
returned from `Get-TargetResource` will return the sum of the average size
and growth. If tempdb has data files with both percentage and megabytes the
value returned is a sum of the average megabytes and the average percentage.
For example is there is one data file using growth 100MB and another file
having growth set to 10% then the returned value would be 110.
This will be notable if there are multiple files in the filegroup `PRIMARY`
with different sizes and growths.

#### Parameters

* **`[String]` Action** _(Write)_: The action to be performed. Default value is 'Install'.
  *Note: AddNode is not currently functional.*
  { _Install_ | InstallFailoverCluster | AddNode | PrepareFailoverCluster |
   CompleteFailoverCluster }
* **`[String]` InstanceName** _(Key)_: SQL instance to be installed.
* **`[String]` SourcePath** _(Write)_: The path to the root of the source files for
  installation. I.e and UNC path to a shared resource. Environment variables can
  be used in the path.
* **`[PSCredential]` SourceCredential** _(Write)_: Credentials used to access the
  path set in the parameter `SourcePath`. Using this parameter will trigger a
  copy of the installation media to a temp folder on the target node. Setup will
  then be started from the temp folder on the target node. For any subsequent
  calls to the resource, the parameter `SourceCredential` is used to evaluate what
  major version the file 'setup.exe' has in the path set, again, by the parameter
  `SourcePath`. To know how the temp folder is evaluated please read the online
  documentation for [System.IO.Path.GetTempPath()](https://msdn.microsoft.com/en-us/library/system.io.path.gettemppath(v=vs.110).aspx).
  If the path, that is assigned to parameter `SourcePath`, contains a leaf folder,
  for example '\\server\share\folder', then that leaf folder will be used as the
  name of the temporary folder. If the path, that is assigned to parameter
  `SourcePath`, does not have a leaf folder, for example '\\server\share', then
  a unique GUID will be used as the name of the temporary folder.
* **`[Boolean]` SuppressReboot** _(Write)_: Suppresses reboot.
* **`[Boolean]` ForceReboot** _(Write)_: Forces reboot.
* **`[String]` Features** _(Write)_: SQL features to be installed.
* **`[String]` InstanceID** _(Write)_: SQL instance ID, if different from InstanceName.
* **`[String]` ProductKey** _(Write)_: Product key for licensed installations.
* **`[String]` UpdateEnabled** _(Write)_: Enabled updates during installation.
* **`[String]` UpdateSource** _(Write)_: Path to the source of updates to be applied
  during installation.
* **`[String]` SQMReporting** _(Write)_: Enable customer experience reporting.
* **`[String]` ErrorReporting** _(Write)_: Enable error reporting.
* **`[String]` InstallSharedDir** _(Write)_: Installation path for shared SQL files.
* **`[String]` InstallSharedWOWDir** _(Write)_: Installation path for x86 shared
  SQL files.
* **`[String]` InstanceDir** _(Write)_: Installation path for SQL instance files.
* **`[PSCredential]` SQLSvcAccount** _(Write)_: Service account for the SQL service.
* **`[PSCredential]` AgtSvcAccount** _(Write)_: Service account for the SQL Agent
  service.
* **`[String]` SQLCollation** _(Write)_: Collation for SQL.
* **`[String[]]` SQLSysAdminAccounts** _(Write)_: Array of accounts to be made SQL
  administrators.
* **`[String]` SecurityMode** _(Write)_: Security mode to apply to the
  SQL Server instance. 'SQL' indicates mixed-mode authentication while
  'Windows' indicates Windows authentication.
  Default is Windows. { *Windows* | SQL }
* **`[PSCredential]` SAPwd** _(Write)_: SA password, if SecurityMode is set to 'SQL'.
* **`[String]` InstallSQLDataDir** _(Write)_: Root path for SQL database files.
* **`[String]` SQLUserDBDir** _(Write)_: Path for SQL database files.
* **`[String]` SQLUserDBLogDir** _(Write)_: Path for SQL log files.
* **`[String]` SQLTempDBDir** _(Write)_: Path for SQL TempDB files.
* **`[String]` SQLTempDBLogDir** _(Write)_: Path for SQL TempDB log files.
* **`[String]` SQLBackupDir** _(Write)_: Path for SQL backup files.
* **`[PSCredential]` FTSvcAccount** _(Write)_: Service account for the Full Text
  service.
* **`[PSCredential]` RSSvcAccount** _(Write)_: Service account for Reporting Services
  service.
* **`[String]` RSInstallMode** _(Write)_: Reporting Services install mode.
  { SharePointFilesOnlyMode | DefaultNativeMode | FilesOnlyMode }
* **`[PSCredential]` ASSvcAccount** _(Write)_: Service account for Analysis Services
  service.
* **`[String]` ASCollation** _(Write)_: Collation for Analysis Services.
* **`[String[]]` ASSysAdminAccounts** _(Write)_: Array of accounts to be made Analysis
  Services admins.
* **`[String]` ASDataDir** _(Write)_: Path for Analysis Services data files.
* **`[String]` ASLogDir** _(Write)_: Path for Analysis Services log files.
* **`[String]` ASBackupDir** _(Write)_: Path for Analysis Services backup files.
* **`[String]` ASTempDir** _(Write)_: Path for Analysis Services temp files.
* **`[String]` ASConfigDir** _(Write)_: Path for Analysis Services config.
* **`[String]` ASServerMode** _(Write)_: The server mode for SQL Server Analysis
  Services instance. The default is to install in Multidimensional mode. Valid
  values in a cluster scenario are MULTIDIMENSIONAL or TABULAR. Parameter
  ASServerMode is case-sensitive. All values must be expressed in upper case.
  { MULTIDIMENSIONAL | TABULAR | POWERPIVOT }.
* **`[PSCredential]` ISSvcAccount** _(Write)_: Service account for Integration
  Services service.
* **`[String]` SqlSvcStartupType** _(Write)_: Specifies the startup mode for
  SQL Server Engine service. { Automatic | Disabled | Manual }
* **`[String]` AgtSvcStartupType** _(Write)_: Specifies the startup mode for
  SQL Server Agent service. { Automatic | Disabled | Manual }
* **`[String]` AsSvcStartupType** _(Write)_: Specifies the startup mode for
  SQL Server Analysis service. { Automatic | Disabled | Manual }
* **`[String]` IsSvcStartupType** _(Write)_: Specifies the startup mode for
  SQL Server Integration service. { Automatic | Disabled | Manual }
* **`[String]` RsSvcStartupType** _(Write)_: Specifies the startup mode for
  SQL Server Report service. { Automatic | Disabled | Manual }
* **`[String]` BrowserSvcStartupType** _(Write)_: Specifies the startup mode for
  SQL Server Browser service. { Automatic | Disabled | Manual }
* **`[String]` FailoverClusterGroupName** _(Write)_: The name of the resource group
  to create for the clustered SQL Server instance.
  Default is 'SQL Server (_InstanceName_)'.
* **`[String[]]` FailoverClusterIPAddress** _(Write)_: Array of IP Addresses to be
  assigned to the clustered SQL Server instance. IP addresses must be in
  [dotted-decimal notation](https://en.wikipedia.org/wiki/Dot-decimal_notation),
  for example ````10.0.0.100````. If no IP address is specified, uses 'DEFAULT' for
  this setup parameter.
* **`[String]` FailoverClusterNetworkName** _(Write)_: Host name to be assigned to
  the clustered SQL Server instance.
* **`[UInt32]` SqlTempdbFileCount** _(Write)_: Specifies the number of tempdb
  data files to be added by setup.
* **`[UInt32]` SqlTempdbFileSize** _(Write)_: Specifies the initial size of
  each tempdb data file in MB.
* **`[UInt32]` SqlTempdbFileGrowth** _(Write)_: Specifies the file growth
  increment of each tempdb data file in MB.
* **`[UInt32]` SqlTempdbLogFileSize** _(Write)_: Specifies the initial size
  of each tempdb log file in MB.
* **`[UInt32]` SqlTempdbLogFileGrowth** _(Write)_: Specifies the file growth
  increment of each tempdb data file in MB.
* **`[Boolean]` NpEnabled** _(Write)_: Specifies the state of the Named Pipes
  protocol for the SQL Server service. The value $true will enable the Named
  Pipes protocol and $false will disabled it.
* **`[Boolean]` TcpEnabled** _(Write)_: Specifies the state of the TCP protocol
  for the SQL Server service. The value $true will enable the TCP protocol and
  $false will disabled it.
* **`[UInt32]` SetupProcessTimeout** _(Write)_: The timeout, in seconds, to wait
  for the setup process to finish. Default value is 7200 seconds (2 hours). If
  the setup process does not finish before this time, and error will be thrown.
* **`[Boolean]` UseEnglish** _(Write)_: Specifies to install the English version
  of SQL Server on a localized operating system when the installation media
  includes language packs for both English and the language corresponding to the
  operating system.
* **`[String[]]` SkipRule** _(Write)_: Specifies optional skip rules during
  setup.
* **`[String[]]` FeatureFlag** _(Write)_: Feature flags are used to toggle
  functionality on or off. See the documentation for what additional
  functionality exist through a feature flag.

#### Read-Only Properties from Get-TargetResource

* **`[String]` SQLSvcAccountUsername** _(Read)_: Output user name for the SQL service.
* **`[String]` AgtSvcAccountUsername** _(Read)_: Output user name for the SQL Agent
  service.
* **`[String]` FTSvcAccountUsername** _(Read)_: Output username for the Full Text
  service.
* **`[String]` RSSvcAccountUsername** _(Read)_: Output username for the Reporting
  Services service.
* **`[String]` ASSvcAccountUsername** _(Read)_: Output username for the Analysis
  Services service.
* **`[String]` ISSvcAccountUsername** _(Read)_: Output user name for the Integration
  Services service.
* **`[Boolean]` IsClustered** _(Read)_: Returns a boolean value of $true if the
  instance is clustered, otherwise it returns $false.

#### Examples

* [Install a default instance on a single server](/source/Examples/Resources/SqlSetup/1-InstallDefaultInstanceSingleServer.ps1)
* [Install a named instance on a single server](/source/Examples/Resources/SqlSetup/2-InstallNamedInstanceSingleServer.ps1)
* [Install a named instance on a single server from an UNC path using SourceCredential](/source/Examples/Resources/SqlSetup/3-InstallNamedInstanceSingleServerFromUncPathUsingSourceCredential.ps1)
* [Install a named instance as the first node in SQL Server Failover Cluster](/source/Examples/Resources/SqlSetup/4-InstallNamedInstanceInFailoverClusterFirstNode.ps1)
* [Install a named instance as the second node in SQL Server Failover Cluster](/source/Examples/Resources/SqlSetup/5-InstallNamedInstanceInFailoverClusterSecondNode.ps1)
* [Install a named instance with the Agent Service set to Disabled](/source/Examples/Resources/SqlSetup/6-InstallNamedInstanceSingleServerWithAgtSvcStartupTypeDisabled.ps1)
* [Install a default instance on a single server (Sql Server 2016 or Later)](/source/Examples/Resources/SqlSetup/7-InstallDefaultInstanceSingleServer2016OrLater.ps1)

#### Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlSetup).

### SqlWaitForAG

This resource will wait for a cluster role/group to be created. This is used to
wait for an Availability Group to create the cluster role/group in the cluster.

>Note: This only evaluates if the cluster role/group has been created and when it
found it will wait for RetryIntervalSec a last time before returning. There is
currently no check to validate that the Availability Group was successfully created
or that it has finished creating the Availability Group.

#### Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the Failover Cluster PowerShell module.

#### Security Requirements

* The account running this resource must have permission in the cluster to be able
  to run the cmdlet Get-ClusterGroup.

#### Parameters

* **`[String]` Name** _(Key)_: Name of the cluster role/group to look for (normally
  the same as the Availability Group name).
* **`[Uint64]` RetryIntervalSec** _(Write)_: The interval, in seconds, to check for
  the presence of the cluster role/group. Default value is 20 seconds. When the
  cluster role/group has been found the resource will wait for this amount of time
  once more before returning.
* **`[UInt32]` RetryCount** _(Write)_: Maximum number of retries until the resource
  will timeout and throw an error. Default value is 30 times.

#### Read-Only Properties from Get-TargetResource

* **`[Boolean]` GroupExist** _(Read)_: Returns $true if the cluster role/group exist,
  otherwise it returns $false. Used by Get-TargetResource.

#### Examples

* [Wait for a cluster role/group to be available](/source/Examples/Resources/SqlWaitForAG/1-WaitForASingleClusterGroup.ps1)
* [Wait for multiple cluster roles/groups to be available](/source/Examples/Resources/SqlWaitForAG/2-WaitForMultipleClusterGroups.ps1)

#### Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlWaitForAG).

### SqlWindowsFirewall

This will set default firewall rules for the supported features. Currently the
features supported are Database Engine, Analysis Services, SQL Browser,
SQL Reporting Services and Integration Services.

#### Firewall rules

##### Database Engine (SQLENGINE) - Default instance

Firewall Rule | Firewall Display Name
--- | ---
Application: sqlservr.exe | SQL Server Database Engine instance MSSQLSERVER
Service: SQLBrowser | SQL Server Browser

##### Database Engine (SQLENGINE) - Named instance

Firewall Rule | Firewall Display Name
--- | ---
Application: sqlservr.exe | SQL Server Database Engine instance \<INSTANCE\>
Service: SQLBrowser | SQL Server Browser

##### Analysis Services (AS) - Default instance

Firewall Rule | Firewall Display Name
--- | ---
Service: MSSQLServerOLAPService | SQL Server Analysis Services instance MSSQLSERVER
Service: SQLBrowser | SQL Server Browser

##### Analysis Services (AS) - Named instance

Firewall Rule | Firewall Display Name
--- | ---
Service: MSOLAP$\<INSTANCE\> | SQL Server Analysis Services instance \<INSTANCE\>
Service: SQLBrowser | SQL Server Browser

##### Reporting Services (RS)

Firewall Rule | Firewall Display Name
--- | ---
Port: tcp/80 | SQL Server Reporting Services 80
Port: tcp/443 | SQL Server Reporting Services 443

##### Integration Services (IS)

Firewall Rule | Firewall Display Name
--- | ---
Application: MsDtsSrvr.exe | SQL Server Integration Services Application
Port: tcp/135 | SQL Server Integration Services Port

#### Requirements

* Target machine must be running Windows Server 2012 or later.

#### Parameters

* **`[String]` Features** _(Key)_: SQL features to enable firewall rules for.
* **`[String]` InstanceName** _(Key)_: SQL instance to enable firewall rules for.
* **`[String]` Ensure** _(Write)_: Ensures that SQL firewall rules are **Present**
  or **Absent** on the machine. { *Present* | Absent }.
* **`[String]` SourcePath** _(Write)_: UNC path to the root of the source files for
  installation.
* **`[String]` SourceCredential** _(Write)_: Credentials used to access the path
  set in the parameter 'SourcePath'. This parameter is optional either if built-in
  parameter 'PsDscRunAsCredential' is used, or if the source path can be access
  using the SYSTEM account.

#### Read-Only Properties from Get-TargetResource

* **`[Boolean]` DatabaseEngineFirewall** _(Read)_: Is the firewall rule for the
  Database Engine enabled?
* **`[Boolean]` BrowserFirewall** _(Read)_: Is the firewall rule for the Browser
  enabled?
* **`[Boolean]` ReportingServicesFirewall** _(Read)_: Is the firewall rule for
  Reporting Services enabled?
* **`[Boolean]` AnalysisServicesFirewall** _(Read)_: Is the firewall rule for
  Analysis Services enabled?
* **`[Boolean]` IntegrationServicesFirewall** _(Read)_: Is the firewall rule for
  the Integration Services enabled?

#### Examples

* [Create inbound firewall rules](/source/Examples/Resources/SqlWindowsFirewall/1-CreateInboundFirewallRules.ps1)
* [Remove inbound firewall rules](/source/Examples/Resources/SqlWindowsFirewall/2-RemoveInboundFirewallRules.ps1)

#### Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlWindowsFirewall).
