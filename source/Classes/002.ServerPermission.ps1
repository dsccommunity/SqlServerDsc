<#
    .SYNOPSIS
        The possible server permission states.

    .PARAMETER State
        The state of the permission.

    .PARAMETER Permission
        The permissions to be granted or denied for the user in the database.

    .NOTES
        The DSC properties specifies the attribute Mandatory but State was meant
        to be attribute Key, but those attributes are not honored correctly during
        compilation in the current implementation of PowerShell DSC. If the
        attribute would have been left as Key then it would not have been possible
        to add an identical instance of ServerPermission in two separate DSC
        resource instances in a DSC configuration. The Key property only works
        on the top level DSC properties. E.g. two resources instances of
        SqlPermission in a DSC configuration trying to grant the database
        permission 'AlterAnyDatabase' in two separate databases would have failed compilation
        as a the property State would have been seen as "duplicate resource".

        Since it is not possible to use the attribute Key the State property is
        evaluate during runtime so that no two states are enforcing the same
        permission.

        The method Equals() returns $false if type is not the same on both sides
        of the comparison. There was a thought to throw an exception if the object
        being compared was of another type, but since there was issues with using
        for example [ServerPermission[]], it was left out. This can be the correct
        way since if moving for example [ServerPermission[]] to the left side and
        the for example [ServerPermission] to the right side, then the left side
        array is filtered with the matching values on the right side. This is the
        normal behavior for other types.

    .EXAMPLE
        [ServerPermission] @{}

        Initializes a new instance of the ServerPermission class without any
        property values.

    .EXAMPLE
        [ServerPermission] @{ State = 'Grant'; Permission = @('ConnectSql', 'ViewServerState') }

        Initializes a new instance of the ServerPermission class with property
        values.
#>
class ServerPermission : PermissionBase
{
    [DscProperty(Mandatory)]
    [ValidateSet('Grant', 'GrantWithGrant', 'Deny')]
    [System.String]
    $State

    [DscProperty(Mandatory)]
    [AllowEmptyCollection()]
    [ValidateSet(
        'AdministerBulkOperations',
        'AlterAnyServerAudit',
        'AlterAnyCredential',
        'AlterAnyConnection',
        'AlterAnyDatabase',
        'AlterAnyEventNotification',
        'AlterAnyEndpoint',
        'AlterAnyLogin',
        'AlterAnyLinkedServer',
        'AlterResources',
        'AlterServerState',
        'AlterSettings',
        'AlterTrace',
        'AuthenticateServer',
        'ControlServer',
        'ConnectSql',
        'CreateAnyDatabase',
        'CreateDdlEventNotification',
        'CreateEndpoint',
        'CreateTraceEventNotification',
        'Shutdown',
        'ViewAnyDefinition',
        'ViewAnyDatabase',
        'ViewServerState',
        'ExternalAccessAssembly',
        'UnsafeAssembly',
        'AlterAnyServerRole',
        'CreateServerRole',
        'AlterAnyAvailabilityGroup',
        'CreateAvailabilityGroup',
        'AlterAnyEventSession',
        'SelectAllUserSecurables',
        'ConnectAnyDatabase',
        'ImpersonateAnyLogin'
    )]
    [System.String[]]
    $Permission

    ServerPermission ()
    {
    }
}
