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

    .OUTPUTS
        [System.Boolean]

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
        $ExcludeApplicationRoles
    )

    process
    {
        $principalExist = $false

        $sqlDatabaseObject = $ServerObject.Databases[$DatabaseName]

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
