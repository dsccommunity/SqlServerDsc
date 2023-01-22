# Description

The `SqlRS` DSC resource initializes and configures SQL Reporting Services
server.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Reporting Services 20012 or later.
* To use parameter `UseSSL` target machine must be running SQL Server Reporting
  Services 2012 or later.
* If `PsDscRunAsCredential` common parameter is used to run the resource, the
  specified credential must have permissions to connect to the SQL Server instance
  specified in `DatabaseServerName` and `DatabaseInstanceName`, and have permission
  to create the Reporting Services databases.
* Parameter `Encrypt` controls whether the connection used by `Invoke-SqlCmd`
  should enforce encryption. This parameter can only be used together with the
  module _SqlServer_ v22.x (minimum v22.0.49-preview). The parameter will be
  ignored if an older major versions of the module _SqlServer_ is used.
  Encryption is mandatory by default, which generates the following exception
  when the correct certificates are not present:

  ```plaintext
  A connection was successfully established with the server, but then
  an error occurred during the login process. (provider: SSL Provider,
  error: 0 - The certificate chain was issued by an authority that is
  not trusted.)
  ```

  For more details, see the article [Connect to SQL Server with strict encryption](https://learn.microsoft.com/en-us/sql/relational-databases/security/networking/connect-with-strict-encryption?view=sql-server-ver16)
  and [Configure SQL Server Database Engine for encrypting connections](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption?view=sql-server-ver16).

## Known issues

* This resource does not currently have full SSL support, please see
  [issue #587](https://github.com/dsccommunity/SqlServerDsc/issues/587) for more
  information.

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlRS).

## Known error messages

### Error: `The parameter is incorrect (HRESULT:-2147024809)`

This is caused by trying to add an URL with the wrong format
i.e. 'htp://+:80'.

### Error: `The Url has already been reserved (HRESULT:-2147220932)`

This is caused when the URL is already reserved. For example when 'http://+:80'
already exist.

### Error: `Cannot create a file when that file already exists (HRESULT:-2147024713)`

This is caused when trying to add another URL using the same protocol. For example
when trying to add 'http://+:443' when 'http://+:80' already exist.

### Error: `A connection was successfully established with the server, but then an error occurred during the login process`

This is cause by encryption certificates are not correctly configured. Configure
the certificates so that encryption works, or turn off the need of encryption
by setting `Encrypt` to `Optional` (not recommended).
