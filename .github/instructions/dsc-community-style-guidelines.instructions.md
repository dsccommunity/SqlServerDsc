---
applyTo: "**/*.psm1,**/*.psd1,**/*.Tests.ps1"
---

# Style Guidelines

In these sections we describe the current state of the guidelines and best
practices to create a **High Quality DSC Resource Module**.

## Correct File Encoding

Make sure all files are encoded using UTF-8 (not UTF-8 with BOM), except mof files
which should be encoded using ASCII.
You can use ```ConvertTo-UTF8``` and ```ConvertTo-ASCII``` to convert a file to
UTF-8 or ASCII.

## Descriptive Names

Use descriptive, clear, and full names for all variables, parameters, and functions.
All names must be at least more than **2** characters.
No abbreviations should be used.

**Bad:**

```powershell
$r = Get-RdsHost
```

**Bad:**

```powershell
$frtytw = 42
```

**Bad:**

```powershell
function Get-Thing
{
    ...
}
```

**Bad:**

```powershell
function Set-ServerName
{
    param
    (
        $mySTU
    )
    ...
}
```

**Good:**

```powershell
$remoteDesktopSessionHost = Get-RemoteDesktopSessionHost
```

**Good:**

```powershell
$fileCharacterLimit = 42
```

**Good:**

```powershell
function Get-ArchiveFileHandle
{
    ...
}
```

**Good:**

```powershell
function Set-ServerName
{
    param
    (
        [Parameter()]
        $myServerToUse
    )
    ...
}
```

## Correct Parameter Usage in Function and Cmdlet Calls

Use named parameters for function and cmdlet calls rather than positional parameters.
Named parameters help other developers who are unfamiliar with your code to better
understand it.

When calling a function with many long parameters, use parameter splatting. If
splatting is used, then all the parameters should be in the splat.
More help on splatting can be found in the article
[About Splatting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting).

Make sure hashtable parameters are still properly formatted with multiple lines
and the proper indentation.

**Bad:**

Not using named parameters.

```powershell
Get-ChildItem C:\Documents *.md
```

**Bad:**

The call is very long and will wrap a lot in the review tool when the code is
viewed by the reviewer during the review process of the PR.

```powershell
$mySuperLongHashtableParameter = @{
    MySuperLongKey1 = 'MySuperLongValue1'
    MySuperLongKey2 = 'MySuperLongValue2'
}

$superLongVariableName = Get-MySuperLongVariablePlease -MySuperLongHashtableParameter  $mySuperLongHashtableParameter -MySuperLongStringParameter '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890' -Verbose
```

**Bad:**

Hashtable is not following [Correct Format for Hashtables or Objects](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-hashtables-or-objects).

```powershell
$superLongVariableName = Get-MySuperLongVariablePlease -MySuperLongHashtableParameter @{ MySuperLongKey1 = 'MySuperLongValue1'; MySuperLongKey2 = 'MySuperLongValue2' } -MySuperLongStringParameter '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890' -Verbose
```

**Bad:**

Hashtable is not following [Correct Format for Hashtables or Objects](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-hashtables-or-objects).

```powershell
$superLongVariableName = Get-MySuperLongVariablePlease -MySuperLongHashtableParameter @{ MySuperLongKey1 = 'MySuperLongValue1'; MySuperLongKey2 = 'MySuperLongValue2' } `
                                                       -MySuperLongStringParameter '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890' `
                                                       -Verbose
```

**Bad:**

Hashtable is not following [Correct Format for Hashtables or Objects](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-hashtables-or-objects).

```powershell
$superLongVariableName = Get-MySuperLongVariablePlease `
    -MySuperLongHashtableParameter @{ MySuperLongKey1 = 'MySuperLongValue1'; MySuperLongKey2 = 'MySuperLongValue2' } `
    -MySuperLongStringParameter '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890' `
    -Verbose
```

**Bad:**

Passing parameter (`Verbose`) outside of the splat.

```powershell
$getMySuperLongVariablePleaseParameters = @{
    MySuperLongHashtableParameter = @{
        MySuperLongKey1 = 'MySuperLongValue1'
        MySuperLongKey2 = 'MySuperLongValue2'
    }
    MySuperLongStringParameter = '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'
}

$superLongVariableName = Get-MySuperLongVariablePlease @getMySuperLongVariablePleaseParameters -Verbose
```

**Good:**

```powershell
Get-ChildItem -Path C:\Documents -Filter *.md
```

**Good:**

```powershell
$superLongVariableName = Get-MyVariablePlease -MyStringParameter '123456789012349012345678901234567890' -Verbose
```

**Good:**

```powershell
$superLongVariableName = Get-MyVariablePlease -MyString1 '1234567890' -MyString2 '1234567890' -MyString3 '1234567890' -Verbose
```

**Good:**

```powershell
$mySuperLongHashtableParameter = @{
    MySuperLongKey1 = 'MySuperLongValue1'
    MySuperLongKey2 = 'MySuperLongValue2'
}

$superLongVariableName = Get-MySuperLongVariablePlease -MySuperLongHashtableParameter $mySuperLongHashtableParameter -Verbose
```

**Good:**

Splatting all parameters.

```powershell
$getMySuperLongVariablePleaseParameters = @{
    MySuperLongHashtableParameter = @{
        MySuperLongKey1 = 'MySuperLongValue1'
        MySuperLongKey2 = 'MySuperLongValue2'
    }
    MySuperLongStringParameter = '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'
    Verbose = $true
}

$superLongVariableName = Get-MySuperLongVariablePlease @getMySuperLongVariablePleaseParameters
```

**Good:**

```powershell
$superLongVariableName = Get-MySuperLongVariablePlease `
    -MySuperLongHashtableParameter @{
        MySuperLongKey1 = 'MySuperLongValue1'
        MySuperLongKey2 = 'MySuperLongValue2'
    } `
    -MySuperLongStringParameter '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890' `
    -Verbose
```

## Correct Format for Arrays

Arrays should be written in one of the following formats.

If an array is declared on a single line, then there should be a single space
between each element in the array. If arrays written on a single line tend to be
long, please consider using one of the alternative ways of writing the array.

**Bad:**

Array elements are not format consistently.

```powershell
$array = @( 'one', `
'two', `
'three'
)
```

**Bad:**

There are no single space beetween the elements in the array.

```powershell
$array = @('one','two','three')
```

**Bad:**

There are multiple array elements on the same row.

```powershell
$array = @(
    'one', 'two', `
    'my long string example', `
    'three', 'four'
)
```

**Bad:**

Hashtable is not following [Correct Format for Hashtables or Objects](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-hashtables-or-objects).

```powershell
$array = @(
    'one',
    @{MyKey = 'MyValue'},
    'three'
)
```

**Bad:**

Hashtables are not following [Correct Format for Hashtables or Objects](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-hashtables-or-objects).

```powershell
$myArray = @(
    @{Key1 = Value1;Key2 = Value2},
    @{Key1 = Value1;Key2 = Value2}
)
```

**Good:**

```powershell
$array = @('one', 'two', 'three')
```

**Good:**

```powershell
$array = @(
    'one',
    'two',
    'three'
)
```

**Good:**

```powershell
$array = @(
    'one'
    'two'
    'three'
)
```

**Good:**

```powershell
$hashtable = @{
    Key = "Value"
}

$array = @( 'one', 'two', 'three', $hashtable )
```

**Good:**

```powershell
$hashtable = @{
    Key = "Value"
}

$array = @(
    'one',
    'two',
    'three',
    $hashtable
)
```

**Good:**

```powershell
$myArray = @(
    @{
        Key1 = Value1
        Key2 = Value2
    },
    @{
        Key1 = Value1
        Key2 = Value2
    }
)
```

## Correct Format for Hashtables or Objects

Hashtables and Objects should be written in the following format.
Each property should be on its own line indented once.
There should be no space between the brackets of an empty hashtable.

**Bad:**

```powershell
$hashtable = @{
}
```

**Bad:**

```powershell
$hashtable = @{Key1 = 'Value1';Key2 = 2;Key3 = '3'}
```

**Bad:**

```powershell
$hashtable = @{ Key1 = 'Value1'
Key2 = 2
Key3 = '3' }
```

**Good:**

```powershell
$hashtable = @{}
```

**Good:**

```powershell
$hashtable = @{
    Key1 = 'Value1'
    Key2 = 2
    Key3 = '3'
}
```

**Good:**

```powershell
$hashtable = @{
    Key1 = 'Value1'
    Key2 = 2
    Key3 = @{
        Key3Key1 = 'ExampleText'
        Key3Key2 = 42
    }
}
```

## Correct use of single- and double quotes

Single quotes should always be used to delimit string literals wherever possible.
Double quoted string literals may only be used when it contains ($) expressions
that need to be evaluated.

**Bad:**

```powershell
$string = "String that do not evaluate variable"
```

**Bad:**

```powershell
$string = "String that evaluate variable {0}" -f $SomeObject.SomeProperty
```

**Good:**

```powershell
$string = 'String that do not evaluate variable'
```

**Good:**

```powershell
$string = 'String that evaluate variable {0}' -f $SomeObject.SomeProperty
```

**Good:**

```powershell
$string = "String that evaluate variable $($SomeObject.SomeProperty)"
```

**Good:**

```powershell
$string = 'String that evaluate variable ''{0}''' -f $SomeObject.SomeProperty
```

**Good:**

```powershell
$string = "String that evaluate variable '{0}'" -f $SomeObject.SomeProperty
```

## Correct Format for Comments

There should not be any commented-out code in checked-in files.
The first letter of the comment should be capitalized.

Single line comments should be on their own line and start with a single pound-sign
followed by a single space. The comment should be indented the same amount as the
following line of code.

Comments that are more than one line should use the ```<# #>``` format rather
than the single pound-sign. The opening and closing brackets should be on their
own lines. The comment inside the brackets should be indented once more than the
brackets. The brackets should be indented the same amount as the following line
of code.

Formatting help-comments for functions has a few more specific rules that can be
found [here](#all-functions-must-have-comment-based-help).

**Bad:**

```powershell
function Get-MyVariable
{#this is a bad comment
    [CmdletBinding()]
    param ()
#this is a bad comment
    foreach ($example in $examples)
    {
        Write-Verbose -Message $example #this is a bad comment
    }
}
```

**Bad:**

```powershell
function Get-MyVariable
{
    [CmdletBinding()]
    param ()

    # this is a bad comment
    # On multiple lines
    foreach ($example in $examples)
    {
        # No commented-out code!
        # Write-Verbose -Message $example
    }
}
```

**Good:**

```powershell
function Get-MyVariable
{
    # This is a good comment
    [CmdletBinding()]
    param ()

    # This is a good comment
    foreach ($example in $examples)
    {
        # This is a good comment
        Write-Verbose -Message $example
    }
}
```

**Good:**

```powershell
function Get-MyVariable
{
    [CmdletBinding()]
    param ()

    <#
        This is a good comment
        on multiple lines
    #>
    foreach ($example in $examples)
    {
        Write-Verbose -Message $example
    }
}
```

## Correct Format for Keywords

PowerShell reserved Keywords should be in all lower case and should
be immediately followed by a space if there is non-whitespace characters
following (for example, an open brace).

Some reserved Keywords may also be followed by an open curly brace, for
example the `catch` keyword. These keywords that are followed by a
curly brace should also follow the [One Newline Before Braces](#one-newline-before-braces)
guideline.

The following is the current list of PowerShell reserved keywords in
PowerShell 5.1:

```powershell
begin, break, catch, class, continue, data, define do, dynamicparam, else,
elseif, end, enum, exit, filter, finally, for, foreach, from, function
hidden, if, in, inlinescript, param, process, return, static, switch,
throw, trap, try, until, using, var, while
```

This list may change in newer versions of PowerShell.

The latest list of PowerShell reserved keywords can also be found
on [this page](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_keywords?view=powershell-5.1).

**Bad:**

```powershell
# Missing space after keyword and before open bracket
foreach($item in $list)
```

**Bad:**

```powershell
# Capital letters in keyword
BEGIN
```

**Bad:**

```powershell
# Violates 'One Newline Before Braces' guideline
begin {
    # Do some work
}
```

**Bad:**

```powershell
# Capital letters in 'in' and 'foreach' keyword
ForEach ($item In $list)
```

**Good:**

```powershell
foreach ($item in $list)
```

**Good:**

```powershell
begin
{
    # Do some work
}
```

## Indentation

For all indentation, use **4** spaces instead of tabs.
There should be no tab characters in the file unless they are in a here-string.

## No Trailing Whitespace After Backticks

Backticks should always be directly followed by a newline

## Newline at End of File

All files must end with a newline, see [StackOverflow.](http://stackoverflow.com/questions/5813311/no-newline-at-end-of-file)

## Newline Character Encoding

Save [newlines](http://en.wikipedia.org/wiki/Newline) using CR+LF instead of CR.
For interoperability reasons, we recommend that you follow [these instructions](GettingStartedWithGitHub.md#setup-git)
when installing Git on Windows so that newlines saved to GitHub are simply CRs.

## No More Than Two Consecutive Newlines

Code should not contain more than two consecutive newlines unless they are contained
in a here-string.

**Bad:**

```powershell
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'


    return $MyValue
}
```

**Bad:**

```powershell
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'
    return $MyValue
}

function Write-Log
{
    Write-Verbose -Message 'Logging...'
}
```

**Good:**

```powershell
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'
    return $MyValue
}
```

**Good:**

```powershell
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'
    return $MyValue
}

function Write-Log
{
    Write-Verbose -Message 'Logging...'
}
```

## One Newline Before Braces

Each curly brace should be preceded by a newline unless assigning to a variable.

**Bad:**

```powershell
if ($booleanValue) {
    Write-Verbose -Message "Boolean is $booleanValue"
}
```

**Good:**

```powershell
if ($booleanValue)
{
    Write-Verbose -Message "Boolean is $booleanValue"
}
```

When assigning to a variable, opening curly braces should be on the same line as
the assignment operator.

**Bad:**

```powershell
$scriptBlockVariable =
{
    Write-Verbose -Message 'Executing script block'
}
```

**Bad:**

```powershell
$hashtableVariable =
@{
    Key1 = 'Value1'
    Key2 = 'Value2'
}
```

**Good:**

```powershell
$scriptBlockVariable = {
    Write-Verbose -Message 'Executing script block'
}
```

**Good:**

```powershell
$hashtableVariable = @{
    Key1 = 'Value1'
    Key2 = 'Value2'
}
```

## One Newline After Opening Brace

Each opening curly brace should be followed by only one newline.

**Bad:**

```powershell
function Get-MyValue
{

    Write-Verbose -Message 'Getting MyValue'

    return $MyValue
}
```

**Bad:**

```powershell
function Get-MyValue
{ Write-Verbose -Message 'Getting MyValue'

    return $MyValue
}
```

**Good:**

```powershell
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'
    return $MyValue
}
```

## Two Newlines After Closing Brace

Each closing curly brace **ending** a function, conditional block, loop, etc.
should be followed by exactly two newlines unless it is directly followed by another
closing brace. If the closing brace is followed by another closing brace or continues
a conditional or switch block, there should be only one newline after the closing
brace.

**Bad:**

```powershell
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'
    return $MyValue
} Get-MyValue
```

**Bad:**

```powershell
function Get-MyValue
{ Write-Verbose -Message 'Getting MyValue'

    if ($myBoolean)
    {
        return $MyValue
    }

    else
    {
        return 0
    }

}
Get-MyValue
```

**Good:**

```powershell
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'

    if ($myBoolean)
    {
        return $MyValue
    }
    else
    {
        return 0
    }
}

Get-MyValue
```

## One Space Between Type and Variable Name

If you must declare a variable type, type declarations should be separated from
the variable name by a single space.

**Bad:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param ()

    [Int]$number = 2
}
```

**Good:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param ()

    [Int] $number = 2
}
```

## One Space on Either Side of Operators

There should be one blank space on either side of all operators.

**Bad:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param ()

    $number=2+4-5*9/6
}
```

**Bad:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param ()

    if ('example'-eq'example'-or'magic')
    {
        Write-Verbose -Message 'Example found.'
    }
}
```

**Good:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param ()

    $number = 2 + 4 - 5 * 9 / 6
}
```

**Good:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param ()

    if ('example' -eq 'example' -or 'magic')
    {
        Write-Verbose -Message 'Example found.'
    }
}
```

## One Space Between Keyword and Parenthesis

If a keyword is followed by a parenthesis, there should be single space between
the keyword and the parenthesis.

**Bad:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param ()

    if('example' -eq 'example' -or 'magic')
    {
        Write-Verbose -Message 'Example found.'
    }

    foreach($example in $examples)
    {
        Write-Verbose -Message $example
    }
}
```

**Good:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param ()

    if ('example' -eq 'example' -or 'magic')
    {
        Write-Verbose -Message 'Example found.'
    }

    foreach ($example in $examples)
    {
        Write-Verbose -Message $example
    }
}
```

## Function Names Use Pascal Case

Function names must use PascalCase.  This means that each concatenated word is capitalized.

**Bad:**

```powershell
function get-targetresource
{
    # ...
}
```

**Good:**

```powershell
function Get-TargetResource
{
    # ...
}
```

## Function Names Use Verb-Noun Format

All function names must follow the standard PowerShell Verb-Noun format.

**Bad:**

```powershell
function TargetResourceGetter
{
    # ...
}
```

**Good:**

```powershell
function Get-TargetResource
{
    # ...
}
```

## Function Names Use Approved Verbs

All function names must use [approved verbs](https://msdn.microsoft.com/en-us/library/ms714428(v=vs.85).aspx).

**Bad:**

```powershell
function Normalize-String
{
    # ...
}
```

**Good:**

```powershell
function ConvertTo-NormalizedString
{
    # ...
}
```

## Functions Have Comment-Based Help

All functions should have comment-based help with the correct syntax directly
above the function. Comment-help should include at least the SYNOPSIS section and
a PARAMETER section for each parameter.

**Bad:**

```powershell
# Creates an event
function New-Event
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateSet('operational', 'debug', 'analytic')]
        [String]
        $Channel = 'operational'
    )
    # Implementation...
}
```

**Good:**

```powershell
<#
    .SYNOPSIS
        Creates an event

    .PARAMETER Message
        Message to write

    .PARAMETER Channel
        Channel where message should be stored

    .EXAMPLE
        New-Event -Message 'Attempting to connect to server' -Channel 'debug'
#>
function New-Event
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateSet('operational', 'debug', 'analytic')]
        [String]
        $Channel = 'operational'
    )
    # Implementation
}
```

## Parameter Block at Top of Function

There must be a parameter block declared for every function.
The parameter block must be at the top of the function and not declared next to
the function name. Functions with no parameters should still display an empty
parameter block.

**Bad:**

```powershell
function Write-Text([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$Text)
{
    Write-Verbose -Message $Text
}
```

**Bad:**

```powershell
function Write-Nothing
{
    Write-Verbose -Message 'Nothing'
}
```

**Good:**

```powershell
function Write-Text
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text
    )

    Write-Verbose -Message $Text
}
```

**Good:**

```powershell
function Write-Nothing
{
    param ()

    Write-Verbose -Message 'Nothing'
}
```

## Correct Format for Parameter Block

- An empty parameter block should be displayed on its own line like this:
  `param ()`.
- A non-empty parameter block should have the opening and closing parentheses on
  their own line.
- All text inside the parameter block should be indented once.
- Every parameter should include the `[Parameter()]` attribute, regardless of
  whether the attribute requires decoration or not.
- A parameter that is mandatory should contain this decoration:
  `[Parameter(Mandatory = $true)]`.
- A parameter that is not mandatory should _not_ contain a `Mandatory` decoration
  in the `[Parameter()]`.

**Bad:**

```powershell
function Write-Nothing
{
    param
    (

    )

    Write-Verbose -Message 'Nothing'
}
```

**Bad:**

```powershell
function Write-Text
{
    param([Parameter(Mandatory = $true)]
[ValidateNotNullOrEmpty()]
                    [String] $Text )

    Write-Verbose -Message $Text
}
```

**Bad:**

```powershell
function Write-Text
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PrefixText

        [Boolean]
        $AsWarning = $false
    )

    if ($AsWarning)
    {
        Write-Warning -Message "$PrefixText - $Text"
    }
    else
    {
        Write-Verbose -Message "$PrefixText - $Text"
    }
}
```

**Good:**

```powershell
function Write-Nothing
{
    param ()

    Write-Verbose -Message 'Nothing'
}
```

**Good:**

```powershell
function Write-Text
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text
    )

    Write-Verbose -Message $Text
}
```

**Good:**

```powershell
function Write-Text
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $PrefixText

        [Parameter()]
        [Boolean]
        $AsWarning = $false
    )

    if ($AsWarning)
    {
        Write-Warning -Message "$PrefixText - $Text"
    }
    else
    {
        Write-Verbose -Message "$PrefixText - $Text"
    }
}
```

## Parameter Names Use Pascal Case

All parameters must use PascalCase.  This means that each concatenated word is capitalized.

**Bad:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        $SOURCEPATH
    )
}
```

**Bad:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        $sourcepath
    )
}
```

**Good:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        $SourcePath
    )
}
```

## Parameters Separated by One Line

Parameters must be separated by a single, blank line.

**Bad:**

```powershell
function New-Event
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,
        [ValidateSet('operational', 'debug', 'analytic')]
        [String]
        $Channel = 'operational'
    )
}
```

**Good:**

```powershell
function New-Event
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateSet('operational', 'debug', 'analytic')]
        [String]
        $Channel = 'operational'
    )
}
```

## Parameter Type on Line Above

The parameter type must be on its own line above the parameter name.
If an attribute needs to follow the type, it should also have its own line between
the parameter type and the parameter name.

**Bad:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        [String] $SourcePath = 'c:\'
    )
}
```

**Good:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [String]
        $SourcePath = 'c:\'
    )
}
```

**Good:**

```powershell
function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [PSCredential]
        [Credential()]
        $MyCredential
    )
}
```

**Good:**

```powershell
function New-Event
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateSet('operational', 'debug', 'analytic')]
        [String]
        $Channel = 'operational'
    )
}
```

## Parameter Attributes on Separate Lines

Parameter attributes should each have their own line.
All attributes should go above the parameter type, except those that *must* be
between the type and the name.

**Bad:**

```powershell
function New-Event
{
    param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]
        $Message,

        [ValidateSet('operational', 'debug', 'analytic')][String]
        $Channel = 'operational'
    )
}
```

**Good:**

```powershell
function New-Event
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateSet('operational', 'debug', 'analytic')]
        [String]
        $Channel = 'operational'
    )
}
```

## Variable Names Use Camel Case

Variable names should use camelCase.

**Bad:**

```powershell
function Write-Log
{
    $VerboseMessage = 'New log message'
    Write-Verbose $VerboseMessage
}
```

**Bad:**

```powershell
function Write-Log
{
    $verbosemessage = 'New log message'
    Write-Verbose $verbosemessage
}
```

**Good:**

```powershell
function Write-Log
{
    $verboseMessage = 'New log message'
    Write-Verbose $verboseMessage
}
```

## Script, Environment and Global Variable Names Include Scope

Script, environment, and global variables must always include their scope in the
variable name unless the 'using' scope is needed. The script and global scope
specifications should be all in lowercase. Script and global variable names following
the scope should use camelCase.

**Bad:**

```powershell
$fileCount = 0
$GLOBAL:MYRESOURCENAME = 'MyResource'

function New-File
{
    $fileCount++
    Write-Verbose -Message "Adding file to $MYRESOURCENAME to $ENV:COMPUTERNAME."
}
```

**Good:**

```powershell
$script:fileCount = 0
$global:myResourceName = 'MyResource'

function New-File
{
    $script:fileCount++
    Write-Verbose -Message "Adding file to $global:myResourceName to $env:computerName."
}
```

## Avoid Using ard coded Computer Name

Using hard coded computer names exposes sensitive information on your machine.
Use a parameter or environment variable instead if a computer name is necessary.
This comes from [this](https://github.com/PowerShell/PSScriptAnalyzer/blob/development/RuleDocumentation/AvoidUsingComputerNameHardcoded.md)
PS Script Analyzer rule.

**Bad:**

```powershell
Invoke-Command -Port 0 -ComputerName 'hardcodedName'
```

**Good:**

```powershell
Invoke-Command -Port 0 -ComputerName $env:computerName
```

## Avoid Empty Catch Blocks

Empty catch blocks are not necessary.
Most errors should be thrown or at least acted upon in some way.
If you really don't want an error to be thrown or logged at all, use the ErrorAction
parameter with the SilentlyContinue value instead.

**Bad:**

```powershell
try
{
    Get-Command -Name Invoke-NotACommand
}
catch {}
```

**Good:**

```powershell
Get-Command -Name Invoke-NotACommand -ErrorAction SilentlyContinue
```

## Ensure Null is on Left Side of Comparisons

When comparing a value to ```$null```, ```$null``` should be on the left side of
the comparison.
This is due to an issue in PowerShell.
If ```$null``` is on the right side of the comparison and the value you are comparing
it against happens to be a collection, PowerShell will return true if the collection
*contains* ```$null``` rather than if the entire collection actually *is* ```$null```.
Even if you are sure your variable will never be a collection, for consistency,
please ensure that ```$null``` is on the left side of all comparisons.

**Bad:**

```powershell
if ($myArray -eq $null)
{
    Remove-AllItems
}
```

**Good:**

```powershell
if ($null -eq $myArray)
{
    Remove-AllItems
}
```

## Avoid Global Variables

Avoid using global variables whenever possible.
These variables can be edited by any other script that ran before your script or
is running at the same time as your script.
Use them only with extreme caution, and try to use parameters or script/local
variables instead.

This rule has a few exceptions:

- The use of ```$global:DSCMachineStatus``` is still recommended to restart a
  machine from a DSC resource.

**Bad:**

```powershell
$global:configurationName = 'MyConfigurationName'
...
Set-MyConfiguration -ConfigurationName $global:configurationName
```

**Good:**

```powershell
$script:configurationName = 'MyConfigurationName'
...
Set-MyConfiguration -ConfigurationName $script:configurationName
```

## Use Declared Local and Script Variables More Than Once

Don't declare a local or script variable if you're not going to use it.
This creates excess code that isn't needed

## Use PSCredential for All Credentials

PSCredentials are more secure than using plaintext username and passwords.

**Bad:**

```powershell
function Get-Settings
{
    param
    (
        [String]
        $Username

        [String]
        $Password
    )
    ...
}
```

**Good:**

```powershell
function Get-Settings
{
    param
    (
        [PSCredential]
        [Credential()]
        $UserCredential
    )
}
```

## Use Variables Rather Than Extensive Piping

This is a script not a console. Code should be easy to follow. There should be no
more than 1 pipe in a line. This rule is specific to the DSC Resource Kit - other
PowerShell best practices may say differently, but this is our preferred format
for readability.

**Bad:**

```powershell
Get-Objects | Where-Object { $_.Propery -ieq 'Valid' } | Set-ObjectValue `
    -Value 'Invalid' | Foreach-Object { Write-Output $_ }
```

**Good:**

```powershell
$validPropertyObjects = Get-Objects | Where-Object { $_.Property -ieq 'Valid' }

foreach ($validPropertyObject in $validPropertyObjects)
{
    $propertySetResult = Set-ObjectValue $validPropertyObject -Value 'Invalid'
    Write-Output $propertySetResult
}
```

## Avoid Unnecessary Type Declarations

If it is clear what type a variable is then it is not necessary to explicitly
declare its type. Extra type declarations can clutter the code.

**Bad:**

```powershell
[String] $myString = 'My String'
```

**Bad:**

```powershell
[System.Boolean] $myBoolean = $true
```

**Good:**

```powershell
$myString = 'My String'
```

**Good:**

```powershell
$myBoolean = $true
```

## Avoid Cmdlet Aliases

When calling a function use the full command not an alias.
You can get the full command an alias represents by calling ```Get-Alias```.

**Bad:**

```powershell
ls -File $root -Recurse | ? { @('.gitignore', '.mof') -contains $_.Extension }
```

**Good:**

```Powershell
Get-ChildItem -File $root -Recurse | Where-Object -FilterScript {
    @('.gitignore', '.mof') -contains $_.Extension
}
```

### Avoid Invoke-Expression

Invoke-Expression is vulnerable to string injection attacks.
It should not be used in any DSC resources.

**Bad:**

```powershell
Invoke-Expression -Command "Test-$DSCResourceName"
```

**Good:**

```powershell
& "Test-$DSCResourceName"
```

## Use the Force Parameter with Calls to ShouldContinue

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Avoid the WMI Cmdlets

The WMI cmdlets can all be replaced by CIM cmdlets.
Use the CIM cmdlets instead because they align with industry standards.

**Bad:**

```powershell
Get-WMIInstance -ClassName Win32_Process
```

**Good:**

```powershell
Get-CIMInstance -ClassName Win32_Process
```

## Avoid Write-Host

[Write-Host is harmful](http://www.jsnover.com/blog/2013/12/07/write-host-considered-harmful/).
Use alternatives such as Write-Verbose, Write-Output, Write-Debug, etc.

**Bad:**

```powershell
Write-Host 'Setting the variable to a value.'
```

**Good:**

```powershell
Write-Verbose -Message 'Setting the variable to a value.'
```

## Avoid ConvertTo-SecureString with AsPlainText

SecureStrings should be encrypted. When using ConvertTo-SecureString with the
`AsPlainText` parameter specified the SecureString text is not encrypted and thus
not secure. This is allowed in tests/examples when needed, but never in the actual
resources.

**Bad:**

```powershell
ConvertTo-SecureString -String 'mySecret' -AsPlainText -Force
```

## Assign Function Results to Variables Rather Than Extensive Inline Calls

**Bad:**

```powershell
Set-Background -Color (Get-Color -Name ((Get-Settings -User (Get-CurrentUser)).ColorName))
```

**Good:**

```powershell
$currentUser = Get-CurrentUser
$userSettings = Get-Settings -User $currentUser
$backgroundColor = Get-Color -Name $userSettings.ColorName

Set-Background -Color $backgroundColor
```

## Avoid Default Values for Mandatory Parameters

Default values for mandatory parameters will always be overwritten, thus they are
never used and can cause confusion.

**Bad:**

```powershell
function Get-Something
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name = 'My Name'
    )

    ...
}
```

**Good:**

```powershell
function Get-Something
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name
    )

    ...
}
```

## Avoid Default Values for Switch Parameters

Switch parameters have 2 values - there or not there.
The default value is automatically $false so it doesn't need to be declared.
If you are tempted to set the default value to $true - don't - refactor your code
instead.

**Bad:**

```powershell
function Get-Something
{
    param
    (
        [Switch]
        $MySwitch = $true
    )

    ...
}
```

**Good:**

```powershell
function Get-Something
{
    param
    (
        [Switch]
        $MySwitch
    )

    ...
}
```

## Include the Force Parameter in Functions with the ShouldContinue Attribute

**Bad:**

```powershell

```

**Good:**

```powershell

```

### Use ShouldProcess if the ShouldProcess Attribute is Defined

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Define the ShouldProcess Attribute if the Function Calls ShouldProcess

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Avoid Redefining Reserved Parameters

[Reserved Parameters](https://msdn.microsoft.com/en-us/library/dd901844(v=vs.85).aspx)
such as Verbose, Debug, etc. are already added to the function at runtime so don't
redefine them. Add the CmdletBinding attribute to include the reserved parameters
in your function.

## Use the CmdletBinding Attribute on Every Function

The CmdletBinding attribute adds the reserved parameters to your function which is
always preferable.

**Bad:**

```powershell
function Get-Property
{
    param
    (
        ...
    )
    ...
}
```

**Good:**

```powershell
function Get-Property
{
    [CmdletBinding()]
    param
    (
        ...
    )
    ...
}
```

## Define the OutputType Attribute for All Functions With Output

The OutputType attribute should be declared if the function has output so that
the correct error messages get displayed if the function ever produces an incorrect
output type.

**Bad:**

```powershell
function Get-MyBoolean
{
    [OutputType([Boolean])]
    param ()

    ...

    return $myBoolean
}
```

**Good:**

```powershell
function Get-MyBoolean
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param ()

    ...

    return $myBoolean
}
```

## Return Only One Object From Each Function

Functions should only return one object. If you need to return multiple objects,
use a collection such as an array or a hashtable. Returning multiple objects
from a function can lead to confusion and unexpected behavior.

## Avoid Using Deprecated Manifest Fields

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Ensure Manifest Contains Correct Fields

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Do not use NestedModules to export shared commands

Since we don't use the `RootModule` key in the module manifest, we should not
use the `NestedModules` key to add modules that export commands that are shared
between resource modules.

Normally, a single list in the `RootModule` key, can restrict what is
exported using the cmdlet `Export-ModuleMember`. Since we don't use the `RootModule`
key we can't restrict what is exported, so every nested module will export all the
commands (or all the commands restricted by `Export-ModuleMember` in that
individual nested module). If two resource modules were to use the `NestedModules`
method, it would result in one of them being unable to install since they have
conflicting exported commands.
