---
Category: Usage
---

# Credential overview

## Group Managed Service Account

To support [Group Managed Service Accounts](https://docs.microsoft.com/en-us/windows-server/security/group-managed-service-accounts/group-managed-service-accounts-overview)
(gMSAs) the DSC resource must support it. This also applies to Managed Service
Accounts (MSAs).

There are more information about using (g)MSAs with SQL Server
in the article [Configure Windows Service Accounts and Permissions](https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-windows-service-accounts-and-permissions) in section [Managed Service Accounts, Group Managed Service Accounts, and Virtual Accounts](https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-windows-service-accounts-and-permissions#New_Accounts)

To use a (g)MSA with a DSC resource you should pass the (g)MSA account name
in the credential object and use any text string as password.

>It is not possible to pass `$null` as password, it is a limitation by
>how the MOF is generated when encrypting passwords.

If there is a resource that you find that will not work with a (g)MSAs then
please submit a [new issue](https://github.com/dsccommunity/SqlServerDsc/issues/new?template=Problem_with_resource.md).
Then the community can work together to support (g)MSAs for that DSC resource
too.

For designing a resource for (g)MSAs see the section [Group Managed Service Account](https://github.com/dsccommunity/SqlServerDsc/blob/main/CONTRIBUTING.md#group-managed-service-account)
in the contribution guidelines.

<sup>_This was discussed in [issue #738](https://github.com/dsccommunity/SqlServerDsc/issues/738)_.</sup>

## Built-In Account

To use a built-in account with a DSC resource you should pass the built-in
account name, e.g. 'NT AUTHORITY\NetworkService' in the credential object
and use any text string as password.

>It is not possible to pass `$null` as password, it is a limitation by
>how the MOF is generated when encrypting passwords.

If there is a resource that you find that will not work with a built-in account
then please submit a [new issue](https://github.com/dsccommunity/SqlServerDsc/issues/new?template=Problem_with_resource.md).
Then the community can work together to support built-in accounts for that
DSC resource too.

## Windows User Credentials

When using Windows user credentials (i.e., `LoginType = 'WindowsUser'`) with
SqlServerDsc resources, there are important considerations regarding the
username format and how it is extracted from the `PSCredential` object.

### Username Property vs GetNetworkCredential()

The `PSCredential` object has two ways to access the username:

| Property | Behavior |
|----------|----------|
| `$Credential.UserName` | Returns the **full username as provided**, including domain prefix (NetBIOS or FQDN). |
| `$Credential.GetNetworkCredential().UserName` | Returns **only the username portion**, stripping the domain prefix when using NetBIOS format (`DOMAIN\user` → `user`). |

**Always use `$Credential.UserName`** when passing the username to SMO connection
contexts (e.g., `ConnectAsUserName`). This preserves the domain format exactly
as the user entered it.

### Supported Username Formats

| Format | Example | Works with SQLPS (SQL 2016) | Works with SqlServer module |
|--------|---------|-----------------------------|----------------------------|
| **FQDN (UPN)** | `user@domain.local` | ✅ Yes | ✅ Yes |
| **Username only** | `user` | ✅ Yes | ✅ Yes |
| **NetBIOS** | `DOMAIN\user` | ❌ **No** | ✅ Yes |

> **Important**: The NetBIOS format (`DOMAIN\user`) **does not work** with the
> legacy SQLPS module (SQL Server 2016 and earlier). When using SQLPS,
> you must use either FQDN format (`user@domain.local`) or just the username
> without domain prefix.

This limitation was identified in [issue #1223](https://github.com/dsccommunity/SqlServerDsc/issues/1223)
where `GetNetworkCredential().UserName` was being used internally, causing
NetBIOS domain names to be stripped and authentication to fail on SQL Server 2016.

### Recommendations

1. **Prefer FQDN format** (`user@domain.local`) for maximum compatibility across
   all SQL Server versions and PowerShell modules.
2. **Avoid NetBIOS format** (`DOMAIN\user`) when targeting SQL Server 2016 or
   environments where SQLPS may be used.
3. **Use `$Credential.UserName`** (not `GetNetworkCredential().UserName`) in
   any custom code that passes credentials to SMO connection contexts.

### Example: Creating a Windows User Credential

```powershell
# FQDN format (recommended - works everywhere)
$password = ConvertTo-SecureString 'P@ssw0rd1' -AsPlainText -Force
$username = 'user@company.local'
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

# Username only (works everywhere)
$username = 'user'
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

# NetBIOS format (AVOID for SQL 2016 / SQLPS)
$username = 'COMPANY\user'
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password
```

When using these credentials with SqlServerDsc resources, pass them via the
built-in `PsDscRunAsCredential` parameter:

```powershell
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlLogin 'Add_WindowsUser'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\WindowsUser'
            LoginType            = 'WindowsUser'
            ServerName           = 'TestServer.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
```

<sup>_This section was informed by [issue #1223](https://github.com/dsccommunity/SqlServerDsc/issues/1223)
and [issue #1768](https://github.com/dsccommunity/SqlServerDsc/issues/1768)._</sup>
