---
description: Guidelines for implementing localization.
applyTo: "source/**/*.ps1"
---

# Localization Style Guidelines

For public commands and private functions you should always add all localized
strings for in the source/en-US/SqlServerDsc.strings.psd1 file, re-use the
same pattern for new string keys. Localized string key names should always
be prefixed with the function name but use underscore as word separator.
Always assume that all localized string keys have already been assigned to
the variable $script:localizedData.

All message strings for Write-Debug, Write-Verbose, Write-Error, Write-Warning
and other error messages in classes, public commands and private functions should
be localized using localized string keys.

## String File Format
```powershell
# Localized resources for <ResourceName>
ConvertFrom-StringData @'
    KeyName = Message with {0} placeholder. (PREFIX0001)
'@
```

## String ID Format
Use unique IDs: `(PREFIX####)`
- PREFIX: First letter of each word in resource name or function name
- ####: Sequential number starting 0001
- Examples: SqlSetup → SS0001, SqlAGDatabase → SAGD0001, Get-SqlDscSqlDatabase → GSDSD0001

## Usage Patterns
```powershell
# Verbose/Warning messages
Write-Verbose -Message ($script:localizedData.KeyName -f $value)
Write-Warning -Message ($script:localizedData.KeyName -f $value)

# Error messages
New-InvalidOperationException -Message ($script:localizedData.KeyName -f $value1, $value2)
New-InvalidOperationException -ErrorRecord $_ -Message ($script:localizedData.KeyName -f $value1)
```
