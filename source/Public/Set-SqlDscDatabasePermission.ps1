<#
    .SYNOPSIS
        Returns the current permissions for the database principal.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specifies the database name.

    .PARAMETER Name
        Specifies the name of the database principal for which the permissions are
        returned.

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

    .OUTPUTS
        None.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $setPermission = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
            Connect = $true
            Update = $true
        }

        Set-SqlDscDatabasePermission -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal' -State 'Grant' -Permission $setPermission

    .NOTES
        This command excludes fixed roles like _db_datareader_ by default, and will
        always throw a non-terminating error if a fixed role is specified as **Name**.

        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the database (parameter **DatabaseName**) is not present or the
        database principal is not present. If specifying `-ErrorAction 'Stop'` the
        command will throw an error if the database or database principal is missing.

        # TODO: This command should support ShouldProcess and Force parameter. Also,
                the ScriptAnalyzer rule should be run on Public functions.

        # TODO: Document the public commands using PlatyPS, might use Sampler/ActiveDirectoryDsc as an example?
#>
function Set-SqlDscDatabasePermission
{
    <#
        The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error
        in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8
        When QA test run it loads the stub SMO classes so that the rule passes.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
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
        $WithGrant
    )

    # TODO: Assert properties to WithGrant it only possible for Grant and Revoke
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
            # TODO: Set permissions.
            Write-Verbose -Message (
                $script:localizedData.DatabasePermission_ChangePermissionForUser -f $Name, $DatabaseName, $InstanceName
            )

            # Get the permissions names that are set to $true in the DatabasePermissionSet.
            $permissionName = $Permission |
                Get-Member -MemberType 'Property' |
                Select-Object -ExpandProperty 'Name' |
                Where-Object -FilterScript {
                    $setPermission.$_
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

            Write-Error -Message $missingPrincipalMessage -Category 'InvalidOperation' -ErrorId 'GSDDP0001' -TargetObject $Name
        }
    }
    else
    {
        $missingDatabaseMessage = $script:localizedData.DatabasePermission_MissingDatabase -f $DatabaseName

        Write-Error -Message $missingDatabaseMessage -Category 'InvalidOperation' -ErrorId 'GSDDP0002' -TargetObject $DatabaseName
    }
}
