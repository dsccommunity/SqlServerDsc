# Description

The `SqlDatabaseObjectPermission` DSC resource manage the permissions
of database objects in a database for a SQL Server instance.

For more information about permission names that can be managed, see the
property names of the [ObjectPermissionSet](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.objectpermissionset#properties) class.

>**Note:** When revoking permission with PermissionState 'GrantWithGrant', both the
>grantee and _all the other users the grantee has granted the same permission to_,
>will also get their permission revoked.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the
  SqlServer PowerShell module.

## Embedded instance DSC_DatabaseObjectPermission

* **`[String]` State** _(Key)_: Specifies the state of the permission.
  Valid values are 'Grant', 'Deny' and 'GrantWithGrant'.
* **`[String[]]` Permission** _(Required)_: Specifies the set of permissions
  for the database object for the principal assigned to 'Name'. Valid
  permission names can be found in the article [ObjectPermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.objectpermissionset#properties).
* **`[String]` Ensure** _(Key)_: Specifies the desired state of the permission.
  When set to 'Present', the permissions will be added. When set to 'Absent',
  the permissions will be removed. Default value is 'Present'.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabaseObjectPermission).
