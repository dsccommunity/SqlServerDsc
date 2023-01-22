# Stubs

A stub function is command or class with just the skeleton of the original
command or class. Stubs make it possible to run unit tests without having
the actual module with the command or class installed. It also helps that
all contributors have the same stubs to test against that is a reflection
of the real module.

For example, Pester can use a stub function to have something to hook onto
when mocking a command in a unit test. Then there is no need to modify the
computer running the tests to actually have the real module or class available,
it makes it safe to run the unit tests on development machines.

## How to

### Generate stub module

#### Generate module

> These steps replaces the script file [`Write-ModuleStubFile`](https://github.com/dsccommunity/SqlServerDsc/blob/bed3b1267591ac4351de68eb04ddd22272d2926f/tests/Unit/Stubs/Write-ModuleStubFile.ps1#L17-L187).

Install the module _Indented.StubCommand_ from PowerShell Gallery.

```powershell
Install-Module -Name 'Indented.StubCommand' -Scope 'CurrentUser'
```

Install the necessary modules to create stubs from. Install the latest
version of the _SQL Server_ Database Engine to get the latest version of
module _SQLPS_. For the latest (preview) version of module _SqlServer_ run:

<!-- markdownlint-disable MD013 - Line length -->
```powershell
Install-Module -Name 'SqlServer' -Scope 'CurrentUser' -AllowClobber -AllowPrerelease -Force
```
<!-- markdownlint-enable MD013 - Line length -->

Create the stub modules in the repository's `tests/Unit/Stubs` folder by
running the below script. For safety, repeat the script in a individual
PowerShell session for each module (since the commands have the same names
in both modules).

```powershell
$destinationFolder = 'tests/Unit/Stubs'

$functionBody = {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            'StubNotImplemented',
            'StubCalledError',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $MyInvocation.MyCommand
        )
    )
}

$sqlTypeDefinition = @(
    @{
        ReplaceType = 'Microsoft\.AnalysisServices\.[.\w]*'
        WithType    = 'System.Object'
    }
    @{
        ReplaceType = 'Microsoft\.AnalysisServices\.[.\w]*\[\]'
        WithType    = 'System.Object[]'
    }
    @{
        ReplaceType = 'Microsoft\.SqlServer\.[.\w]*'
        WithType    = 'System.Object'
    }
    @{
        ReplaceType = 'Microsoft\.SqlServer\.[.\w]*\[\]'
        WithType    = 'System.Object[]'
    }
    @{
        ReplaceType = 'System\.Nullable\[Microsoft\.Data\.[.\w]*]'
        WithType    = 'System.Object'
    },
    @{
        ReplaceType = 'System\.Nullable\[Microsoft\.Data\.[.\w]*\[\]]'
        WithType    = 'System.Object[]'
    }
)

# Set FromModule to either SqlServer or SQLPS.
$newStubModuleParameters = @{
    FromModule            = 'SqlServer'
    Path                  = $destinationFolder
    FunctionBody          = $functionBody
    ReplaceTypeDefinition = $sqlTypeDefinition
}

New-StubModule @newStubModuleParameters
```

#### Rename the module

The generated module is named `SqlServer.psm1` or `SQLPS.psm1`. Rename
the file so that they are easily distinguished among a PowerShell sessions
loaded module:
Generated Name | New name
--- | ---
SqlServer.psm1 | SqlServerStub.psm1
SQLPS.psm1 | SQLPSStub.psm1

#### Stub module customization

In Visual Studio Code, open the generated file. At the top of the file,
remove the code beginning with `Add-Type` and continues with a here-string
that ends just before the first command. Remove all that code.

>All the removed types are are generated into a separate stub C# file (`SMO.cs`).
>See [Generate SMO stubs](#generate-smo-stubs) for more information.

<!-- markdownlint-disable MD033 - Line length -->
In Visual Studio Code, open the generated file. Format the document by pressing
(on Windows) <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>F</kbd>. It also possible
from the Command Palette <kbd>F1</kbd> or <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd>,
then search for `Format Document`.
<!-- markdownlint-enable MD033 - Line length -->

### Generate SMO stubs

_Not yet written._
