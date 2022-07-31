<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlPermission.
#>

ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class SqlDatabasePermission.
    EvaluateServerPermissionForPrincipal = Evaluate the current permissions for the principal '{0}' on the instance '{1}'. (SP0001)
    DesiredPermissionAreAbsent = The desired permission '{0}' that shall be present are absent. (SP0002)
    DesiredAbsentPermissionArePresent = The desired permission '{0}' that shall be absent are present. (SP0003)
    NameIsMissing = The name '{0}' is not a login on the instance '{1}'. (SP0004)
    FailedToRevokePermissionFromCurrentState = Failed to revoke the permissions from the current state for the user '{0}'. (SP0005)
    FailedToSetPermission = Failed to set the desired permissions for the user '{0}'. (SP0006)
    DuplicatePermissionState = One or more permission states was added more than once. It is only allowed to specify one of each permission state. (SP0007)
    MissingPermissionState = One or more permission states was missing. One of each permission state must be provided. (SP0008)
    MustAssignOnePermissionProperty = At least one of the properties 'Permission', 'PermissionToInclude', or 'PermissionToExclude' must be specified. (SP0009)
    DuplicatePermissionBetweenState = One or more permission state specifies the same permission. It is only allowed to specify a specific permission in one permission state. (SP0010)
    MustHaveMinimumOnePermissionInState = At least one state does not specify a permission in the property '{0}'. (SP0011)
'@
