# Description

The `SqlDatabaseObjectPermission` DSC resource manage the permissions
of database objects in a database for a SQL Server instance.

For more information about permission names that can be managed, see the
property names of the [ObjectPermissionSet](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.objectpermissionset#properties) class.

> [!CAUTION]
> When revoking permission with PermissionState 'GrantWithGrant', both the
> grantee and _all the other users the grantee has granted the same permission to_,
> will also get their permission revoked.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the
  SqlServer PowerShell module.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabaseObjectPermission).
