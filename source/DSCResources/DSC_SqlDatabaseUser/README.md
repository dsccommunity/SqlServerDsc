# Description

The `SqlDatabaseUser` DSC resource is used to create database users.
A database user can be created with or without a login, and a database
user can be mapped to a certificate or asymmetric key. The resource also
allows re-mapping of the SQL login. If the targeted database is not updatable,
the resource returns true.

> [!NOTE]
> This resource does not yet support [Contained Databases](https://docs.microsoft.com/en-us/sql/relational-databases/databases/contained-databases).

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabaseUser).
