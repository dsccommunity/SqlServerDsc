---
description: Guidelines for implementing localization for MOF DSC resources.
applyTo: "source/DSCResources/**/*.psm1,source/DSCResources/**/*.strings.psd1"
---

# MOF Desired State Configuration (DSC) Resource Localization

## File Structure
- Create `en-US` folder in each resource directory
- Name strings file: `DSC_<ResourceName>.strings.psd1`
- Use names returned from `Get-UICulture` for additional language folder names

## String File Format
```powershell
# Localized resources for <ResourceName>
ConvertFrom-StringData @'
    KeyName = Message with {0} placeholder. (PREFIX0001)
'@
```

## String ID Format
Use unique IDs: `(PREFIX####)`
- PREFIX: First letter of each word in resource name
- ####: Sequential number starting 0001
- Examples: SqlSetup → SS0001, SqlAGDatabase → SAGD0001

## Usage Patterns
```powershell
# Verbose/Warning messages
Write-Verbose -Message ($script:localizedData.KeyName -f $value)
Write-Warning -Message ($script:localizedData.KeyName -f $value)

# Error messages
New-InvalidOperationException -Message ($script:localizedData.KeyName -f $value1, $value2)
New-InvalidOperationException -ErrorRecord $_ -Message ($script:localizedData.KeyName -f $value1)
```
