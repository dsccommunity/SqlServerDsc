---
description: Guidelines for implementing localization.
applyTo: "source/**/*.ps1"
---

# Localization Guidelines

## Requirements
- Localize all Write-Debug, Write-Verbose, Write-Error, Write-Warning and $PSCmdlet.ThrowTerminatingError() messages
- Use localized string keys, not hardcoded strings
- Assume `$script:localizedData` is available

## String Files
- Commands/functions: `source/en-US/{MyModuleName}.strings.psd1`
- Class resources: `source/en-US/{ResourceClassName}.strings.psd1`

## Key Naming Patterns
- Format: `Verb_FunctionName_Action` (underscore separators), e.g. `Get_Database_ConnectingToDatabase`

## String Format
```powershell
ConvertFrom-StringData @'
    KeyName = Message with {0} placeholder. (PREFIX0001)
'@
```

## String IDs
- Format: `(PREFIX####)`
- PREFIX: First letter of each word in class or function name (SqlSetup → SS, Get-SqlDscDatabase → GSDD)
- Number: Sequential from 0001

## Usage
```powershell
Write-Verbose -Message ($script:localizedData.KeyName -f $value1)
```
