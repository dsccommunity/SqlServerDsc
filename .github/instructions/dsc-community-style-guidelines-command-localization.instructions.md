---
applyTo: "source/[pP]ublic/**/*.ps1,source/[pP]rivate/**/*.ps1"
---

# Command Localization Style Guidelines

For public commands and private functions you should always add all localized
strings for in the source/en-US/SqlServerDsc.strings.psd1 file, re-use the
same pattern for new string keys. Localized string key names should always
be prefixed with the function name but use underscore as word separator.
Always assume that all localized string keys have already been assigned to
the variable $script:localizedData.
