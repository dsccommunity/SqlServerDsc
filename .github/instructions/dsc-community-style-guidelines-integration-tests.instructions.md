---
description: Guidelines for implementing integration tests for commands.
applyTo: "tests/[iI]ntegration/**/*.[iI]ntegration.[tT]ests.ps1"
---

# Integration Tests Guidelines

## Requirements
- Location Commands: `tests/Integration/Commands/{CommandName}.Integration.Tests.ps1`
- Location Resources: `tests/Integration/Resources/{ResourceName}.Integration.Tests.ps1`
- No mocking - real environment only
- Cover all scenarios and code paths
- Use `Get-ComputerName` for computer names in CI
- Avoid `ExpectedMessage` for `Should -Throw` assertions
- Only run integration tests in CI unless explicitly instructed.
- Call commands with `-Force` parameter where applicable (avoids prompting).
- Use `-ErrorAction 'Stop'` on commands so failures surface immediately

## Required Setup Block

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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = '{MyModuleName}'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}
```
