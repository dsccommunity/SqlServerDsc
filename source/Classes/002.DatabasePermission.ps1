<#
    .SYNOPSIS
        The possible database permission states.

    .PARAMETER Permission
        The permissions to be granted or denied for the user in the database.

    .EXAMPLE
        [DatabasePermission] @{}

        Initializes a new instance of the DatabasePermission class without any
        property values.

    .EXAMPLE
        [DatabasePermission] @{ State = 'Grant'; Permission = @('Connect', 'Select') }

        Initializes a new instance of the DatabasePermission class with property
        values.

#>
class DatabasePermission : PermissionBase
{
    [DscProperty(Mandatory)]
    [AllowEmptyCollection()]
    [ValidateSet(
        'AdministerDatabaseBulkOperations',
        'Alter',
        'AlterAnyApplicationRole',
        'AlterAnyAssembly',
        'AlterAnyAsymmetricKey',
        'AlterAnyCertificate',
        'AlterAnyColumnEncryptionKey',
        'AlterAnyColumnMasterKey',
        'AlterAnyContract',
        'AlterAnyDatabaseAudit',
        'AlterAnyDatabaseDdlTrigger',
        'AlterAnyDatabaseEventNotification',
        'AlterAnyDatabaseEventSession',
        'AlterAnyDatabaseEventSessionAddEvent',
        'AlterAnyDatabaseEventSessionAddTarget',
        'AlterAnyDatabaseEventSessionDisable',
        'AlterAnyDatabaseEventSessionDropEvent',
        'AlterAnyDatabaseEventSessionDropTarget',
        'AlterAnyDatabaseEventSessionEnable',
        'AlterAnyDatabaseEventSessionOption',
        'AlterAnyDatabaseScopedConfiguration',
        'AlterAnyDataspace',
        'AlterAnyExternalDataSource',
        'AlterAnyExternalFileFormat',
        'AlterAnyExternalJob',
        'AlterAnyExternalLanguage',
        'AlterAnyExternalLibrary',
        'AlterAnyExternalStream',
        'AlterAnyFulltextCatalog',
        'AlterAnyMask',
        'AlterAnyMessageType',
        'AlterAnyRemoteServiceBinding',
        'AlterAnyRole',
        'AlterAnyRoute',
        'AlterAnySchema',
        'AlterAnySecurityPolicy',
        'AlterAnySensitivityClassification',
        'AlterAnyService',
        'AlterAnySymmetricKey',
        'AlterAnyUser',
        'AlterLedger',
        'AlterLedgerConfiguration',
        'Authenticate',
        'BackupDatabase',
        'BackupLog',
        'Checkpoint',
        'Connect',
        'ConnectReplication',
        'Control',
        'CreateAggregate',
        'CreateAnyDatabaseEventSession',
        'CreateAssembly',
        'CreateAsymmetricKey',
        'CreateCertificate',
        'CreateContract',
        'CreateDatabase',
        'CreateDatabaseDdlEventNotification',
        'CreateDefault',
        'CreateExternalLanguage',
        'CreateExternalLibrary',
        'CreateFulltextCatalog',
        'CreateFunction',
        'CreateMessageType',
        'CreateProcedure',
        'CreateQueue',
        'CreateRemoteServiceBinding',
        'CreateRole',
        'CreateRoute',
        'CreateRule',
        'CreateSchema',
        'CreateService',
        'CreateSymmetricKey',
        'CreateSynonym',
        'CreateTable',
        'CreateType',
        'CreateUser',
        'CreateView',
        'CreateXmlSchemaCollection',
        'Delete',
        'DropAnyDatabaseEventSession',
        'EnableLedger',
        'Execute',
        'ExecuteAnyExternalEndpoint',
        'ExecuteAnyExternalScript',
        'Insert',
        'KillDatabaseConnection',
        'OwnershipChaining',
        'References',
        'Select',
        'Showplan',
        'SubscribeQueryNotifications',
        'TakeOwnership',
        'Unmask',
        'Update',
        'ViewAnyColumnEncryptionKeyDefinition',
        'ViewAnyColumnMasterKeyDefinition',
        'ViewAnySensitivityClassification',
        'ViewCryptographicallySecuredDefinition',
        'ViewDatabasePerformanceState',
        'ViewDatabaseSecurityAudit',
        'ViewDatabaseSecurityState',
        'ViewDatabaseState',
        'ViewDefinition',
        'ViewLedgerContent',
        'ViewPerformanceDefinition',
        'ViewSecurityDefinition'
    )]
    [System.String[]]
    $Permission

    DatabasePermission ()
    {
    }
}
