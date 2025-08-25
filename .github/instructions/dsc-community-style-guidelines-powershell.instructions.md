---
description: Guidelines for writing PowerShell scripts and modules.
applyTo: "**/*.ps?(m|d)1"
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
- Multi-line: each property on separate line with proper indentation
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
- INPUTS: List each pipeline‑accepted type (one per line) with a 1‑line description.
- OUTPUTS: List each return type (one per line) with a 1‑line description. Must match both [OutputType()] and actual returns.
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
  - `$PSCmdlet.ShouldProcess` must use required pattern
- Use `$PSCmdlet.ThrowTerminatingError()` for terminating errors, use relevant error category
- Use `Write-Error` for non-terminating errors, use relevant error category
- Use `Write-Warning` for warnings
- Use `Write-Debug` for debugging information
- Use `Write-Verbose` for actionable information
- Use `Write-Information` for informational messages.
- Never use backtick as line continuation in production code.

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
        TypeName

        Description

    .OUTPUTS
        TypeName

        Description
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
- Pipeline parameters (`ValueFromPipeline = $true`) must be declared in ALL parameter sets

## Best Practices

### Code Organization

- Use named parameters in function calls
- Use splatting for long parameter lists
- Limit piping to one pipe per line
- Assign function results to variables rather than inline calls
- Return a single, consistent object type per function

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
- Use CR+LF line endings
- Maximum two consecutive newlines

## File Encoding

- Use UTF-8 encoding (no BOM) for all files

## Module Manifest

- Don't use `NestedModules` for shared commands without `RootModule`
