# AI Instructions for SqlServerDsc

This file provides AI agent guidance for the SqlServerDsc project. Each
instruction file below targets specific file glob patterns and use cases.

## Instructions Overview

The guidelines always take priority over existing code patterns in project.

- SqlServerDsc-specific guidelines override general project guidelines
- Follow PowerShell style guidelines
- Maintain localization requirements across all source files
- Follow test patterns strictly for maintainability

## Core Project Guidelines

- Follow SqlServerDsc project specific guidelines: [./instructions/SqlServerDsc-guidelines.instructions.md](./instructions/SqlServerDsc-guidelines.instructions.md)
- Always follow PowerShell code style guidelines: [./instructions/dsc-community-style-guidelines-powershell.instructions.md](./instructions/dsc-community-style-guidelines-powershell.instructions.md)
- Follow Project-level guidelines: [./instructions/dsc-community-style-guidelines.instructions.md](./instructions/dsc-community-style-guidelines.instructions.md)
- Follow localization requirements: [./instructions/dsc-community-style-guidelines-localization.instructions.md](./instructions/dsc-community-style-guidelines-localization.instructions.md)
- Always add Unit testing according to: [./instructions/dsc-community-style-guidelines-unit-tests.instructions.md](./instructions/dsc-community-style-guidelines-unit-tests.instructions.md)
- Always add Integration testing according to: [./instructions/dsc-community-style-guidelines-integration-tests.instructions.md](./instructions/dsc-community-style-guidelines-integration-tests.instructions.md)
- Follow Markdown formatting requirements: [./instructions/dsc-community-style-guidelines-markdown.instructions.md](./instructions/dsc-community-style-guidelines-markdown.instructions.md)
- Always update CHANGELOG.md: [./instructions/dsc-community-style-guidelines-changelog.instructions.md](./instructions/dsc-community-style-guidelines-changelog.instructions.md)

## Desired State Configuration (DSC) Resource Guidelines

New DSC resources should always be created as class-based resources.

Follow class-based resources guidelines: [./instructions/dsc-community-style-guidelines-class-resource.instructions.md](./instructions/dsc-community-style-guidelines-class-resource.instructions.md)
