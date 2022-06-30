<#
    .SYNOPSIS
        The possible database permission states.

    .PARAMETER State
        The state of the permission.

    .PARAMETER Permission
        The permissions to be granted or denied for the user in the database.

    .NOTES
        The parameter State cannot use the enum [Microsoft.SqlServer.Management.Smo.PermissionState]
        because we cannot know what assembly to use prior to loading the SqlServerDsc.
        A user can either choose SqlServer och SQLPS. When we can move to only SqlServer
        then the the module SqlServer can me loaded in the SqlServerDsc's module
        manifest and then we could possible use the type [Microsoft.SqlServer.Management.Smo.PermissionState]
        directly. Then the parameter Permission could also be of the type
        [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet].
#>
class DatabasePermission
{
    [DscProperty(Key)]
    [DatabasePermissionState]
    $State

    # TODO: Can we use a validate set for the permissions?
    [DscProperty(Mandatory)]
    [System.String[]]
    $Permission
}
