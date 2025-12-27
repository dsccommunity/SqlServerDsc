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
    ServerPermission_Set_ShouldProcessVerboseDescription = Setting exact server permissions for the principal '{0}' on the instance '{1}'.
    ServerPermission_Set_ShouldProcessVerboseWarning = Are you sure you want to set exact server permissions for the principal '{0}'? This will revoke any permissions not specified.
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    ServerPermission_Set_ShouldProcessCaption = Set exact server permissions
    ServerPermission_GrantPermission = Grant the permissions '{0}' for the principal '{1}'.
    ServerPermission_DenyPermission = Deny the permissions '{0}' for the principal '{1}'.
    ServerPermission_RevokePermission = Revoke the permissions '{0}' for the principal '{1}'.

    ## Grant-SqlDscServerPermission
    ServerPermission_Grant_ShouldProcessVerboseDescription = Granting server permissions '{2}' for the principal '{0}' on the instance '{1}'.
    ServerPermission_Grant_ShouldProcessVerboseWarning = Are you sure you want to grant server permissions for the principal '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    ServerPermission_Grant_ShouldProcessCaption = Grant server permissions
    ServerPermission_Grant_FailedToGrantPermission = Failed to grant server permissions '{2}' for principal '{0}' on instance '{1}'.

    ## Deny-SqlDscServerPermission
    ServerPermission_Deny_ShouldProcessVerboseDescription = Denying server permissions '{2}' for the principal '{0}' on the instance '{1}'.
    ServerPermission_Deny_ShouldProcessVerboseWarning = Are you sure you want to deny server permissions for the principal '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    ServerPermission_Deny_ShouldProcessCaption = Deny server permissions
    ServerPermission_Deny_FailedToDenyPermission = Failed to deny server permissions '{2}' for principal '{0}' on instance '{1}'.

    ## Test-SqlDscServerPermission
    ServerPermission_TestingDesiredState = Testing desired state for server permissions for principal '{0}' on instance '{1}'.
    ServerPermission_Test_TestFailed = Failed to test server permissions for principal '{0}': {1}
    ServerPermission_Test_CurrentPermissions = Current server permissions for principal '{0}': {1}
    ServerPermission_Test_NoPermissionsFound = No server permissions found for principal '{0}'.

    ## Revoke-SqlDscServerPermission
    ServerPermission_Revoke_ShouldProcessVerboseDescription = Revoking server permissions '{2}' for the principal '{0}' on the instance '{1}'.
    ServerPermission_Revoke_ShouldProcessVerboseWarning = Are you sure you want to revoke server permissions for the principal '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    ServerPermission_Revoke_ShouldProcessCaption = Revoke server permissions
    ServerPermission_Revoke_FailedToRevokePermission = Failed to revoke server permissions '{2}' for principal '{0}' on instance '{1}'.

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
    Audit_AuditGuidChangeRequiresAllowParameter = Cannot modify the AuditGuid property of the audit '{0}'. SQL Server does not allow direct modification of the audit GUID. Use the parameter AllowAuditGuidChange to permit dropping and recreating the audit with the new GUID.
    Audit_RecreatingAuditForGuidChange = Recreating the audit '{0}' on instance '{1}' to change the audit GUID to '{2}'.

    ## Get-SqlDscAudit
    Audit_Missing = There is no audit with the name '{0}'.

    ## Get-SqlDscLogin
    Login_Get_Missing = There is no login with the name '{0}'.
    Login_Get_RefreshingLogins = Refreshing logins on server '{0}'.
    Login_Get_RetrievingByName = Retrieving login by name '{0}' from server '{1}'.
    Login_Get_ReturningAllLogins = Returning all logins from server '{0}'.

    ## Remove-SqlDscLogin
    Login_Remove_ShouldProcessVerboseDescription = Removing the login '{0}' on the instance '{1}'.
    Login_Remove_ShouldProcessVerboseWarning = Are you sure you want to remove the login '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Login_Remove_ShouldProcessCaption = Remove login on instance
    Login_Remove_Failed = Removal of the login '{0}' failed. (RSDL0001)
    Login_Remove_KillingActiveSessions = Killing active sessions for login '{0}'. (RSDL0002)
    Login_Remove_KillingProcess = Killing process with SPID '{0}' for login '{1}'. (RSDL0003)
    Login_Remove_KillProcessFailed = Failed to kill process with SPID '{0}'. It may have already terminated. Error: {1} (RSDL0004)

    ## Enable-SqlDscLogin
    Login_Enable_ShouldProcessVerboseDescription = Enabling the login '{0}' on the instance '{1}'.
    Login_Enable_ShouldProcessVerboseWarning = Are you sure you want to enable the login '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Login_Enable_ShouldProcessCaption = Enable login on instance

    ## Disable-SqlDscLogin
    Login_Disable_ShouldProcessVerboseDescription = Disabling the login '{0}' on the instance '{1}'.
    Login_Disable_ShouldProcessVerboseWarning = Are you sure you want to disable the login '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Login_Disable_ShouldProcessCaption = Disable login on instance

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
    InstallSqlServerProperties_AllowDqRemovalInvalidVersion = The parameter AllowDqRemoval is only allowed for SQL Server 2025 (17.x) and later versions. The media version is {0}.x.

    ## Get-SqlDscManagedComputer
    ManagedComputer_GetState = Returning the managed computer object for server {0}.

    ## Get-SqlDscManagedComputerService
    ManagedComputerService_GetState = Returning the managed computer service object(s) for server {0}.

    ## Get-SqlDscManagedComputerInstance
    ManagedComputerInstance_GetFromServer = Getting managed computer instance information from server '{0}'.
    ManagedComputerInstance_GetFromObject = Getting managed computer instance information from managed computer object.
    ManagedComputerInstance_GetSpecificInstance = Getting specific server instance '{0}'.
    ManagedComputerInstance_GetAllInstances = Getting all server instances.
    ManagedComputerInstance_InstanceNotFound = Could not find SQL Server instance '{0}' on server '{1}'.

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
    TraceFlag_Remove_NoChange = The specified trace flags are not currently set on the instance. No changes needed.

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

    ## Get-SqlDscConfigurationOption
    ConfigurationOption_Get_Missing = There is no configuration option with the name '{0}'.

    ## Set-SqlDscConfigurationOption
    ConfigurationOption_Set_Missing = There is no configuration option with the name '{0}'.
    ConfigurationOption_Set_InvalidValue = The value '{1}' for configuration option '{0}' is outside the valid range of {2} to {3}.
    ConfigurationOption_Set_ShouldProcessDescription = Set configuration option '{0}' to '{1}' on server '{2}'.
    ConfigurationOption_Set_ShouldProcessConfirmation = Are you sure you want to set configuration option '{0}' to '{1}'?
    ConfigurationOption_Set_ShouldProcessCaption = Set configuration option
    ConfigurationOption_Set_Success = Successfully set configuration option '{0}' to '{1}' on server '{2}'.
    ConfigurationOption_Set_Failed = Failed to set configuration option '{0}' to '{1}'. {2}

    ## Test-SqlDscConfigurationOption
    ConfigurationOption_Test_Missing = There is no configuration option with the name '{0}'.
    ConfigurationOption_Test_Result = Testing configuration option '{0}': Current value is '{1}', expected value is '{2}', match result is '{3}' on server '{4}'.

    ## Save-SqlDscSqlServerMediaFile
    SqlServerMediaFile_Save_ShouldProcessVerboseDescription = The existing destination file '{0}' already exists and will be replaced.
    SqlServerMediaFile_Save_ShouldProcessVerboseWarning = Are you sure you want to replace existing file '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    SqlServerMediaFile_Save_ShouldProcessCaption = Replace existing file
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

    ## Get-SqlDscServerProtocol
    ServerProtocol_GetState = Getting server protocol '{0}' information for instance '{1}' on server '{2}'.
    ServerProtocol_GetAllProtocols = Getting all server protocols for instance '{0}' on server '{1}'.
    ServerProtocol_ProtocolNotFound = Could not find server protocol '{0}' for instance '{1}' on server '{2}'.

    ## Get-SqlDscServerProtocolName
    ServerProtocolName_GetProtocolMappings = Getting SQL Server protocol name mappings.

    ## Assert-SqlDscLogin
    Assert_Login_CheckingLogin = Checking if the principal '{0}' exists as a login on the instance '{1}'.
    Assert_Login_LoginMissing = The principal '{0}' does not exist as a login on the instance '{1}'.
    Assert_Login_LoginExists = The principal '{0}' exists as a login.

    ## Get-SqlDscRole
    Role_Get = Getting server roles from instance '{0}'.
    Role_GetAll = Getting all server roles.
    Role_Found = Found server role '{0}'.
    Get_SqlDscRole_NotFound = Server role '{0}' was not found. (GSDR0001)

    ## New-SqlDscRole
    Role_CreateFailed = Failed to create server role '{0}' on instance '{1}'.
    Role_AlreadyExists = Server role '{0}' already exists on instance '{1}'.
    Role_Create_ShouldProcessDescription = Creating the server role '{0}' on the instance '{1}'.
    Role_Create_ShouldProcessConfirmation = Are you sure you want to create the server role '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Role_Create_ShouldProcessCaption = Create server role on instance

    ## Remove-SqlDscRole
    Role_Remove = Removing server role '{0}' from instance '{1}'.
    Remove_SqlDscRole_NotFound = Server role '{0}' was not found. (RSDR0001)
    Role_RemoveFailed = Failed to remove server role '{0}' from instance '{1}'. (RSDR0003)
    Role_CannotRemoveBuiltIn = Cannot remove built-in server role '{0}'. (RSDR0002)
    Role_Remove_ShouldProcessDescription = Removing the server role '{0}' from the instance '{1}'.
    Role_Remove_ShouldProcessConfirmation = Are you sure you want to remove the server role '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Role_Remove_ShouldProcessCaption = Remove server role from instance

    ## New-SqlDscLogin
    Login_Add_ShouldProcessVerboseDescription = Creating the login '{0}' of type '{1}' on the instance '{2}'.
    Login_Add_ShouldProcessVerboseWarning = Are you sure you want to create the login '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Login_Add_ShouldProcessCaption = Create login on instance
    Login_Add_LoginCreated = Successfully created login '{0}' on the instance '{1}'.
    Login_Add_LoginAlreadyExists = The login '{0}' already exists on the instance '{1}'.

    ## Get-SqlDscDatabase
    Database_Get = Getting databases from instance '{0}'.
    Database_GetAll = Getting all databases.
    Database_Found = Found database '{0}'.
    Database_NotFound = Database '{0}' was not found.

    ## New-SqlDscDatabase
    Database_Create = Creating database '{0}' on instance '{1}'.
    Database_Creating = Creating database '{0}'.
    Database_Created = Database '{0}' was created successfully.
    Database_CreateFailed = Failed to create database '{0}' on instance '{1}'.
    Database_AlreadyExists = Database '{0}' already exists on instance '{1}'.
    Database_InvalidCompatibilityLevel = The specified compatibility level '{0}' is not a valid compatibility level for the instance '{1}'.
    Database_InvalidCollation = The specified collation '{0}' is not a valid collation for the instance '{1}'.
    Database_CatalogCollationNotSupported = The parameter CatalogCollation is not supported on SQL Server instance '{0}' with version '{1}'. This parameter requires SQL Server 2019 (version 15) or later.
    Database_IsLedgerNotSupported = The parameter IsLedger is not supported on SQL Server instance '{0}' with version '{1}'. This parameter requires SQL Server 2022 (version 16) or later.
    Database_SnapshotSourceDatabaseNotFound = The source database '{0}' for the database snapshot does not exist on instance '{1}'.
    Database_CreatingSnapshot = Creating database snapshot '{0}' from source database '{1}'.
    Database_Create_ShouldProcessVerboseDescription = Creating the database '{0}' on the instance '{1}'.
    Database_Create_ShouldProcessVerboseWarning = Are you sure you want to create the database '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Database_Create_ShouldProcessCaption = Create database on instance

    ## Resume-SqlDscDatabase
    Database_Resume_ShouldProcessVerboseDescription = Bringing the database '{0}' online on the instance '{1}'.
    Database_Resume_ShouldProcessVerboseWarning = Are you sure you want to bring the database '{0}' online?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Database_Resume_ShouldProcessCaption = Bring database online
    Database_AlreadyOnline = Database '{0}' is already online (Status: {1}).
    Database_BringingOnline = Bringing database '{0}' online.
    Database_BroughtOnline = Database '{0}' was brought online successfully.
    Database_ResumeFailed = Failed to bring database '{0}' online.

    ## Suspend-SqlDscDatabase
    Database_Suspend_ShouldProcessVerboseDescription = Taking the database '{0}' offline on the instance '{1}'.
    Database_Suspend_ShouldProcessVerboseWarning = Are you sure you want to take the database '{0}' offline?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Database_Suspend_ShouldProcessCaption = Take database offline
    Database_AlreadyOffline = Database '{0}' is already offline (Status: {1}).
    Database_TakingOffline = Taking database '{0}' offline.
    Database_TakingOfflineWithForce = Taking database '{0}' offline with force (disconnecting active users).
    Database_KillingProcesses = Killing all processes for database '{0}'.
    Database_TakenOffline = Database '{0}' was taken offline successfully.
    Database_SuspendFailed = Failed to take database '{0}' offline.
    Database_KillProcessesFailed = Failed to kill processes for database '{0}'.

    ## New-SqlDscDatabaseSnapshot
    DatabaseSnapshot_Create = Creating database snapshot '{0}' from source database '{1}' on instance '{2}'. (NSDS0002)
    DatabaseSnapshot_EditionNotSupported = Database snapshots are not supported on SQL Server instance '{0}' with edition '{1}'. Snapshots are only supported in Enterprise, Developer, and Evaluation editions. (NSDS0001)

    ## New-SqlDscFileGroup
    FileGroup_Create_ShouldProcessDescription = Creating the filegroup '{0}' for database '{1}' on instance '{2}'. (NSDFG0001)
    FileGroup_Create_ShouldProcessConfirmation = Are you sure you want to create the filegroup '{0}'? (NSDFG0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    FileGroup_Create_ShouldProcessCaption = Create filegroup for database
    FileGroup_DatabaseMissingServerObject = The Database object must have a Server object attached to the Parent property. (NSDFG0003)

    ## Add-SqlDscFileGroup
    AddSqlDscFileGroup_Add_ShouldProcessDescription = Adding the filegroup '{0}' to database '{1}'. (ASDFG0001)
    AddSqlDscFileGroup_Add_ShouldProcessConfirmation = Are you sure you want to add the filegroup '{0}'? (ASDFG0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    AddSqlDscFileGroup_Add_ShouldProcessCaption = Add filegroup to database

    ## New-SqlDscDataFile
    DataFile_Create_ShouldProcessDescription = Creating the data file '{0}' for filegroup '{1}'. (NSDDF0001)
    DataFile_Create_ShouldProcessConfirmation = Are you sure you want to create the data file '{0}'? (NSDDF0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DataFile_Create_ShouldProcessCaption = Create data file for filegroup
    DataFile_PrimaryFileMustBeInPrimaryFileGroup = The primary file must reside in the PRIMARY filegroup. (NSDDF0003)

    ## Set-SqlDscDatabaseProperty
    Database_Set = Setting properties of database '{0}' on instance '{1}'. (SSDDP0001)
    Database_Updating = Updating database '{0}'. (SSDDP0002)
    Database_Updated = Database '{0}' was updated successfully. (SSDDP0003)
    Database_SetFailed = Failed to set properties of database '{0}' on instance '{1}'. (SSDDP0004)
    Database_UpdatingProperty = Setting property '{0}' to '{1}'. (SSDDP0005)
    Database_PropertyAlreadySet = Property '{0}' is already set to '{1}'. (SSDDP0006)
    Database_NoPropertiesChanged = No properties were changed for database '{0}'. (SSDDP0007)
    Database_Set_ShouldProcessVerboseDescription = Setting properties of the database '{0}' on the instance '{1}'.
    Database_Set_ShouldProcessVerboseWarning = Are you sure you want to modify the database '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Database_Set_ShouldProcessCaption = Set database properties on instance
    Set_SqlDscDatabaseProperty_InvalidCompatibilityLevel = The specified compatibility level '{0}' is not a valid compatibility level for the instance '{1}'. (SSDDP0008)
    Set_SqlDscDatabaseProperty_InvalidCollation = The specified collation '{0}' is not a valid collation for the instance '{1}'. (SSDDP0009)
    Set_SqlDscDatabaseProperty_PropertyNotFound = The property '{0}' does not exist on database '{1}'. This might be due to the property not being supported on this SQL Server version. (SSDDP0010)

    ## Get-SqlDscCompatibilityLevel
    GetCompatibilityLevel_GettingForInstance = Getting supported compatibility levels for instance '{0}' (version {1}).
    GetCompatibilityLevel_GettingForVersion = Getting supported compatibility levels for SQL Server version '{0}' (major version {1}).
    GetCompatibilityLevel_Found = Found {0} supported compatibility level(s) for SQL Server major version {1}.
    GetCompatibilityLevel_SmoTooOld = The loaded SMO library does not support SQL Server major version {0}. Returning compatibility levels up to {1} (expected maximum {2}). Consider updating the SqlServer PowerShell module to support newer SQL Server versions.

    ## Set-SqlDscDatabaseOwner
    DatabaseOwner_Updating = Setting owner of database '{0}' to '{1}'. (SSDDO0001)
    DatabaseOwner_Updated = Owner of database '{0}' was set to '{1}'. (SSDDO0002)
    DatabaseOwner_OwnerAlreadyCorrect = Owner of database '{0}' is already set to '{1}'. (SSDDO0003)
    DatabaseOwner_SetFailed = Failed to set owner of database '{0}' to '{1}'. (SSDDO0004)
    DatabaseOwner_Set_ShouldProcessVerboseDescription = Setting the owner of the database '{0}' to '{1}' on the instance '{2}'.
    DatabaseOwner_Set_ShouldProcessVerboseWarning = Are you sure you want to change the owner of the database '{0}' to '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DatabaseOwner_Set_ShouldProcessCaption = Set database owner on instance

    ## Enable-SqlDscDatabaseSnapshotIsolation
    DatabaseSnapshotIsolation_Enabling = Enabling snapshot isolation for database '{0}'. (ESDSI0002)
    DatabaseSnapshotIsolation_Enabled = Snapshot isolation for database '{0}' was enabled. (ESDSI0003)
    DatabaseSnapshotIsolation_AlreadyEnabled = Snapshot isolation for database '{0}' is already enabled. (ESDSI0004)
    DatabaseSnapshotIsolation_EnableFailed = Failed to enable snapshot isolation for database '{0}'. (ESDSI0001)
    DatabaseSnapshotIsolation_Enable_ShouldProcessVerboseDescription = Enabling snapshot isolation for the database '{0}' on the instance '{1}'.
    DatabaseSnapshotIsolation_Enable_ShouldProcessVerboseWarning = Are you sure you want to enable snapshot isolation for the database '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DatabaseSnapshotIsolation_Enable_ShouldProcessCaption = Enable snapshot isolation on database

    ## Disable-SqlDscDatabaseSnapshotIsolation
    DatabaseSnapshotIsolation_Disabling = Disabling snapshot isolation for database '{0}'. (DSDSI0002)
    DatabaseSnapshotIsolation_Disabled = Snapshot isolation for database '{0}' was disabled. (DSDSI0003)
    DatabaseSnapshotIsolation_AlreadyDisabled = Snapshot isolation for database '{0}' is already disabled. (DSDSI0004)
    DatabaseSnapshotIsolation_DisableFailed = Failed to disable snapshot isolation for database '{0}'. (DSDSI0001)
    DatabaseSnapshotIsolation_Disable_ShouldProcessVerboseDescription = Disabling snapshot isolation for the database '{0}' on the instance '{1}'.
    DatabaseSnapshotIsolation_Disable_ShouldProcessVerboseWarning = Are you sure you want to disable snapshot isolation for the database '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DatabaseSnapshotIsolation_Disable_ShouldProcessCaption = Disable snapshot isolation on database

    ## Remove-SqlDscDatabase
    Database_RemoveFailed = Failed to remove database '{0}' from instance '{1}'.
    Database_CannotRemoveSystem = Cannot remove system database '{0}'.
    Database_DroppingConnections = Dropping all active connections to database '{0}'.
    Database_DropConnectionsFailed = Failed to drop active connections for database '{0}'.
    Database_Remove_ShouldProcessDescription = Removing the database '{0}' from the instance '{1}'.
    Database_Remove_ShouldProcessConfirmation = Are you sure you want to remove the database '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Database_Remove_ShouldProcessCaption = Remove database from instance
    Remove_SqlDscDatabase_NotFound = Database '{0}' was not found.

    ## Backup-SqlDscDatabase
    Backup_SqlDscDatabase_NotFound = Database '{0}' was not found. (BSDD0001)
    Database_Backup_BackingUp = Performing {0} backup of database '{1}' to '{2}'. (BSDD0005)
    Database_Backup_Success = Successfully completed {0} backup of database '{1}'. (BSDD0006)
    Database_Backup_Failed = Failed to perform {0} backup of database '{1}' on instance '{2}'. (BSDD0004)
    Database_Backup_LogBackupSimpleRecoveryModel = Cannot perform transaction log backup on database '{0}' because the database uses the Simple recovery model. Transaction log backups require the Full or Bulk-Logged recovery model. (BSDD0002)
    Database_Backup_DatabaseNotOnline = Cannot backup database '{0}' because it is not online. Current status: '{1}'. (BSDD0003)
    Database_Backup_ShouldProcessVerboseDescription = Performing {0} backup of database '{1}' to '{2}'.
    Database_Backup_ShouldProcessVerboseWarning = Are you sure you want to perform a {0} backup of database '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Database_Backup_ShouldProcessCaption = Backup database

    ## Restore-SqlDscDatabase
    Restore_SqlDscDatabase_DatabaseExists = Cannot restore to database '{0}' because it already exists. Use the ReplaceDatabase parameter to overwrite the existing database. (RSDD0001)
    Restore_SqlDscDatabase_Failed = Failed to perform {0} restore to database '{1}' on instance '{2}'. (RSDD0003)
    Restore_SqlDscDatabase_Restoring = Performing {0} restore to database '{1}' from '{2}'. (RSDD0004)
    Restore_SqlDscDatabase_Success = Successfully completed {0} restore to database '{1}'. (RSDD0005)
    Restore_SqlDscDatabase_ShouldProcessVerboseDescription = Performing {0} restore to database '{1}' from '{2}' on instance '{3}'.
    Restore_SqlDscDatabase_ShouldProcessVerboseWarning = Are you sure you want to perform a {0} restore to database '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Restore_SqlDscDatabase_ShouldProcessCaption = Restore database
    Restore_SqlDscDatabase_StandbyConflict = The Standby parameter cannot be used together with NoRecovery. Use either Standby or NoRecovery, but not both. (RSDD0006)
    Restore_SqlDscDatabase_RestoreType_Full = full
    Restore_SqlDscDatabase_RestoreType_Differential = differential
    Restore_SqlDscDatabase_RestoreType_Log = transaction log
    Restore_SqlDscDatabase_RestoreType_Files = file

    ## Test-SqlDscBackupFile
    Test_SqlDscBackupFile_Verifying = Verifying backup file '{0}'. (TSBF0001)
    Test_SqlDscBackupFile_VerifySuccess = Backup file '{0}' verification completed successfully. (TSBF0002)
    Test_SqlDscBackupFile_VerifyFailed = Backup file '{0}' verification failed. {1} (TSBF0003)
    Test_SqlDscBackupFile_Error = Failed to verify backup file '{0}'. (TSBF0004)

    ## Get-SqlDscBackupFileList
    Get_SqlDscBackupFileList_Reading = Reading file list from backup file '{0}'. (GSBFL0001)
    Get_SqlDscBackupFileList_Failed = Failed to read file list from backup file '{0}'. (GSBFL0002)

    ## Test-SqlDscIsDatabase
    IsDatabase_Test = Testing if database '{0}' exists on instance '{1}'. (TSID0001)

    ## Test-SqlDscDatabaseProperty
    DatabaseProperty_TestingProperties = Testing properties of database '{0}' on instance '{1}'. (TSDDP0001)
    DatabaseProperty_TestingPropertiesFromObject = Testing properties of database '{0}' on instance '{1}' using database object. (TSDDP0002)
    DatabaseProperty_PropertyWrong = The database '{0}' property '{1}' has the value '{2}', but expected it to have the value '{3}'. (TSDDP0003)
    DatabaseProperty_PropertyCorrect = The database '{0}' property '{1}' has the expected value '{2}'. (TSDDP0004)
    DatabaseProperty_PropertyNotFound = The property '{0}' does not exist on database '{1}'. This might be due to the property not being supported on this SQL Server version. (TSDDP0005)

    ## Set-SqlDscDatabaseDefault
    DatabaseDefault_Set = Setting default objects of database '{0}' on instance '{1}'. (SSDDD0001)
    DatabaseDefault_Updated = Database '{0}' default objects were updated successfully. (SSDDD0002)
    DatabaseDefault_SetFailed = Failed to set default objects of database '{0}' on instance '{1}'. (SSDDD0003)
    DatabaseDefault_SetFileGroup_ShouldProcessVerboseDescription = Setting the default filegroup of database '{0}' to '{1}' on instance '{2}'.
    DatabaseDefault_SetFileGroup_ShouldProcessVerboseWarning = Are you sure you want to set the default filegroup of database '{0}' to '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DatabaseDefault_SetFileGroup_ShouldProcessCaption = Set database default filegroup
    DatabaseDefault_SetFileStreamFileGroup_ShouldProcessVerboseDescription = Setting the default FILESTREAM filegroup of database '{0}' to '{1}' on instance '{2}'.
    DatabaseDefault_SetFileStreamFileGroup_ShouldProcessVerboseWarning = Are you sure you want to set the default FILESTREAM filegroup of database '{0}' to '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DatabaseDefault_SetFileStreamFileGroup_ShouldProcessCaption = Set database default FILESTREAM filegroup
    DatabaseDefault_SetFullTextCatalog_ShouldProcessVerboseDescription = Setting the default Full-Text catalog of database '{0}' to '{1}' on instance '{2}'.
    DatabaseDefault_SetFullTextCatalog_ShouldProcessVerboseWarning = Are you sure you want to set the default Full-Text catalog of database '{0}' to '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    DatabaseDefault_SetFullTextCatalog_ShouldProcessCaption = Set database default Full-Text catalog

    ## Get-AgentAlertObject
    Get_AgentAlertObject_GettingAlert = Getting SQL Agent Alert '{0}'. (GAAO0001)

    ## Get-SqlDscAgentAlert
    Get_SqlDscAgentAlert_GettingAlerts = Getting SQL Agent Alerts from instance '{0}'. (GSAA0001)
    Get_SqlDscAgentAlert_ReturningAllAlerts = Returning all {0} SQL Agent Alerts. (GSAA0005)

    ## New-SqlDscAgentAlert
    New_SqlDscAgentAlert_AlertAlreadyExists = SQL Agent Alert '{0}' already exists. (NSAA0001)
    New_SqlDscAgentAlert_CreatingAlert = Creating SQL Agent Alert '{0}'. (NSAA0002)
    New_SqlDscAgentAlert_AlertCreated = SQL Agent Alert '{0}' was created successfully. (NSAA0003)
    New_SqlDscAgentAlert_CreateFailed = Failed to create SQL Agent Alert '{0}'. (NSAA0004)
    New_SqlDscAgentAlert_SettingSeverity = Setting severity '{0}' for SQL Agent Alert '{1}'. (NSAA0005)
    New_SqlDscAgentAlert_SettingMessageId = Setting message ID '{0}' for SQL Agent Alert '{1}'. (NSAA0006)
    New_SqlDscAgentAlert_CreateShouldProcessVerboseDescription = Creating the SQL Agent Alert '{0}' on the instance '{1}'.
    New_SqlDscAgentAlert_CreateShouldProcessVerboseWarning = Are you sure you want to create the SQL Agent Alert '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SqlDscAgentAlert_CreateShouldProcessCaption = Create SQL Agent Alert on instance

    ## Set-SqlDscAgentAlert
    Set_SqlDscAgentAlert_RefreshingServerObject = Refreshing server object's alerts collection. (SSAA0001)
    Set_SqlDscAgentAlert_AlertNotFound = SQL Agent Alert '{0}' was not found. (SSAA0002)
    Set_SqlDscAgentAlert_UpdatingAlert = Updating SQL Agent Alert '{0}'. (SSAA0003)
    Set_SqlDscAgentAlert_SettingSeverity = Setting severity '{0}' for SQL Agent Alert '{1}'. (SSAA0004)
    Set_SqlDscAgentAlert_SettingMessageId = Setting message ID '{0}' for SQL Agent Alert '{1}'. (SSAA0005)
    Set_SqlDscAgentAlert_AlertUpdated = SQL Agent Alert '{0}' was updated successfully. (SSAA0006)
    Set_SqlDscAgentAlert_NoChangesNeeded = No changes needed for SQL Agent Alert '{0}'. (SSAA0007)
    Set_SqlDscAgentAlert_UpdateFailed = Failed to update SQL Agent Alert '{0}'. (SSAA0008)
    Set_SqlDscAgentAlert_SeverityAlreadyCorrect = Severity '{0}' for SQL Agent Alert '{1}' is already correct. (SSAA0009)
    Set_SqlDscAgentAlert_MessageIdAlreadyCorrect = Message ID '{0}' for SQL Agent Alert '{1}' is already correct. (SSAA0010)
    Set_SqlDscAgentAlert_UpdateShouldProcessVerboseDescription = Updating the SQL Agent Alert '{0}' on the instance '{1}'.
    Set_SqlDscAgentAlert_UpdateShouldProcessVerboseWarning = Are you sure you want to update the SQL Agent Alert '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Set_SqlDscAgentAlert_UpdateShouldProcessCaption = Update SQL Agent Alert on instance

    ## Remove-SqlDscAgentAlert
    Remove_SqlDscAgentAlert_RefreshingServerObject = Refreshing server object's alerts collection. (RSAA0001)
    Remove_SqlDscAgentAlert_AlertNotFound = SQL Agent Alert '{0}' was not found. (RSAA0002)
    Remove_SqlDscAgentAlert_RemovingAlert = Removing SQL Agent Alert '{0}'. (RSAA0003)
    Remove_SqlDscAgentAlert_AlertRemoved = SQL Agent Alert '{0}' was removed successfully. (RSAA0004)
    Remove_SqlDscAgentAlert_RemoveFailed = Failed to remove SQL Agent Alert '{0}'. (RSAA0005)
    Remove_SqlDscAgentAlert_RemoveShouldProcessVerboseDescription = Removing the SQL Agent Alert '{0}' on the instance '{1}'.
    Remove_SqlDscAgentAlert_RemoveShouldProcessVerboseWarning = Are you sure you want to remove the SQL Agent Alert '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Remove_SqlDscAgentAlert_RemoveShouldProcessCaption = Remove SQL Agent Alert on instance

    ## Test-SqlDscIsAgentAlert
    Test_SqlDscIsAgentAlert_TestingAlert = Testing if the SQL Agent Alert '{0}' exists. (TSIAA0001)
    Test_SqlDscIsAgentAlert_AlertNotFound = SQL Agent Alert '{0}' was not found. (TSIAA0002)
    Test_SqlDscIsAgentAlert_AlertFound = SQL Agent Alert '{0}' was found. (TSIAA0003)

    ## Test-SqlDscAgentAlertProperty
    Test_SqlDscAgentAlertProperty_AlertNotFound = SQL Agent Alert '{0}' was not found. (TSDAAP0001)

    ## Get-SqlDscAgentOperator
    Get_SqlDscAgentOperator_GettingOperator = Getting SQL Agent Operator '{0}'. (GSAO0003)
    Get_SqlDscAgentOperator_GettingOperators = Getting SQL Agent Operators from instance '{0}'. (GSAO0001)
    Get_SqlDscAgentOperator_ReturningAllOperators = Returning all {0} SQL Agent Operators. (GSAO0002)

    ## New-SqlDscAgentOperator
    New_SqlDscAgentOperator_OperatorAlreadyExists = SQL Agent Operator '{0}' already exists. (NSAO0001)
    New_SqlDscAgentOperator_CreateFailed = Failed to create SQL Agent Operator '{0}'. (NSAO0004)
    New_SqlDscAgentOperator_CreateShouldProcessVerboseDescription = Creating the SQL Agent Operator '{0}' on the instance '{1}'.
    New_SqlDscAgentOperator_CreateShouldProcessVerboseWarning = Are you sure you want to create the SQL Agent Operator '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SqlDscAgentOperator_CreateShouldProcessCaption = Create SQL Agent Operator on instance

    ## Set-SqlDscAgentOperator
    Set_SqlDscAgentOperator_RefreshingServerObject = Refreshing server object's operators collection. (SSAO0001)
    Set_SqlDscAgentOperator_UpdateFailed = Failed to update SQL Agent Operator '{0}'. (SSAO0007)
    Set_SqlDscAgentOperator_UpdateShouldProcessVerboseDescription = Updating the SQL Agent Operator '{0}' on the instance '{1}' with parameters:{2}
    Set_SqlDscAgentOperator_UpdateShouldProcessVerboseWarning = Are you sure you want to update the SQL Agent Operator '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Set_SqlDscAgentOperator_UpdateShouldProcessCaption = Update SQL Agent Operator on instance

    ## Remove-SqlDscAgentOperator
    Remove_SqlDscAgentOperator_RemoveFailed = Failed to remove SQL Agent Operator '{0}'. (RSAO0005)
    Remove_SqlDscAgentOperator_RemoveShouldProcessVerboseDescription = Removing the SQL Agent Operator '{0}' on the instance '{1}'.
    Remove_SqlDscAgentOperator_RemoveShouldProcessVerboseWarning = Are you sure you want to remove the SQL Agent Operator '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Remove_SqlDscAgentOperator_RemoveShouldProcessCaption = Remove SQL Agent Operator on instance
    Remove_SqlDscAgentOperator_OperatorNotFound = SQL Agent Operator '{0}' was not found. (RSAO0002)

    ## Test-SqlDscIsAgentOperator
    Test_SqlDscIsAgentOperator_TestingOperator = Testing if the SQL Agent Operator '{0}' exists and has the desired properties. (TISAO0001)
    Test_SqlDscIsAgentOperator_OperatorNotFound = SQL Agent Operator '{0}' was not found. (TISAO0002)
    Test_SqlDscIsAgentOperator_OperatorFound = SQL Agent Operator '{0}' was found. (TISAO0003)

    ## Enable-SqlDscAgentOperator
    Enable_SqlDscAgentOperator_EnableFailed = Failed to enable SQL Agent Operator '{0}'. (ESAO0005)
    Enable_SqlDscAgentOperator_ShouldProcessVerboseDescription = Enabling the SQL Agent Operator '{0}' on the instance '{1}'.
    Enable_SqlDscAgentOperator_ShouldProcessVerboseWarning = Are you sure you want to enable the SQL Agent Operator '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Enable_SqlDscAgentOperator_ShouldProcessCaption = Enable SQL Agent Operator on instance

    ## Disable-SqlDscAgentOperator
    Disable_SqlDscAgentOperator_DisableFailed = Failed to disable SQL Agent Operator '{0}'. (DSAO0005)
    Disable_SqlDscAgentOperator_ShouldProcessVerboseDescription = Disabling the SQL Agent Operator '{0}' on the instance '{1}'.
    Disable_SqlDscAgentOperator_ShouldProcessVerboseWarning = Are you sure you want to disable the SQL Agent Operator '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Disable_SqlDscAgentOperator_ShouldProcessCaption = Disable SQL Agent Operator on instance

    ## Agent Operator common
    AgentOperator_NotFound = The SQL Agent Operator '{0}' was not found. (AO0001)

    ## Get-AgentOperatorObject
    Get_AgentOperatorObject_GettingOperator = Getting SQL Agent Operator '{0}' from server object. (GAOO0002)
    Get_AgentOperatorObject_RefreshingOperators = Refreshing SQL Agent Operators collection. (GAOO0003)

    ## ConvertTo-FormattedParameterDescription
    ConvertTo_FormattedParameterDescription_NoParametersToUpdate = (no parameters to update)

    ## Get-SqlDscSetupLog
    Get_SqlDscSetupLog_SearchingForFile = Searching for '{0}' in path '{1}'. (GSDSL0001)
    Get_SqlDscSetupLog_FileFound = Found setup log file at '{0}'. (GSDSL0002)
    Get_SqlDscSetupLog_FileNotFound = Setup log file '{0}' not found. (GSDSL0003)
    Get_SqlDscSetupLog_Header = ==== SQL Server Setup {0} (from {1}) ==== (GSDSL0004)
    Get_SqlDscSetupLog_Footer = ==== End of {0} ==== (GSDSL0005)
    Get_SqlDscSetupLog_PathNotFound = Path '{0}' does not exist. (GSDSL0006)

    ## Invoke-SqlDscScalarQuery
    Invoke_SqlDscScalarQuery_ExecutingQuery = Executing the scalar query `{0}`. (ISDSQ0001)
    Invoke_SqlDscScalarQuery_FailedToExecute = Failed to execute scalar query: {0} (ISDSQ0002)

    ## Get-SqlDscDateTime
    Get_SqlDscDateTime_RetrievingDateTime = Retrieving date and time using {0}(). (GSDD0001)
    Get_SqlDscDateTime_FailedToRetrieve = Failed to retrieve date and time using {0}(): {1} (GSDD0002)

    ## Get-SqlDscRSPackage
    Get_SqlDscRSPackage_GettingVersionFromFile = Getting version information from file '{0}'. (GSDRSP0001)
    Get_SqlDscRSPackage_InvalidProductName = The product name '{0}' is not a valid Reporting Services package. Expected product names are: '{1}'. Use the Force parameter to skip this validation. (GSDRSP0002)
    Get_SqlDscRSPackage_ReturningVersionInfo = Returning version information for '{0}' version '{1}'. (GSDRSP0003)
'@
