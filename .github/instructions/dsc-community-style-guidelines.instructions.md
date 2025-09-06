---
description: Core DSC community guidelines for AI development.
applyTo: "**"
---

# DSC Community Guidelines

## Terminology
- **Command**: Public command
- **Function**: Private function
- **Resource**: DSC class-based resource

## Build & Test Workflow
- Run in PowerShell, from repository root
- Build before running tests: `.\build.ps1 -Tasks build`
- Always run tests in new PowerShell session: `Invoke-Pester -Path @({test paths}) -Output Detailed`

## File Organization
- Public commands: `source/Public/{CommandName}.ps1`
- Private functions: `source/Private/{FunctionName}.ps1`
- Unit tests: `tests/Unit/{Classes|Public|Private}/{Name}.Tests.ps1`
- Integration tests: `tests/Integration/Commands/{CommandName}.Integration.Tests.ps1`

## Requirements
- Follow instructions over existing code patterns
- Follow PowerShell style and test guideline instructions strictly
- Always update CHANGELOG.md Unreleased section
- Localize all strings using string keys; remove any orphaned string keys
- Check DscResource.Common before creating private functions
- Separate reusable logic into private functions
- DSC resources should always be created as class-based resources
- Add unit tests for all commands/functions/resources
- Add integration tests for all public commands and resources
