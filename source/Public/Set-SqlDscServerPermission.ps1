<#
    .SYNOPSIS
        Sets exact server permissions for a principal.

    .DESCRIPTION
        This command sets the exact server permissions for a principal on a SQL Server
        Database Engine instance. The permissions passed in will be the only permissions
        set for the principal - any existing permissions not specified will be revoked.

        The principal can be specified as either a Login object (from Get-SqlDscLogin)
        or a ServerRole object (from Get-SqlDscRole).

        This command internally uses Get-SqlDscServerPermission, Grant-SqlDscServerPermission,
        Deny-SqlDscServerPermission, and Revoke-SqlDscServerPermission to ensure the
        principal has exactly the permissions specified.

    .PARAMETER Login
        Specifies the Login object for which the permissions are set.
        This parameter accepts pipeline input.

    .PARAMETER ServerRole
        Specifies the ServerRole object for which the permissions are set.
        This parameter accepts pipeline input.

    .PARAMETER Grant
        Specifies the permissions that should be granted. The permissions specified
        will be the exact granted permissions - any existing granted permissions not
        in this list will be revoked. If this parameter is omitted (not specified),
        existing Grant permissions are left unchanged.

    .PARAMETER GrantWithGrant
        Specifies the permissions that should be granted with the grant option.
        The permissions specified will be the exact grant-with-grant permissions -
        any existing grant-with-grant permissions not in this list will be revoked.
        If this parameter is omitted (not specified), existing GrantWithGrant
        permissions are left unchanged.

    .PARAMETER Deny
        Specifies the permissions that should be denied. The permissions specified
        will be the exact denied permissions - any existing denied permissions not
        in this list will be revoked. If this parameter is omitted (not specified),
        existing Deny permissions are left unchanged.

    .PARAMETER Force
        Specifies that the permissions should be set without any confirmation.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Login`

        Accepts input via the pipeline.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.ServerRole`

        Accepts input via the pipeline.

    .OUTPUTS
        None.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $login = $serverInstance | Get-SqlDscLogin -Name 'MyLogin'

        Set-SqlDscServerPermission -Login $login -Grant ConnectSql, ViewServerState

        Sets the exact granted permissions for the login 'MyLogin'. Any other
        granted permissions will be revoked.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $login = $serverInstance | Get-SqlDscLogin -Name 'MyLogin'

        Set-SqlDscServerPermission -Login $login -Grant ConnectSql -GrantWithGrant AlterAnyDatabase -Deny ViewAnyDatabase

        Sets exact permissions for the login 'MyLogin': grants ConnectSql,
        grants AlterAnyDatabase with grant option, and denies ViewAnyDatabase.
        Any other permissions will be revoked.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $role = $serverInstance | Get-SqlDscRole -Name 'MyRole'

        $role | Set-SqlDscServerPermission -Grant @() -Force

        Revokes all granted permissions from the role 'MyRole' without prompting
        for confirmation.

    .NOTES
        The Login or ServerRole object must come from the same SQL Server instance
        where the permissions will be set. If specifying `-ErrorAction 'SilentlyContinue'`
        then the command will silently continue if any errors occur. If specifying
        `-ErrorAction 'Stop'` the command will throw an error on any failure.

        > [!IMPORTANT]
        > This command only modifies permission categories that are explicitly specified.
        > If you omit a parameter (e.g., don't specify `-Grant`), permissions in that
        > category are left unchanged. However, if you specify a parameter (even as an
        > empty array like `-Grant @()`), the command sets exact permissions for that
        > category only - revoking any permissions not in the list. This allows you to
        > independently manage Grant, GrantWithGrant, and Deny permissions without
        > affecting the other categories.
#>
function Set-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Login')]
        [Microsoft.SqlServer.Management.Smo.Login]
        $Login,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ServerRole')]
        [Microsoft.SqlServer.Management.Smo.ServerRole]
        $ServerRole,

        [Parameter()]
        [AllowEmptyCollection()]
        [SqlServerPermission[]]
        $Grant,

        [Parameter()]
        [AllowEmptyCollection()]
        [SqlServerPermission[]]
        $GrantWithGrant,

        [Parameter()]
        [AllowEmptyCollection()]
        [SqlServerPermission[]]
        $Deny,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        # Determine which principal object we're working with
        if ($PSCmdlet.ParameterSetName -eq 'Login')
        {
            $principalObject = $Login
            $principalName = $Login.Name
            $serverObject = $Login.Parent
        }
        else
        {
            $principalObject = $ServerRole
            $principalName = $ServerRole.Name
            $serverObject = $ServerRole.Parent
        }

        $verboseDescriptionMessage = $script:localizedData.ServerPermission_Set_ShouldProcessVerboseDescription -f $principalName, $serverObject.InstanceName
        $verboseWarningMessage = $script:localizedData.ServerPermission_Set_ShouldProcessVerboseWarning -f $principalName
        $captionMessage = $script:localizedData.ServerPermission_Set_ShouldProcessCaption

        if (-not $PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Return without doing anything if the user did not want to continue processing.
            return
        }

        # Get current permissions for the principal
        $currentPermissionInfo = $principalObject | Get-SqlDscServerPermission -ErrorAction 'SilentlyContinue'

        # Convert current permissions to categorized arrays
        $currentGrant = @()
        $currentGrantWithGrant = @()
        $currentDeny = @()

        if ($currentPermissionInfo)
        {
            $currentServerPermission = $currentPermissionInfo | ConvertTo-SqlDscServerPermission

            foreach ($permissionState in $currentServerPermission)
            {
                switch ($permissionState.State)
                {
                    'Grant'
                    {
                        $currentGrant = $permissionState.Permission
                    }

                    'GrantWithGrant'
                    {
                        $currentGrantWithGrant = $permissionState.Permission
                    }

                    'Deny'
                    {
                        $currentDeny = $permissionState.Permission
                    }
                }
            }
        }

        # Calculate what needs to be revoked and added
        # Only process permission categories that were explicitly specified via parameters
        $grantToRevoke = @()
        $grantToAdd = @()
        $grantWithGrantToRevoke = @()
        $grantWithGrantToAdd = @()
        $denyToRevoke = @()
        $denyToAdd = @()

        # Only process Grant permissions if the parameter was explicitly specified
        if ($PSBoundParameters.ContainsKey('Grant'))
        {
            $grantToRevoke = $currentGrant | Where-Object -FilterScript { $_ -notin $Grant }
            $grantToAdd = $Grant | Where-Object -FilterScript { $_ -notin $currentGrant }
        }

        # Only process GrantWithGrant permissions if the parameter was explicitly specified
        if ($PSBoundParameters.ContainsKey('GrantWithGrant'))
        {
            $grantWithGrantToRevoke = $currentGrantWithGrant | Where-Object -FilterScript { $_ -notin $GrantWithGrant }
            $grantWithGrantToAdd = $GrantWithGrant | Where-Object -FilterScript { $_ -notin $currentGrantWithGrant }
        }

        # Only process Deny permissions if the parameter was explicitly specified
        if ($PSBoundParameters.ContainsKey('Deny'))
        {
            $denyToRevoke = $currentDeny | Where-Object -FilterScript { $_ -notin $Deny }
            $denyToAdd = $Deny | Where-Object -FilterScript { $_ -notin $currentDeny }
        }

        # Revoke permissions that should no longer exist
        if ($grantToRevoke -and $grantToRevoke.Count -gt 0)
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_RevokePermission -f ($grantToRevoke -join ', '), $principalName
            )

            $principalObject | Revoke-SqlDscServerPermission -Permission $grantToRevoke -Force
        }

        if ($grantWithGrantToRevoke -and $grantWithGrantToRevoke.Count -gt 0)
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_RevokePermission -f ($grantWithGrantToRevoke -join ', '), $principalName
            )

            $principalObject | Revoke-SqlDscServerPermission -Permission $grantWithGrantToRevoke -WithGrant -Force
        }

        if ($denyToRevoke -and $denyToRevoke.Count -gt 0)
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_RevokePermission -f ($denyToRevoke -join ', '), $principalName
            )

            $principalObject | Revoke-SqlDscServerPermission -Permission $denyToRevoke -Force
        }

        # Grant permissions that should be added
        if ($grantToAdd -and $grantToAdd.Count -gt 0)
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_GrantPermission -f ($grantToAdd -join ', '), $principalName
            )

            $principalObject | Grant-SqlDscServerPermission -Permission $grantToAdd -Force
        }

        if ($grantWithGrantToAdd -and $grantWithGrantToAdd.Count -gt 0)
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_GrantPermission -f ($grantWithGrantToAdd -join ', '), $principalName
            )

            $principalObject | Grant-SqlDscServerPermission -Permission $grantWithGrantToAdd -WithGrant -Force
        }

        # Deny permissions that should be added
        if ($denyToAdd -and $denyToAdd.Count -gt 0)
        {
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_DenyPermission -f ($denyToAdd -join ', '), $principalName
            )

            $principalObject | Deny-SqlDscServerPermission -Permission $denyToAdd -Force
        }
    }
}
