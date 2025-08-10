# Specific instructions for the PowerShell module project SqlServerDsc

Assume that the word "command" references to a public command, the word
"function" references to a private function, and the word "resource"
references a Desired State Configuration (DSC) class-based resource.

## Public commands

PowerShell commands that should be public should always have its separate
script file and the command name as the file name with the .ps1 extension,
these files shall always be placed in the folder source/Public.

Public commands may use private functions to move out logic that can be
reused by other public commands, so move out any logic that can be deemed
reusable.

## Private functions

Private functions (also known as helper functions) should always have its
separate script file and the function name as the file name with the .ps1
extension. These files shall always be placed in the folder source/Private.
This also applies to functions that are only used within a single public
command.

## Desired State Configuration (DSC) class-based resource

Desired State Configuration (DSC) class-based resource should always have
its separate script file and the resource class name as the file name with
the .ps1 extension, these files shall always be placed in the folder
source/Classes.

### Parent classes

#### ResourceBase

A derived class should inherit the parent class `ResourceBase`.

The parent class `ResourceBase` will set up `$this.localizedData` and provide
logic to compare the desired state against the current state. To get the
current state it will call the overridable method `GetCurrentState`. If not
in desired state it will call the overridable method `Modify`. It will also
call the overridable methods `AssertProperties` and `NormalizeProperties` to
validate and normalize the provided values of the desired state.


### Derived class

The derived class should use the decoration `[DscResource(RunAsCredential = 'Optional')]`.

The derived class should always inherit from a parent class.

The derived class should override the methods `Get`, `Test`, `Set`, `GetCurrentState`,
`Modify`, `AssertProperties`, and `NormalizeProperties` using this pattern
(and replace MyResourceName with actual resource name):

```powershell
[MyResourceName] Get()
{
    # Call the base method to return the properties.
    return ([ResourceBase] $this).Get()
}

[System.Boolean] Test()
{
    # Call the base method to test all of the properties that should be enforced.
    return ([ResourceBase] $this).Test()
}

[void] Set()
{
    # Call the base method to enforce the properties.
    ([ResourceBase] $this).Set()
}

<#
    Base method Get() call this method to get the current state as a hashtable.
    The parameter properties will contain the key properties.
#>
hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
{
    # Add code to return the current state as an hashtable.
}

<#
    Base method Set() call this method with the properties that are not in
    desired state and should be enforced. It is not called if all properties
    are in desired state. The variable $properties contains only the properties
    that are not in desired state.
#>
hidden [void] Modify([System.Collections.Hashtable] $properties)
{
    # Add code to set the desired state based on the properties that are not in desired state.
}

<#
    Base method Assert() call this method with the properties that was assigned
    a value.
#>
hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
{
    # Add code to validate class properties that the user passed values to.
}

<#
    Base method Normalize() call this method with the properties that was assigned
    a value.
#>
hidden [void] NormalizeProperties([System.Collections.Hashtable] $properties)
{
    # Add code to normalize class properties that the user passed values to.
}
```

## Comment-based help

Comment-based help should always be before the function-statement for each
public command and private function, and before the class-statement for each
class-based resource. Comment-based help should always be in the format of
a comment block and at least use the keywords: .SYNOPSIS, .DESCRIPTION,
.PARAMETER, .EXAMPLE, and .NOTES.

Each comment-based help keyword should be indented with 4 spaces and each
keyword's text should be indented 8 spaces.

The text for keyword .DESCRIPTION should be descriptive and must have a
length greater than 40 characters. The .SYNOPSIS keyword text should be
a short description of the public command, private function, or class-based
resource.

A comment-based help must have at least one example, but preferably more
examples to showcase all possible parameter sets and different parameter
combinations.

## Localization

All message strings for Write-Debug, Write-Verbose, Write-Error, Write-Warning
and other error messages in public commands and private functions should be
localized using localized string keys.

For public commands and private functions you should always add all localized
strings for in the source/en-US/SqlServerDsc.strings.psd1 file, re-use the
same pattern for new string keys. Localized string key names should always
be prefixed with the function name but use underscore as word separator.
Always assume that all localized string keys have already been assigned to
the variable $script:localizedData.

For class-based resource you should always add a localized strings in a
separate file the folder source\en-US. The strings file for a class-based
resource should be named to exactly match the resource class name with the
suffix `.strings.psd1`.
Localized string key names should use underscore as word separator if key
name has more than one word. Always assume that all localized string keys
for a class-based resource already have been assigned to the variable
`$this.localizedData` by the parent class.

## Tests

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

### Unit tests

Never test, mock or use `Should -Invoke` for `Write-Verbose` and `Write-Debug`
regardless of other instructions.

Never use `Should -Not -Throw` to prepare for Pester v6 where it has been
removed. By default the `It` block will handle any unexpected exception.
Instead of `{ Command } | Should -Not -Throw`, use `Command` directly.

Unit tests should be added for all public commands, private functions and
class-based resources. The unit tests for class-based resources should be
placed in the folder tests/Unit/Classes. The unit tests for public command
should be placed in the folder tests/Unit/Public and the unit tests for
private functions should be placed in the folder tests/Unit/Private. The
unit tests should be named after the public command or private function
they are testing, but should have the suffix .Tests.ps1. The unit tests
should be written to cover all possible scenarios and code paths, ensuring
that both edge cases and common use cases are tested.

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

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
}
```

### Integration tests

All public commands must have an integration test in the folder "tests/Integration/Commands"

For detailed integration test guidelines and code templates, refer to the
[integration test style guidelines](.github/instructions/dsc-community-style-guidelines-command-integration-tests.instructions.md).

## Change log

The Unreleased section in CHANGELOG.md should always be updated when making
changes to the codebase. Use the keepachangelog format and provide concrete
release notes that describe the main changes made. This includes new commands,
private functions, class-based resources, or significant modifications to
existing functionality.

## Project scripts

The build script is located in the root of the repository and is named
`build.ps1`.

### Build

- To run the build script after code changes in ./source, run `.\build.ps1 -Tasks build`.

## Test project

- To run tests, always run `.\build.ps1 -Tasks noop` prior to running `Invoke-Pester`.
- To run single test file, always run `.\build.ps1 -Tasks noop` together with `Invoke-Pester`,
  e.g `.\build.ps1 -Tasks noop;Invoke-Pester -Path '<test path>' -Output Detailed`
- `.\build.ps1 -Tasks test` which will run all QA and unit tests in the project
  with code coverage. Add `-CodeCoverageThreshold 0` to disable code coverage, e.g.
  `.\build.ps1 -Tasks test -CodeCoverageThreshold 0`.
