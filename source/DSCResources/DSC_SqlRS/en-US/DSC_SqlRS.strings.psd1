ConvertFrom-StringData @'
    Restart = Restarting Reporting Services.
    SuppressRestart = Suppressing restart of Reporting Services.
    TestFailedAfterSet = Test-TargetResource function returned false when Set-TargetResource function verified the desired state. This indicates that the Set-TargetResource did not correctly set set the desired state, or that the function Test-TargetResource does not correctly evaluate the desired state.
    ReportingServicesNotFound = SQL Reporting Services instance '{0}' does not exist.
    GetConfiguration = Get the current reporting services configuration for the instance '{0}'.
    RestartToFinishInitialization = Restarting Reporting Services to finish initialization.
    SetServiceAccount = The service account should be '{0}' but is '{1}'.
    TestDatabaseName = The database name is '{0}' but should be '{1}'.
    ReportServerReservedUrlNotInDesiredState = Report Server reserved URLs on '{0}\{1}' are '{2}', should be '{3}'.
    ReportsReservedUrlNotInDesiredState = Reports URLs on '{0}\{1}' are '{2}', should be '{3}'.
    BackupEncryptionKey = Backing up the encryption key to '{0}'.
    GetLocalServiceAccountName = The local service account name is '{0}' for the type '{1}'.
    DatabaseServerIsRemote = The database server '{0}' is remote: {1}
    LocalServiceAccountUnsupportedException = Cannot use '{0}' as the service account in reporting services version '{1}'.
    HttpsCertificateThumbprintNotInDesiredState = The HTTPS certificate thumbprint is '{0}' but should be '{1}'.
    HttpsIPAddessNotInDesiredState = The HTTPS IP address binding is '{0}' but should be '{1}'.
    HttpsPortNotInDesiredState = The HTTPS port is '{0}' but should be '{1}'.
    RemoveSslCertficateBindingError = Failed to remove the SSL certificate binding for the application '{0}', certificate thumbprint '{1}', IP Address '{2}', and port '{3}'.
    CreateSslCertficateBindingError = Failed to create the SSL certificate binding for the application '{0}', certificate thumbprint '{1}', IP Address '{2}', and port '{3}'.
'@
