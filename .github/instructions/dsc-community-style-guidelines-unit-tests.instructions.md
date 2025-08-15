---
description: Guidelines for writing and maintaining tests using Pester.
applyTo: "tests/**/*.[Tt]ests.ps1"
---

# Unit Tests Guidelines

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

Use localized strings in tests only when necessary. You can assign the
localized text to a mock variable by getting the localized string key
from $script:localizedData inside an `InModuleScope` block.
Example of retrieving a localized string key from $script:localizedData:

```powershell
$mockLocalizedStringText = InModuleScope -ScriptBlock { $script:localizedData.LocalizedStringKey }
```

Files that need to be mocked should be created in Pester’s test drive. The
variable `$TestDrive` holds the path to the test drive. `$TestDrive` is a
temporary drive that is created for each test run and is automatically
cleaned up after the test run is complete.

All unit tests should use this code block before the `Describe` block to set
up the test environment and load the correct module being tested:

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
