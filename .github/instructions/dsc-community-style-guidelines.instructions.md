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
- Run project scripts in PowerShell from repository root
- Build after source changes: `.\build.ps1 -Tasks build`
- Test workflow: Build → `Invoke-Pester -Path @('<test paths>') -Output Detailed`
- New session required after class changes

## File Organization
- Public commands: `source/Public/{CommandName}.ps1`
- Private functions: `source/Private/{FunctionName}.ps1`
- Unit tests: `tests/Unit/{Classes|Public|Private}/{Name}.Tests.ps1`
- Integration tests: `tests/Integration/Commands/{CommandName}.Integration.Tests.ps1`

## Requirements
- Follow guidelines over existing code patterns
- Always update CHANGELOG.md Unreleased section
- Localize all strings using string keys
- Check DscResource.Common before creating private functions
- Separate reusable logic into private functions
- Add unit tests for all commands/functions/resources
- Add integration tests for all public commands and resources
