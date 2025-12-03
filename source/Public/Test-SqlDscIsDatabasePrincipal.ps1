<#
    .SYNOPSIS
        Returns whether the database principal exist.

    .DESCRIPTION
        Returns whether the database principal exist.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specifies the SQL database name.

    .PARAMETER Name
        Specifies the name of the database principal.

    .PARAMETER ExcludeUsers
        Specifies that database users should not be evaluated.

    .PARAMETER ExcludeRoles
        Specifies that database roles should not be evaluated for the specified
        name. This will also exclude fixed roles.

    .PARAMETER ExcludeFixedRoles
        Specifies that fixed roles should not be evaluated for the specified name.

    .PARAMETER ExcludeApplicationRoles
        Specifies that fixed application roles should not be evaluated for the
        specified name.

    .PARAMETER Refresh
        Specifies that the database's principal collections (Users, Roles, and
        ApplicationRoles) should be refreshed before testing if the principal exists.
        This is helpful when principals could have been modified outside of the
        **ServerObject**, for example through T-SQL. But on databases with a large
        amount of principals it might be better to make sure the **ServerObject**
        is recent enough. When exclude parameters are specified (e.g., **ExcludeUsers**,
        **ExcludeRoles**, **ExcludeApplicationRoles**), only the collections that will
        be used are refreshed to improve performance.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Accepts input via the pipeline.

    .OUTPUTS
        `System.Boolean`

        Returns the output object.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsDatabasePrincipal -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal'

        Returns $true if the principal exist in the database, if not $false is returned.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsDatabasePrincipal -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal' -ExcludeUsers

        Returns $true if the principal exist in the database and is not a user, if not $false is returned.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsDatabasePrincipal -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal' -ExcludeRoles

        Returns $true if the principal exist in the database and is not a role, if not $false is returned.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsDatabasePrincipal -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal' -ExcludeFixedRoles

        Returns $true if the principal exist in the database and is not a fixed role, if not $false is returned.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsDatabasePrincipal -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal' -ExcludeApplicationRoles

        Returns $true if the principal exist in the database and is not a application role, if not $false is returned.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsDatabasePrincipal -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal' -Refresh

        Returns $true if the principal exist in the database, if not $false is returned.
        The database's principal collections are refreshed before testing.
#>
function Test-SqlDscIsDatabasePrincipal
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
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

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeUsers,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeRoles,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeFixedRoles,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeApplicationRoles,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        $principalExist = $false

        if ($Refresh.IsPresent)
        {
            # Refresh the server's databases collection to ensure we have current data
            $ServerObject.Databases.Refresh()
        }

        $sqlDatabaseObject = $ServerObject.Databases[$DatabaseName]

        if ($Refresh.IsPresent -and $sqlDatabaseObject)
        {
            # Refresh the database object's collections to ensure we have current data
            # Only refresh collections that will be used based on exclude parameters
            if (-not $ExcludeRoles.IsPresent)
            {
                $sqlDatabaseObject.Roles.Refresh()
            }

            if (-not $ExcludeUsers.IsPresent)
            {
                $sqlDatabaseObject.Users.Refresh()
            }

            if (-not $ExcludeApplicationRoles.IsPresent)
            {
                $sqlDatabaseObject.ApplicationRoles.Refresh()
            }
        }

        if (-not $sqlDatabaseObject)
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.IsDatabasePrincipal_DatabaseMissing -f $DatabaseName),
                    'TSDISO0001', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DatabaseName
                )
            )
        }

        if (-not $ExcludeUsers.IsPresent -and $sqlDatabaseObject.Users[$Name])
        {
            $principalExist = $true
        }

        if (-not $ExcludeRoles.IsPresent)
        {
            $userDefinedRole = if ($ExcludeFixedRoles.IsPresent)
            {
                # Skip fixed roles like db_datareader.
                $sqlDatabaseObject.Roles | Where-Object -FilterScript {
                    -not $_.IsFixedRole -and $_.Name -eq $Name
                }
            }
            else
            {
                $sqlDatabaseObject.Roles[$Name]
            }

            if ($userDefinedRole)
            {
                $principalExist = $true
            }
        }

        if (-not $ExcludeApplicationRoles.IsPresent -and $sqlDatabaseObject.ApplicationRoles[$Name])
        {
            $principalExist = $true
        }

        return $principalExist
    }
}
