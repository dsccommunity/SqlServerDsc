---
description: Guidelines for implementing Desired State Configuration (DSC) class-based resources.
applyTo: "source/[cC]lasses/**/*.ps1"
---

# DSC Class-Based Resource Guidelines

**Applies to:** Classes with `[DscResource(...)]` decoration only.

## Requirements
- File: `source/Classes/020.{ResourceName}.ps1`
- Decoration: `[DscResource(RunAsCredential = 'Optional')]` (replace with `'Mandatory'` if required)
- Inheritance: Must inherit `ResourceBase` (part of module DscResource.Base)
- `$this.localizedData` hashtable auto-populated by `ResourceBase` from localization file
- value-type properties: Use `[Nullable[{FullTypeName}]]` (e.g., `[Nullable[System.Int32]]`)

## Required constructor

```powershell
MyResourceName () : base ($PSScriptRoot)
{
    # Property names where state cannot be enforced, e.g. IsSingleInstance, Force
    $this.ExcludeDscProperties = @()
}
```

## Required Method Pattern

```powershell
[MyResourceName] Get()
{
    # Call base implementation to get current state
    $currentState = ([ResourceBase] $this).Get()

    # If needed, post-processing on current state that can not be handled by GetCurrentState()

    return $currentState
}

[System.Boolean] Test()
{
    # Call base implementation to test current state
    $inDesiredState = ([ResourceBase] $this).Test()

    # If needed, post-processing on test result that can not be handled by base Test()

    return $inDesiredState
}

[void] Set()
{
    # Call base implementation to set desired state
    ([ResourceBase] $this).Set()

    # If needed, additional state changes that can not be handled by Modify()
}

hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
{
    # Always return current state as hashtable, $properties contains key properties
}

hidden [void] Modify([System.Collections.Hashtable] $properties)
{
    # Always set desired state, $properties contain those that must change state
}
```

## Optional Method Pattern

```powershell
hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
{
    # Validate user-provided properties, $properties contains user assigned values
}

hidden [void] NormalizeProperties([System.Collections.Hashtable] $properties)
{
    # Normalize user-provided properties, $properties contains user assigned values
}
```

## Required comment-based help

Add to .DESCRIPTION section:
- `## Requirements`: List minimum requirements
- `## Known issues`: Critical issues + pattern: `All issues are not listed here, see [all open issues](https://github.com/{owner}/{repo}/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+{ResourceName}).`

## Error Handling
- Use `try/catch` blocks to handle exceptions
- Do not use `throw` for terminating errors, use `New-*Exception` commands:
  - [`New‑InvalidDataException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidDataException)
  - [`New-ArgumentException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91ArgumentException)
  - [`New-InvalidOperationException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidOperationException)
  - [`New-ObjectNotFoundException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91ObjectNotFoundException)
  - [`New-InvalidResultException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidResultException)
  - [`New-NotImplementedException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91NotImplementedException)
