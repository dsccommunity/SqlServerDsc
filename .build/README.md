# DSC Resource Integration Test Optimization

This document describes the script used to dynamically determine whether DSC resource integration tests should run in Azure Pipelines.

## What the Script Does

The `Test-ShouldRunDscResourceIntegrationTests.ps1` script analyzes git changes between two references and determines if DSC resource integration tests need to run. It automatically discovers which public commands are used by DSC resources and classes, then checks if any relevant files have been modified.

## How It Works

The script checks for changes to:

1. **DSC Resources**: Files under `source/DSCResources/`
2. **Classes**: Files under `source/Classes/`  
3. **Public Commands**: Commands that are actually used by DSC resources or classes (dynamically discovered)
4. **Private Functions**: Functions used by the monitored public commands
5. **Integration Tests**: DSC resource integration test files under `tests/Integration/Resources/`
6. **Pipeline Configuration**: Azure Pipelines configuration and build scripts

## Usage

### Azure Pipelines
```yaml
- powershell: |
    .build/Test-ShouldRunDscResourceIntegrationTests.ps1
  displayName: 'Determine if DSC resource tests should run'
```

### Command Line
```powershell
# Basic usage (compares current HEAD with origin/main)
.build/Test-ShouldRunDscResourceIntegrationTests.ps1

# Custom branches
.build/Test-ShouldRunDscResourceIntegrationTests.ps1 -BaseBranch 'origin/dev' -CurrentBranch 'feature-branch'
```

## Dynamic Discovery

The script automatically discovers public commands used by DSC resources by scanning source files, eliminating the need to maintain hardcoded lists. This ensures accuracy and reduces maintenance overhead.
