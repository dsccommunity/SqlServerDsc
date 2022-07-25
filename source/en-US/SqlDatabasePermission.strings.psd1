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
    DesiredAbsentPermissionArePresent = The desired permission '{0}' that shall be absent are present. (SDP0003)
    DesiredPermissionAreAbsent = The desired permission '{0}' that shall be present are absent. (SDP0003)
    FailedToRevokePermissionFromCurrentState = Failed to revoke the permissions from the current state for the user '{0}' in the database '{1}'. (SDP0007)
    FailedToSetPermission = Failed to set the desired permissions for the user '{0}' in the database '{1}'. (SDP0007)
    DuplicatePermissionState = One or more permission states was added more than once. It is only allowed to specify one of each permission state. (SDP0009)
    MissingPermissionState = One or more permission states was missing. One of each permission state must be provided. (SDP0009)
    MustAssignOnePermissionProperty = At least one of the properties 'Permission', 'PermissionToInclude', or 'PermissionToExclude' must be specified. (SDP0010)
'@