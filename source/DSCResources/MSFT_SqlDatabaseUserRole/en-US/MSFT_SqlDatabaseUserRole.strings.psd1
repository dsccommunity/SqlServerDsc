ConvertFrom-StringData @'
    AddDatabaseRoleMember = Adding member '{0}' to role '{1}' in database '{2}'.
    AddDatabaseRoleMemberError = Failed to add member '{0}' to role '{1}' in database '{2}'.
    DatabaseNotFound = The database '{0}' does not exist.
    DatabaseRoleOrUserNotFound = The user '{0}' or role '{1}' does not exist in database '{2}'.
    DropDatabaseRoleMember = Removing user '{0}' from role '{1}' in database '{2}'.
    DropDatabaseRoleMemberError = Failed to remove user '{0}' from role '{1}' in database '{2}'.
    GetDatabaseUserRoleMembership = Getting role membership for the SQL database user '{0}'.
    GetDatabaseUserRoleNames = Getting role names for the SQL database user '{0}'.
    GetDatabaseUserRoleNamesCount = Found {1} role(s) for the SQL database user '{0}'.
    RoleNamesToIncludeAndExcludeParamMustBeNull = The parameter RoleNamesToInclude and/or RoleNamesToExclude must not be set, or be set to $null, when parameter RoleNamesToEnforce is used.
    RoleNotPresent = User '{0}' is not a member of the role '{1}' in database '{2}'.
    RolePresent = User '{0}' should not be a member of the role '{1}' in database '{2}'.
    RolesDoNotMatchListToBeEnforced = One or more roles are not present or extraneous for user '{0}' in database '{1}'.
    SetDatabaseUserRoleMembership = Setting role membership for the SQL database user '{0}'.
    TestDatabaseUserRoleMembership = Testing the desired state of the SQL database user '{0}' role membership.
'@
