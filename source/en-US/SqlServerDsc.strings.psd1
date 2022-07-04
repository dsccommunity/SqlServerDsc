<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DnsServerDsc module. This file should only contain
        localized strings for private and public functions.
#>

ConvertFrom-StringData @'
    # Get-SqlDscDatabasePermission
    DatabasePermission_MissingPrincipal = The database principal '{0}' is neither a user, database role (user-defined), or database application role in the database '{1}'.
    DatabasePermission_MissingDatabase = The database '{0}' cannot be found.

    # Test-SqlDscIsDatabasePrincipal
    IsDatabasePrincipal_DatabaseMissing = The database '{0}' cannot be found.
'@
