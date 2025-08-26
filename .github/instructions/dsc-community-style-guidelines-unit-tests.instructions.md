---
description: Guidelines for writing and maintaining unit tests using Pester.
applyTo: "tests/[u]Unit/**/*.[Tt]ests.ps1"
---

# Unit Tests Guidelines

- Test with localized strings: Use `InModuleScope -ScriptBlock { $script:localizedData.Key }`
- Mock files: Use `$TestDrive` variable (path to the test drive)
- All public commands require parameter set validation tests
- After modifying classes, always run tests in new session (for changes to take effect)

## Test Setup Requirements

Use this exact setup block before `Describe`:

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
    $script:dscModuleName = '{MyModuleName}'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}
```

## Required Test Templates

### Parameter Set Validation
Single parameter set:
```powershell
It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
    @{
        ExpectedParameterSetName = '{ParameterSetName}' # e.g. __AllParameterSets
        ExpectedParameters = '[-Parameter1] <Type> [-Parameter2] <Type> [<CommonParameters>]'
    }
) {
    $result = (Get-Command -Name 'CommandName').ParameterSets |
        Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
        Select-Object -Property @(
            @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
            @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
        )
    $result.ParameterSetName | Should -Be $ExpectedParameterSetName
    $result.ParameterListAsString | Should -Be $ExpectedParameters
}
```

Multiple parameter sets: Use same pattern with multiple hashtables in `-ForEach` array.

### Parameter Properties
```powershell
It 'Should have ParameterName as a mandatory parameter' {
    $parameterInfo = (Get-Command -Name 'CommandName').Parameters['ParameterName']
    $parameterInfo.Attributes.Mandatory | Should -BeTrue
}
```
