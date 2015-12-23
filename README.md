[![Build status](https://ci.appveyor.com/api/projects/status/mxn453y284eab8li/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xsqlserver/branch/master)

# xSQLServer

The **xSQLServer** module contains DSC resources for deployment and configuration of SQL Server in a way that is fully compliant with the requirements of System Center.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


## Resources

* **xSQLServerSetup** installs a standalone SQL Server instance
* **xSQLServerFirewall** configures firewall settings to allow remote access to a SQL Server instance.
* **xSQLServerRSSecureConnectionLevel** sets the secure connection level for SQL Server Reporting Services.
* **xSQLServerFailoverClusterSetup** installs SQL Server failover cluster instances.
* **xSQLServerRSConfig** configures SQL Server Reporting Services to use a database engine in another instance.

### xSQLServerSetup

* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **SetupCredential**: (Required) Credential to be used to perform the installation.
* **Features**: (Key) SQL features to be installed.
* **InstanceName**: (Key) SQL instance to be installed.
* **InstanceID**: SQL instance ID, if different from InstanceName.
* **PID**: Product key for licensed installations.
* **UpdateEnabled**: Enabled updates during installation.
* **UpdateSource**: Source of updates to be applied during installation.
* **SQMReporting**: Enable customer experience reporting.
* **ErrorReporting**: Enable error reporting.
* **InstallSharedDir**: Installation path for shared SQL files.
* **InstallSharedWOWDir**: Installation path for x86 shared SQL files.
* **InstanceDir**: Installation path for SQL instance files.
* **SQLSvcAccount**: Service account for the SQL service.
* **SQLSvcAccountUsername**: Output user name for the SQL service.
* **AgtSvcAccount**: Service account for the SQL Agent service.
* **AgtSvcAccountUsername**: Output user name for the SQL Agent service.
* **SQLCollation**: Collation for SQL.
* **SQLSysAdminAccounts**: Array of accounts to be made SQL administrators.
* **SecurityMode**: SQL security mode.
* **SAPwd**: SA password, if SecurityMode=SQL.
* **InstallSQLDataDir**: Root path for SQL database files.
* **SQLUserDBDir**: Path for SQL database files.
* **SQLUserDBLogDir**: Path for SQL log files.
* **SQLTempDBDir**: Path for SQL TempDB files.
* **SQLTempDBLogDir**: Path for SQL TempDB log files.
* **SQLBackupDir**: Path for SQL backup files.
* **FTSvcAccount**: Service account for the Full Text service.
* **FTSvcAccountUsername**: Output username for the Full Text service.
* **RSSvcAccount**: Service account for Reporting Services service.
* **RSSvcAccountUsername**: Output username for the Reporting Services service.
* **ASSvcAccount**: Service account for Analysus Services service.
* **ASSvcAccountUsername**: Output username for the Analysis Services service.
* **ASCollation**: Collation for Analysis Services.
* **ASSysAdminAccounts**: Array of accounts to be made Analysis Services admins.
* **ASDataDir**: Path for Analysis Services data files.
* **ASLogDir**: Path for Analysis Services log files.
* **ASBackupDir**: Path for Analysis Services backup files.
* **ASTempDir**: Path for Analysis Services temp files.
* **ASConfigDir**: Path for Analysis Services config.
* **ISSvcAccount**: Service account for Integration Services service.
* **ISSvcAccountUsername**: Output user name for the Integration Services service.

### xSQLServerFirewall

* **Ensure**: (Key) Ensures that SQL firewall rules are **Present** or **Absent** on the machine.
* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **Features**: (Key) SQL features to enable firewall rules for.
* **InstanceName**: (Key) SQL instance to enable firewall rules for.
* **DatabaseEngineFirewall**: Is the firewall rule for the Database Engine enabled?
* **BrowserFirewall**: Is the firewall rule for the Browser enabled?
* **ReportingServicesFirewall**: Is the firewall rule for Reporting Services enabled?
* **AnalysisServicesFirewall**: Is the firewall rule for Analysis Services enabled?
* **IntegrationServicesFirewall**: Is the firewall rule for the Integration Services enabled?

### xSQLServerRSSecureConnectionLevel

* **InstanceName**: (Key) SQL instance to set secure connection level for.
* **SecureConnectionLevel**: (Key) SQL Server Reporting Service secure connection level.
* **Credential**: (Required) Credential with administrative permissions to the SQL instance.

### xSQLServerFailoverClusterSetup

* **Action**: (Key) { Prepare | Complete }
* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **Credential**: (Required) Credential to be used to perform the installation.
* **Features**: (Required) SQL features to be installed.
* **InstanceName**: (Key) SQL instance to be installed.
* **InstanceID**: SQL instance ID, if different from InstanceName.
* **PID**: Product key for licensed installations.
* **UpdateEnabled**: Enabled updates during installation.
* **UpdateSource**: Source of updates to be applied during installation.
* **SQMReporting**: Enable customer experience reporting.
* **ErrorReporting**: Enable error reporting.
* **FailoverClusterGroup**: Name of the resource group to be used for the SQL Server failover cluster.
* **FailoverClusterNetworkName**: (Required) Network name for the SQL Server failover cluster.
* **FailoverClusterIPAddress**: IPv4 address for the SQL Server failover cluster.
* **InstallSharedDir**: Installation path for shared SQL files.
* **InstallSharedWOWDir**: Installation path for x86 shared SQL files.
* **InstanceDir**: Installation path for SQL instance files.
* **SQLSvcAccount**: Service account for the SQL service.
* **SQLSvcAccountUsername**: Output user name for the SQL service.
* **AgtSvcAccount**: Service account for the SQL Agent service.
* **AgtSvcAccountUsername**: Output user name for the SQL Agent service.
* **SQLCollation**: Collation for SQL.
* **SQLSysAdminAccounts**: Array of accounts to be made SQL administrators.
* **SecurityMode**: SQL security mode.
* **SAPwd**: SA password, if SecurityMode=SQL.
* **InstallSQLDataDir**: Root path for SQL database files.
* **SQLUserDBDir**: Path for SQL database files.
* **SQLUserDBLogDir**: Path for SQL log files.
* **SQLTempDBDir**: Path for SQL TempDB files.
* **SQLTempDBLogDir**: Path for SQL TempDB log files.
* **SQLBackupDir**: Path for SQL backup files.
* **ASSvcAccount**: Service account for Analysis Services service.
* **ASSvcAccountUsername**: Output user name for the Analysis Services service.
* **ASCollation**: Collation for Analysis Services.
* **ASSysAdminAccounts**: Array of accounts to be made Analysis Services admins.
* **ASDataDir**: Path for Analysis Services data files.
* **ASLogDir**: Path for Analysis Services log files.
* **ASBackupDir**: Path for Analysis Services backup files.
* **ASTempDir**: Path for Analysis Services temp files.
* **ASConfigDir**: Path for Analysis Services config.
* **ISSvcAccount**: Service account for Integration Services service.
* **ISSvcAccountUsername**: Output user name for the Integration Services service.
* **ISFileSystemFolder**: File system folder for Integration Services.

### xSQLServerRSConfig

* **InstanceName**: (Key) Name of the SQL Server Reporting Services instance to be configured.
* **RSSQLServer**: (Required) Name of the SQL Server to host the Reporting Service database.
* **RSSQLInstanceName**: (Required) Name of the SQL Server instance to host the Reporting Service database.
* **SQLAdminCredential**: (Required) Credential to be used to perform the configuration.
* **IsInitialized**: Output is the Reporting Services instance initialized.

### xSQLServerNetwork
* **InstanceName**: (Key) name of SQL Server instance for which network will be configured.
* **ProtocolName**: (Required) Name of network protocol to be configured. Only tcp is currently supported.
* **IsEnabled**: Enables/Disables network protocol.
* **TCPDynamicPorts**: 0 if Dynamic ports should be used otherwise empty.
* **TCPPort**: Custom TCP port.
* **RestartService**: If true will restart SQL Service instance service after update. Default false.

## Versions

### Unreleased

* xSQLServerSetup:
  - Added support for SQL Server 2008 R2 installation
  - Removed default values for parameters, to avoid compatibility issues and setup errors
  - Added Replication sub feature detection
  - Added setup parameter BrowserSvcStartupType
* xSQLServerFirewall
  - Removed default values for parameters, to avoid compatibility issues
  - Updated firewall rule name to not use 2012 version, since package supports 2008, 2012 and 2014 versions
* xSQLServerNetwork
  - Added new resource that configures network settings.
  - Currently supports only tcp network protocol
  - Allows to enable and disable network protocol for specified instance service
  - Allows to set custom or dynamic port values

* Updated example files to use correct DebugMode parameter value ForceModuleImport, this is not boolean in WMF 5.0 RTM



### 1.3.0.0

* xSqlServerSetup: 
    - Make Features case-insensitive.

### 1.2.1.0

* Increased timeout for setup process to start to 60 seconds.

### 1.2.0.0

* Updated release with the following new resources 
    - xSQLServerFailoverClusterSetup
    - xSQLServerRSConfig

### 1.1.0.0

* Initial release with the following resources 
    - xSQLServerSetup
    - xSQLServerFirewall
    - xSQLServerRSSecureConnectionLevel

## Examples

Examples for use of this resource can be found with the System Center resources, such as **xSCVMM**, **xSCSMA**, and **xSCOM**.
