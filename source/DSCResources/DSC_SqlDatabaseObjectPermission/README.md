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

### Only one permission per `DSC_DatabaseObjectPermission` instance

Each `DSC_DatabaseObjectPermission` instance can only contain a single permission
name. When multiple permissions need to be configured for the same state (e.g.,
`Grant`), each permission must be specified in a separate `DSC_DatabaseObjectPermission`
block. Specifying multiple permissions as a comma-separated string (e.g.,
`'DELETE,INSERT,SELECT'`) will cause an error similar to:

```text
The permission value 'DELETE,INSERT,SELECT' is invalid. Each
DSC_DatabaseObjectPermission instance can only contain a single permission
name. Specify each permission in a separate DSC_DatabaseObjectPermission
instance.
```

**Incorrect usage:**

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Permission = @(
    DSC_DatabaseObjectPermission {
        State      = 'Grant'
        Permission = 'DELETE,INSERT,SELECT' # This will fail - multiple permissions in single string
    }
)
```
<!-- markdownlint-enable MD013 - Line length -->

**Correct usage:**

```powershell
Permission = @(
    DSC_DatabaseObjectPermission {
        State      = 'Grant'
        Permission = 'DELETE'
    }
    DSC_DatabaseObjectPermission {
        State      = 'Grant'
        Permission = 'INSERT'
    }
    DSC_DatabaseObjectPermission {
        State      = 'Grant'
        Permission = 'SELECT'
    }
)
```

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabaseObjectPermission).
