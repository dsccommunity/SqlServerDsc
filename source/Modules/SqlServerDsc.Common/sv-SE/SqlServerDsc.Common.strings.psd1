<#
    Swedish localized resources for helper module SqlServerDsc.Common.

    Strings are added in English here by non-Swedish speaking contributors.
    if you are a Swedish speaking contributor, then please help us translate
    or improve these strings.
#>

ConvertFrom-StringData @'
    RobocopyIsCopying = Robocopy kopierar media från källan '{0}' till destinationen '{1}'. (SQLCOMMON0008)
    RobocopyUsingUnbufferedIo = Robocopy använder sig av obuffrad I/O. (SQLCOMMON0009)
    RobocopyNotUsingUnbufferedIo = Obuffrad I/O kan inte användas på grund av versionen av Robocopy inte är kompatibel. (SQLCOMMON0010)
    RobocopyArguments = Robocopy startas med följande argument: {0} (SQLCOMMON0011)
    RobocopyErrorCopying = Robocopy rapporterade fel när filer kopierades. Felkod: {0}. (SQLCOMMON0012)
    RobocopyFailuresCopying = Robocopy rapporterade att fel uppstod när filer kopierades. Felkod: {0}. (SQLCOMMON0013)
    RobocopySuccessful = Robocopy lyckades kopiera filer till destinationen. (SQLCOMMON0014)
    RobocopyRemovedExtraFilesAtDestination = Robocopy fann extra filer på destinationen som inte finns i källan, dessa extra filer togs bort på destinationen. (SQLCOMMON0015)
    RobocopyAllFilesPresent = Robocopy rapporterade att alla filer redan finns på destinationen. (SQLCOMMON0016)
    StartSetupProcess = Started the process with id {0} using the path '{1}', and with a timeout value of {2} seconds. (SQLCOMMON0017)
    ConnectedToDatabaseEngineInstance = Ansluten till SQL instans '{0}'. (SQLCOMMON0018)
    FailedToConnectToDatabaseEngineInstance = Misslyckades att ansluta till SQL instans '{0}'. (SQLCOMMON0019)
    ConnectedToAnalysisServicesInstance = Ansluten till Analysis Services instans '{0}'. (SQLCOMMON0020)
    FailedToConnectToAnalysisServicesInstance = Misslyckades att ansluta till Analysis Services instans '{0}'. (SQLCOMMON0021)
    SqlServerVersionIsInvalid = Kunde inte hämta SQL version för instansen '{0}'. (SQLCOMMON0022)
    GetSqlServerClusterResources = Hämtar kluster resurser för SQL Server. (SQLCOMMON0032)
    GetSqlAgentClusterResource = Hämtar aktiva kluster resurser för SQL Server Agent. (SQLCOMMON0033)
    BringClusterResourcesOffline = Tar SQL Server resurser '{0}' offline. (SQLCOMMON0034)
    BringSqlServerClusterResourcesOnline = Tar SQL Server resurser online igen. (SQLCOMMON0035)
    BringSqlServerAgentClusterResourcesOnline = Tar SQL Server Agent resurser online. (SQLCOMMON0036)
    GetServiceInformation = Hämtar information om SQL Server-tjänst '{0}'. (SQLCOMMON0037)
    RestartService = '{0}' service is restarting. (SQLCOMMON0038)
    StoppingService = '{0}' service is stopping. (SQLCOMMON0039)
    StartingService = '{0}' service is starting. (SQLCOMMON0040)
    WaitServiceRestart = Waiting {0} seconds before starting service '{1}'. (SQLCOMMON0041)
    StartingDependentService = Startar tjänst {0} (SQLCOMMON0042)
    WaitingInstanceTimeout = Waiting for instance {0}\\{1} to report status online, with a timeout value of {2} seconds. (SQLCOMMON0043)
    FailedToConnectToInstanceTimeout = Failed to connect to the instance {0}\\{1} within the timeout period of {2} seconds. (SQLCOMMON0044)
    AlterAvailabilityGroupReplicaFailed = Misslyckades att ändra Availability Group kopia '{0}'. (SQLCOMMON0047)
    GetEffectivePermissionForLogin = Hämtar effektiva behörigheter för inloggningen '{0}' på '{1}'. (SQLCOMMON0048)
    ClusterPermissionsMissing = The cluster does not have permissions to manage the Availability Group on '{0}\\{1}'. Grant 'Connect SQL', 'Alter Any Availability Group', and 'View Server State' to either 'NT SERVICE\\ClusSvc' or 'NT AUTHORITY\\SYSTEM'. (SQLCOMMON0049)
    ClusterLoginMissing = The login '{0}' is not present. {1} (SQLCOMMON0050)
    ClusterLoginMissingPermissions = The account '{0}' is missing one or more of the following permissions: {1} (SQLCOMMON0051)
    ClusterLoginMissingRecommendedPermissions = The recommended account '{0}' is missing one or more of the following permissions: {1} (SQLCOMMON0052)
    ClusterLoginPermissionsPresent = The cluster login '{0}' has the required permissions. (SQLCOMMON0053)
    ConnectingUsingIntegrated = Anslutning som nuvarande användare '{0}' med integrerad säkerhet. (SQLCOMMON0054)
    ConnectingUsingImpersonation = Uppträder som behörigheten '{0}' med inloggningstyp '{1}'. (SQLCOMMON0056)
    ClusterResourceNotFoundOrOffline = The SQL Server cluster resource '{0}' was not found or the resource has been taken offline. (SQLCOMMON0066)
    NotOwnerOfClusterResource = The node '{0}' is not the owner of the cluster resource '{1}'. The owner is '{2}' so no restart is needed. (SQLCOMMON0067)
    LoadedAssembly = Loaded the assembly '{0}'. (SQLCOMMON0068)
    FailedToLoadAssembly = Failed to load the assembly '{0}'. (SQLCOMMON0069)
    FailedToObtainServerInstance = Failed to obtain a SQL Server instance with name '{0}' on server '{1}'. Ensure the SQL Server instance exists on the server and that the 'SQLServer' module references a version of the 'Microsoft.SqlServer.Management.Smo.Wmi' library that supports the version of the SQL Server instance. (SQLCOMMON0070)
    DatabaseEngineInstanceNotOnline = The SQL instance '{0}' was expected to have the status 'Online', but had status '{1}'. (SQLCOMMON0071)
    WaitForDatabaseEngineInstanceStatus = The SQL instance status is '{0}' expected '{1}', waiting {2} seconds.  (SQLCOMMON0072)
'@
