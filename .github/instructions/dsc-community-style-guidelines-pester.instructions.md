---
description: Guidelines for writing and maintaining tests using Pester.
applyTo: "**/*.[Tt]ests.ps1"
---

# Tests Guidelines

## Core Requirements
- All public commands, private functions and classes must have unit tests
- Use Pester v5 syntax only
- One `Describe` block per file matching the tested entity name
- Test code only inside `Describe` blocks
- Assertions only in `It` blocks
- Never test `Write-Verbose`, `Write-Debug`, or parameter binding behavior
- Pass all mandatory parameters to avoid prompts

## Structure & Scope
- Public commands: Never use `InModuleScope` (unless to get localized string)
- Private functions/class resources: Always use `InModuleScope`
- Each scenario = separate `Context` block
- Use nested `Context` blocks for complex scenarios
- Mocking in `BeforeAll` (`BeforeEach` only when required)
- Setup/teardown in `BeforeAll`,`BeforeEach`/`AfterAll`,`AfterEach` close to usage

## Syntax Rules
- PascalCase: `Describe`, `Context`, `It`, `Should`, `BeforeAll`, `BeforeEach`, `AfterAll`, `AfterEach`
- `It` descriptions start with 'Should'
- `Context` descriptions start with 'When'
- Mock variables prefix: 'mock'
- Prefer `-BeTrue`/`-BeFalse` over `-Be $true`/`-Be $false`
- No `Should -Not -Throw` - invoke commands directly

## File Organization
- Class resources: `tests/Unit/Classes/{Name}.Tests.ps1`
- Public commands: `tests/Unit/Public/{Name}.Tests.ps1`
- Private functions: `tests/Unit/Private/{Name}.Tests.ps1`

## Data-Driven Tests
- Define variables in separate `BeforeDiscovery` for `-ForEach` (close to usage)
- `-ForEach` allowed on `Context` and `It` blocks
- Keep scope close to usage context

## Best Practices
- Assign unused return objects to `$null`
- Tested entity must be called from within the `It` blocks
- Keep results and assertions in same `It` block
- Cover all scenarios and code paths
- Use `BeforeEach` and `AfterEach` sparingly
