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
