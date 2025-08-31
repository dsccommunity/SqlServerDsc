<#
    .SYNOPSIS
        Tests if server permissions for a principal are in the desired state.

    .DESCRIPTION
        This private function tests if server permissions for a principal are
        in the desired state by comparing current permissions with desired permissions.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the principal to test.

    .PARAMETER State
        Specifies the desired state of the permission to be tested.

    .PARAMETER Permission
        Specifies the desired permissions as a ServerPermissionSet object.

    .PARAMETER WithGrant
        Specifies that the principal should have the right to grant other principals
        the same permission. This parameter is only valid when parameter **State** is
        set to 'Grant'.

    .OUTPUTS
        [System.Boolean]
#>
function Test-SqlDscServerPermissionState
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny')]
        [System.String]
        $State,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
        $Permission,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $WithGrant
    )

    # Handle WithGrant parameter by adjusting the effective state
    $effectiveState = $State
    if ($WithGrant.IsPresent -and $State -eq 'Grant')
    {
        $effectiveState = 'GrantWithGrant'
    }

    # Get current permissions
    $serverPermissionInfo = $ServerObject |
        Get-SqlDscServerPermission -Name $Name -ErrorAction 'SilentlyContinue'

    if (-not $serverPermissionInfo)
    {
        return $false
    }

    # Convert current permissions to ServerPermission objects
    $currentPermissions = $serverPermissionInfo | ConvertTo-SqlDscServerPermission

    # Find the current permission for the desired state
    $currentPermissionForState = $currentPermissions |
        Where-Object -FilterScript {
            $_.State -eq $effectiveState
        }

    if (-not $currentPermissionForState)
    {
        $currentPermissionForState = [ServerPermission] @{
            State      = $effectiveState
            Permission = @()
        }
    }

    # Get the list of permission names that should be true in the permission set
    $desiredPermissionNames = @()
    $permissionProperties = $Permission | Get-Member -MemberType Property | Where-Object { $_.Name -ne 'IsEmpty' }

    foreach ($property in $permissionProperties)
    {
        if ($Permission.$($property.Name) -eq $true)
        {
            $desiredPermissionNames += $property.Name
        }
    }

    # Check if all desired permissions are present in current state
    foreach ($desiredPermissionName in $desiredPermissionNames)
    {
        if ($desiredPermissionName -notin $currentPermissionForState.Permission)
        {
            return $false
        }
    }

    # Check if current state has permissions not in desired state (unless desired is empty)
    if ($desiredPermissionNames.Count -gt 0)
    {
        foreach ($currentPermissionName in $currentPermissionForState.Permission)
        {
            if ($currentPermissionName -notin $desiredPermissionNames)
            {
                return $false
            }
        }
    }
    else
    {
        # If no permissions are desired, current should also be empty
        if ($currentPermissionForState.Permission.Count -gt 0)
        {
            return $false
        }
    }

    return $true
}
