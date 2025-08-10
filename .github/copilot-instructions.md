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


### Unit tests

Unit tests should be added for all public commands, private functions and
class-based resources.

The unit tests for class-based resources should be
placed in the folder tests/Unit/Classes.
The unit tests for public command should be placed in the folder tests/Unit/Public.
The unit tests for private functions should be placed in the folder tests/Unit/Private.

For detailed integration test guidelines and code templates, refer to the
[Command Unit Test Style Guidelines](instructions/dsc-community-style-guidelines-command-unit-tests.instructions.md).


### Integration tests

All public commands must have an integration test in the folder "tests/Integration/Commands"

For detailed integration test guidelines and code templates, refer to the
[Command Integration Test Style Guidelines](instructions/dsc-community-style-guidelines-command-integration-tests.instructions.md).

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
