<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlDatabasePermission.
#>

ConvertFrom-StringData @'
    # Strings overrides for the ResourceBase's default strings.
    # None

    # Strings directly used by the derived class SqlDatabasePermission.
    EvaluateDatabasePermissionForPrincipal = Evaluate the current permissions for the user '{0}' in the database '{1}' on the instance '{2}'. (SDP0001)
    NameIsMissing = The name '{0}' is neither a database user, database role (user-defined), or database application role in the database '{1}', or the database '{1}' does not exist on the instance '{2}'. (SDP0004)
    DesiredAbsentPermissionArePresent = The desired permissions that shall be absent are present for the user '{0}' in the database '{1}' on the instance '{2}'. (SDP0003)
    FailedToSetPermissionDatabase = Failed to set the permissions for the user '{0}' in the database '{1}'. (SDP0007)
'@
