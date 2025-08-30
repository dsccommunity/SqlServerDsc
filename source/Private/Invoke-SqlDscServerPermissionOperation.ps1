<#
    .SYNOPSIS
        Invokes a server permission operation on a SQL Server principal.

    .DESCRIPTION
        This private function encapsulates the core logic for granting, denying,
        or revoking server permissions on a SQL Server principal. It validates
        the principal exists and executes the specified permission operation.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the principal for which the permissions are modified.

    .PARAMETER Permission
        Specifies the permissions.

    .PARAMETER State
        Specifies the state of the permission operation (Grant, Deny, Revoke).

    .PARAMETER WithGrant
        Specifies that the principal should also be granted the right to grant
        other principals the same permission. This parameter is only valid when
        parameter State is set to Grant or Revoke.

    .OUTPUTS
        None.
#>
function Invoke-SqlDscServerPermissionOperation
{
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
        $Permission,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'Revoke')]
        [System.String]
        $State,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $WithGrant
    )

    # Validate that the principal exists
    $testSqlDscIsPrincipalParameters = @{
        ServerObject = $ServerObject
        Name         = $Name
    }

    $isLogin = Test-SqlDscIsLogin @testSqlDscIsPrincipalParameters
    $isRole = Test-SqlDscIsRole @testSqlDscIsPrincipalParameters

    if (-not ($isLogin -or $isRole))
    {
        $missingPrincipalMessage = $script:localizedData.ServerPermission_MissingPrincipal -f $Name, $ServerObject.InstanceName

        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                $missingPrincipalMessage,
                'ISDSP0001', # cSpell: disable-line
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Name
            )
        )
    }

    # Get the permissions names that are set to $true in the ServerPermissionSet.
    $permissionName = $Permission |
        Get-Member -MemberType 'Property' |
        Select-Object -ExpandProperty 'Name' |
        Where-Object -FilterScript {
            $Permission.$_
        }

    switch ($State)
    {
        'Grant'
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_GrantPermission -f ($permissionName -join ','), $Name
            )

            if ($WithGrant.IsPresent)
            {
                $ServerObject.Grant($Permission, $Name, $true)
            }
            else
            {
                $ServerObject.Grant($Permission, $Name)
            }
        }

        'Deny'
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_DenyPermission -f ($permissionName -join ','), $Name
            )

            $ServerObject.Deny($Permission, $Name)
        }

        'Revoke'
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_RevokePermission -f ($permissionName -join ','), $Name
            )

            if ($WithGrant.IsPresent)
            {
                $ServerObject.Revoke($Permission, $Name, $false, $true)
            }
            else
            {
                $ServerObject.Revoke($Permission, $Name)
            }
        }
    }
}