# Specific instructions for the PowerShell module project SqlServerDsc

Assume that the word "command" references to a public command, and the word
"function" references to a private function.

PowerShell commands that should be public should always have its separate
script file and the the command name as the file name with the .ps1 extension,
these files shall always be placed in the folder source/Public.

Public commands may use private functions to move out logic that can be
reused by other public commands, so move out any logic that can be deemed
reusable. Private functions should always have its separate script file and
the the function name as the file name with the .ps1 extension, these files
shall always be placed in the folder source/Private.

Comment-based help should be added to each public command and private functions.
The comment-based help should always be before the function-statement. Each
comment-based help keyword should be indented with 4 spaces and each keywords
text should be indented 8 spaces. The text for keyword .DESCRIPTION should
be descriptive and must have a length greater than 40 characters. A comment-based
help must have at least one example, but preferably more examples to showcase
all possible parameter sets and different parameter combinations.

All message strings for Write-Debug, Write-Verbose, Write-Error, Write-Warning
and other error messages in public commands and private functions should be
localized using localized string keys. You should always add all localized
strings for public commands and private functions in the source/en-US/SqlServerDsc.strings.psd1
file, re-use the same pattern for new string keys. Localized string key names
should always be prefixed with the function name but use underscore as word
separator. Always assume that all localized string keys have already been
assigned to the variable $script:localizedData.

All tests should use the Pester framework and use Pester v5.0 syntax.

Never test, mock or use `Should -Invoke` for `Write-Verbose` and `Write-Debug`
regardless of other instructions.

Test code should never be added outside of the `Describe` block.

Unit tests should be added for all public commands and private functions.
The unit tests for public command should be placed in the folder tests/Unit/Public
and the unit tests for private functions should be placed in the folder
tests/Unit/Private. The unit tests should be named after the public command
or private function they are testing, but should have the suffix .Tests.ps1.
The unit tests should be written to cover all possible scenarios and code paths,
ensuring that both edge cases and common use cases are tested.

There should only be one Pester `Describe` block per test file, and the name of
the `Describe` block should be the same as the name of the public command or
private function being tested. Each scenario or code path being tested should
have its own Pester `Context` block that starts with the phrase 'When'. Use
nested `Context` blocks to split up test cases and improve tests readability.
Pester `It` block descriptions should start with the phrase 'Should'. `It`
blocks must always call the command or function being tested and result and
outcomes should be kept in the same `It` block. `BeforeAll` and `BeforeEach`
blocks should never call the command or function being tested.

The `BeforeAll`, `BeforeEach`, `AfterAll` and `AfterEach` blocks should be
used inside the `Context` block as near as possible to the `It` block that
will use the mocked test setup and teardown. The `BeforeAll` block should
be used to set up any necessary test data or mocking, and the `AfterAll`
block can be used to clean up any test data. The `BeforeEach` and `AfterEach`
blocks should be used sparingly. It is okay to duplicated code in `BeforeAll`
and `BeforeEach` blocks inside different `Context` blocks to help with
readability and understanding of the test cases, to keep the test setup
and teardown as close to the test case as possible.

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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Integration tests should be added for all public commands. Integration must
never mock any command but run the command in a real environment. The integration
tests should be placed in the folder tests/Integration/Commands and the
integration tests should be named after the public command they are testing,
but should have the suffix .Integration.Tests.ps1. The integration tests should be
written to cover all possible scenarios and code paths, ensuring that both
edge cases and common use cases are tested. The integration tests should
also be written to test the command in a real environment, using real
resources and dependencies.

The module being tested should not be imported in the integration tests.
All integration tests for commands should should use this code block prior
to the `Describe` block which will set up the test environment and will make
sure the correct module is available for testing:

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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
```
