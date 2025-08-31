<#
    .SYNOPSIS
        Converts a collection of Microsoft.SqlServer.Management.Smo.ServerPermissionInfo
        objects into an array of ServerPermission objects.

    .DESCRIPTION
        Converts a collection of Microsoft.SqlServer.Management.Smo.ServerPermissionInfo
        objects into an array of ServerPermission objects.

    .PARAMETER ServerPermissionInfo
        Specifies a collection of Microsoft.SqlServer.Management.Smo.ServerPermissionInfo
        objects.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $serverPermissionInfo = Get-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyPrincipal'
        ConvertTo-SqlDscServerPermission -ServerPermissionInfo $serverPermissionInfo

        Get all permissions for the principal 'MyPrincipal' and converts the permissions
        into an array of `[ServerPermission[]]`.

    .OUTPUTS
        [ServerPermission[]]
#>
function ConvertTo-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when the output type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([ServerPermission[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]]
        $ServerPermissionInfo
    )

    begin
    {
        [ServerPermission[]] $permissions = @()
    }

    process
    {
        $permissionState = foreach ($currentServerPermissionInfo in $ServerPermissionInfo)
        {
            # Convert from the type PermissionState to String.
            [System.String] $currentServerPermissionInfo.PermissionState
        }

        $permissionState = $permissionState | Select-Object -Unique

        foreach ($currentPermissionState in $permissionState)
        {
            $filteredServerPermission = $ServerPermissionInfo |
                Where-Object -FilterScript {
                    $_.PermissionState -eq $currentPermissionState
                }

            $serverPermissionStateExist = $permissions.Where({
                    $_.State -contains $currentPermissionState
                }) |
                Select-Object -First 1

            if ($serverPermissionStateExist)
            {
                $serverPermission = $serverPermissionStateExist
            }
            else
            {
                $serverPermission = [ServerPermission] @{
                    State      = $currentPermissionState
                    Permission = [System.String[]] @()
                }
            }

            foreach ($currentPermission in $filteredServerPermission)
            {
                # Get the permission names that is set to $true
                $permissionProperty = $currentPermission.PermissionType |
                    Get-Member -MemberType 'Property' |
                    Select-Object -ExpandProperty 'Name' -Unique |
                    Where-Object -FilterScript {
                        $currentPermission.PermissionType.$_
                    }


                foreach ($currentPermissionProperty in $permissionProperty)
                {
                    $serverPermission.Permission += $currentPermissionProperty
                }
            }

            # Only add the object if it was created.
            if (-not $serverPermissionStateExist)
            {
                $permissions += $serverPermission
            }
        }
    }

    end
    {
        return $permissions
    }
}
