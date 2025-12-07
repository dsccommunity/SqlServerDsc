# Contributing to SqlServerDsc

If you are keen to make SqlServerDsc better, why not consider contributing your work
to the project? Every little change helps us make a better resource for everyone
to use, and we would love to have contributions from the community.

## Core contribution guidelines

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Documentation with Markdown

In each resource folder there is a README.md that is the main resource
documentation, parameter descriptions are documented in the resource schema
MOF file. And examples are added to the resource examples folder.

On build the resources README, schema.mof and example files will be parsed
and build a wiki page and conceptual help for each resource.

The parameter descriptions in the schema MOF file can contain markdown
code. That markdown code will only be used in the Wiki page and will be
automatically removed in the conceptual help.

The following table is a guideline on when to use markdown code in parameter
description. There can be other usages that are not described here. Backslash
must always be escaped (using `\`, e.g `\\`).

<!-- markdownlint-disable MD013 - Line length -->
Type | Markdown syntax | Example
-- | -- | --
**Parameter reference** | `**ParameterName**` (bold) | **ParameterName**
**Parameter value reference** | `` `'String1'` ``, `` `$true` ``, `` `50` `` (inline code-block) | `'String1'`, `$true`, `50`
**Name reference** (resource, modules, products, or features, etc.) | `_Microsoft SQL Server Database Engine_` (Italic) | _Microsoft SQL Server Database Engine_
**Path reference** | `` `C:\\Program Files\\SSRS` `` | `C:\\Program Files\\SSRS`
**Filename reference** | `` `log.txt` `` | `log.txt`

<!-- markdownlint-enable MD013 - Line length -->

If using Visual Studio Code to edit Markdown files it can be a good idea
to install the markdownlint extension. It will help to do style checking.
The file [.markdownlint.json](/.markdownlint.json) is prepared with a default
set of rules which will automatically be used by the extension.

## Automatic formatting with VS Code

There is a VS Code workspace settings file within this project with formatting
settings matching the style guideline. That will make it possible inside VS Code
to press SHIFT+ALT+F, or press F1 and choose 'Format document' in the list. The
PowerShell code will then be formatted according to the Style Guideline
(although maybe not complete, but would help a long way).

### SQL Server products supported by resources

Any resource should be able to target at least all SQL Server versions that are
currently supported by Microsoft (also those in extended support).
Unless the functionality that the resource targets does not exist in a certain
SQL Server version.
There can also be other limitations that restrict the resource from targeting all
supported versions.

Those SQL Server products that are still supported can be listed at the
[Microsoft life cycle site](https://support.microsoft.com/en-us/lifecycle/search?alpha=SQL%20Server).

## Script Analyzer rules

There are several Script Analyzer rules to help with the development and review
process. Rules come from the modules **ScriptAnalyzer**, **DscResource.AnalyzerRules**,
**Indented.ScriptAnalyzerRules**, and **SqlServerDsc.AnalyzerRules**.

Some rules (but not all) are allowed to be overridden with a justification.

This is an example how to override a rule from the module **SqlServerDsc.AnalyzerRules**.

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql is called when Get-TargetResource is called')]
param ()
```

This is an example how to override a rule from the module **ScriptAnalyzer**.

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification='Because $global:DSCMachineStatus is used to trigger a Restart, either by force or when there are pending changes')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Because $global:DSCMachineStatus is only set, never used (by design of Desired State Configuration)')]
param ()
```

This is an example how to override a rule from the module **Indented.ScriptAnalyzerRules**.

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification='Because the code throws based on an prior expression')]
param ()
```

## Design patterns

### Credentials that does not have password

Credential that needs to be passed to a DSC resource might include Manged
Service Account (MSA), Group Managed Service Account (gMSA), and built-in
accounts (e.g. 'NT AUTHORITY\NetworkService').

For a resource to support these types of accounts (credentials) the DSC
resource need to ignore the password part of the credential object when
it is passed to the DSC resource. We should not add separate parameters
for passing such account names.

_This was discussed in [issue #738](https://github.com/dsccommunity/SqlServerDsc/issues/738)_
_and [issue #1230](https://github.com/dsccommunity/SqlServerDsc/issues/1230)_.

### Naming convention

The DSC resources contained in SqlServerDsc use the following naming convention:

```naming
<Module Identifier>[<Component>][<Action>]<Scope>{<Feature>|<Property>}
```

The following list describes the components that make up a resource name and
lists possible names used for each of the components. The component names are
not limited to the names in this list.

- **Module Identifier**
  - **Sql**
- **Component**
  - **\<none\>** - Database Engine _(No component abbreviation)_
  - **AS** - Analysis Services
  - **IS** - Integration Services
  - **RS** - Reporting Services
- **Action** _(not required)_
  - **Setup**
  - **WaitFor**
- **Scope** - Where the action, feature, or property is being applied.
  - **AG** (AvailabilityGroup)
  - **Database**
  - **ServiceAccount**
  - **Windows**
- **Feature**
  - **AlwaysOn** - This is for the overall AlwaysOn feature
  - **Endpoint**
  - **Firewall**
  - **Network**
  - **Script**
- **Property** _(not required)_
  - **Alias**
  - **Configuration**
  - **Database**
  - **DatabaseMembership**
  - **DefaultLocation**
  - **Listener**
  - **Login**
  - **MaxDop**
  - **Memory**
  - **Owner**
  - **Permission**
  - **RecoveryModel**
  - **Replica**
  - **Replication**
  - **Role**
  - **SecureConnectionLevel**
  - **Service**
  - **State**

#### Example of Resource Naming

The `SqlEndpointPermission` resource name is built using the defined
naming structure using the following components.

- **Module Identifier**: Sql
- **Component**: \<blank\>
- **Action**: \<none\>
- **Scope**: Server
- **Feature**: Endpoint
- **Property**: Permission

### mof-based resource

A mof-based resource is a resource tha has the functions Get-, Set-, and
Test-TargetResource in a PowerShell module script file (.psm1) and a
schema.mof that describes the properties of the resource.

#### Folder and file structure

Please note that for the examples folder we don't use the 'DSC\_' prefix on the
resource folders.
This is to make those folders more user friendly, to resemble the name the user
would use in the configuration file.

```Text
source/DSCResources/DSC_SqlConfiguration/DSC_SqlConfiguration.psm1
source/DSCResources/DSC_SqlConfiguration/DSC_SqlConfiguration.schema.mof
source/DSCResources/DSC_SqlConfiguration/en-US/DSC_SqlConfiguration.strings.psd1
source/DSCResources/DSC_SqlConfiguration/README.md

source/Examples/Resources/SqlConfiguration/1-AddConfigurationOption.ps1
source/Examples/Resources/SqlConfiguration/2-RemoveConfigurationOption.ps1

tests/Unit/DSC_SqlConfiguration.Tests.ps1

tests/Integration/DSC_SqlConfiguration.config.ps1
tests/Integration/DSC_SqlConfiguration.Integration.Tests.ps1
```

##### Schema mof file

The class name should be prefixed with 'DSC\_Sql', e.g. _DSC_SqlConfiguration_.
Please note that the `FriendlyName` in the schema mof file should not contain the
prefix `DSC\_`.

```powershell
[ClassVersion("1.0.0.0"), FriendlyName("SqlConfiguration")]
class DSC_SqlConfiguration : OMI_BaseResource
{
    # Properties removed for readability.
};
```

### Composite or class-based resource

Any composite (with a Configuration) or class-based resources should be prefixed
with 'Sql'

### Localization

In each resource folder there should be, at least, a localization folder for
english language 'en-US'.

Read more about this in the [localization style guideline](https://dsccommunity.org/styleguidelines/localization/).

### Helper functions

Helper functions or wrapper functions that are used only by the resource can
preferably be placed in the resource module file. If the functions are of a
type that could be used by more than one resource, then the functions can also
be placed in the common module [SqlServerDsc.Common](https://github.com/dsccommunity/SqlServerDsc/blob/main/source/Modules/SqlServerDsc.Common)
module file.

If a helper function can be used by more than one DSC module it is preferably
that the helper function is added to the PowerShell module [DscResource.Common](https://github.com/dsccommunity/DscResource.Common).
Once the helper function is in a full release (not preview) then it can be
automatically be used by DSC resources in this module. This is because the
_DscResource.Common_ module is incorporating during the build phase.

### Unit tests

For a review of a Pull Request (PR) to start, all tests must pass without error.
If you need help to figure why some test don't pass, just write a comment in the
Pull Request (PR), or submit an issue, and somebody will come along and assist.

If want to know how to run this module's tests you can look at the [Testing Guidelines](https://dsccommunity.org/guidelines/testing-guidelines/#running-tests)

#### Using SMO stub classes

There are [stub classes](https://github.com/PowerShell/SqlServerDsc/blob/main/Tests/Unit/Stubs/SMO.cs)
for the SMO classes which can be used and improved on when creating tests where
SMO classes are used in the code being tested.

#### Using stub modules

There are [stub modules](https://github.com/PowerShell/SqlServerDsc/blob/main/Tests/Unit/Stubs)
for the modules SQLPS and SqlServer. The stub modules should be used when
writing unit test so that mocks have something to hook onto without the
need to have the real modules installed.

There is documentation how to generate the stub modules for the unit tests in
['tests/Unit/Stubs`](https://github.com/dsccommunity/SqlServerDsc/tree/main/tests/Unit/Stubs).
The stub modules only need to be updated when there is changes to the source
module.

### Integration tests

Integration tests should be written for resources so they can be validated by
the CI.

There are also configuration made by existing integration tests that can be reused
to write integration tests for other resources. This is documented in
[Integration tests for SqlServerDsc](https://github.com/PowerShell/SqlServerDsc/blob/main/Tests/Integration/README.md).

Since integration tests must run in order because they are dependent on each
other to some degree. Most resource are dependent on that integration tests
for the DSC resource _SqlSetup_ have installed the instance to connect to.
To make sure a integration tests is run in the correct order the integration
tests are grouped in the file `azure-pipelines.yml` in the integration tests
jobs.

There are three, separate, integration tests jobs that each, independently, test
SQL Server 2016, SQL Server 2017 and SQL Server 2019.

### Testing of examples files

When sending in a Pull Request (PR) all example files will be tested so they can
be compiled to a .mof file. If the tests find any errors the build will fail.

### Class-based DSC resource

#### Terminating Error

A terminating error is an error that prevents the resource to continue further.
If a DSC resource shall throw an terminating error the commands of the module
**DscResource.Common** shall be used primarily; [`New-ArgumentException`](https://github.com/dsccommunity/DscResource.Common#new-invalidargumentexception),
[`New-InvalidDataException`](https://github.com/dsccommunity/DscResource.Common#new-invaliddataexception),
[`New-InvalidOperationException`](https://github.com/dsccommunity/DscResource.Common#new-invalidoperationexception),
[`New-InvalidResultException`](https://github.com/dsccommunity/DscResource.Common#new-invalidresultexception),
or [`New-NotImplementedException`](https://github.com/dsccommunity/DscResource.Common#new-notimplementedexception).
If neither of those commands works in the scenario then `throw` shall be used.

### Commands

Commands are publicly exported commands from the module, and the source for
commands are located in the folder `./source/Public`.

#### Error Handling Guidelines

Public commands should primarily use `Write-Error` for error handling, as it
provides the most flexible and predictable behavior for callers. The statement
`throw` shall never be used in public commands except within parameter
validation attributes like `[ValidateScript()]` where it is the only valid
mechanism for validation failures.

##### When to Use Write-Error

Use `Write-Error` in most scenarios where a public command encounters an error:

- **Validation failures**: When input parameters fail validation
- **Resource not found**: When a requested resource doesn't exist
- **Operation failures**: When an operation cannot be completed
- **Permission issues**: When access is denied

`Write-Error` generates a non-terminating error by default, allowing the caller
to control behavior via the `-ErrorAction` parameter. This is the expected
PowerShell pattern.

**Example**: A command that retrieves a database returns an error if not found:

```powershell
if (-not $databaseExist)
{
    $errorMessage = $script:localizedData.MissingDatabase -f $DatabaseName

    Write-Error -Message $errorMessage -Category 'ObjectNotFound' -ErrorId 'GSD0001' -TargetObject $DatabaseName

    return
}
```

The caller controls the behavior:

```powershell
# Returns $null, continues execution (non-terminating)
$db = Get-Database -Name 'NonExistent'

# Throws terminating error, stops execution
$db = Get-Database -Name 'NonExistent' -ErrorAction 'Stop'
```

> [!IMPORTANT]
> Always use `return` after `Write-Error` to prevent further processing in the
> command. Without `return`, the command continues executing, which may cause
> unexpected behavior or additional errors.

##### Understanding $PSCmdlet.ThrowTerminatingError

The `$PSCmdlet.ThrowTerminatingError()` method is **not recommended** for public
commands despite its name suggesting it throws a terminating error. It actually
throws a **command-terminating error** which has unexpected behavior when called
from another command.

**The Problem**: When a command uses `$PSCmdlet.ThrowTerminatingError()`, the
error behaves like a non-terminating error to the caller unless the caller
explicitly uses `-ErrorAction 'Stop'`. This creates confusing behavior:

```powershell
function Get-Something
{
    [CmdletBinding()]
    param ()

    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            'Database not found',
            'GS0001',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            'MyDatabase'
        )
    )

    # This line never executes (correctly stopped)
    Write-Output 'After error'
}

function Start-Operation
{
    [CmdletBinding()]
    param ()

    Get-Something

    # BUG: This line DOES execute even though Get-Something threw an error!
    Write-Output 'Operation completed'
}

# Caller must use -ErrorAction 'Stop' to prevent continued execution
Start-Operation -ErrorAction 'Stop'
```

Because of this behavior, **use `Write-Error` instead** in public commands.

##### When $PSCmdlet.ThrowTerminatingError Can Be Used

Use `$PSCmdlet.ThrowTerminatingError()` only in these limited scenarios:

1. **Private functions** that are only called internally and where the behavior
   is well understood
2. **Assert-style commands** (like `Assert-SqlDscLogin`) whose purpose is to
   throw on failure
3. **Commands with `SupportsShouldProcess`** where an operation failure in the
   `ShouldProcess` block must terminate (common for state-changing operations
   that cannot be partially completed)
4. **Catch blocks in state-changing commands** where a critical operation
   failure must be communicated as a terminating error to prevent further
   state changes

In these cases, ensure callers are aware of the behavior. **Important:** When calling
these commands, using `-ErrorAction 'Stop'` alone is NOT sufficient to stop the calling
function. Callers must ALSO either:
- Wrap the call in try-catch, OR
- Set `$ErrorActionPreference = 'Stop'` in the calling function

##### Handling Errors from .NET Methods and Cmdlets

When working with .NET methods (like SMO objects) and PowerShell cmdlets, understand
how exceptions are caught:

**For .NET methods (.NET Framework/Core APIs and SMO):**
- Exceptions are **always caught** in try-catch blocks
- No need to set `$ErrorActionPreference` - the exceptions throw naturally
- Example: `$alertObject.Drop()`, `$database.Create()`, `[System.IO.File]::OpenRead()`

**For PowerShell cmdlets:**
- Use `-ErrorAction 'Stop'` to make errors catchable in try-catch
- **Do not** set `$ErrorActionPreference = 'Stop'` when using `-ErrorAction 'Stop'` - it's redundant
- Only set `$ErrorActionPreference = 'Stop'` if you need blanket error handling for multiple cmdlets

**Recommended pattern for .NET methods:**

This example shows a state-changing command using `$PSCmdlet.ThrowTerminatingError()`
in a catch block. This is acceptable for commands with `SupportsShouldProcess` where
operation failures must terminate. Note that callers must use `-ErrorAction 'Stop'`
to catch this error.

For non-state-changing commands (like Get/Test commands), prefer `Write-Error` in
catch blocks instead.

```powershell
try
{
    # .NET methods throw exceptions automatically - no ErrorActionPreference needed
    $alertObject.Drop()

    Write-Verbose -Message ($script:localizedData.AlertRemoved -f $alertObject.Name)
}
catch
{
    $errorMessage = $script:localizedData.RemoveFailed -f $alertObject.Name

    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
            'RSAA0001',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $alertObject
        )
    )
}
```

**Pattern for blanket error handling:**

Use `$ErrorActionPreference = 'Stop'` when you need blanket error handling for
multiple cmdlets or when calling commands that use `$PSCmdlet.ThrowTerminatingError()`:

```powershell
try
{
    $originalErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    # Multiple cmdlets without -ErrorAction on each
    $instance = Get-SqlDscManagedComputerInstance -InstanceName $InstanceName
    $protocol = Get-SqlDscServerProtocolName -ProtocolName $ProtocolName
    $serverProtocol = $instance.ServerProtocols[$protocol.ShortName]
}
catch
{
    # Handle error
}
finally
{
    $ErrorActionPreference = $originalErrorActionPreference
}
```

> [!NOTE]
> Setting `$ErrorActionPreference = 'Stop'` is particularly useful when calling
> commands that use `$PSCmdlet.ThrowTerminatingError()`. **Important:**
> Using `-ErrorAction 'Stop'` alone when calling such commands is NOT sufficient
> to stop the calling function - it will continue executing after the error.
> You must set `$ErrorActionPreference = 'Stop'` OR wrap the call in try-catch.

> [!TIP]
> **Prefer `Write-Error` in public commands instead of `$PSCmdlet.ThrowTerminatingError()`.**
> With `Write-Error`, callers can use `-ErrorAction 'Stop'` alone and it works as
> expected - the caller stops executing. This is standard PowerShell behavior and
> avoids the need for `$ErrorActionPreference` or try-catch in callers.

> [!IMPORTANT]
> **Do not** use the pattern `$ErrorActionPreference = 'Stop'` followed by
> `-ErrorAction 'Stop'` on the same cmdlet - this is redundant. The
> `-ErrorAction` parameter takes precedence over `$ErrorActionPreference`
> for that specific cmdlet call.

> [!NOTE]
> The pattern of setting `$ErrorActionPreference = 'Stop'` in a try block
> with restoration in finally is useful for:
> - Blanket error handling across multiple cmdlets
> - Catching errors from commands that use `$PSCmdlet.ThrowTerminatingError()`
>   (without this, those errors won't stop the caller)
> - However, it's NOT necessary for .NET method calls (they always throw) or
>   when using `-ErrorAction 'Stop'` on individual cmdlets.

##### Parameter Validation with ValidateScript

When using `[ValidateScript()]` attribute on parameters, you **must** use
`throw` for validation failures, as it is the only mechanism that works
within validation attributes:

```powershell
[Parameter()]
[ValidateScript({
        if (-not (Test-Path -Path $_))
        {
            throw ($script:localizedData.Audit_PathParameterValueInvalid -f $_)
        }

        return $true
    })]
[System.String]
$Path
```

This is the **only acceptable use** of `throw` in public commands and private
functions.

##### Exception Handling in Commands

When catching exceptions in try-catch blocks, re-throw errors using `Write-Error`
with the original exception:

```powershell
try
{
    $database.Create()
}
catch
{
    $errorMessage = $script:localizedData.CreateDatabaseFailed -f $DatabaseName

    Write-Error -Message $errorMessage -Category 'InvalidOperation' -ErrorId 'CD0001' -TargetObject $DatabaseName -Exception $_.Exception

    return
}
```

##### Pipeline Processing Considerations

For commands that accept pipeline input and process multiple items, use
`Write-Error` to allow processing to continue for remaining items:

```powershell
process
{
    foreach ($item in $Items)
    {
        if (-not (Test-ItemValid $item))
        {
            Write-Error -Message "Invalid item: $item" -Category 'InvalidData' -ErrorId 'PI0001' -TargetObject $item
            continue
        }

        # Process valid items
        Process-Item $item
    }
}
```

The caller can control whether to stop on first error or continue:

```powershell
# Continue processing all items, collect errors
$results = $items | Process-Items

# Stop on first error
$results = $items | Process-Items -ErrorAction 'Stop'
```

##### Summary

<!-- markdownlint-disable MD013 - Line length -->
| Scenario | Use | Why |
|----------|-----|-----|
| General error handling in public commands | `Write-Error` | Provides consistent, predictable behavior; allows caller to control termination |
| Pipeline processing with multiple items | `Write-Error` | Allows processing to continue for remaining items |
| Catching .NET method exceptions | try-catch without setting `$ErrorActionPreference` | .NET exceptions are always caught automatically |
| Blanket error handling for multiple cmdlets | Set `$ErrorActionPreference = 'Stop'` in try, restore in finally | Avoids adding `-ErrorAction 'Stop'` to each cmdlet; also catches ThrowTerminatingError from child commands |
| Single cmdlet error handling | Use `-ErrorAction 'Stop'` on the cmdlet | Simpler and more explicit than setting `$ErrorActionPreference` |
| Calling commands that use ThrowTerminatingError | Set `$ErrorActionPreference = 'Stop'` in caller OR wrap in try-catch | Using `-ErrorAction 'Stop'` alone is NOT sufficient; caller continues after error |
| Assert-style commands | `$PSCmdlet.ThrowTerminatingError()` | Command purpose is to throw on failure |
| State-changing commands (catch blocks) | `$PSCmdlet.ThrowTerminatingError()` | Prevents partial state changes; caller must set `$ErrorActionPreference = 'Stop'` OR wrap in try-catch |
| Private functions (internal use only) | `$PSCmdlet.ThrowTerminatingError()` or `Write-Error` | Behavior is understood by internal callers |
| Parameter validation in `[ValidateScript()]` | `throw` | Only valid option within validation attributes |
| Any other scenario in commands | Never use `throw` | Poor error messages; unpredictable behavior |
<!-- markdownlint-enable MD013 - Line length -->
