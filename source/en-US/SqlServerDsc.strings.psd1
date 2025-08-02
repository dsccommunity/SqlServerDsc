<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlServerDsc module. This file should only contain
        localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## Get-SqlDscDatabasePermission, Set-SqlDscDatabasePermission
    DatabasePermission_MissingPrincipal = The database principal '{0}' is neither a user, database role (user-defined), or database application role in the database '{1}'.
    DatabasePermission_MissingDatabase = The database '{0}' cannot be found.

    ## Set-SqlDscDatabasePermission
    DatabasePermission_GrantPermission = Grant the permissions '{0}' for the principal '{1}'.
    DatabasePermission_DenyPermission = Deny the permissions '{0}' for the principal '{1}'.
    DatabasePermission_RevokePermission = Revoke the permissions '{0}' for the principal '{1}'.
    DatabasePermission_IgnoreWithGrantForStateDeny = The parameter WithGrant cannot be used together with the state Deny, the parameter WithGrant is ignored.
    DatabasePermission_ChangePermissionShouldProcessVerboseDescription = Changing the permission for the principal '{0}' in the database '{1}' on the instance '{2}'.
    DatabasePermission_ChangePermissionShouldProcessVerboseWarning = Are you sure you want to change the permission for the principal '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DatabasePermission_ChangePermissionShouldProcessCaption = Change permission on principal

    ## Test-SqlDscIsDatabasePrincipal
    IsDatabasePrincipal_DatabaseMissing = The database '{0}' cannot be found.

    ## Get-SqlDscServerPermission, Set-SqlDscServerPermission
    ServerPermission_MissingPrincipal = The principal '{0}' is not a login nor role on the instance '{1}'.

    ## Set-SqlDscServerPermission
    ServerPermission_IgnoreWithGrantForStateDeny = The parameter WithGrant cannot be used together with the state Deny, the parameter WithGrant is ignored.
    ServerPermission_ChangePermissionShouldProcessVerboseDescription = Changing the permission for the principal '{0}' on the instance '{1}'.
    ServerPermission_ChangePermissionShouldProcessVerboseWarning = Are you sure you want to change the permission for the principal '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    ServerPermission_ChangePermissionShouldProcessCaption = Change permission on principal
    ServerPermission_GrantPermission = Grant the permissions '{0}' for the principal '{1}'.
    ServerPermission_DenyPermission = Deny the permissions '{0}' for the principal '{1}'.
    ServerPermission_RevokePermission = Revoke the permissions '{0}' for the principal '{1}'.

    ## Class DatabasePermission
    InvalidTypeForCompare = Invalid type in comparison. Expected type [{0}], but the type was [{1}]. (DP0001)

    ## New-SqlDscAudit, Set-SqlDscAudit
    Audit_PathParameterValueInvalid = The path '{0}' does not exist. Audit file can only be created in a path that already exist and where the SQL Server instance has permission to write.

    ## New-SqlDscAudit
    Audit_Add_ShouldProcessVerboseDescription = Adding the audit '{0}' on the instance '{1}'.
    Audit_Add_ShouldProcessVerboseWarning = Are you sure you want to add the audit '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Audit_Add_ShouldProcessCaption = Add audit on instance
    Audit_AlreadyPresent = There is already an audit with the name '{0}'.

    ## Set-SqlDscAudit
    Audit_Update_ShouldProcessVerboseDescription = Updating the audit '{0}' on the instance '{1}'.
    Audit_Update_ShouldProcessVerboseWarning = Are you sure you want to update the audit '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Audit_Update_ShouldProcessCaption = Update audit on instance
    Audit_MaximumFileSizeParameterValueInvalid = The maximum file size must be set to a value of 0 or a value between 2 and 2147483647.
    Audit_QueueDelayParameterValueInvalid = The queue delay must be set to a value of 0 or a value between 1000 and 2147483647.

    ## Get-SqlDscAudit
    Audit_Missing = There is no audit with the name '{0}'.

    ## Remove-SqlDscAudit
    Audit_Remove_ShouldProcessVerboseDescription = Removing the audit '{0}' on the instance '{1}'.
    Audit_Remove_ShouldProcessVerboseWarning = Are you sure you want to remove the audit '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Audit_Remove_ShouldProcessCaption = Remove audit on instance

    ## Enable-SqlDscAudit
    Audit_Enable_ShouldProcessVerboseDescription = Enabling the audit '{0}' on the instance '{1}'.
    Audit_Enable_ShouldProcessVerboseWarning = Are you sure you want to enable the audit '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Audit_Enable_ShouldProcessCaption = Enable audit on instance

    ## Disable-SqlDscAudit
    Audit_Disable_ShouldProcessVerboseDescription = Disabling the audit '{0}' on the instance '{1}'.
    Audit_Disable_ShouldProcessVerboseWarning = Are you sure you want to disable the audit '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Audit_Disable_ShouldProcessCaption = Disable audit on instance

    ## Invoke-SetupAction, Invoke-ReportServerSetupAction
    SetupAction_SetupExitMessage = Setup exited with code '{0}'.
    SetupAction_SetupSuccessful = Setup finished successfully.
    SetupAction_SetupSuccessfulRebootRequired = Setup finished successfully, but a reboot is required.

    ## Invoke-SetupAction
    Invoke_SetupAction_ShouldProcessVerboseDescription = Invoking the Microsoft SQL Server setup action '{0}'.
    Invoke_SetupAction_ShouldProcessVerboseWarning = Are you sure you want to invoke the setup action '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Invoke_SetupAction_ShouldProcessCaption = Invoke a Microsoft SQL Server setup action
    Invoke_SetupAction_ConfigurationFileNotFound = The specified configuration file was not found.
    Invoke_SetupAction_MediaPathNotFound = The specified media path does not exist or does not contain 'setup.exe'.
    Invoke_SetupAction_SetupArguments = Specified setup executable arguments: {0}
    Invoke_SetupAction_SetupFailed = Please see the 'Summary.txt' log file in the 'Setup Bootstrap\\Log' folder.

    ## Invoke-ReportServerSetupAction
    ReportServerSetupAction_ReportServerExecutableNotFound = The specified executable does not exist.
    ReportServerSetupAction_InstallFolderNotFound = The parent of the specified install folder does not exist.
    ReportServerSetupAction_SetupArguments = Specified executable arguments: {0}
    ReportServerSetupAction_ShouldProcessVerboseDescription = Invoking the setup action '{0}'.
    ReportServerSetupAction_ShouldProcessVerboseWarning = Are you sure you want to invoke the setup action '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    ReportServerSetupAction_ShouldProcessCaption = Invoke a setup action

    ## Assert-SetupActionProperties
    InstallSqlServerProperties_ASServerModeInvalidValue = The value for ASServerMode is not valid for the setup action {0}.
    InstallSqlServerProperties_RsInstallModeInvalidValue = The only valid value for RsInstallMode is 'FilesOnlyMode' when using setup action {0}.

    ## Get-SqlDscManagedComputer
    ManagedComputer_GetState = Returning the managed computer object for server {0}.

    ## Get-SqlDscManagedComputerService
    ManagedComputerService_GetState = Returning the managed computer service object(s) for server {0}.

    ## StartupParameters
    StartupParameters_DebugFoundTraceFlags = {0}: Found the trace flags: {1}
    StartupParameters_DebugParsingStartupParameters = {0}: Parsing the startup parameters: {1}

    ## ConvertFrom-ManagedServiceType
    ManagedServiceType_ConvertFrom_UnknownServiceType = The service type '{0}' is unknown and cannot me converted to its normalized service account equivalent

    ## Assert-ManagedServiceType
    ManagedServiceType_Assert_WrongServiceType = The provided ServiceObject is of the wrong type. Expected {0}, but was {1}.

    ## Get-SqlDscStartupParameter
    StartupParameter_Get_ReturnStartupParameters = Returning the startup parameters for instance {0} on server {1}.
    StartupParameter_Get_FailedToFindServiceObject = Failed to find the service object.
    StartupParameter_Get_FailedToFindStartupParameters = {0}: Failed to find the instance's startup parameters.

    ## Set-SqlDscStartupParameter
    StartupParameter_Set_ShouldProcessVerboseDescription = Setting startup parameters on the instance '{0}'.
    StartupParameter_Set_ShouldProcessVerboseWarning = Are you sure you want to set the startup parameters on the instance '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    StartupParameter_Set_ShouldProcessCaption = Set startup parameter on instance
    StartupParameter_Set_FailedToFindServiceObject = Failed to find the service object.

    ## Get-SqlDscTraceFlag
    TraceFlag_Get_ReturnTraceFlags = Returning the trace flags for instance {0} on server {1}.
    TraceFlag_Get_DebugReturningTraceFlags = {0}: Returning the trace flag values: {1}

    ## Set-SqlDscTraceFlag
    TraceFlag_Set_ShouldProcessVerboseDescription = Replacing the trace flags on the instance '{0}' with the trace flags '{1}'.
    TraceFlag_Set_ShouldProcessVerboseWarning = Are you sure you want to replace the trace flags on the instance '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    TraceFlag_Set_ShouldProcessCaption = Replace trace flag on instance

    ## Add-SqlDscTraceFlag
    TraceFlag_Add_ShouldProcessVerboseDescription = Adding trace flags '{1}' to the instance '{0}'.
    TraceFlag_Add_ShouldProcessVerboseWarning = Are you sure you want to add trace flags to the instance '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    TraceFlag_Add_ShouldProcessCaption = Add trace flag on instance

    ## Remove-SqlDscTraceFlag
    TraceFlag_Remove_ShouldProcessVerboseDescription = Removing trace flags '{1}' from the instance '{0}'.
    TraceFlag_Remove_ShouldProcessVerboseWarning = Are you sure you want to remove the trace flags from the instance '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    TraceFlag_Remove_ShouldProcessCaption = Remove trace flag from instance
    TraceFlag_Remove_NoCurrentTraceFlags = There are no current trace flags on instance. Nothing to remove.

    ## Get-SqlDscPreferredModule
    PreferredModule_ModuleVersionFound = Preferred module '{0}' with version '{1}' found.
    PreferredModule_ModuleNotFound =  No preferred PowerShell module was found.
    PreferredModule_ModuleVersionNotFound = No preferred Powershell module with version '{0}' was found.

    ## Import-SqlDscPreferredModule
    PreferredModule_ImportedModule = Imported PowerShell module '{0}' with version '{1}' from path '{2}'.
    PreferredModule_AlreadyImported = Found PowerShell module {0} already imported in the session.
    PreferredModule_ForceRemoval = Forcibly removed the SQL PowerShell module from the session to import it fresh again.
    PreferredModule_PushingLocation = SQLPS module changes CWD to SQLServer:\ when loading, pushing location to pop it when module is loaded.
    PreferredModule_PoppingLocation = Popping location back to what it was before importing SQLPS module.
    PreferredModule_FailedFinding = Failed to find a dependent module. Unable to run SQL Server commands or use SQL Server types. Please install one of the preferred SMO modules or the SQLPS module, then try to import SqlServerDsc again.

    ## Invoke-SqlDscQuery
    Query_Invoke_ShouldProcessVerboseDescription = Executing a Transact-SQL query on the instance '{0}'.
    Query_Invoke_ShouldProcessVerboseWarning = Are you sure you want to execute the Transact-SQL script on the instance '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Query_Invoke_ShouldProcessCaption = Execute Transact-SQL script on instance
    Query_Invoke_ExecuteQueryWithResults = Returning the results of the query `{0}`.
    Query_Invoke_ExecuteNonQuery = Executing the query `{0}`.

    ## Disconnect-SqlDscDatabaseEngine
    DatabaseEngine_Disconnect_ShouldProcessVerboseDescription = Disconnecting from the instance '{0}'.
    DatabaseEngine_Disconnect_ShouldProcessVerboseWarning = Are you sure you want to disconnect from the instance '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DatabaseEngine_Disconnect_ShouldProcessCaption = Disconnect from instance

    ## Assert-Feature
    Feature_Assert_NotSupportedFeature = The feature '{0}' is not supported for Microsoft SQL Server product version {1}. See the Microsoft SQL Server documentation https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt#Feature for more information.

    ## Get-FileVersionInformation
    FileVersionInformation_Get_FilePathIsNotFile = The specified path is not a file.

    ## Get-SqlDscConfigurationOption
    ConfigurationOption_Get_Missing = There is no configuration option with the name '{0}'.

    ## Save-SqlDscSqlServerMediaFile
    SqlServerMediaFile_Save_ShouldProcessVerboseDescription = The existing destination file '{0}' already exists and will be replaced.
    SqlServerMediaFile_Save_ShouldProcessVerboseWarning = Are you sure you want to replace existing file '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    SqlServerMediaFile_Save_ShouldProcessCaption = Replace existing file
    SqlServerMediaFile_Save_InvalidDestinationFolder = Multiple files with the .iso extension was found in the destination path. Please choose another destination folder.
    SqlServerMediaFile_Save_MultipleFilesFoundAfterDownload = Multiple files with the .iso extension was found in the destination path. Cannot determine which one of the files that was downloaded.
    SqlServerMediaFile_Save_DownloadingInformation = Downloading the SQL Server media from '{0}'.
    SqlServerMediaFile_Save_IsExecutable = Downloaded an executable file. Using the executable to download the media file.
    SqlServerMediaFile_Save_RemovingExecutable = Removing the downloaded executable file.
    SqlServerMediaFile_Save_RenamingFile = Renaming the downloaded file from '{0}' to '{1}'.

    ## Get-SqlDscRSSetupConfiguration
    Get_SqlDscRSSetupConfiguration_GetAllInstances = Getting all SQL Server Reporting Services instances.
    Get_SqlDscRSSetupConfiguration_GetSpecificInstance = Getting SQL Server Reporting Services instance '{0}'.
    Get_SqlDscRSSetupConfiguration_FoundInstance = Found a Microsoft SQL Server Reporting Services instance with the name '{0}'.
    Get_SqlDscRSSetupConfiguration_ProcessingInstance = Processing configuration for instance '{0}'.
    Get_SqlDscRSSetupConfiguration_InstanceNotFound = Could not find a Microsoft SQL Server Reporting Services instance with the name '{0}'.
    Get_SqlDscRSSetupConfiguration_NoInstancesFound = No SQL Server Reporting Services instances were found.

    ## Test-SqlDscRSInstalled
    Test_SqlDscRSInstalled_Checking = Checking if Reporting Services instance '{0}' is installed.
    Test_SqlDscRSInstalled_Found = Reporting Services instance '{0}' was found.
    Test_SqlDscRSInstalled_NotFound = Reporting Services instance '{0}' was not found.

    ## ConvertTo-SqlDscEditionName
    ConvertTo_EditionName_ConvertingEditionId = Converting EditionId '{0}' to Edition name.
    ConvertTo_EditionName_UnknownEditionId = The EditionId '{0}' is unknown and could not be converted.

    ## Assert-SqlDscLogin
    Assert_Login_CheckingLogin = Checking if the principal '{0}' exists as a login on the instance '{1}'.
    Assert_Login_LoginMissing = The principal '{0}' does not exist as a login on the instance '{1}'.
    Assert_Login_LoginExists = The principal '{0}' exists as a login.
'@
