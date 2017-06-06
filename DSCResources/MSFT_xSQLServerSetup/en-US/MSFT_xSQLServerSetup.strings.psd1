# Localized resources for xSQLServerSetup

ConvertFrom-StringData @'
    UsingPath = Using path '{0}'.
    EvaluateReplicationFeature = Detecting replication feature ({0}).
    ReplicationFeatureFound = Replication feature detected.
    ReplicationFeatureNotFound = Replication feature not detected.
    EvaluateDataQualityClientFeature = Detecting Data Quality Client feature ({0}).
    DataQualityClientFeatureFound = Data Quality Client feature detected.
    DataQualityClientFeatureNotFound = Data Quality Client feature not detected.
    EvaluateDataQualityServicesFeature = Detecting Data Services Client feature ({0}).
    DataQualityServicesFeatureFound = Data Quality Services feature detected.
    DataQualityServicesFeatureNotFound = Data Quality Services feature not detected.
    ClusterInstanceFound = Clustered instance detected.
    ClusterInstanceNotFound = Clustered instance not detected.
    FailoverClusterResourceFound = Clustered SQL Server resource located.
    FailoverClusterResourceNotFound = Could not locate a SQL Server cluster resource for instance {0}.
    EvaluateDocumentationComponentsFeature = Detecting Documentation Components feature ({0}).
    DocumentationComponentsFeatureFound = Documentation Components feature detected.
    DocumentationComponentsFeatureNotFound = Documentation Components feature not detected.
    EvaluateFullTextFeature = Detecting Full-text feature.
    FullTextFeatureFound = Full-text feature detected.
    FullTextFeatureNotFound = Full-text feature not detected.
    EvaluateReportingServicesFeature = Detecting Reporting Services feature.
    ReportingServicesFeatureFound = Reporting Services feature detected.
    ReportingServicesFeatureNotFound = Reporting Services feature not detected.
    EvaluateAnalysisServicesFeature = Detecting Analysis Services feature.
    AnalysisServicesFeatureFound = Analysis Services feature detected.
    AnalysisServicesFeatureNotFound = Analysis Services feature not detected.
    EvaluateIntegrationServicesFeature = Detecting Integration Services feature.
    IntegrationServicesFeatureFound = Integration Services feature detected.
    IntegrationServicesFeatureNotFound = Integration Services feature not detected.
    EvaluateClientConnectivityToolsFeature = Detecting Client Connectivity Tools feature ({0}).
    ClientConnectivityToolsFeatureFound = Client Connectivity Tools feature detected.
    ClientConnectivityToolsFeatureNotFound = Client Connectivity Tools feature not detected.
    EvaluateClientConnectivityBackwardsCompatibilityToolsFeature = Detecting Client Connectivity Backwards Compatibility Tools feature ({0}).
    ClientConnectivityBackwardsCompatibilityToolsFeatureFound = Client Connectivity Backwards Compatibility Tools feature detected.
    ClientConnectivityBackwardsCompatibilityToolsFeatureNotFound = Client Connectivity Backwards Compatibility Tools feature not detected.
    EvaluateClientToolsSdkFeature = Detecting Client Tools SDK feature ({0}).
    ClientToolsSdkFeatureFound = Client Tools SDK feature detected.
    ClientToolsSdkFeatureNotFound = Client Tools SDK feature not detected.
    RobocopyIsCopying = Robocopy is copying media from source '{0}' to destination '{1}'.
    FeatureNotSupported = '{0}' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information.
    PathRequireClusterDriveFound = Found assigned parameter '{0}'. Adding path '{1}' to list of paths that required cluster drive.
    FailoverClusterDiskMappingError = Unable to map the specified paths to valid cluster storage. Drives mapped: {0}.
    FailoverClusterIPAddressNotValid = Unable to map the specified IP Address(es) to valid cluster networks.
    AddingFirstSystemAdministratorSqlServer = Adding user '{0}' from the parameter 'PsDscRunAsCredential' as the first system administrator account for SQL Server.
    AddingFirstSystemAdministratorAnalysisServices = Adding user '{0}' from the parameter 'PsDscRunAsCredential' as the first system administrator account for Analysis Services.
    SetupArguments = Starting setup using arguments: {0}
    SetupExitMessage = Setup exited with code '{0}'.
    SetupSuccessful = Setup finished successfully.
    SetupSuccessfulRebootRequired = Setup finished successfully, but a reboot is required.
    SetupFailed = Please see the 'Summary.txt' log file in the 'Setup Bootstrap\\Log' folder.
    Reboot = Rebooting target node.
    SuppressReboot = Suppressing reboot of target node.
    TestFailedAfterSet = Test-TargetResource returned false after calling Set-TargetResource.
    FeaturesFound = Features found: {0}
    UnableToFindFeature = Unable to find feature '{0}' among the installed features: '{1}'.
    EvaluatingClusterParameters = Clustered install, checking parameters.
    ClusterParameterIsNotInDesiredState = {0} '{1}' is not in the desired state for this cluster.
    RobocopyUsingUnbufferedIo = Robocopy is using unbuffered I/O.
    RobocopyNotUsingUnbufferedIo = Unbuffered I/O cannot be used due to incompatible version of Robocopy.
    RobocopyArguments = Robocopy is started with the following arguments: {0}
    RobocopyErrorCopying = Robocopy reported errors when copying files. Error code: {0}.
    RobocopyFailuresCopying = Robocopy reported that failures occurred when copying files. Error code: {0}.
    RobocopySuccessful = Robocopy copied files successfully
    RobocopyRemovedExtraFilesAtDestination = Robocopy found files at the destination path that is not present at the source path, these extra files was remove at the destination path.
    RobocopySuccessfulAndRemovedExtraFilesAtDestination = Robocopy copied files to destination successfully. Robocopy also found files at the destination path that is not present at the source path, these extra files was remove at the destination path.
    RobocopyAllFilesPresent = Robocopy reported that all files already present.
    StartSetupProcess = Started the process with id {0} using the path '{1}', and with a timeout value of {2} seconds.
'@
