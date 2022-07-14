<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsServerDsc module. This file should only contain
        localized strings for private and public functions.
#>

ConvertFrom-StringData @'
    # Get-SqlDscDatabasePermission, Set-SqlDscDatabasePermission
    DatabasePermission_MissingPrincipal = The database principal '{0}' is neither a user, database role (user-defined), or database application role in the database '{1}'.
    DatabasePermission_MissingDatabase = The database '{0}' cannot be found.

    # Set-SqlDscDatabasePermission
    DatabasePermission_ChangePermissionForUser = Changing the permission for the principal '{0}' in the database '{1}' on the instance '{2}'.
    DatabasePermission_GrantPermission = Grant the permissions '{0}' for the principal '{1}'.
    DatabasePermission_DenyPermission = Deny the permissions '{0}' for the principal '{1}'.
    DatabasePermission_RevokePermission = Revoke the permissions '{0}' for the principal '{1}'.

    # Test-SqlDscIsDatabasePrincipal
    IsDatabasePrincipal_DatabaseMissing = The database '{0}' cannot be found.
'@
