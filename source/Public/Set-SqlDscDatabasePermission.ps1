<#
    .SYNOPSIS
        Set permission for a database principal.

    .DESCRIPTION
        Set permission for a database principal.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specifies the database name.

    .PARAMETER Name
        Specifies the name of the database principal for which the permissions are
        set.

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

        $setPermission = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
            Connect = $true
            Update = $true
        }

        Set-SqlDscDatabasePermission -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal' -State 'Grant' -Permission $setPermission

        Sets the permissions for the principal 'MyPrincipal'.

    .NOTES
        This command excludes fixed roles like _db_datareader_ by default, and will
        always throw a non-terminating error if a fixed role is specified as **Name**.

        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the database (parameter **DatabaseName**) is not present or the
        database principal is not present. If specifying `-ErrorAction 'Stop'` the
        command will throw an error if the database or database principal is missing.
#>
function Set-SqlDscDatabasePermission
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
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'Revoke')]
        [System.String]
        $State,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
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
            Write-Warning -Message $script:localizedData.DatabasePermission_IgnoreWithGrantForStateDeny
        }

        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $sqlDatabaseObject = $null

        if ($ServerObject.Databases)
        {
            $sqlDatabaseObject = $ServerObject.Databases[$DatabaseName]
        }

        if ($sqlDatabaseObject)
        {
            $testSqlDscIsDatabasePrincipalParameters = @{
                ServerObject      = $ServerObject
                DatabaseName      = $DatabaseName
                Name              = $Name
                ExcludeFixedRoles = $true
            }

            $isDatabasePrincipal = Test-SqlDscIsDatabasePrincipal @testSqlDscIsDatabasePrincipalParameters

            if ($isDatabasePrincipal)
            {
                # Get the permissions names that are set to $true in the DatabasePermissionSet.
                $permissionName = $Permission |
                    Get-Member -MemberType 'Property' |
                    Select-Object -ExpandProperty 'Name' |
                    Where-Object -FilterScript {
                        $Permission.$_
                    }

                $verboseDescriptionMessage = $script:localizedData.DatabasePermission_ChangePermissionShouldProcessVerboseDescription -f $Name, $DatabaseName, $ServerObject.InstanceName
                $verboseWarningMessage = $script:localizedData.DatabasePermission_ChangePermissionShouldProcessVerboseWarning -f $Name
                $captionMessage = $script:localizedData.DatabasePermission_ChangePermissionShouldProcessCaption

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
                            $script:localizedData.DatabasePermission_GrantPermission -f ($permissionName -join ','), $Name
                        )

                        if ($WithGrant.IsPresent)
                        {
                            $sqlDatabaseObject.Grant($Permission, $Name, $true)
                        }
                        else
                        {
                            $sqlDatabaseObject.Grant($Permission, $Name)
                        }
                    }

                    'Deny'
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DatabasePermission_DenyPermission -f ($permissionName -join ','), $Name
                        )

                        $sqlDatabaseObject.Deny($Permission, $Name)
                    }

                    'Revoke'
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DatabasePermission_RevokePermission -f ($permissionName -join ','), $Name
                        )

                        if ($WithGrant.IsPresent)
                        {
                            $sqlDatabaseObject.Revoke($Permission, $Name, $false, $true)
                        }
                        else
                        {
                            $sqlDatabaseObject.Revoke($Permission, $Name)
                        }
                    }
                }
            }
            else
            {
                $missingPrincipalMessage = $script:localizedData.DatabasePermission_MissingPrincipal -f $Name, $DatabaseName

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
        else
        {
            $missingDatabaseMessage = $script:localizedData.DatabasePermission_MissingDatabase -f $DatabaseName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $missingDatabaseMessage,
                    'GSDDP0002', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DatabaseName
                )
            )
        }
    }
}
