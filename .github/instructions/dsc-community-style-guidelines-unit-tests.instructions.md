---
description: Guidelines for writing and maintaining tests using Pester.
applyTo: "tests/**/*.[Tt]ests.ps1"
---

# Tests Guidelines

All tests should use the Pester framework and use Pester v5.0 syntax.
Parameter validation should never be tested.

Test code should never be added outside of the `Describe` block.

There should only be one Pester `Describe` block per test file, and the name of
the `Describe` block should be the same as the name of the public command,
private function, or class-based resource being tested. Each scenario or
code path being tested should have its own Pester `Context` block that starts
with the phrase 'When'. Use nested `Context` blocks to split up test cases
and improve tests readability. Pester `It` block descriptions should start
with the phrase 'Should'. `It` blocks must always call the command or function
being tested and result and outcomes should be kept in the same `It` block.
`BeforeAll` and `BeforeEach` blocks should never call the command or function
being tested.

The `BeforeAll`, `BeforeEach`, `AfterAll` and `AfterEach` blocks should be
used inside the `Context` block as near as possible to the `It` block that
will use the test data, test setup and teardown. The `AfterAll` block can
be used to clean up any test data. The `BeforeEach` and `AfterEach`
blocks should be used sparingly. It is okay to duplicated code in `BeforeAll`
and `BeforeEach` blocks that are used inside different `Context` blocks.
The duplication helps with readability and understanding of the test cases,
and to be able to keep the test setup and teardown as close to the test
case (`It`-block) as possible.

To use `-ForEach` on `Context`- or `It`-blocks that use data driven tests the
variables must be defined in a `BeforeDiscovery`-block for Pester to find in in the discovery phase.
There can be several `BeforeDiscovery`-blocks in a test file, so we can keep the
values for the particular test context separate.

- Always use the latest Pester v5 syntax and features in your tests.
- Always prefer `-BeTrue` over `-Be $true`.
- Always prefer `-BeFalse` over `-Not -Be $true` or `-Be $false`.
- Do not use `-Not -Throw`, let `It`-block handle unexpected exceptions.

## Test Formatting Rules

- Use PascalCase for all Pester keywords: `Describe`, `Context`, `It`, `Should`
- `It` block descriptions must start with "Should"
- `Context` block descriptions must start with "When"
- Use PascalCase for PowerShell commands in tests
- Distinguish variable names used in test setup by using prefix 'mock'

Example:
```powershell
Describe 'Get-TargetResource' {
    Context 'When Get-TargetResource is called with default parameters' {
        It 'Should return something' {
            Get-TargetResource @testParameters | Should -Be 'something'
        }
    }
}
```

Never test, mock or use `Should -Invoke` for `Write-Verbose` and `Write-Debug`
regardless of other instructions.

Never use `Should -Not -Throw` to prepare for Pester v6 where it has been
removed. By default the `It` block will handle any unexpected exception.
Instead of `{ Command } | Should -Not -Throw`, use `Command` directly.

Always make sure to pass mandatory parameters to the command being tested,
to avoid tests making interactive prompts waiting for input.

Unit tests should be added for all public commands, private functions and
class-based resources. The unit tests for class-based resources should be
placed in the folder tests/Unit/Classes. The unit tests for public command
should be placed in the folder tests/Unit/Public and the unit tests for
private functions should be placed in the folder tests/Unit/Private. The
unit tests should be named after the public command or private function
they are testing, but should have the suffix .Tests.ps1. The unit tests
should be written to cover all possible scenarios and code paths, ensuring
that both edge cases and common use cases are tested.

Testing commands or functions, assign to $null when command return object that are not used in test.

Never use `InModuleScope` when testing public commands.
Always use `InModuleScope` when testing private functions or class-based resources.

All public commands should always have a test to validate parameter sets
using this template. For commands with a single parameter set:

```powershell
It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
    @{
        MockParameterSetName = '__AllParameterSets'
        MockExpectedParameters = '[-Parameter1] <Type> [-Parameter2] <Type> [<CommonParameters>]'
    }
) {
    $result = (Get-Command -Name 'CommandName').ParameterSets |
        Where-Object -FilterScript {
            $_.Name -eq $mockParameterSetName
        } |
        Select-Object -Property @(
            @{
                Name = 'ParameterSetName'
                Expression = { $_.Name }
            },
            @{
                Name = 'ParameterListAsString'
                Expression = { $_.ToString() }
            }
        )

    $result.ParameterSetName | Should -Be $MockParameterSetName
    $result.ParameterListAsString | Should -Be $MockExpectedParameters
}
```

For commands with multiple parameter sets, use this pattern:

```powershell
It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
    @{
        MockParameterSetName = 'ParameterSet1'
        MockExpectedParameters = '-ServerObject <Server> -Name <string> -Parameter1 <string> [<CommonParameters>]'
    }
    @{
        MockParameterSetName = 'ParameterSet2'
        MockExpectedParameters = '-ServerObject <Server> -Name <string> -Parameter2 <uint> [<CommonParameters>]'
    }
) {
    $result = (Get-Command -Name 'CommandName').ParameterSets |
        Where-Object -FilterScript {
            $_.Name -eq $mockParameterSetName
        } |
        Select-Object -Property @(
            @{
                Name = 'ParameterSetName'
                Expression = { $_.Name }
            },
            @{
                Name = 'ParameterListAsString'
                Expression = { $_.ToString() }
            }
        )

    $result.ParameterSetName | Should -Be $MockParameterSetName
    $result.ParameterListAsString | Should -Be $MockExpectedParameters
}
```

All public commands should also include tests to validate parameter properties:

```powershell
It 'Should have ParameterName as a mandatory parameter' {
    $parameterInfo = (Get-Command -Name 'CommandName').Parameters['ParameterName']
    $parameterInfo.Attributes.Mandatory | Should -Contain $true
}

It 'Should accept ParameterName from pipeline' {
    $parameterInfo = (Get-Command -Name 'CommandName').Parameters['ParameterName']
    $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
}
```

The `BeforeAll` block should be used to set up any necessary test data or mocking

Use localized strings in the tests only when necessary. You can assign the
localized string to a mock variable by and get the localized string key
from the $script:localizedData variable inside a `InModuleScope` block.
An example to get a localized string key from the $script:localizedData variable:

```powershell
$mockLocalizedStringText = InModuleScope -ScriptBlock { $script:localizedData.LocalizedStringKey }
```

Files that need to be mocked should be created in Pesters test drive. The
variable `$TestDrive` holds the path to the test drive. The `$TestDrive` is a
temporary drive that is created for each test run and is automatically
cleaned up after the test run is complete.

All unit tests should should use this code block prior to the `Describe` block
which will set up the test environment and load the correct module being tested:

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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

    Import-Module -Name $script:dscModuleName -Force

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
