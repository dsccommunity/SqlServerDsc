---
applyTo: "tests/**/*.[Tt]ests.ps1"
---

## Capitalized Pester Assertions

Pester assertions should all start with capital letters. This makes code easier
to read.

**Bad:**

```powershell
it 'Should return something' {
    get-targetresource @testParameters | should -be 'something'
}
```

**Good:**

```powershell
It 'Should return something' {
    Get-TargetResource @testParameters | Should -Be 'something'
}
```

## Assertion Messages Start with Should

Pester assertions should always start with the word 'Should'. This is to ensure the
test results read more naturally as well as helping to indentify assertion messages
that aren't making assertions.

**Bad:**

```powershell
# This is not an assertive message
It 'When calling Get-TargetResource' {
    Get-TargetResource @testParameters | Should -Be 'something'
}
```

**Bad:**

```powershell
# This does not start with 'Should'
It 'Something is returned' {
    Get-TargetResource @testParameters | Should -Be 'something'
}
```

**Good:**

```powershell
It 'Should return something' {
    Get-TargetResource @testParameters | Should -Be 'something'
}
```

## Context Block Messages Start with When

Pester test **outer** `Context` block messages should always start with the word
'When'. This is to ensure the test results read more naturally as well as helping
to indentify context messages that aren't defining context.

**Bad:**

```powershell
# Context block not using 'When'
Context 'Calling Get-TargetResource with default parameters'
    It 'Should return something' {
        Get-TargetResource @testParameters | Should -Be 'something'
    }
}
```

**Bad:**

```powershell
Context 'When calling Get-TargetResource'
    # Inner context block not using 'When'
    Context 'With default parameters'
        It 'Should return something' {
            Get-TargetResource @testParameters | Should -Be 'something'
        }
    }
}
```

**Good:**

```powershell
Context 'When Get-TargetResource is called with default parameters'
    It 'Should return something' {
        Get-TargetResource @testParameters | Should -Be 'something'
    }
}
```

**Good:**

```powershell
Context 'When Get-TargetResource is called'
    Context 'When passing default parameters'
        It 'Should return something' {
            Get-TargetResource @testParameters | Should -Be 'something'
        }
    }
}
```
