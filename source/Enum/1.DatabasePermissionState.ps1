<#
    .SYNOPSIS
        The possible database permission states.

    .NOTES
        This is the permission states from the enum [Microsoft.SqlServer.Management.Smo.PermissionState]
        except for the 'Revoke' which is handled by a resource is using 'Absent' for
        the parameter Ensure.
#>

enum DatabasePermissionState
{
    Grant
    Deny
    GrantWithGrant
}
