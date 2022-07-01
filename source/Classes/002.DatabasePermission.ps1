<#
    .SYNOPSIS
        The possible database permission states.

    .PARAMETER State
        The state of the permission.

    .PARAMETER Permission
        The permissions to be granted or denied for the user in the database.

    .NOTES
        The DSC properties specifies attributes Key and Required, those attributes
        are not honored during compilation in the current implementation of
        PowerShell DSC. They are kept here so when they do get honored it will help
        detect missing properties during compilation. The Key property is evaluate
        during runtime so that no two states are enforcing the same permission.
#>
class DatabasePermission
{
    [DscProperty(Key)]
    [ValidateSet('Grant', 'GrantWithGrant', 'Deny')]
    [System.String]
    $State

    # TODO: Can we use a validate set for the permissions?
    [DscProperty(Mandatory)]
    [System.String[]]
    $Permission
}
