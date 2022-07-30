<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlDatabasePermission.
#>

ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class SqlDatabasePermission.
    EvaluateDatabasePermissionForPrincipal = Evaluate the current permissions for the principal '{0}' in the database '{1}' on the instance '{2}'. (SDP0001)
    NameIsMissing = The name '{0}' is neither a database user, database role (user-defined), or database application role in the database '{1}', or the database '{1}' does not exist on the instance '{2}'. (SDP0002)
    DesiredAbsentPermissionArePresent = The desired permission '{0}' that shall be absent are present. (SDP0003)
    DesiredPermissionAreAbsent = The desired permission '{0}' that shall be present are absent. (SDP0004)
    FailedToRevokePermissionFromCurrentState = Failed to revoke the permissions from the current state for the user '{0}' in the database '{1}'. (SDP0005)
    FailedToSetPermission = Failed to set the desired permissions for the user '{0}' in the database '{1}'. (SDP0006)
    DuplicatePermissionState = One or more permission states was added more than once. It is only allowed to specify one of each permission state. (SDP0007)
    MissingPermissionState = One or more permission states was missing. One of each permission state must be provided. (SDP0008)
    MustAssignOnePermissionProperty = At least one of the properties 'Permission', 'PermissionToInclude', or 'PermissionToExclude' must be specified. (SDP0009)
    DuplicatePermissionBetweenState = One or more permission state specifies the same permission. It is only allowed to specify a specific permission in one permission state. (SDP0010)
    MustHaveMinimumOnePermissionInState = At least one state does not specify a permission in the property '{0}'. (SDP0011)
'@
