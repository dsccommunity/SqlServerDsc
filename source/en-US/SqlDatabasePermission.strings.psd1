<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlDatabasePermission.
#>

ConvertFrom-StringData @'
    # Strings overrides for the ResourceBase's default strings.
    # None

    # Strings directly used by the derived class SqlDatabasePermission.

    GetDatabasePermission = Get permissions for the user '{0}' in the database '{1}' on the instance '{2}'. (SDP0001)
    DatabaseNotFound = The database '{0}' does not exist. (SDP0002)
    ChangePermissionForUser = Changing the permission for the user '{0}' in the database '{1}' on the instance '{2}'. (SDP0003)
    NameIsMissing = The name '{0}' is neither a database user, database role (user-defined), or database application role in the database '{1}'. (SDP0004)
    AddPermission = {0} the permissions '{1}' to the database '{2}'. (SDP0005)
    DropPermission = Revoking the {0} permissions '{1}' from the database '{2}'. (SDP0006)
    FailedToSetPermissionDatabase = Failed to set the permissions for the login '{0}' in the database '{1}'. (SDP0007)
    TestingConfiguration = Determines if the user '{0}' has the correct permissions in the database '{1}' on the instance '{2}'. (SDP0008)
'@
