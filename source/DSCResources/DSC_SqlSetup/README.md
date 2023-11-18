# Description

The `SqlSetup` DSC resource installs SQL Server on the target node.

## Requirements

- Target machine must be running Windows Server 2012 or later.
- For configurations that utilize the `'InstallFailoverCluster'` action, the following
  parameters are required (beyond those required for the standalone installation).
  See the article [Install SQL Server from the Command Prompt](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt)
  under the section [Failover Cluster Parameters](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt#ClusterInstall)
  for more information.
  - `InstanceName` (can be `'MSSQLSERVER'` if you want to install a default
    clustered instance).
  - `FailoverClusterNetworkName`
  - `FailoverClusterIPAddress`
  - Additional parameters needed when installing Database Engine.
    - `InstallSQLDataDir`
    - `AgtSvcAccount`
    - `SQLSvcAccount`
    - `SQLSysAdminAccounts`
  - Additional parameters needed when installing Analysis Services.
    - `ASSysAdminAccounts`
    - `AsSvcAccount`
- These parameters cannot be used for configurations that utilize the
  `'InstallFailoverCluster'` action:
  - `BrowserSvcStartupType`
- The parameters below can only be used when installing SQL Server 2016 or
  later:
  - `SqlTempDbFileCount`
  - `SqlTempDbFileSize`
  - `SqlTempDbFileGrowth`
  - `SqlTempDbLogFileSize`
  - `SqlTempDbLogFileGrowth`
- When installing _SQL Server Analysis Services_ the account used to start
  the service must have the correct permissions in directory tree for the
  data folders. If not the service can fail with an access denied error.
  For more information see the [issue #1443](https://github.com/dsccommunity/SqlServerDsc/issues/1443).
  To change permissions on folders the DSC resource [FileSystemAccessRule](https://github.com/dsccommunity/FileSystemDsc)
  can be used.
- On certain operating systems, when using least privilege for the service
  account for the _SQL Server Database Engine_ the security policy setting
  [Network access: Restrict clients allowed to make remote calls to SAM](https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-access-restrict-clients-allowed-to-make-remote-sam-calls)
  can result in an access denied when validating accounts in the domain.
  For more information see the [issue #1559](https://github.com/dsccommunity/SqlServerDsc/issues/1559).

## Features supported

This is a list of currently supported features. All features might not be
available on all versions of _SQL Server_.

- SQLENGINE
- REPLICATION
- DQ
- DQC
- BOL
- CONN
- BC
- SDK
- MDS
- FULLTEXT
- RS
- AS
- IS
- SSMS
- ADV_SSMS

> [!IMPORTANT]
> It is not possible to add or remove features to a SQL Server failover
> cluster. This is a limitation of SQL Server. See article
> [You cannot add or remove features to a SQL Server 2008, SQL Server 2008 R2, or
> SQL Server 2012 failover cluster](https://support.microsoft.com/en-us/help/2547273/you-cannot-add-or-remove-features-to-a-sql-server-2008,-sql-server-2008-r2,-or-sql-server-2012-failover-cluster).

## Skip rules

The parameter `SkipRule` accept one or more skip rules with will be passed
to `setup.exe`. Using the parameter `SkipRule` is _not recommended_ in a
production environment unless there is a valid reason for it.

For more information about skip rules see the article [SQL 2012 Setup Rules – The 'Missing Reference'](https://deep.data.blog/2014/04/02/sql-2012-setup-rules-the-missing-reference/).

## Credentials for running the resource

### PsDscRunAsCredential

If PsDscRunAsCredential is set, the installation will be performed with those
credentials, and the user name will be used as the first system administrator.

### SYSTEM

If PsDscRunAsCredential is not assigned credentials then installation will be
performed by the SYSTEM account. When installing as the SYSTEM account, then
parameter SQLSysAdminAccounts and ASSysAdminAccounts must be specified when
installing feature Database Engine and Analysis Services respectively.

## Credentials for service accounts

### Service Accounts

Service account username containing dollar sign ('$') is allowed, but if the
dollar sign is at the end of the username it will be considered a Managed Service
Account.

### Managed Service Accounts

If a service account username has a dollar sign at the end of the name it will
be considered a Managed Service Account. Any password passed in
the credential object will be ignored, meaning the account is not expected to
need a '*SVCPASSWORD' argument in the setup arguments.

## Note about 'tempdb' properties

The properties `SqlTempdbFileSize` and `SqlTempdbFileGrowth` that are
returned from `Get-TargetResource` will return the sum of the average size
and growth. If tempdb has data files with both percentage and megabytes the
value returned is a sum of the average megabytes and the average percentage.
For example is there is one data file using growth 100MB and another file
having growth set to 10% then the returned value would be 110.
This will be notable if there are multiple files in the filegroup `PRIMARY`
with different sizes and growths.

## Considerations for the parameter SourceCredential

Using the parameter `SourceCredential` will trigger a copy of the installation
media to a temp folder on the target node. Setup will then be started from
the temp folder on the target node. For any subsequent calls to the resource,
the parameter `SourceCredential` is used to evaluate what major version the
file 'setup.exe' has in the path set, again, by the parameter `SourcePath`.
To know how the temp folder is evaluated please read the online documentation
for [System.IO.Path.GetTempPath()](https://msdn.microsoft.com/en-us/library/system.io.path.gettemppath(v=vs.110).aspx).
If the path, that is assigned to parameter `SourcePath`, contains a leaf folder,
for example '\\server\share\folder', then that leaf folder will be used as the
name of the temporary folder. If the path, that is assigned to parameter
`SourcePath`, does not have a leaf folder, for example '\\server\share', then
a unique GUID will be used as the name of the temporary folder.

## Feature flags

_Not to be mistaken with the **Features** parameter._

Feature flags are used to toggle resource functionality on or off. One or
more feature flags can be added to the parameter `FeatureFlag`, i.e.
`FeatureFlag = @('DetectionSharedFeatures')`.

> [!CAUTION]
> The functionality, exposed with a feature flag, can be changed
> from one release to another, including having breaking changes.

<!-- markdownlint-disable MD013 -->
Feature flag | Description
--- | ---
DetectionSharedFeatures | A new way of detecting if the shared features is installed or not. This was implemented because the previous implementation did not work fully with SQL Server 2017.
AnalysisServicesConnection | A new method of loading the assembly *Microsoft.AnalysisServices*. Using this, no longer is the helper function `Connect-SqlAnalysis` using `LoadWithPartial()` to load the assembly **Microsoft.AnalysisServices**. This requires the [SqlServer module](https://www.powershellgallery.com/packages/SqlServer) to be present on the node.
<!-- markdownlint-enable MD013 -->

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlSetup).

> [!IMPORTANT] The setup action AddNode is not currently functional.
