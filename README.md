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
