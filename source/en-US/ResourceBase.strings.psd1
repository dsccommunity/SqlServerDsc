<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        class ResourceBase.
#>

ConvertFrom-StringData @'
    GetCurrentState = Getting the current state for resource '{0}' using the key property '{1}'. (RB0001)
    TestDesiredState = Determining the current state for resource '{0}' using the key property '{1}'. (RB0002)
    SetDesiredState = Setting the desired state for resource '{0}' using the key property '{1}'. (RB0003)
    NotInDesiredState = The current state is not the desired state. (RB0004)
    InDesiredState = The current state is the desired state. (RB0005)
    SetProperty = The property '{0}' will be set to '{1}'. (RB0006)
    NoPropertiesToSet = All properties are in desired state. (RB0007)
    ModifyMethodNotImplemented = An override for the method Modify() is not implemented in the resource. (RB0008)
    GetCurrentStateMethodNotImplemented = An override for the method GetCurrentState() is not implemented in the resource. (RB0009)
'@
