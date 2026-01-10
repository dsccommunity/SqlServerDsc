---
description: Guidelines for writing and maintaining tests using Pester.
applyTo: "**/*.[Tt]ests.ps1"
---

# Tests Guidelines

## Core Requirements
- All public commands, private functions and classes must have unit tests
- All public commands and class-based resources must have integration tests
- Use Pester v5 syntax only
- Test code only inside `Describe` blocks
- Assertions only in `It` blocks
- Never test verbose messages, debug messages or parameter binding behavior
- Pass all mandatory parameters to avoid prompts

## Requirements
- Inside `It` blocks, assign unused return objects to `$null` (unless part of pipeline)
- Tested entity must be called from within the `It` blocks
- Keep results and assertions in same `It` block
- Avoid try-catch-finally for cleanup, use `AfterAll` or `AfterEach`
- Avoid unnecessary remove/recreate cycles

## Naming
- One `Describe` block per file matching the tested entity name
- `Context` descriptions start with 'When'
- `It` descriptions start with 'Should', must not contain 'when'
- Mock variables prefix: 'mock'

## Structure & Scope
- Public commands: Never use `InModuleScope` (unless retrieving localized strings or creating an object using an internal class)
- Private functions/class resources: Always use `InModuleScope`
- Each class method = separate `Context` block
- Each scenario = separate `Context` block
- Use nested `Context` blocks for complex scenarios
- Mocking in `BeforeAll` (`BeforeEach` only when required)
- Setup/teardown in `BeforeAll`,`BeforeEach`/`AfterAll`,`AfterEach` close to usage
- Spacing between blocks, arrange, act, and assert for readability

## Syntax Rules
- PascalCase: `Describe`, `Context`, `It`, `Should`, `BeforeAll`, `BeforeEach`, `AfterAll`, `AfterEach`
- Use `-BeTrue`/`-BeFalse` never `-Be $true`/`-Be $false`
- Never use `Assert-MockCalled`, use `Should -Invoke` instead
- No `Should -Not -Throw` - invoke commands directly
- Never add an empty `-MockWith` block
- Omit `-MockWith` when returning `$null`
- Set `$PSDefaultParameterValues` for `Mock:ModuleName`, `Should:ModuleName`, `InModuleScope:ModuleName`
- Omit `-ModuleName` parameter on Pester commands
- Never use `Mock` inside `InModuleScope`-block
- Never use `param()` inside `-MockWith` scriptblocks, parameters are auto-bound

## File Organization
- Class resources: `tests/Unit/Classes/{Name}.Tests.ps1`
- Public commands: `tests/Unit/Public/{Name}.Tests.ps1`
- Private functions: `tests/Unit/Private/{Name}.Tests.ps1`

## Data-Driven Tests (Test Cases)
- Define `-ForEach` variables in `BeforeDiscovery` (close to usage)
- `-ForEach` allowed on `Context` and `It` blocks
- Never add `param()` inside Pester blocks when using `-ForEach`
- Access test case properties directly: `$PropertyName`

## Best Practices
- Cover all scenarios and code paths
- Use `BeforeEach` and `AfterEach` sparingly
- Use `$PSDefaultParameterValues` only for Pester commands (`Describe`, `Context`, `It`, `Mock`, `Should`, `InModuleScope`)
