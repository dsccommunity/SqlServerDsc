# DSC Resource Integration Test Optimization

This document describes the script used to dynamically determine whether DSC
resource integration tests should run in Azure Pipelines.

## What the Script Does

The `Test-ShouldRunDscResourceIntegrationTests.ps1` script analyzes git
changes between two references and determines if DSC resource integration
tests need to run. It automatically discovers which public commands are used
by DSC resources and classes, then checks if any relevant files have been
modified.

## How It Works

The script checks for changes to:

1. **DSC Resources**: Files under `source/DSCResources/`
1. **Classes**: Files under `source/Classes/`
1. **Public Commands**: Commands that are actually used by DSC resources or
   classes (dynamically discovered)
1. **Private Functions**: Functions used by the monitored public commands or
   class-based DSC resources
1. **Integration Tests**: DSC resource integration test files under
   `tests/Integration/Resources/`

## Usage

### Azure Pipelines

```yaml
- powershell: |
    .build/Test-ShouldRunDscResourceIntegrationTests.ps1
  displayName: 'Determine if DSC resource tests should run'
```

The Azure Pipelines task sets an output variable that downstream stages can
use to conditionally run DSC resource integration tests. The script returns
a boolean value that the pipeline captures using:

```powershell
Write-Host "##vso[task.setvariable variable=ShouldRunDscResourceIntegrationTests;isOutput=true]$shouldRun"
```

Downstream stages reference this output variable using the pattern:
`dependencies.JobName.outputs['StepName.VariableName']` to gate their
execution based on whether DSC resource tests should run.

### Command Line

```powershell
# Basic usage (compares current HEAD with origin/main)
.build/Test-ShouldRunDscResourceIntegrationTests.ps1

# Custom branches
.build/Test-ShouldRunDscResourceIntegrationTests.ps1 -BaseBranch 'origin/dev' \
    -CurrentBranch 'feature-branch'
```

## Dynamic Discovery

The script automatically discovers public commands used by DSC resources by
scanning source files, eliminating the need to maintain hardcoded lists.
This ensures accuracy and reduces maintenance overhead.
