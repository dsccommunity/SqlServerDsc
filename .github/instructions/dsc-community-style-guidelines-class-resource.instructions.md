---
description: Guidelines for implementing Desired State Configuration (DSC) class-based resources.
applyTo: "source/[cC]lasses/**/*.ps1"
---

# Desired State Configuration (DSC) class-based resource Style Guidelines

Only use this instruction when the class is decorated with `[DscResource(...)]`.

Each DSC class-based resource must have its own script file named after the
resource class (with the .ps1 extension). Place these files in source/Classes.

## Parent classes

### ResourceBase

A derived class should inherit the parent class `ResourceBase`.

The parent class `ResourceBase` will set up `$this.localizedData` and provide
logic to compare the desired state against the current state. To get the
current state it will call the overridable method `GetCurrentState`. If not
in desired state it will call the overridable method `Modify`. It will also
call the overridable methods `AssertProperties` and `NormalizeProperties` to
validate and normalize the provided values of the desired state.

## Derived class

The derived class should use the decoration `[DscResource(RunAsCredential = 'Optional')]`.

The derived class should always inherit from a parent class.

The derived class should override the methods `Get`, `Test`, `Set`, `GetCurrentState`,
`Modify`, `AssertProperties`, and `NormalizeProperties` using this pattern
(and replace MyResourceName with actual resource name):

```powershell
[MyResourceName] Get()
{
    # Call the base method to return the properties.
    return ([ResourceBase] $this).Get()
}

[System.Boolean] Test()
{
    # Call the base method to test all of the properties that should be enforced.
    return ([ResourceBase] $this).Test()
}

[void] Set()
{
    # Call the base method to enforce the properties.
    ([ResourceBase] $this).Set()
}

<#
    Base method Get() calls this method to get the current state as a hashtable.
    The parameter properties will contain the key properties.
#>
hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
{
    # Add code to return the current state as a hashtable.
}

<#
    Base method Set() calls this method with the properties that are not in
    the desired state and must be enforced. It is not called if all properties
    are in the desired state. The $properties variable contains only the
    properties that are not in the desired state.
#>
hidden [void] Modify([System.Collections.Hashtable] $properties)
{
    # Add code to set the desired state based on the properties that are not in desired state.
}

<#
    Base method Assert() calls this method with the properties that were assigned
    a value.
#>
hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
{
    # Add code to validate class properties that the user passed values to.
}

<#
    Base method Normalize() calls this method with the properties that were assigned
    a value.
#>
hidden [void] NormalizeProperties([System.Collections.Hashtable] $properties)
{
    # Add code to normalize class properties that the user passed values to.
}
```

## Localization

For class-based resources, add a localized strings file in the folder
source/en-US. Name the file exactly after the resource class with the suffix
`.strings.psd1`.
Localized string key names should use underscores as word separators if the key
name has more than one word. Always assume that all localized string keys for a
class-based resource have already been assigned to `$this.localizedData` by the
parent class.
