# AI Instructions for SqlServerDsc

This file provides AI agent guidance for the SqlServerDsc project. Each instruction file below targets specific file glob patterns and use cases.

## Instruction File Reference

- Always check file patterns to determine applicable instructions
- SqlServerDsc-specific rules override general DSC Community guidelines
- Maintain localization requirements across all source files
- Follow test patterns strictly for maintainability

## Usage Priority

1. [SqlServerDsc Guidelines](instructions/SqlServerDsc-guidelines.instructions.md) - Always apply first for SqlServerDsc-specific requirements
2. **File-type specific guidelines** - Apply based on glob pattern and type
3. **General guidelines** - Apply as baseline for all files

### Core Project Guidelines

- [SqlServerDsc Guidelines](instructions/SqlServerDsc-guidelines.instructions.md) (`**/*.psm1,**/*.psd1,**/*.ps1`)
  - SqlServerDsc-specific rules: public command naming (SqlDsc prefix), SQL Server Management Objects (SMO) preference, integration test environments
  - Use for: All PowerShell files requiring SqlServerDsc-specific patterns

- [DSC Community Style Guidelines](instructions/dsc-community-style-guidelines.instructions.md) (`**`)
  - Project-level guidelines: build scripts, testing, localization requirements
  - Use for: General project structure and workflow guidance

### PowerShell Code Guidelines

- [DSC Community Style Guidelines - PowerShell](instructions/dsc-community-style-guidelines-powershell.instructions.md) (`**/*.psm1,**/*.psd1,**/*.ps1`)
  - Core PowerShell style: naming conventions, formatting, indentation, braces, quotes
  - Use for: All PowerShell code formatting and style

### DSC Resource Guidelines

- [DSC Community Style Guidelines - Class Resource](instructions/dsc-community-style-guidelines-class-resource.instructions.md) (`source/[cC]lasses/**/*.ps1`)
  - Class-based DSC resources: inheritance patterns, method overrides, ResourceBase usage
  - Use for: Files in source/Classes/ decorated with `[DscResource(...)]`

- [DSC Community Style Guidelines - MOF Resources](instructions/dsc-community-style-guidelines-mof-resources.instructions.md) (`source/DSCResources/**/*.psm1`)
  - MOF-based DSC resources: required functions, return types, error handling
  - Use for: Traditional DSC resources in source/DSCResources/

### Localization Guidelines

- [DSC Community Style Guidelines - Localization](instructions/dsc-community-style-guidelines-localization.instructions.md) (`source/**/*.ps1`)
  - General localization requirements for all source files
  - Use for: Any source file requiring localized strings

- [DSC Community Style Guidelines - Command Localization](instructions/dsc-community-style-guidelines-command-localization.instructions.md) (`source/[pP]ublic/**/*.ps1,source/[pP]rivate/**/*.ps1`)
  - Command-specific localization: string key naming, SqlServerDsc.strings.psd1 usage
  - Use for: Public commands and private functions

- [DSC Community Style Guidelines - MOF Resource Localization](instructions/dsc-community-style-guidelines-mof-resource-localization.instructions.md) (`source/DSCResources/**/*.psm1,source/DSCResources/**/*.strings.psd1`)
  - MOF resource localization: file structure, string ID format, usage patterns
  - Use for: Traditional DSC resource localization files

### Test Guidelines

- [DSC Community Style Guidelines - Tests](instructions/dsc-community-style-guidelines-tests.instructions.md) (`tests/**/*.[Tt]ests.ps1`)
  - General test patterns: Pester v5 syntax, Describe/Context/It structure, formatting
  - Use for: All test files

- [DSC Community Style Guidelines - Command Unit Tests](instructions/dsc-community-style-guidelines-command-unit-tests.instructions.md) (`tests/[uU]nit/[pP]ublic/**/*.[tT]ests.ps1,tests/[uU]nit/[pP]rivate/**/*.[tT]ests.ps1`)
  - Unit test specifics: parameter validation, mocking patterns, coverage requirements
  - Use for: Unit tests for public commands and private functions

- [DSC Community Style Guidelines - Command Integration Tests](instructions/dsc-community-style-guidelines-command-integration-tests.instructions.md) (`tests/[iI]ntegration/[cC]ommands/**/*.[iI]ntegration.[tT]ests.ps1`)
  - Integration test patterns: environment setup, real testing, naming conventions
  - Use for: Integration tests for public commands

### Documentation Guidelines

- [DSC Community Style Guidelines - Changelog](instructions/dsc-community-style-guidelines-changelog.instructions.md) (`CHANGELOG.md`)
  - Changelog format: keepachangelog format, issue references, concrete descriptions
  - Use for: CHANGELOG.md updates

- [DSC Community Style Guidelines - Markdown](instructions/dsc-community-style-guidelines-markdown.instructions.md) (`**/*.md`)
  - Markdown formatting: line wrapping (80 chars), indentation (2 spaces)
  - Use for: All Markdown documentation
