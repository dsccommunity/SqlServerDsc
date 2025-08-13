---
applyTo: "tests/[iI]ntegration/[cC]ommands/**/*.[iI]ntegration.[tT]ests.ps1"
---

# Command Integration Tests Style Guidelines

Every public command must have an integration test. Integration tests must
never mock any command but run the command in a real environment. All integration
tests should be placed in the root of the folder "tests/Integration/Commands"
and the integration tests should be named after the public command they are testing,
but should have the suffix .Integration.Tests.ps1. The integration tests should
be written to cover all possible scenarios and code paths, ensuring that both
edge cases and common use cases are tested. The integration tests should
also be written to test the command in a real environment, using real
resources and dependencies.

When integration tests need the computer name in CI environments, always use
the `Get-ComputerName` command, which is available in the build pipeline.

All integration tests must use the below code block prior to the first
`Describe`-block. The following code will set up the integration test
environment and it will make sure the module being tested is available

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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

    Import-Module -Name $script:dscModuleName
}
```

The module DscResource.Test is used by the pipeline and its commands
are normally not used when testing public functions, private functions or
class-based resources.

Do not run integration tests locally unless explicitly instructed.
