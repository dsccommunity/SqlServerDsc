ConvertFrom-StringData @'
    Restart = Restarting Reporting Services.
    SuppressRestart = Suppressing restart of Reporting Services.
    TestFailedAfterSet = Test-TargetResource function returned false when Set-TargetResource function verified the desired state. This indicates that the Set-TargetResource did not correctly set set the desired state, or that the function Test-TargetResource does not correctly evaluate the desired state.
    ReportingServicesNotFound = SQL Reporting Services instance '{0}' does not exist.
    GetConfiguration = Get the current reporting services configuration for the instance '{0}'.
    RestartToFinishInitialization = Restarting Reporting Services to finish initialization.
    SetServiceAccount = The WindowsServiceIdentityActual should be '{0}' but is '{1}'.
    TestDatabaseName = The database name is '{0}' but should be '{1}'.
    ReportServerReservedUrlNotInDesiredState = Report Server reserved URLs on '{0}\{1}' are '{2}', should be '{3}'.
    ReportsReservedUrlNotInDesiredState = Reports URLs on '{0}\{1}' are '{2}', should be '{3}'.
    BackupEncryptionKey = Backing up the encryption key to '{0}'.
'@
