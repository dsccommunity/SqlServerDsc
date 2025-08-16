---
description: Guidelines for implementing integration tests for commands.
applyTo: "**/*.[iI]ntegration.[tT]ests.ps1"
---

# Command Integration Tests Style Guidelines

Every public command must have an integration test. Integration tests must
never mock any command; they run in a real environment. Place all integration
tests in the folder `tests/Integration/Commands`. Name each test after the
public command it verifies and suffix it with `.Integration.Tests.ps1`.

Write tests to cover all scenarios and code paths, including common cases
and edge cases. Tests should exercise the command in a real environment,
using real resources and dependencies.

When integration tests need the computer name in CI, use [`Get-ComputerName`](https://github.com/dsccommunity/DscResource.Common/wiki/Get%E2%80%91ComputerName).
This helper is provided in the build pipeline and is not required locally.

All integration tests must use the code block below before the first
`Describe` block. The following code sets up the integration test
environment and ensures the module under test is available:

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'
}
```

The DscResource.Test module is used by the pipeline and its commands are
typically not used when testing public functions, private functions, or
class-based resources.

Do not run integration tests locally unless explicitly instructed.
