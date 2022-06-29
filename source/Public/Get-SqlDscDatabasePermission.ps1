<#
    .SYNOPSIS
        Returns the current permissions for the database principal.

    .PARAMETER ServerObject
        Specifies current server connection object.

    # .PARAMETER InstanceName
    #     Specifies the SQL instance for the database.

    .PARAMETER DatabaseName
        Specifies the SQL database name.

    .PARAMETER Name
        Specifies the name of the database principal for which the permission set is returned.

    # .PARAMETER PermissionState
    #     This is the state of permission set. Valid values are 'Grant' or 'Deny'.

    # .PARAMETER Permissions
    #     This is a list that represents a SQL Server set of database permissions.

    .NOTES
        This command excludes fixed roles like db_datareader.

        TODO: This function will not throw an error if for example the database
              does not exist, so that the Get() method of the resource does not
              throw. Suggest adding optional parmeter 'FailOnError',
              or 'EvaluateMandatoryProperties', or a combination.
#>
function Get-SqlDscDatabasePermission
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        # [Parameter(Mandatory = $true)]
        # [System.String]
        # $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name

        # [Parameter(Mandatory = $true)]
        # [ValidateSet('Grant', 'Deny', 'GrantWithGrant')]
        # [System.String]
        # $PermissionState,

        # [Parameter(Mandatory = $true)]
        # [System.String[]]
        # $Permissions,

        # [Parameter()]
        # [ValidateNotNullOrEmpty()]
        # [System.String]
        # $ServerName = (Get-ComputerName)
    )

    # Initialize variable permission
    [System.String[]] $getSqlDatabasePermissionResult = @()

    $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]

    if ($sqlDatabaseObject)
    {
        $isDatabasePrincipal = Test-SqlDscIsDatabasePrincipal @PSBoundParameters -ExcludeFixedRoles

        if ($isDatabasePrincipal)
        {
            $databasePermissionInfo = $sqlDatabaseObject.EnumDatabasePermissions($Name) |
                Where-Object -FilterScript {
                    $_.PermissionState -eq $PermissionState
                }

            if ($databasePermissionInfo)
            {
                foreach ($currentDatabasePermissionInfo in $databasePermissionInfo)
                {
                    $permissionProperty = (
                        $currentDatabasePermissionInfo.PermissionType |
                            Get-Member -MemberType Property
                    ).Name

                    foreach ($currentPermissionProperty in $permissionProperty)
                    {
                        if ($currentDatabasePermissionInfo.PermissionType."$currentPermissionProperty")
                        {
                            $getSqlDatabasePermissionResult += $currentPermissionProperty
                        }
                    }

                    # Remove any duplicate permissions.
                    $getSqlDatabasePermissionResult = @(
                        $getSqlDatabasePermissionResult |
                            Sort-Object -Unique
                    )
                }
            }
        }
        else
        {
            Write-Verbose -Message ("The database principal '{0}' is neither a user, database role (user-defined), or database application role in the database '{1}'. (GETSDP0001)." -f $Name, $DatabaseName)
        }
    }
    else
    {
        Write-Verbose -Message ("The database '{0}' did not exist. (GETSDP0002)" -f $DatabaseName)
    }

    return [System.String[]] $getSqlDatabasePermissionResult
}
