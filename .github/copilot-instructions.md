# Specific instructions for the PowerShell module project SqlServerDsc

Assume that the word "command" references to a public command, the word
"function" references to a private function, and the word "resource"
references a Desired State Configuration (DSC) class-based resource.

## Public commands

PowerShell commands that should be public should always have its separate
script file and the command name as the file name with the .ps1 extension,
these files shall always be placed in the folder source/Public.

Public commands may use private functions to move out logic that can be
reused by other public commands, so move out any logic that can be deemed
reusable.

## Private functions

Private functions (also known as helper functions) should always have its
separate script file and the function name as the file name with the .ps1
extension. These files shall always be placed in the folder source/Private.
This also applies to functions that are only used within a single public
command.

## Localization

All strings in public commands, private functions and classes should be localized
using localized string keys.

### Public Commands and Private Functions

For detailed localization guidelines for commands and functions, refer to the
[Command Localization Style Guidelines](instructions/dsc-community-style-guidelines-command-localization.instructions.md).

### Classes

For detailed localization guidelines for classes, refer to the
[Class Localization Style Guidelines](instructions/dsc-community-style-guidelines-class-localization.instructions.md).

## Unit tests

Unit tests should be added for all public commands, private functions and
class-based resources.

The unit tests for class-based resources should be
placed in the folder tests/Unit/Classes.
The unit tests for public command should be placed in the folder tests/Unit/Public.
The unit tests for private functions should be placed in the folder tests/Unit/Private.

For detailed unit test guidelines and code templates, refer to the
[Command Unit Test Style Guidelines](instructions/dsc-community-style-guidelines-command-unit-tests.instructions.md).


### Integration tests

All public commands must have an integration test in the folder "tests/Integration/Commands"

For detailed integration test guidelines and code templates, refer to the
[Command Integration Test Style Guidelines](instructions/dsc-community-style-guidelines-command-integration-tests.instructions.md).
