<#
    .PARAMETER State
        The state of the permission.

    .PARAMETER Permission
        The permissions to be granted or denied for the user in the database.
#>

class DatabasePermission
{
    [DscProperty(Key)]
    [DatabasePermissionState]
    $State

    [DscProperty(Mandatory)]
    [System.String]
    $Permission
}
