# DSC Resource Integration Test Optimization

This document describes the optimization implemented to conditionally run DSC resource integration tests in Azure Pipelines based on the changes made in a pull request or commit.

## Overview

The Azure Pipelines configuration has been enhanced to automatically determine whether DSC resource integration tests need to run based on the files that have been changed. This optimization significantly reduces CI/CD time when changes don't affect DSC resources.

## How It Works

### Detection Script

The `.build/Test-ShouldRunDscResourceIntegrationTests.ps1` script analyzes git diff output to determine if DSC resource integration tests should run. It checks for changes in:

1. **DSC Resources**: Any changes to files under `source/DSCResources/` or `source/Classes/`
2. **Public Commands Used by DSC Resources**: Changes to specific public commands that are called by DSC resources or classes
3. **Private Functions**: Changes to private functions that are used by the public commands mentioned above
4. **Integration Test Files**: Changes to DSC resource integration test files themselves
5. **Pipeline Configuration**: Changes to pipeline configuration files

### Public Commands Monitored

The following public commands are monitored because they are used by DSC resources or classes:

- `Add-SqlDscDatabaseRoleMember`
- `Add-SqlDscServerRoleMember`
- `Connect-SqlDscDatabaseEngine`
- `Disable-SqlDscAudit`
- `Enable-SqlDscAudit`
- `Get-SqlDscAudit`
- `Get-SqlDscDatabasePermission`
- `Get-SqlDscDynamicMaxDop`
- `Get-SqlDscDynamicMaxMemory`
- `Get-SqlDscManagedComputer`
- `Get-SqlDscPercentMemory`
- `Get-SqlDscRSSetupConfiguration`
- `Get-SqlDscServerPermission`
- `Import-SqlDscPreferredModule`
- `Install-SqlDscBIReportServer`
- `Install-SqlDscReportingService`
- `Invoke-SqlDscQuery`
- `New-SqlDscAudit`
- `Remove-SqlDscAudit`
- `Remove-SqlDscDatabaseRoleMember`
- `Remove-SqlDscServerRoleMember`
- `Repair-SqlDscBIReportServer`
- `Repair-SqlDscReportingService`
- `Set-SqlDscAudit`
- `Set-SqlDscDatabasePermission`
- `Set-SqlDscServerPermission`
- `Test-SqlDscIsDatabasePrincipal`
- `Test-SqlDscIsLogin`
- `Test-SqlDscIsSupportedFeature`
- `Uninstall-SqlDscBIReportServer`
- `Uninstall-SqlDscReportingService`

### Pipeline Changes

The Azure Pipelines configuration has been modified to:

1. Add a new job `Determine_DSC_Resource_Test_Requirements` in the `Quality_Test_and_Unit_Test` stage
2. Add conditions to the following stages to only run when DSC resource integration tests are needed:
   - `Integration_Test_Resources_SqlServer`
   - `Integration_Test_Resources_SqlServer_dbatools`
   - `Integration_Test_Resources_ReportingServices`
   - `Integration_Test_Resources_PowerBIReportServer`
   - `Integration_Test_Resources_ReportingServices_dbatools`
3. Update the `Deploy` stage to handle conditional dependencies

## What Always Runs

The following tests and stages always run regardless of changes:

- **Unit Tests**: All unit tests continue to run for every change
- **QA Tests**: Quality assurance tests always run
- **Command Integration Tests**: Integration tests for public commands always run
  - `Integration_Test_Commands_SqlServer`
  - `Integration_Test_Commands_ReportingServices`
  - `Integration_Test_Commands_BIReportServer`

## What Runs Conditionally

The following stages only run when changes affect DSC resources:

- `Integration_Test_Resources_SqlServer`
- `Integration_Test_Resources_SqlServer_dbatools`
- `Integration_Test_Resources_ReportingServices`
- `Integration_Test_Resources_PowerBIReportServer`
- `Integration_Test_Resources_ReportingServices_dbatools`

## Benefits

- **Reduced CI/CD Time**: DSC resource integration tests can take significant time; skipping them when not needed speeds up the pipeline
- **Resource Efficiency**: Fewer compute resources used when DSC resource tests are skipped
- **Faster Feedback**: Developers get faster feedback on changes that don't affect DSC resources
- **Maintained Quality**: All relevant tests still run when needed to ensure quality is not compromised

## Edge Cases

The script errs on the side of caution:

- If git diff fails, DSC resource integration tests will run
- If no changes are detected, DSC resource integration tests will run
- If pipeline configuration changes, DSC resource integration tests will run

## Maintenance

When adding new public commands that are used by DSC resources or classes, update the `$PublicCommandsUsedByDscResources` array in the `.build/Test-ShouldRunDscResourceIntegrationTests.ps1` script.

To check which commands are used by DSC resources, run:

```bash
# Find DSC resources that use public commands
find source/DSCResources -name "*.psm1" -exec grep -l "Get-SqlDsc\|Set-SqlDsc\|Test-SqlDsc\|Connect-SqlDsc\|Invoke-SqlDsc\|New-SqlDsc\|Remove-SqlDsc\|Add-SqlDsc\|Disable-SqlDsc\|Enable-SqlDsc\|Complete-SqlDsc\|Import-SqlDsc\|Initialize-SqlDsc\|Install-SqlDsc\|Repair-SqlDsc\|Save-SqlDsc\|Uninstall-SqlDsc\|Assert-SqlDsc" {} \;

# Find classes that use public commands  
find source/Classes -name "*.ps1" -exec grep -l "Get-SqlDsc\|Set-SqlDsc\|Test-SqlDsc\|Connect-SqlDsc\|Invoke-SqlDsc\|New-SqlDsc\|Remove-SqlDsc\|Add-SqlDsc\|Disable-SqlDsc\|Enable-SqlDsc\|Complete-SqlDsc\|Import-SqlDsc\|Initialize-SqlDsc\|Install-SqlDsc\|Repair-SqlDsc\|Save-SqlDsc\|Uninstall-SqlDsc\|Assert-SqlDsc" {} \;
```