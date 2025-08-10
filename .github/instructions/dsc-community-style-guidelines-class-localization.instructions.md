---
applyTo: "source/[cC]lasses/**/*.ps1"
---

# Class Localization Style Guidelines

All message strings for Write-Debug, Write-Verbose, Write-Error, Write-Warning
and other error messages in classes should be localized using localized string keys.

For class-based resource you should always add a localized strings in a
separate file the folder source\en-US. The strings file for a class-based
resource should be named to exactly match the resource class name with the
suffix `.strings.psd1`.
Localized string key names should use underscore as word separator if key
name has more than one word. Always assume that all localized string keys
for a class-based resource already have been assigned to the variable
`$this.localizedData` by the parent class.
