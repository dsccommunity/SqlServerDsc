<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlServerDsc module. This file should only contain
        localized strings for private and public functions.
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
    ServerPermission_MissingPrincipal = The principal '{0}' is not a login on the instance '{1}'.

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

    ## Install-SqlDscServer
    Server_Install_ShouldProcessVerboseDescription = Invoking the Microsoft SQL Server setup action '{0}'.
    Server_Install_ShouldProcessVerboseWarning = Are you sure you want to invoke the setup action '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Server_Install_ShouldProcessCaption = Invoke a Microsoft SQL Server setup action
    Server_SetupExitMessage = Setup exited with code '{0}'.
    Server_SetupSuccessful = Setup finished successfully.
    Server_SetupSuccessfulRebootRequired = Setup finished successfully, but a reboot is required.
    Server_SetupFailed = Please see the 'Summary.txt' log file in the 'Setup Bootstrap\\Log' folder.
    Server_SetupArguments = Specified setup executable arguments: {0}
    Server_MediaPathNotFound = The specified media path does not exist or does not contain 'setup.exe'.
    Server_ConfigurationFileNotFound = The specified configuration file was not found.

    ## Assert-RequiredCommandParameter
    RequiredCommandParameter_SpecificParametersMustAllBeSet = The parameters '{0}' must all be specified.
    RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist = The parameters '{0}' must all be specified if either parameter '{1}' is specified.

    ## Assert-SetupActionProperties
    InstallSqlServerProperties_ASServerModeInvalidValue = The value for ASServerMode is not valid for the setup action {0}.
    InstallSqlServerProperties_RsInstallModeInvalidValue = The only valid value for RsInstallMode is 'FilesOnlyMode' when using setup action {0}.
'@
