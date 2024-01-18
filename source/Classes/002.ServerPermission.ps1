<#
    .SYNOPSIS
        The possible server permission states.

    .PARAMETER Permission
        The permissions to be granted or denied for the user in the database.

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
