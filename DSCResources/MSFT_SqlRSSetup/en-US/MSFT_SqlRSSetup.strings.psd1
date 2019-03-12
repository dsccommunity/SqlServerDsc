# Localized resources for SqlSetup

ConvertFrom-StringData @'
    TestingConfiguration = Determines if the Microsoft SQL Server Reporting Service instance is installed.
    FoundInstance = Found Microsoft SQL Server Reporting Service instance named '{0}'.
    InstanceNotFound = Could not find a Microsoft SQL Server Reporting Service instance.
    InstallationMediaPath = Using installation media at '{0}'.
    SetupArguments = Starting installation using the arguments: {0}
    SetupExitMessage = Installation exited with code '{0}'.
    SetupSuccessfulRebootRequired = Installation finished successfully, but a reboot is required.
    SetupFailed = Please see the log file in the %TEMP% folder.
    SetupFailedWithLog = Please see the log file '{0}'. If not path was provided, the default path for log files is %TEMP%.
    SetupSuccessful = Installation finished successfully.
    Reboot = Rebooting target node.
    SuppressReboot = Suppressing reboot of target node.
    EditionInvalidParameter = Both the parameters Edition and ProductKey was specified. Only either parameter Edition or ProductKey is allowed.
    EditionMissingParameter = Neither the parameters Edition and ProductKey was specified.
'@
