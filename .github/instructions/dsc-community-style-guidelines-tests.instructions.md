---
applyTo: "tests/**/*.[Tt]ests.ps1"
---

# Tests Guidelines

All tests should use the Pester framework and use Pester v5.0 syntax.
Parameter validation should never be tested.

Test code should never be added outside of the `Describe` block.

There should only be one Pester `Describe` block per test file, and the name of
the `Describe` block should be the same as the name of the public command,
private function, or class-based resource being tested. Each scenario or
code path being tested should have its own Pester `Context` block that starts
with the phrase 'When'. Use nested `Context` blocks to split up test cases
and improve tests readability. Pester `It` block descriptions should start
with the phrase 'Should'. `It` blocks must always call the command or function
being tested and result and outcomes should be kept in the same `It` block.
`BeforeAll` and `BeforeEach` blocks should never call the command or function
being tested.

The `BeforeAll`, `BeforeEach`, `AfterAll` and `AfterEach` blocks should be
used inside the `Context` block as near as possible to the `It` block that
will use the test data, test setup and teardown. The `AfterAll` block can
be used to clean up any test data. The `BeforeEach` and `AfterEach`
blocks should be used sparingly. It is okay to duplicated code in `BeforeAll`
and `BeforeEach` blocks that are used inside different `Context` blocks.
The duplication helps with readability and understanding of the test cases,
and to be able to keep the test setup and teardown as close to the test
case (`It`-block) as possible.

To use `-ForEach` on `Context`- or `It`-blocks that use data driven tests the
variables must be defined in a `BeforeDiscovery`-block for Pester to find in in the discovery phase.
There can be several `BeforeDiscovery`-blocks in a test file, so we can keep the
values for the particular test context separate.

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
