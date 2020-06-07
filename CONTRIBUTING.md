# Contributing to SqlServerDsc

If you are keen to make SqlServerDsc better, why not consider contributing your work
to the project? Every little change helps us make a better resource for everyone
to use, and we would love to have contributions from the community.

## Core contribution guidelines

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Running the Tests

If want to know how to run this module's tests you can look at the [Testing Guidelines](https://dsccommunity.org/guidelines/testing-guidelines/#running-tests)

## Specific guidelines for SqlServerDsc

### Automatic formatting with VS Code

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

The `SqlServerEndpointPermission` resource name is built using the defined
naming structure using the following components.

- **Module Identifier**: Sql
- **Component**: \<blank\>
- **Action**: \<none\>
- **Scope**: Server
- **Feature**: Endpoint
- **Property**: Permission

#### mof-based resource

All mof-based resource (with Get/Set/Test-TargetResource) should be prefixed with
'DSC\_Sql'. I.e. DSC\_SqlDatabase

Please note that not all places should contain the prefix 'DSC\_'.

##### Folder and file structure

Please note that for the examples folder we don't use the 'DSC\_' prefix on the
resource folders.
This is to make those folders more user friendly, to resemble the name the user
would use in the configuration file.

```Text
DSCResources/DSC_SqlConfiguration/DSC_SqlConfiguration.psm1
DSCResources/DSC_SqlConfiguration/DSC_SqlConfiguration.schema.mof
DSCResources/DSC_SqlConfiguration/en-US/DSC_SqlConfiguration.strings.psd1

Tests/Unit/DSC_SqlConfiguration.Tests.ps1

Examples/Resources/SqlConfiguration/1-AddConfigurationOption.ps1
Examples/Resources/SqlConfiguration/2-RemoveConfigurationOption.ps1
```

##### Schema mof file

Please note that the `FriendlyName` in the schema mof file should not contain the
prefix `DSC\_`.

```powershell
[ClassVersion("1.0.0.0"), FriendlyName("SqlConfiguration")]
class DSC_SqlConfiguration : OMI_BaseResource
{
    # Properties removed for readability.
};
```

#### Composite or class-based resource

Any composite (with a Configuration) or class-based resources should be prefixed
with just 'Sql'

### Localization

In each resource folder there should be, at least, a localization folder for
english language 'en-US'.
In the 'en-US' (and any other language folder) there should be a file named
'DSC_ResourceName.strings.psd1', i.e.
'DSC_SqlSetup.strings.psd1'.
At the top of each resource the localized strings should be loaded, see the helper
function `Get-LocalizedData` for more information on how this is done.

The localized string file should contain the following (beside the localization
strings)

```powershell
# Localized resources for SqlSetup

ConvertFrom-StringData @'
    InstallingUsingPathMessage = Installing using path '{0}'.
'@
```

### Helper functions

Helper functions or wrapper functions that are used only by the resource can preferably
be placed in the resource module file. If the functions are of a type that could
be used by more than
one resource, then the functions can also be placed in the common module
[SqlServerDsc.Common](https://github.com/dsccommunity/SqlServerDsc/blob/master/source/Modules/SqlServerDsc.Common)
module file.

### Unit tests

For a review of a Pull Request (PR) to start, all tests must pass without error.
If you need help to figure why some test don't pass, just write a comment in the
Pull Request (PR), or submit an issue, and somebody will come along and assist.

#### Unit tests for examples files

When sending in a Pull Request (PR) all example files will be tested so they can
be compiled to a .mof file. If the tests find any errors the build will fail.

### Integration tests

Integration tests should be written for resources so they can be validated by
the CI.

There are also configuration made by existing integration tests that can be reused
to write integration tests for other resources. This is documented in
[Integration tests for SqlServerDsc](https://github.com/PowerShell/SqlServerDsc/blob/dev/Tests/Integration/README.md).

#### Using SMO stub classes

There are [stub classes](https://github.com/PowerShell/SqlServerDsc/blob/dev/Tests/Unit/Stubs/SMO.cs)
for the SMO classes which can be used and improved on when creating tests where
SMO classes are used in the code being tested.

### Documentation with Markdown

If using Visual Studio Code to edit Markdown files it can be a good idea to install
the markdownlint extension. It will help to do style checking.
The file [.markdownlint.json](/.markdownlint.json) is prepared with a default set
of rules which will automatically be used by the extension.
