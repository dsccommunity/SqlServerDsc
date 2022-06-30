<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsServerDsc module. This file should only contain
        localized strings for private and public functions.
#>

ConvertFrom-StringData @'
    # Get-SqlDscDatabasePermission
    DatabasePermissionMissingPrincipal = The database principal '{0}' is neither a user, database role (user-defined), or database application role in the database '{1}'. (GETSDP0001).
    DatabasePermissionMissingDatabase = The database '{0}' did not exist. (GETSDP0002)
'@
