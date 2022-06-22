<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlDatabasePermission.
#>

ConvertFrom-StringData @'
    GetCurrentState = Getting the current state of the database permssions for the user '{0}'. (SDP0001)
    TestDesiredState = Determining the current state of the database permssions for the user '{0}'. (SDP0002)
    SetDesiredState = Setting the desired state for the database permssions for the user '{0}'. (SDP0003)
    NotInDesiredState = The database permssions for the user '{0}' is not in desired state. (SDP0004)
    InDesiredState = The database permssions for the user '{0}' is in desired state. (SDP0005)
    SetProperty = The permission '{0}' will be set to '{1}'. (SDP0006)
'@
