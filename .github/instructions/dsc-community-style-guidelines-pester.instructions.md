---
description: Guidelines for writing and maintaining tests using Pester.
applyTo: "**"
---

# Tests Guidelines

All tests must use the Pester framework and Pester v5 syntax.

Do not test PowerShell’s runtime parameter binding behavior (e.g., type
conversion or binder errors). Instead, validate parameter sets and parameter
metadata (e.g., Mandatory, ValueFromPipeline) as instructed below.

Test code should never be added outside the `Describe` block.
Assertions must always be made in `It` blocks.
Never use `InModuleScope` when testing public commands.
Always use `InModuleScope` when testing private functions or class-based resources.
The `BeforeAll` or `BeforeEach` block should be used to set up any necessary test data or mocking
Tear-down of any test data or objects should be done in the `AfterAll` or `AfterEach` block.

There should be only one Pester `Describe` block per test file, and its name
must match the public command, private function, or class-based resource
being tested. Each scenario or code path should have its own Pester `Context`
block. Use nested `Context` blocks to split up test cases and improve test readability.
`It` blocks must call the command or function being tested, and keep the result
and assertions in the same `It` block.

The `BeforeAll`, `BeforeEach`, `AfterAll`, and `AfterEach` blocks should be
used inside the `Context` block as close as possible to the `It` block that
uses the test data, setup, and teardown. Use `AfterAll` to clean up any test
data. Use `BeforeEach` and `AfterEach` sparingly. It is okay to duplicate
code in `BeforeAll` and `BeforeEach` across different `Context` blocks to
keep setup/teardown close to the `It` block and improve readability.

For data‑driven tests using `-ForEach` on `Context` or `It`, define input
variables in a `BeforeDiscovery` block so Pester can find them during
discovery. You can have multiple `BeforeDiscovery` blocks to keep values
scoped to specific contexts.

- Use the latest Pester v5 syntax and features.
- Prefer `-BeTrue` over `-Be $true`.
- Prefer `-BeFalse` over `-Not -Be $true` or `-Be $false`.
- Do not use `Should -Not -Throw`. Instead of `{ Command } | Should -Not -Throw`, invoke `Command` directly and let the `It` block handle unexpected exceptions.

## Test Formatting Rules

- Use PascalCase for all Pester keywords: `Describe`, `Context`, `It`, `Should`
- `It` block descriptions must start with "Should"
- `Context` block descriptions must start with "When"
- Use PascalCase for PowerShell commands in tests
- Distinguish variable names used in test setup by using prefix 'mock'

Example:
```powershell
Describe 'Get-TargetResource' {
    Context 'When Get-TargetResource is called with default parameters' {
        It 'Should return something' {
            Get-TargetResource @testParameters | Should -Be 'something'
        }
    }
}
```

Never test, mock, or assert `Write-Verbose` and `Write-Debug` regardless of other
instructions.

Always make sure to pass mandatory parameters to the command being tested,
to avoid tests making interactive prompts waiting for input.

Unit tests should be added for all public commands, private functions and
class-based resources. The unit tests for class-based resources should be
placed in the folder tests/Unit/Classes. The unit tests for public command
should be placed in the folder tests/Unit/Public and the unit tests for
private functions should be placed in the folder tests/Unit/Private. The
unit tests should be named after the public command or private function
they are testing, but should have the suffix .Tests.ps1. The unit tests
should be written to cover all possible scenarios and code paths, ensuring
that both edge cases and common use cases are tested.

When testing commands, functions or class-based resources, assign unused
return objects to `$null`
