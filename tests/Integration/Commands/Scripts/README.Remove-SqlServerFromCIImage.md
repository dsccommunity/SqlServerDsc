# Remove-SqlServerFromCIImage.ps1

## Overview

This script removes all pre-installed SQL Server components from Microsoft
Hosted CI agents that may conflict with SQL Server Sysprep/PrepareImage
operations.

## Problem Statement

Microsoft Hosted agents (both `windows-2022` and `windows-2025` images) come
with pre-installed SQL Server components such as:

- SQL Server LocalDB
- SQL Server Client Tools
- SQL Server Shared Components
- SQL Server ODBC Drivers
- SQL Server OLE DB Providers
- SQL Server Native Client

These pre-installed components are incompatible with SQL Server
PrepareImage/Sysprep operations, causing setup to fail with the error:

> Setup has detected that there are SQL Server features already installed on
> this machine that do not support Sysprep.

## Solution

This script identifies and removes all SQL Server-related products from the
system registry before running PrepareImage operations. It:

1. Scans the Windows registry for SQL Server-related products
1. Identifies uninstall methods (MSI or custom uninstaller)
1. Removes each product silently
1. Provides detailed logging of the removal process

## Usage

### In CI Pipeline

The script is automatically run in the Azure Pipelines CI before PrepareImage
tests:

```yaml
- powershell: |
    Write-Information -MessageData 'Removing pre-installed SQL Server
    components that conflict with PrepareImage...' -InformationAction Continue
    & ./tests/Integration/Commands/Remove-SqlServerFromCIImage.ps1
    -Confirm:$false -InformationAction Continue -Verbose
  name: removeSqlServerComponents
  displayName: 'Remove pre-installed SQL Server components'
```

### Manual Usage

To run the script manually on a CI agent or local machine:

```powershell
# Remove all SQL Server components without prompting
.\Remove-SqlServerFromCIImage.ps1 -Confirm:$false

# Preview what would be removed without actually removing
.\Remove-SqlServerFromCIImage.ps1 -WhatIf

# Run with verbose output
.\Remove-SqlServerFromCIImage.ps1 -Verbose -Confirm:$false
```

## How It Works

1. **Registry Scan**: Searches both 32-bit and 64-bit registry uninstall
   locations
1. **Pattern Matching**: Uses multiple patterns to identify SQL Server-related
   products
1. **Uninstall Method Detection**: Automatically detects whether to use:
   - `msiexec.exe` for MSI-based products
   - Custom uninstaller for EXE-based products
1. **Silent Uninstall**: Runs all uninstallers with quiet/silent flags to avoid
   prompts
1. **Logging**: Creates detailed logs in `%TEMP%` for troubleshooting

## Exit Codes

- **0**: All products removed successfully (or no products found)
- **Non-zero**: One or more products failed to uninstall (warnings are logged)

## Products Removed

The script removes products matching these patterns:

- `*SQL Server*LocalDB*`
- `*SQL Server*Client*`
- `*SQL Server*Shared*`
- `*SQL Server*Browser*`
- `*SQL Server*Management*`
- `*SQL Server*Tools*`
- `*SQL Server*Native*Client*`
- `*SQL Server*ODBC*`
- `*SQL Server*OLE*DB*`
- `*SQL Server*T-SQL*`
- `*SQL Server*Command*Line*Utilities*`
- `*SQL Server*Data*Tier*`
- `*Microsoft*ODBC*Driver*SQL*Server*`
- `*Microsoft*OLE*DB*Driver*SQL*Server*`

## Safety

- Uses `SupportsShouldProcess` with `-Confirm` and `-WhatIf` support
- Validates uninstall methods before execution
- Logs all actions for audit trail
- Handles errors gracefully without stopping the entire process

## Notes

- A system restart may be required after removal for changes to take full effect
- The script does NOT remove SQL Server instances installed by the tests
  themselves
- Only removes pre-installed components that ship with the Microsoft Hosted
  agent images

## Related Issues

- [Issue #2212](https://github.com/dsccommunity/SqlServerDsc/issues/2212):
  PrepareImage support and CI integration
