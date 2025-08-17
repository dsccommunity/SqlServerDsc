---
description: Guidelines for implementing Desired State Configuration (DSC) class-based resources.
applyTo: "source/[cC]lasses/**/*.ps1"
---

# DSC Class-Based Resource Guidelines

**Applies to:** Classes with `[DscResource(...)]` decoration only.

## Requirements
- File: `source/Classes/{ResourceName}.ps1`
- Decoration: `[DscResource(RunAsCredential = 'Optional')]` (replace with `'Mandatory'` if required)
- Inheritance: Must inherit `ResourceBase` (part of module DscResource.Base)
- `$this.localizedData` hashtable auto-populated by `ResourceBase` from localization file

## Required Method Pattern

```powershell
[MyResourceName] Get()
{
    $currentState = ([ResourceBase] $this).Get()

    # If needed, post-processing based on returned current state before returning to user

    return $currentState
}

[System.Boolean] Test()
{
    $inDesiredState = ([ResourceBase] $this).Test()

    # If needed, post-processing based on returned test result before returning to user

    return $inDesiredState
}

[void] Set()
{
    ([ResourceBase] $this).Set()

    # If needed, additional state changes that could not be handled by Modify()
}

hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
{
    # Return current state as hashtable
    # Variable $properties contains the key properties (key-value pairs).
}

hidden [void] Modify([System.Collections.Hashtable] $properties)
{
    # Set desired state for non-compliant properties only
    # Variable $properties contains the properties (key-value pairs) that are not in desired state.
}

hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
{
    # Validate user-provided properties
    # Variable $properties contains properties user assigned values.
}

hidden [void] NormalizeProperties([System.Collections.Hashtable] $properties)
{
    # Normalize user-provided properties
    # Variable $properties contains properties user assigned values.
}
```
