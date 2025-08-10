---
applyTo: "source/DSCResources/**/*.psm1,source/DSCResources/**/*.strings.psd1"
---

# Localization folder structure for MOF-based DSC resources

In each resource folder there should be at least one localization folder for
english language 'en-US'. Add other localization folders as appropriate, the
correct folder name can be found by running `Get-UICulture` on the node that
has a UI culture installed that the strings are being built for.
There is also the list of
[Available Language Packs for Windows](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/available-language-packs-for-windows#language-packs).

In each localization folder there should be a PowerShell data (.psd1) file named
'DSC_\<ResourceName\>.strings.psd1' (e.g. 'DSC_Folder.strings.psd1').
Each localized string file should contain the following with the correct
localization key and accompanying localization string value (the example uses
the friendly resource name of 'Folder').

```powershell
# Localized resources for Folder

ConvertFrom-StringData @'
    CreateFolder = Creating folder at path '{0}'. (F0001)
    RetrievingFolderInformation = Retrieving folder information from path '{0}'. (F0002)
    ProblemAccessFolder = Could not access the requested path '{0}'. (F0003)
    FailedToReadProperties = Could not read property '{0}' of path '{1}'. (F0004)
'@
```

When using the previous example, the folder structure would look like the
following:

```plaintext
DSCResources\DSC_Folder\en-US\DSC_Folder.strings.psd1
DSCResources\DSC_Folder\es-ES\DSC_Folder.strings.psd1
```

To use the localization strings in a resource, then localization strings are
imported at the top of each resource PowerShell module script file (.psm1). The
localized strings should be imported using [`Get-LocalizedData`](#get-localizeddata).

## Localization string ID suffix

To easier debug localized verbose logs, and to find the correct localized string
key in the code, it is recommended to use a hard coded ID on each localized key's
string value. That ID must be the same across the localized language files,
and it is not recommended to reuse ID's once they become obsolete (because of
for example code change).

> Using this method we could also test that each localized string is
> represented in each language specific localization file for that
> resource.

**Format:** `(ID:yyyyZZZZ)`

- 'yyyy' - The resource name prefix. It is composed of every first letter of
   every word in the resource friendly name.
- 'ZZZZ' - The suffix is a serial number starting from '0001'.

**Example of prefixes:**

Module | Resource | ID prefix (yyyy) | First string ID suffix
--- | --- | --- | ---
PSDscResources | GroupResource | GR | `(GR0001)`
PSDscResources | WindowsOptionalFeature | WOF | `(WOF0001)`
SqlServerDsc | SqlSetup | SS | `(SS0001)`
SqlServerDsc | SqlAGDatabase| SAGD | `(SAGD0001)`
NetworkingDsc | DnsClientGlobalSetting | DCGS | `(DCGS0001)`
NetworkingDsc | Firewall | F | `(F0001)`
CertificateDsc | PfxImport | PI | `(PI0001)`
CertificateDsc | WaitForCertificateServices | WFCS | `(WFCS0001)`

**Example of usage:**

See example of localized strings under [Localization](#localization).

## Using localization string in code

This is an example of how to write localized verbose messages.

```powershell
Write-Verbose -Message `
    ($script:localizedData.RetrievingFolderInformation -f $path)
```

This is an example of how to write localized warning messages.

```powershell
Write-Warning -Message `
    ($script:localizedData.ProblemAccessFolder -f $path)
```

This is an example of how to throw localized error messages, but the
[helper functions](#helper-functions-for-localization)
[`New-InvalidArgumentException`](#new-invalidargumentexception),
[`New-InvalidOperationException`](#new-invalidoperationexception),
[`New-ObjectNotFoundException`](#new-objectnotfoundexception) and
[`New-InvalidResultException`](#new-invalidresultexception)
should preferably be used whenever possible.

```powershell
throw ($script:localizedData.FailedToReadProperties -f $property, $path)
```

### Cmdlets for localization

The module [DscResource.Common](https://github.com/dsccommunity/DscResource.Common)
has cmdlets that help with localization. See the [cmdlet documentation](https://github.com/dsccommunity/DscResource.Common#cmdlet)
for more information how to use the cmdlets. The module is also release to the
[PowerShell Gallery](https://www.powershellgallery.com/packages/DscResource.Common).
