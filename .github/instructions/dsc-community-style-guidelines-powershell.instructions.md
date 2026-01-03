---
description: Guidelines for writing PowerShell scripts and modules.
applyTo: "{**/*.ps1,**/*.psm1,**/*.psd1}"
---

# PowerShell Guidelines

## Naming

- Use descriptive names (3+ characters, no abbreviations)
- Functions: PascalCase with Verb-Noun format using approved verbs
- Parameters: PascalCase
- Variables: camelCase
- Keywords: lower-case
- Classes: PascalCase
- Include scope for script/global/environment variables: `$script:`, `$global:`, `$env:`

## File naming

- Class files: `###.ClassName.ps1` format (e.g. `001.SqlReason.ps1`, `004.StartupParameters.ps1`)

## Formatting

### Indentation & Spacing
- Use 4 spaces (no tabs)
- One space around operators: `$a = 1 + 2`
- One space between type and variable: `[String] $name`
- One space between keyword and parenthesis: `if ($condition)`
- No spaces on empty lines
- Try to limit lines to 120 characters

### Braces

- Newline before opening brace (except variable assignments)
- One newline after opening brace
- Two newlines after closing brace (one if followed by another brace or continuation)

### Quotes

- Use single quotes unless variable expansion is needed: `'text'` vs `"text $variable"`

### Arrays

- Single line: `@('one', 'two', 'three')`
- Multi-line: each element on separate line with proper indentation
- Do not use the unary comma operator (`,`) in return statements to force
  an array

### Hashtables

- Empty: `@{}`
- Each property on separate line with proper indentation
- Properties: Use PascalCase

### Comments

- Single line: `# Comment` (capitalized, on own line)
- Multi-line: `<# Comment #>` format (opening and closing brackets on own line), and indent text
- No commented-out code

### Comment-based help

- Always add comment-based help to all functions and scripts
- Comment-based help: SYNOPSIS, DESCRIPTION (40+ chars), PARAMETER, EXAMPLE sections before function/class
- Comment-based help indentation: keywords 4 spaces, text 8 spaces
- Include examples for all parameter sets and combinations
- INPUTS: List each pipeline‑accepted type as inline code with a 1‑line description. Repeat keyword for each input type. If there are no inputs, specify `None.`.
- OUTPUTS: List each return type as inline code with a 1‑line description. Repeat keyword for each output type. Must match both `[OutputType()]` and actual returns. If there are no outputs, specify `None.`.
- .NOTES: Include only if it conveys critical info (constraints, side effects, security, version compatibility, breaking behavior). Keep to ≤2 short sentences.

## Functions

- Avoid aliases (use full command names)
- Avoid `Write-Host` (use `Write-Verbose`, `Write-Information`, etc.)
- Avoid `Write-Output` (use `return` instead)
- Avoid `ConvertTo-SecureString -AsPlainText` in production code
- Don't redefine reserved parameters (Verbose, Debug, etc.)
- Include a `Force` parameter for functions that uses `$PSCmdlet.ShouldContinue` or `$PSCmdlet.ShouldProcess`
- For state-changing functions, use `SupportsShouldProcess`
  - Place ShouldProcess check immediately before each state-change
  - Set `ConfirmImpact` to 'Low', 'Medium', or 'High' depending on risk
  - `$PSCmdlet.ShouldProcess` must use required pattern
  - Inside `$PSCmdlet.ShouldProcess`-block, avoid using `Write-Verbose`
- Never use backtick as line continuation in production code.
- Use `[Alias()]` attribute for function aliases, never `Set-Alias` or `New-Alias`

## Output streams

- Never output sensitive data/secrets
- Use `Write-Debug` for: Internal diagnostics; Variable values/traces; Developer-focused details
- Use `Write-Verbose` for: High-level execution flow only; User-actionable information
- Use `Write-Information` for: User-facing status updates; Important operational messages; Non-error state changes
- Use `Write-Warning` for: Non-fatal issues requiring attention; Deprecated functionality usage; Configuration problems that don't block execution
- **Use `Write-Error` for all error handling in public commands**
  - For terminating errors: Add `-ErrorAction 'Stop'` parameter to `Write-Error`
  - For non-terminating errors: Omit `-ErrorAction` parameter (caller controls via `-ErrorAction`)
  - Always include `-Message` (localized string), `-Category` (relevant error category), `-ErrorId` (unique ID matching localized string ID), `-TargetObject` (object causing error)
  - In catch blocks, pass original exception using `-Exception`
  - Use `return` only after non-terminating `Write-Error` to stop further processing. Omit `return` when using `-ErrorAction 'Stop'`.
- **Never use `$PSCmdlet.ThrowTerminatingError()` in public commands** - it creates command-terminating (not script-terminating) errors; use `Write-Error` with `-ErrorAction 'Stop'` instead
  - May be used in private functions where behavior is understood by internal callers
- **Never use `throw` in public commands** except in `[ValidateScript()]` parameter validation attributes (it's the only valid mechanism there)
- .NET method exceptions (e.g., SMO methods) are always caught in try-catch blocks - no special handling needed

## ShouldProcess Required Pattern

- Ensure `$descriptionMessage` explains what will happen
- Ensure `$confirmationMessage` succinctly asks for confirmation
- Keep `$captionMessage` short and descriptive (no trailing `.`)

```powershell
$descriptionMessage = $script:localizedData.FunctionName_Action_ShouldProcessDescription -f $param1, $param2
$confirmationMessage = $script:localizedData.FunctionName_Action_ShouldProcessConfirmation -f $param1
$captionMessage = $script:localizedData.FunctionName_Action_ShouldProcessCaption

if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
{
    # state changing code
}
```

## Force Parameter Pattern

```powershell
if ($Force.IsPresent -and -not $Confirm)
{
    $ConfirmPreference = 'None'
}
```

### Structure

```powershell
<#
    .SYNOPSIS
        Brief description

    .DESCRIPTION
        Detailed description

    .PARAMETER Name
        Parameter description

    .INPUTS
        TypeName1

        Description1

    .INPUTS
        TypeName2

        Description2

    .OUTPUTS
        TypeName1

        Description1

    .OUTPUTS
        TypeName2

        Description2

#>
function Get-Something
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $OptionalParam
    )

    # Implementation
}
```

### Requirements

- Include `[CmdletBinding()]` on every function
- Parameter block at top
- Parameter block: `param ()` if empty, else opening/closing parentheses on own lines
- `[OutputType({return type})]` for functions with output, no output use `[OutputType()]`
- All parameters use `[Parameter()]` attribute, mandatory parameters use `[Parameter(Mandatory = $true)]`
- Parameter attributes on separate lines
- Parameter type on line above parameter name
- Parameters separated by blank line
- Parameters should use full type name.
- `ValueFromPipeline` must be consistent across all parameter sets declarations for the same parameter

## Best Practices

### Code Organization

- Use named parameters in function calls
- Use splatting for long parameter lists
- Limit piping to one pipe per line
- Assign function results to variables rather than inline calls
- Return a single, consistent object type per function
  - return `$null` for no objects/non-terminating errors
- For most .NET types, use the `::new()` static method instead of `New-Object`, e.g., `[System.DateTime]::new()`.
- For error handling, use dedicated helper commands instead:
  - Use `New-Exception` instead of `[System.Exception]::new(...)`
  - Use `New-ErrorRecord` instead of `[System.Management.Automation.ErrorRecord]::new(...)`

### Security & Safety

- Use `PSCredential` for credentials
- Avoid hardcoded computer names, use cross-platform [`Get-ComputerName`](https://github.com/dsccommunity/DscResource.Common/wiki/Get%E2%80%91ComputerName) instead of `$env:COMPUTERNAME`
- Place `$null` on left side of comparisons
- Avoid empty catch blocks (instead use `-ErrorAction SilentlyContinue`)
- Don't use `Invoke-Expression` (use `&` operator)
- Use CIM commands instead of WMI commands

### Variables

- Avoid global variables (exception: `$global:DSCMachineStatus`)
- Use declared variables more than once
- Avoid unnecessary type declarations when type is clear
- Use full type name when type casting
- No default values for mandatory or switch parameters

## File Rules

- End files with only one blank line
- Use line endings based on .gitattributes policy
- Maximum two consecutive newlines
- No line shall have trailing whitespace

## File Encoding

- Use UTF-8 encoding (no BOM) for all files

## Module Manifest

- Don't use `NestedModules` for shared commands without `RootModule`
