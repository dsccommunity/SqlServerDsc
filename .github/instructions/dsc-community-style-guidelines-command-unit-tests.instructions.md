---
applyTo: "tests/[uU]nit/[pP]ublic/**/*.[tT]ests.ps1,tests/[uU]nit/[pP]rivate/**/*.[tT]ests.ps1"
---

# Command Unit Test Style Guidelines

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

    Import-Module -Name $script:dscModuleName

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
