<#
    .SYNOPSIS
        Set permission for a login.

    .DESCRIPTION
        This command sets the permissions for a existing login on a SQL Server
        Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the principal for which the permissions are set.

    .PARAMETER State
        Specifies the state of the permission.

    .PARAMETER Permission
        Specifies the permissions.

    .PARAMETER WithGrant
        Specifies that the principal should also be granted the right to grant
        other principals the same permission. This parameter is only valid when
        parameter **State** is set to `Grant` or `Revoke`. When the parameter
        **State** is set to `Revoke` the right to grant will also be revoked,
        and the revocation will cascade.

    .PARAMETER Force
        Specifies that the permissions should be set without any confirmation.

    .OUTPUTS
        None.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $setPermission = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
            Connect = $true
            Update = $true
        }

        Set-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyPrincipal' -State 'Grant' -Permission $setPermission

        Sets the permissions for the principal 'MyPrincipal'.

    .NOTES
        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the principal is not present. If specifying `-ErrorAction 'Stop'` the
        command will throw an error if the principal is missing.
#>
function Set-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'Revoke')]
        [System.String]
        $State,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
        $Permission,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $WithGrant,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($State -eq 'Deny' -and $WithGrant.IsPresent)
        {
            Write-Warning -Message $script:localizedData.ServerPermission_IgnoreWithGrantForStateDeny
        }

        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $testSqlDscIsLoginParameters = @{
            ServerObject = $ServerObject
            Name         = $Name
        }

        $isLogin = Test-SqlDscIsLogin @testSqlDscIsLoginParameters

        if ($isLogin)
        {
            # Get the permissions names that are set to $true in the ServerPermissionSet.
            $permissionName = $Permission |
                Get-Member -MemberType 'Property' |
                Select-Object -ExpandProperty 'Name' |
                Where-Object -FilterScript {
                    $Permission.$_
                }

            $verboseDescriptionMessage = $script:localizedData.ServerPermission_ChangePermissionShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
            $verboseWarningMessage = $script:localizedData.ServerPermission_ChangePermissionShouldProcessVerboseWarning -f $Name
            $captionMessage = $script:localizedData.ServerPermission_ChangePermissionShouldProcessCaption

            if (-not $PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
            {
                # Return without doing anything if the user did not want to continue processing.
                return
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
        else
        {
            $missingPrincipalMessage = $script:localizedData.ServerPermission_MissingPrincipal -f $Name, $ServerObject.InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $missingPrincipalMessage,
                    'GSDDP0001', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Name
                )
            )
        }
    }
}
