**Description**

This resource is used to configure the Server Roles of SQL Login (SqlLogin or Windows).
The Name parameter should contain the name of the SQL login, if LoginType is Windows, this is also 
the name of the user or group in format DOMAIN\name. The ServerRole parameter should contain the
type of SQL role to add (Ensure=Present) or remove (Ensure=Absent), like dbcreator or/and securityadmin.
The SQLServer parameter should contain the target SQL Server and the SQLInstanceName parameter should 
contain the target SQL Instance Name. This module depends on the SQL Server login already being added,
which can be done through the use of xSQLServerLogin.
