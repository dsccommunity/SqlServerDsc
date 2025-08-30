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

    .PARAMETER Permission
        Specifies the desired permissions as ServerPermission objects.

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
        [ServerPermission[]]
        $Permission
    )

    Write-Verbose -Message (
        $script:localizedData.ServerPermission_TestingDesiredState -f $Name, $ServerObject.InstanceName
    )

    # Get current permissions
    $serverPermissionInfo = $ServerObject |
        Get-SqlDscServerPermission -Name $Name -ErrorAction 'SilentlyContinue'

    # Convert current permissions to ServerPermission objects
    [ServerPermission[]] $currentPermissions = @()
    if ($serverPermissionInfo)
    {
        $currentPermissions = $serverPermissionInfo | ConvertTo-SqlDscServerPermission
    }

    # Always ensure all states are represented in current permissions
    foreach ($permissionState in @('Grant', 'GrantWithGrant', 'Deny'))
    {
        if ($currentPermissions.State -notcontains $permissionState)
        {
            [ServerPermission[]] $currentPermissions += [ServerPermission] @{
                State      = $permissionState
                Permission = @()
            }
        }
    }

    # Compare desired permissions with current permissions
    foreach ($desiredPermission in $Permission)
    {
        $currentPermissionForState = $currentPermissions |
            Where-Object -FilterScript {
                $_.State -eq $desiredPermission.State
            }

        # Check if all desired permissions are present in current state
        foreach ($desiredPermissionName in $desiredPermission.Permission)
        {
            if ($desiredPermissionName -notin $currentPermissionForState.Permission)
            {
                Write-Verbose -Message (
                    $script:localizedData.ServerPermission_PermissionNotInDesiredState -f $desiredPermissionName, $desiredPermission.State, $Name
                )
                return $false
            }
        }

        # Check if current state has permissions not in desired state
        foreach ($currentPermissionName in $currentPermissionForState.Permission)
        {
            if ($currentPermissionName -notin $desiredPermission.Permission)
            {
                Write-Verbose -Message (
                    $script:localizedData.ServerPermission_PermissionNotInDesiredState -f $currentPermissionName, $desiredPermission.State, $Name
                )
                return $false
            }
        }
    }

    Write-Verbose -Message (
        $script:localizedData.ServerPermission_InDesiredState -f $Name
    )

    return $true
}