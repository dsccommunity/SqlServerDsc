# Welcome to the SqlServerDsc wiki

<sup>*SqlServerDsc v#.#.#*</sup>

Here you will find all the information you need to make use of the SqlServerDsc
DSC resources in the latest release. This includes details of the resources
that are available, current capabilities, known issues, and information to
help plan a DSC based implementation of SqlServerDsc.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.com/dsccommunity/SqlServerDsc/issues)
for this repository.

## Deprecated resources

The documentation, examples, unit test, and integration tests have been removed
for these deprecated resources. These resources will be removed
in a future release.

*No resources are currently deprecated.*

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name SqlServerDsc -Repository PSGallery
```

- Download SqlServerDsc from the [PowerShell Gallery](https://www.powershellgallery.com/packages/SqlServerDsc)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

To confirm installation, run the below command and ensure you see the SqlServerDsc
DSC resources available:

```powershell
Get-DscResource -Module SqlServerDsc
```

## Prerequisites

- Familiarity with Powershell DSC Framework
- Powershell 5.0 or higher
- PowerShell module containing SMO assemblies (optional)
  - For example the SqlServer PowerShell module or the dbatools PowerShell
    module.

### Familiarity with Powershell DSC Framework

SqlServerDSC implements configuration management for *Microsoft SQL Server*
using the [Powershell DSC](https://docs.microsoft.com/en-us/search/?terms=Desired%20State%20Configuration&scope=PowerShell)
technology developed by Microsoft. A [community](https://dsccommunity.org/)
maintains [resources](https://www.powershellgallery.com/packages?q=Tags%3A%22DSCResource%22)
that can be used by [configuration automation tools](https://dsccommunity.org/configmgt/)
from various companies.

### Powershell

It is recommended to use Windows Management Framework (PowerShell) version 5.1.

The minimum Windows Management Framework (PowerShell) version required is 5.0,
which ships with Windows 10 or Windows Server 2016, but can also be installed
on Windows 7 SP1, Windows 8.1, Windows Server 2012, and Windows Server 2012 R2.

These resource might not work on PowerShell 7.x because they depend on
*SQL Server* modules which only works in PowerShell 5.x.

### PowerShell module containing SMO assemblies (optional)

There are two options, installing the [*SqlServer*](https://www.powershellgallery.com/packages/SqlServer)
*PowerShell* module or the *dbatools PowerShell* module.

If the *SqlServer* module is present it will be used instead of *SQLPS*
automatically.

To use the [*dbatools*](https://www.powershellgallery.com/packages/dbatools)
module as a replacement for *SQLPS* the environment variable `SMODefaultModuleName`
must be set to the value `dbatools`. This environment variable can be set
machine-wide, or at minimum set for each user that runs DSC resources, on
the target node. Make sure you comply with any license terms that is part
of dbatools.

> [!TIP]
> It is also possible to use any module as a preferred module if
> its name is set as the value of the environment variable `SMODefaultModuleName`.

## Change log

A full list of changes in each version can be found in the [change log](https://github.com/dsccommunity/SqlServerDsc/blob/main/CHANGELOG.md).
