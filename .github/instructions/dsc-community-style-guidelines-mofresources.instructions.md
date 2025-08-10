---
applyTo: "source/DSCResources/**/*.psm1"
---

# MOF-based Desired State Configuration (DSC) Resources Guidelines

## Required Functions
- Every DSC resource must define: `Get-TargetResource`, `Set-TargetResource`, `Test-TargetResource`
- Export using `*-TargetResource` pattern

## Function Return Types
- `Get-TargetResource`: Must return hashtable with all resource properties
- `Test-TargetResource`: Must return boolean ($true/$false)
- `Set-TargetResource`: Must not return anything (void)

## Parameter Guidelines
- `Get-TargetResource`: Only include parameters needed to retrieve actual current state values
- `Get-TargetResource`: Remove non-mandatory parameters that are never used
- `Set-TargetResource` and `Test-TargetResource`: Must have identical parameters
- `Set-TargetResource` and `Test-TargetResource`: Unused mandatory parameters: Add "Not used in <function_name>" to help comment

## Required Elements
- Each function must include `Write-Verbose` at least once
  - `Get-TargetResource`: Use verbose message starting with "Getting the current state of..."
  - `Set-TargetResource`: Use verbose message starting with "Setting the desired state of..."
  - `Test-TargetResource`: Use verbose message starting with "Determining the current state of..."
- Use localized strings for all messages (Write-Verbose, Write-Error, etc.)
- Import localized strings using `Get-LocalizedData` at module top

## Error Handling
- Do not use `throw` for terminating errors
- Use `try/catch` blocks to handle exceptions
- Throw localized exceptions using the appropriate `New-*Exception` cmdlet:
  - [`New‑InvalidDataException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidDataException)
  - [`New-ArgumentException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91ArgumentException)
  - [`New-InvalidOperationException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidOperationException)
  - [`New-ObjectNotFoundException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91ObjectNotFoundException)
  - [`New-InvalidResultException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidResultException)
  - [`New-NotImplementedException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91NotImplementedException)
