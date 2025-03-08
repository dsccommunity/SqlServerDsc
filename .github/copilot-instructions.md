# Specific instructions for the PowerShell module project SqlServerDsc

Assume that the word "command" references to a public command, and the word
"function" references to a private function.

PowerShell commands that should be public should always have its separate
script file and the the command name as the file name with the .ps1 extension,
these files shall always be placed in the folder source/Public.

Public commands may use private functions to move out logic that can be
reused by other public commands, so move out any logic that can be deemed
reusable. Private functions should always have its separate script file and
the the function name as the file name with the .ps1 extension, these files
shall always be placed in the folder source/Private.

Comment-based help should be added to each public command and private functions.
The comment-based help should always be before the function-statement. Each
comment-based help keyword should be indented with 4 spaces and each keywords
text should be indented 8 spaces. The text for keyword .DESCRIPTION should
be descriptive and must have a length greater than 40 characters. A comment-based
help must have at least one example, but preferably more examples to showcase
all possible parameter sets and different parameter combinations.

All message strings for Write-Debug, Write-Verbose, Write-Error, Write-Warning
and other error messages in public commands and private functions should be
localized using localized string keys. You should always add all localized
strings for public commands and private functions in the source/en-US/SqlServerDsc.strings.psd1
file, re-use the same pattern for new string keys. Localized string key names
should always be prefixed with the function name but use underscore as word
separator. Always assume that all localized string keys have already been
assigned to the variable $script:localizedData.
