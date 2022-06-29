<#
    .SYNOPSIS
        Returns whether the database principal exist.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specifies the SQL database name.

    .PARAMETER Name
        Specifies the name of the database principal.
#>
function Test-SqlDscIsDatabasePrincipal
{
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

    $principalExist = $false

    $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]

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
