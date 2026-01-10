<#
    .SYNOPSIS
        Tests if server permissions for a principal are in the desired state.

    .DESCRIPTION
        This command tests if server permissions for an existing principal on a SQL Server
        Database Engine instance are in the desired state. The principal can be specified as either
        a Login object (from Get-SqlDscLogin) or a ServerRole object (from Get-SqlDscRole).

    .PARAMETER Login
        Specifies the Login object for which the permissions are tested.
        This parameter accepts pipeline input.

    .PARAMETER ServerRole
        Specifies the ServerRole object for which the permissions are tested.
        This parameter accepts pipeline input.

    .PARAMETER Grant
        Specifies that the test should verify if the permissions are granted to the principal.

    .PARAMETER Deny
        Specifies that the test should verify if the permissions are denied to the principal.

    .PARAMETER Permission
        Specifies the desired permissions. Specify multiple permissions by
        providing an array of SqlServerPermission enum values that should be present in the
        specified state. An empty collection can be specified to test that no permissions
        are set for the principal.

    .PARAMETER WithGrant
        Specifies that the principal should have the right to grant other principals
        the same permission. This parameter is only valid when parameter **Grant** is
        used. When this parameter is used, the effective state tested will
        be 'GrantWithGrant'.

    .PARAMETER ExactMatch
        Specifies that the test should verify that only the specified permissions
        are present and no additional permissions exist in the specified state.
        When this parameter is not used, the test will return true if the specified
        permissions are present, regardless of any additional permissions.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Login`

        Accepts input via the pipeline.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.ServerRole`

        Accepts input via the pipeline.

    .OUTPUTS
        `System.Boolean`

        Returns $true if the permissions are in the desired state; otherwise $false.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $login = $serverInstance | Get-SqlDscLogin -Name 'MyLogin'
        $isInDesiredState = Test-SqlDscServerPermission -Login $login -Grant -Permission ConnectSql, ViewServerState

        Tests if the specified permissions are granted to the login 'MyLogin'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $role = $serverInstance | Get-SqlDscRole -Name 'MyRole'
        $isInDesiredState = $role | Test-SqlDscServerPermission -Grant -Permission AlterAnyDatabase -WithGrant

        Tests if the specified permissions are granted with grant option to the role 'MyRole'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $login = $serverInstance | Get-SqlDscLogin -Name 'MyLogin'
        $isInDesiredState = Test-SqlDscServerPermission -Login $login -Grant -Permission @()

        Tests if the login 'MyLogin' has no permissions granted (empty permission set).

    .NOTES
        The Login or ServerRole object must come from the same SQL Server instance
        where the permissions will be tested. If specifying `-ErrorAction 'SilentlyContinue'`
        then the command will silently continue if any errors occur. If specifying
        `-ErrorAction 'Stop'` the command will throw an error on any failure.
#>
function Test-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'LoginGrant')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'LoginDeny')]
        [Microsoft.SqlServer.Management.Smo.Login]
        $Login,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ServerRoleGrant')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ServerRoleDeny')]
        [Microsoft.SqlServer.Management.Smo.ServerRole]
        $ServerRole,

        [Parameter(Mandatory = $true, ParameterSetName = 'LoginGrant')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ServerRoleGrant')]
        [System.Management.Automation.SwitchParameter]
        $Grant,

        [Parameter(Mandatory = $true, ParameterSetName = 'LoginDeny')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ServerRoleDeny')]
        [System.Management.Automation.SwitchParameter]
        $Deny,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [SqlServerPermission[]]
        $Permission,

        [Parameter(ParameterSetName = 'LoginGrant')]
        [Parameter(ParameterSetName = 'ServerRoleGrant')]
        [Parameter(ParameterSetName = 'LoginDeny')]
        [Parameter(ParameterSetName = 'ServerRoleDeny')]
        [System.Management.Automation.SwitchParameter]
        $WithGrant,

        [Parameter(ParameterSetName = 'LoginGrant')]
        [Parameter(ParameterSetName = 'ServerRoleGrant')]
        [Parameter(ParameterSetName = 'LoginDeny')]
        [Parameter(ParameterSetName = 'ServerRoleDeny')]
        [System.Management.Automation.SwitchParameter]
        $ExactMatch
    )

    process
    {
        # Determine which principal object we're working with
        if ($Login)
        {
            $principalName = $Login.Name
            $serverObject = $Login.Parent
        }
        else
        {
            $principalName = $ServerRole.Name
            $serverObject = $ServerRole.Parent
        }

        Write-Verbose -Message (
            $script:localizedData.ServerPermission_TestingDesiredState -f $principalName, $serverObject.InstanceName
        )

        try
        {
            # Determine the state based on the parameter set
            if ($Grant.IsPresent)
            {
                $evaluateState = 'Grant'
            }
            elseif ($Deny.IsPresent)
            {
                $evaluateState = 'Deny'
            }

            # Handle WithGrant parameter by adjusting the effective state
            if ($WithGrant.IsPresent -and $evaluateState -eq 'Grant')
            {
                $evaluateState = 'GrantWithGrant'
            }

            $originalErrorActionPreference = $ErrorActionPreference

            $ErrorActionPreference = 'Stop'

            # Get current permissions for the principal
            $getSqlDscServerPermissionParameters = @{
                ServerObject = $serverObject
                Name         = $principalName
                ErrorAction  = 'Stop'
            }

            $serverPermissionInfo = Get-SqlDscServerPermission @getSqlDscServerPermissionParameters

            $ErrorActionPreference = $originalErrorActionPreference

            if (-not $serverPermissionInfo)
            {
                Write-Debug -Message (
                    $script:localizedData.ServerPermission_Test_NoPermissionsFound -f $principalName
                )

                # If no permissions exist and none are desired, that's the desired state
                if ($Permission.Count -eq 0)
                {
                    return $true
                }
                else
                {
                    return $false
                }
            }

            # Convert current permissions to ServerPermission objects
            $currentPermissions = $serverPermissionInfo | ConvertTo-SqlDscServerPermission

            # Output verbose information about current permissions as compressed JSON
            $currentPermissionsJson = $currentPermissions | ConvertTo-Json -Compress

            Write-Debug -Message (
                $script:localizedData.ServerPermission_Test_CurrentPermissions -f $principalName, $currentPermissionsJson
            )

            # Handle empty Permission collection - check that no permissions are set
            if ($Permission.Count -eq 0)
            {
                # Check if there are any permissions set for any state
                $hasAnyPermissions = $currentPermissions | Where-Object -FilterScript {
                    $_.Permission.Count -gt 0
                }

                if ($hasAnyPermissions)
                {
                    return $false
                }
                else
                {
                    return $true
                }
            }

            # Find the current permission for the desired state
            $currentPermissionForState = $currentPermissions |
                Where-Object -FilterScript {
                    $_.State -eq $evaluateState
                }

            if (-not $currentPermissionForState)
            {
                return $false
            }

            # Check if all desired permissions are present in current state
            foreach ($permissionName in $Permission)
            {
                if ($permissionName.ToString() -notin $currentPermissionForState.Permission)
                {
                    return $false
                }
            }

            # Check that no unexpected permissions are present (only if ExactMatch is specified)
            if ($ExactMatch.IsPresent)
            {
                $desiredPermissionNames = $Permission | ForEach-Object -Process { $_.ToString() }
                foreach ($currentPermissionName in $currentPermissionForState.Permission)
                {
                    if ($currentPermissionName -notin $desiredPermissionNames)
                    {
                        return $false
                    }
                }
            }

            return $true
        }
        catch
        {
            # If the principal doesn't exist or there's another error, return false
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_Test_TestFailed -f $principalName, $_.Exception.Message
            )

            return $false
        }
    }
}
