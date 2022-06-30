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

    .PARAMETER IgnoreMissingPrincipal
        Specifies that the command ignores if the database principal do not exist
        which also include if database is not present.
        If not passed the command throws an error if the database or database
        principal is missing.

    .OUTPUTS
        [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]]

    .NOTES
        This command excludes fixed roles like db_datareader, and will always return
        $null for such roles.
#>
function Get-SqlDscDatabasePermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Because Script Analyzer does not understand type even if cast when using comma in return statement')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]])]
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
        $IgnoreMissingPrincipal
    )

    # Initialize variable permission
    $getSqlDscDatabasePermissionResult = $null

    $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]

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
            $getSqlDscDatabasePermissionResult = $sqlDatabaseObject.EnumDatabasePermissions($Name)
        }
        else
        {
            $missingPrincipalMessage = $script:localizedData.DatabasePermissionMissingPrincipal -f $Name, $DatabaseName

            if ($IgnoreMissingPrincipal.IsPresent)
            {
                Write-Verbose -Message $missingPrincipalMessage
            }
            else
            {
                throw $missingPrincipalMessage
            }
        }
    }
    else
    {
        $missingPrincipalMessage = $script:localizedData.DatabasePermissionMissingDatabase -f $DatabaseName

        if ($IgnoreMissingPrincipal.IsPresent)
        {
            Write-Verbose -Message $missingPrincipalMessage
        }
        else
        {
            throw $missingPrincipalMessage
        }
    }

    return , $getSqlDscDatabasePermissionResult
}
