---
Category: How-to
---

# Change Report Server Service Account

This guide walks you through changing the service account for _Power BI Report
Server_ (PBIRS) or _SQL Server Reporting Services_ (SSRS) using _SqlServerDsc_
PowerShell commands. Changing the service account is a multi-step process that
requires careful handling of encryption keys, database permissions, and URL
reservations.

> [!NOTE]
> The examples in this guide use the instance name `'SSRS'` for _SQL Server
> Reporting Services_. If you are using _Power BI Report Server_ or have a
> custom instance name, substitute `'SSRS'` with your instance name (e.g.,
> `'PBIRS'` or your custom name).

## Why Is This Process Complex?

When you change the Report Server service account, three interconnected systems
are affected:

1. **Encryption Keys** — Report Server uses a symmetric encryption key to protect
   sensitive data stored in the database (such as stored credentials for data
   sources and connection strings). This key is tied to the service account's
   Windows security context. The new account cannot decrypt data encrypted by
   the old account.

2. **Database Permissions** — The Report Server databases (`ReportServer` and
   `ReportServerTempDB`) grant permissions to the service account. The new
   account has no access until you explicitly grant it.

3. **URL Reservations** — URL reservations in HTTP.sys are registered with the
   service account's Security Identifier (SID). After changing accounts, the
   old reservations reference a SID that no longer matches the running service.

Failing to address any of these will leave your Report Server in a broken state.

## Prerequisites

Before starting, ensure you have:

- **SqlServerDsc module installed** — Install from PowerShell Gallery:

  <!-- markdownlint-disable MD013 -->
  ```powershell
  Install-PSResource -Name 'SqlServerDsc' -Scope 'AllUsers' -TrustRepository
  ```
  <!-- markdownlint-enable MD013 -->

- **An existing, initialized Report Server instance** — The instance must be
  fully configured with database connection established and the server initialized.

- **The new service account created** — The Windows or Active Directory account
  must exist before you begin. For domain accounts, use the format `DOMAIN\Username`.

- **SQL Server access** — You need permissions to create logins and execute
  scripts on the SQL Server instance hosting the Report Server databases.

- **Administrator privileges** — Run PowerShell as Administrator on the Report
  Server machine.

## The Complete Workflow

The service account change process consists of eight steps that must be executed
in order:

| Step | Action | Command |
|------|--------|---------|
| 1 | Change the service account | `Set-SqlDscRSServiceAccount` |
| 2 | Verify the change | `Get-SqlDscRSServiceAccount` |
| 3 | Grant database permissions | `New-SqlDscLogin`, `Request-SqlDscRSDatabaseRightsScript`, `Invoke-SqlDscQuery` |
| 4 | Remove the old encryption key | `Remove-SqlDscRSEncryptionKey` |
| 5 | Create a new encryption key | `New-SqlDscRSEncryptionKey` |
| 6 | Recreate URL reservations | `Set-SqlDscRSUrlReservation -RecreateExisting` |
| 7 | Re-initialize the Report Server | `Initialize-SqlDscRS` |
| 8 | Validate accessibility | `Test-SqlDscRSAccessible` |

## Step 1: Change the Service Account

First, obtain the Report Server configuration and change the service account
using `Set-SqlDscRSServiceAccount`.

<!-- markdownlint-disable MD013 -->
```powershell
# Get the Report Server configuration
$configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

# Prepare the new service account credentials
$newCredential = Get-Credential -Message 'Enter the new service account credentials (DOMAIN\Username)'

# Change the service account
$configuration | Set-SqlDscRSServiceAccount `
    -Credential $newCredential `
    -RestartService `
    -SuppressUrlReservationWarning `
    -Force
```
<!-- markdownlint-enable MD013 -->

**Parameters explained:**

- `-Credential` — A `PSCredential` object containing the new service account
  username and password.
- `-RestartService` — Automatically restarts the Report Server service after
  the change.
- `-SuppressUrlReservationWarning` — Suppresses the warning about URL reservations
  needing to be updated (we handle this in Step 6).
- `-Force` — Skips confirmation prompts for automation scenarios.

**What happens internally:**

This command calls the WMI method `SetWindowsServiceIdentity`, which:

- Updates the Windows service to run under the new account
- Sets appropriate file permissions on the Report Server installation directory
- Grants the `LogonAsService` right to the new account

> [!IMPORTANT]
> After this step, the new account does NOT yet have database access, and the
> encryption key is still tied to the old account. The Report Server will not
> function correctly until all remaining steps are completed.

## Step 2: Verify the Service Account Change

Confirm that the service account was changed successfully:

<!-- markdownlint-disable MD013 -->
```powershell
# Refresh the configuration object
$configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

# Get the current service account
$currentServiceAccount = $configuration | Get-SqlDscRSServiceAccount

Write-Information -MessageData "Service account is now: $currentServiceAccount" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

The returned value should match the username you specified in Step 1.

## Step 3: Grant Database Permissions

The new service account needs permissions to access the Report Server databases.
This involves three sub-steps.

### 3a. Create a SQL Server Login for the New Account

Connect to the SQL Server instance hosting the Report Server databases and create
a login for the new service account:

<!-- markdownlint-disable MD013 -->
```powershell
# Connect to the SQL Server hosting the RS databases
$serverObject = Connect-SqlDscDatabaseEngine -ServerName 'localhost' -InstanceName 'RSDB'

# Create a Windows login for the new service account
New-SqlDscLogin -ServerObject $serverObject -Name $currentServiceAccount -WindowsUser -Force

# Disconnect from the server
Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject
```
<!-- markdownlint-enable MD013 -->

> [!NOTE]
> Replace `'localhost'` and `'RSDB'` with your actual SQL Server name and instance
> name. If using the default instance, omit `-InstanceName` or use `'MSSQLSERVER'`.

### 3b. Generate and Execute the Database Rights Script

Request the database rights script from Report Server and execute it:

<!-- markdownlint-disable MD013 -->
```powershell
# Get the database name from the configuration
$databaseName = $configuration.DatabaseName

# Generate the T-SQL script that grants required permissions
$databaseRightsScript = $configuration | Request-SqlDscRSDatabaseRightsScript `
    -DatabaseName $databaseName `
    -UserName $currentServiceAccount

# Execute the script on the SQL Server
Invoke-SqlDscQuery `
    -ServerName 'localhost' `
    -InstanceName 'RSDB' `
    -DatabaseName 'master' `
    -Query $databaseRightsScript `
    -Force
```
<!-- markdownlint-enable MD013 -->

> [!NOTE]
> For more details on the `-UserName` parameter and the permissions granted,
> see [GenerateDatabaseRightsScript Method](https://learn.microsoft.com/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-generatedatabaserightsscript).

### 3c. Restart the Report Server Service

Restart the service to apply the new database permissions:

```powershell
$configuration | Restart-SqlDscRSService -Force
```

After this step, the Report Server can connect to its databases using the new
service account.

## Step 4: Remove the Old Encryption Key

> [!WARNING]
> This is a destructive operation. Once you remove the encryption key, the old
> key cannot be recovered. Any data encrypted with the old key (stored credentials,
> connection strings) will be inaccessible until a new key is generated.

Remove the existing encryption key that was tied to the old service account:

```powershell
$configuration | Remove-SqlDscRSEncryptionKey -Force
```

This command calls the WMI method `DeleteEncryptionKey`, which removes the
symmetric encryption key from the Report Server.

**What this affects:**

- Stored credentials for data sources
- Connection strings with embedded credentials
- Subscription delivery settings with credentials

After removing the key, the Report Server cannot decrypt any previously encrypted
data. You must proceed to Step 5 immediately.

## Step 5: Create a New Encryption Key

Generate a new encryption key tied to the new service account:

```powershell
$configuration | New-SqlDscRSEncryptionKey -Force
```

This command calls the WMI method `ReencryptSecureInformation`, which:

- Creates a new symmetric encryption key
- Associates the key with the new service account's security context
- Re-encrypts all stored secure information using the new key

After this step, the Report Server can again encrypt and decrypt sensitive data.

> [!TIP]
> After completing the entire service account change process, back up the new
> encryption key using `Backup-SqlDscRSEncryptionKey`. This backup is critical
> for disaster recovery scenarios.

## Step 6: Recreate URL Reservations

URL reservations in HTTP.sys are registered with the service account's Security
Identifier (SID). After changing accounts, you must recreate all URL reservations
to register them with the new account's SID:

<!-- markdownlint-disable MD013 -->
```powershell
# Recreate all existing URL reservations
$configuration | Set-SqlDscRSUrlReservation -RecreateExisting -Force

# Restart the service to apply URL reservation changes
$configuration | Restart-SqlDscRSService -Force
```
<!-- markdownlint-enable MD013 -->

The `-RecreateExisting` parameter instructs the command to:

1. Retrieve all current URL reservations
1. Remove each reservation from HTTP.sys
1. Re-add each reservation (now registered to the new account's SID)

This ensures the Report Server service can bind to its configured URLs.

## Step 7: Re-Initialize the Report Server

Re-initialize the Report Server to validate all configuration settings and ensure
the server is ready to handle requests:

```powershell
# Re-initialize the instance
$configuration | Initialize-SqlDscRS -Force

# Restart the service
$configuration | Restart-SqlDscRSService -Force
```

This calls the WMI method `InitializeReportServer`, which performs internal
validation and prepares the server for operation.

## Step 8: Validate Accessibility

Finally, verify that the Report Server is fully operational:

<!-- markdownlint-disable MD013 -->
```powershell
# Refresh the configuration
$configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

# Verify the service account
$finalServiceAccount = $configuration | Get-SqlDscRSServiceAccount
Write-Information -MessageData "Service account: $finalServiceAccount" -InformationAction 'Continue'

# Verify initialization status
$isInitialized = $configuration | Test-SqlDscRSInitialized
Write-Information -MessageData "Is initialized: $isInitialized" -InformationAction 'Continue'

# Verify URL reservations exist
$urlReservations = $configuration | Get-SqlDscRSUrlReservation
Write-Information -MessageData "URL reservations configured: $($urlReservations.Count)" -InformationAction 'Continue'

# Test HTTP accessibility to all configured sites
$configuration | Test-SqlDscRSAccessible -Detailed -TimeoutSeconds 240 -RetryIntervalSeconds 10
```
<!-- markdownlint-enable MD013 -->

The `Test-SqlDscRSAccessible` command tests HTTP connectivity to all configured
Report Server URLs and returns the accessibility status. The `-Detailed` parameter
provides verbose output about each URL tested.

## Complete Script

Here is the complete script combining all steps. Copy and customize for your
environment:

<!-- markdownlint-disable MD013 -->
```powershell
#Requires -Modules SqlServerDsc
#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURATION - Customize these values for your environment
# ============================================================================

$instanceName = 'SSRS'                    # Report Server instance name
$dbServerName = 'localhost'               # SQL Server hosting RS databases
$dbInstanceName = 'RSDB'                  # SQL instance name (or 'MSSQLSERVER' for default)

# ============================================================================
# STEP 0: Get credentials and current configuration
# ============================================================================

$newCredential = Get-Credential -Message 'Enter the new service account credentials (DOMAIN\Username)'
$configuration = Get-SqlDscRSConfiguration -InstanceName $instanceName

Write-Information -MessageData "Current service account: $($configuration.WindowsServiceIdentityActual)" -InformationAction 'Continue'

# ============================================================================
# STEP 1: Change the service account
# ============================================================================

Write-Information -MessageData "`n[Step 1] Changing service account..." -InformationAction 'Continue'

$configuration | Set-SqlDscRSServiceAccount `
    -Credential $newCredential `
    -RestartService `
    -SuppressUrlReservationWarning `
    -Force

# ============================================================================
# STEP 2: Verify the change
# ============================================================================

Write-Information -MessageData "`n[Step 2] Verifying service account change..." -InformationAction 'Continue'

$configuration = Get-SqlDscRSConfiguration -InstanceName $instanceName
$currentServiceAccount = $configuration | Get-SqlDscRSServiceAccount

Write-Information -MessageData "Service account is now: $currentServiceAccount" -InformationAction 'Continue'

# ============================================================================
# STEP 3: Grant database permissions
# ============================================================================

Write-Information -MessageData "`n[Step 3] Granting database permissions..." -InformationAction 'Continue'

# Create SQL login
$serverObject = Connect-SqlDscDatabaseEngine -ServerName $dbServerName -InstanceName $dbInstanceName
New-SqlDscLogin -ServerObject $serverObject -Name $currentServiceAccount -WindowsUser -Force
Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject

# Generate and execute database rights script
$databaseName = $configuration.DatabaseName
$databaseRightsScript = $configuration | Request-SqlDscRSDatabaseRightsScript `
    -DatabaseName $databaseName `
    -UserName $currentServiceAccount

Invoke-SqlDscQuery `
    -ServerName $dbServerName `
    -InstanceName $dbInstanceName `
    -DatabaseName 'master' `
    -Query $databaseRightsScript `
    -Force

# Restart service to apply permissions
$configuration | Restart-SqlDscRSService -Force

Write-Information -MessageData "Database permissions granted" -InformationAction 'Continue'

# ============================================================================
# STEP 4: Remove old encryption key
# ============================================================================

Write-Information -MessageData "`n[Step 4] Removing old encryption key..." -InformationAction 'Continue'

$configuration | Remove-SqlDscRSEncryptionKey -Force

Write-Information -MessageData "Old encryption key removed" -InformationAction 'Continue'

# ============================================================================
# STEP 5: Create new encryption key
# ============================================================================

Write-Information -MessageData "`n[Step 5] Creating new encryption key..." -InformationAction 'Continue'

$configuration | New-SqlDscRSEncryptionKey -Force

Write-Information -MessageData "New encryption key created" -InformationAction 'Continue'

# ============================================================================
# STEP 6: Recreate URL reservations
# ============================================================================

Write-Information -MessageData "`n[Step 6] Recreating URL reservations..." -InformationAction 'Continue'

$configuration | Set-SqlDscRSUrlReservation -RecreateExisting -Force
$configuration | Restart-SqlDscRSService -Force

Write-Information -MessageData "URL reservations recreated" -InformationAction 'Continue'

# ============================================================================
# STEP 7: Re-initialize Report Server
# ============================================================================

Write-Information -MessageData "`n[Step 7] Re-initializing Report Server..." -InformationAction 'Continue'

$configuration | Initialize-SqlDscRS -Force
$configuration | Restart-SqlDscRSService -Force

Write-Information -MessageData "Report Server re-initialized" -InformationAction 'Continue'

# ============================================================================
# STEP 8: Validate accessibility
# ============================================================================

Write-Information -MessageData "`n[Step 8] Validating accessibility..." -InformationAction 'Continue'

$configuration = Get-SqlDscRSConfiguration -InstanceName $instanceName

$finalServiceAccount = $configuration | Get-SqlDscRSServiceAccount
$isInitialized = $configuration | Test-SqlDscRSInitialized
$urlReservations = $configuration | Get-SqlDscRSUrlReservation

Write-Information -MessageData "`nFinal Status:" -InformationAction 'Continue'
Write-Information -MessageData "  Service Account: $finalServiceAccount" -InformationAction 'Continue'
Write-Information -MessageData "  Is Initialized: $isInitialized" -InformationAction 'Continue'
Write-Information -MessageData "  URL Reservations: $($urlReservations.Count)" -InformationAction 'Continue'

Write-Information -MessageData "`nTesting HTTP accessibility..." -InformationAction 'Continue'
$configuration | Test-SqlDscRSAccessible -Detailed -TimeoutSeconds 240 -RetryIntervalSeconds 10

Write-Information -MessageData "`n[Complete] Service account change finished successfully!" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

## Important Considerations

### Plan for Downtime

The Report Server will be unavailable during this process. Plan to perform this
change during a maintenance window when users do not need access to reports.

### SQL Server 2017 Limitation

On SQL Server 2017 Reporting Services, the encryption key operations (Steps 4-5)
may fail with the error:

```text
The report server was unable to validate the integrity of encrypted data in the
database. (rsCannotValidateEncryptedData); Keyset does not exist
(Exception from HRESULT: 0x80090016)
```

This is a known limitation. The required steps to resolve this issue are unknown
at this time. If you encounter this error, you may need to use the Report Server
Configuration Manager to complete the encryption key steps manually.

### Test in Non-Production First

Always test this procedure in a non-production environment before applying it
to production servers. Verify that reports, subscriptions, and data sources
function correctly after the change.

### Document Your Configuration

Before making changes, document your current configuration including:

- Current service account
- Database server and instance names
- URL reservations
- Any custom SSL certificate bindings

This information is invaluable for troubleshooting if issues arise.

## Summary

Changing the service account for SQL Server Reporting Services or Power BI Report
Server requires a methodical approach that addresses encryption keys, database
permissions, and URL reservations. By following this eight-step process using
SqlServerDsc commands, you can automate this change reliably and consistently
across your Report Server infrastructure.

The key takeaways are:

1. The process must be performed in order — each step depends on the previous
1. Encryption key removal is destructive — there is no undo
1. Always validate accessibility after completing all steps
1. Plan for service downtime during the change
