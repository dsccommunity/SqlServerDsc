ConvertFrom-StringData @'
    Restart = Restarting Reporting Services.
    SuppressRestart = Suppressing restart of Reporting Services.
    TestFailedAfterSet = Test-TargetResource function returned false when Set-TargetResource function verified the desired state. This indicates that the Set-TargetResource did not correctly set the desired state, or that the function Test-TargetResource does not correctly evaluate the desired state.
    ReportingServicesNotFound = SQL Reporting Services instance '{0}' does not exist.
    GetConfiguration = Get the current reporting services configuration for the instance '{0}'.
    RestartToFinishInitialization = Restarting Reporting Services to finish initialization.
    WaitingForServiceReady = Waiting {0} seconds for Reporting Services to be fully ready after restart. (DSC_SQLRS0001)
    ServiceNameIsNullOrEmpty = The Configuration.ServiceName property is null or empty for SQL Server Reporting Services instance '{0}'. This property is required to determine the service name for SQL Server version 14 and higher. (DSC_SQLRS0002)
    ReportServerWaitingToJoin = Reporting Services installation '{0}\{1}' is registered in the existing report server database but is waiting to join the scale-out deployment. Connect Report Server Configuration Manager to initialized installation '{2}\{3}', open Scale-out Deployment, select the waiting server, and choose Add Server. (DSC_SQLRS0003)
'@
