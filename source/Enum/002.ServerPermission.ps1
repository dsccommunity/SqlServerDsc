<#
    .SYNOPSIS
        The possible server permissions that can be granted, denied, or revoked.

    .NOTES
        The available permissions can be seen in the ServerPermission Class documentation:
        https://learn.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.serverpermission
#>
enum SqlServerPermission
{
    # cSpell:ignore securables
    AdministerBulkOperations = 1
    AlterAnyAvailabilityGroup
    AlterAnyConnection
    AlterAnyCredential
    AlterAnyDatabase
    AlterAnyEndpoint
    AlterAnyEventNotification
    AlterAnyEventSession
    AlterAnyEventSessionAddEvent
    AlterAnyEventSessionAddTarget
    AlterAnyEventSessionDisable
    AlterAnyEventSessionDropEvent
    AlterAnyEventSessionDropTarget
    AlterAnyEventSessionEnable
    AlterAnyEventSessionOption
    AlterAnyLinkedServer
    AlterAnyLogin
    AlterAnyServerAudit
    AlterAnyServerRole
    AlterResources
    AlterServerState
    AlterSettings
    AlterTrace
    AuthenticateServer
    ConnectAnyDatabase
    ConnectSql
    ControlServer
    CreateAnyDatabase
    CreateAnyEventSession
    CreateAvailabilityGroup
    CreateDdlEventNotification
    CreateEndpoint
    CreateLogin
    CreateServerRole
    CreateTraceEventNotification
    DropAnyEventSession
    ExternalAccessAssembly
    ImpersonateAnyLogin
    SelectAllUserSecurables
    Shutdown
    UnsafeAssembly
    ViewAnyCryptographicallySecuredDefinition
    ViewAnyDatabase
    ViewAnyDefinition
    ViewAnyErrorLog
    ViewAnyPerformanceDefinition
    ViewAnySecurityDefinition
    ViewServerPerformanceState
    ViewServerSecurityAudit
    ViewServerSecurityState
    ViewServerState
}
