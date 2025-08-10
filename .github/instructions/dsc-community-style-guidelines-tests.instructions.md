---
applyTo: "tests/**/*.[Tt]ests.ps1"
---

## Pester Test Formatting Rules

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
