ConvertFrom-StringData @'
    GetDatabasePermission = Get permissions for the user '{0}' in the database '{1}' on the instance '{2}'.
    DatabaseNotFound = The database '{0}' does not exist.
    ChangePermissionForUser = Changing the permission for the user '{0}' in the database '{1}' on the instance '{2}'.
    NameIsMissing = The name '{0}' is neither a database user, database role (user-defined), or database application role in the database '{1}'.
    AddPermission = {0} the permissions '{1}' to the database '{2}'.
    DropPermission = Revoking the {0} permissions '{1}' from the database '{2}'.
    FailedToSetPermissionDatabase = Failed to set the permissions for the login '{0}' in the database '{1}'.
    TestingConfiguration = Determines if the user '{0}' has the correct permissions in the database '{1}' on the instance '{2}'.
'@
