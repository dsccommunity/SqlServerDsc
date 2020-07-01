# Description

The `SqlAGReplica` DSC resource is used to create, remove, and update an
Always On Availability Group Replica.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' must have the 'Connect SQL',
  'Alter Any Availability Group', and 'View Server State' permissions.
* There are circumstances where the PowerShell module _SQLPS_ that is install
  together with SQL Server does not work with all features of this resource.
  The solution is to install the PowerShell module [_SqlServer_](https://www.powershellgallery.com/packages/SqlServer)
  from the PowerShell Gallery. The module must be installed in a machine-wide
  path of `env:PSModulePath` so it is found when LCM runs the DSC resource.
  This will also make all SqlServerDsc DSC resources use the PowerShell
  module _SqlServer_ instead of the PowerShell module _SQLPS_.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlAGReplica).
