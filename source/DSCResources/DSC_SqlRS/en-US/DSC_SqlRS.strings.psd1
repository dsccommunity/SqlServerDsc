ConvertFrom-StringData @'
    Restart = Restarting Reporting Services.
    SuppressRestart = Suppressing restart of Reporting Services.
    TestFailedAfterSet = Test-TargetResource function returned false when Set-TargetResource function verified the desired state. This indicates that the Set-TargetResource did not correctly set set the desired state, or that the function Test-TargetResource does not correctly evaluate the desired state.
    ReportingServicesNotFound = SQL Reporting Services instance '{0}' does not exist.
    GetConfiguration = Get the current reporting services configuration for the instance '{0}'.
    RestartToFinishInitialization = Restarting Reporting Services to finish initialization.
    SetServiceAccount = The service account should be '{0}' but is '{1}'.
    TestDatabaseName = The database name is '{0}' but should be '{1}'.
    ReportServerReservedUrlNotInDesiredState = Report Server reserved URLs on '{0}\\{1}' are '{2}', should be '{3}'.
    ReportsReservedUrlNotInDesiredState = Reports URLs on '{0}\\{1}' are '{2}', should be '{3}'.
    BackupEncryptionKey = Backing up the encryption key to '{0}'.
    GetLocalServiceAccountName = The local service account name is '{0}' for the type '{1}'.
    DatabaseServerIsRemote = The database server '{0}' is remote: {1}
    LocalServiceAccountUnsupportedException = Cannot use '{0}' as the service account in reporting services version '{1}'.
    HttpsCertificateThumbprintNotInDesiredState = The HTTPS certificate thumbprint is '{0}' but should be '{1}'.
    HttpsIPAddressNotInDesiredState = The HTTPS IP address binding is '{0}' but should be '{1}'.
    HttpsPortNotInDesiredState = The HTTPS port is '{0}' but should be '{1}'.
    RemoveSslCertficateBindingError = Failed to remove the SSL certificate binding for the application '{0}', certificate thumbprint '{1}', IP Address '{2}', and port '{3}'.
    GetOperatingSystemClassError = Unable to find WMI object Win32_OperatingSystem.
    InvokeRsCimMethodError = Method {0}() failed with an error. Error: {1} (HRESULT:{2})
    GenerateDatabaseCreateScript = Generate database creation script on '{0}\\{1}' for database '{2}'.
    GenerateDatabaseRightsScript = Generate database rights script on '{0}\\{1}' for database '{2}'.
    SetDatabaseConnection = Set database connection on '{0}\\{1}' to database '{2}'.
    SetReportServerVirtualDirectory = Setting report server virtual directory on '{0}\\{1}' to '{2}'.
    SetReportsVirtualDirectory = Setting report server virtual directory on '{0}\\{1}' to '{2}'.
    AddReportsUrlReservation = Adding reports URL reservation on '{0}\\{1}': '{2}'.
    RestartDidNotHelp = Did not help restarting the Reporting Services service, running the CIM method to initialize report server on '{0}\\{1}' for instance ID '{2}'.
    SetUseSsl = Changing value for using SSL to '{0}'.
    TestNotInitialized = Reporting services '{0}\\{1}' is not initialized.
    TestReportServerVirtualDirectory = Report server virtual directory on '{0}\\{1}' is '{2}', should be '{3}'.
    TestReportsVirtualDirectory = Report server virtual directory on '{0}\\{1}' is '{2}', should be '{3}'.
    TestUseSsl = The value for using SSL is not in desired state. Should be '{0}', but is '{1}'.
    TestServiceAccount = The ServiceAccount should be '{0}' but is '{1}'.
    GetLocalServiceAccountNameServiceNotSpecified = The 'ServiceName' parameter is required with the 'LocalServiceAccountType' is '{0}'.
    InitializeReportingServices = Initializing Reporting Services on '{0}\{1}'.
    ReportingServicesIsInitialized = Reporting Services on '{0}\{1}' is initialized: {2}.
    EncryptionKeyBackupCredentialNotSpecified = An encryption key backup credential was not specified. Generating a random credential.
    EncryptionKeyBackupCredentialUserName = The encryption key backup credential user name is '{0}'.
'@
