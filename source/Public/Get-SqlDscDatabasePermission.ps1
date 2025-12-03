<#
    .SYNOPSIS
        Returns the current permissions for the database principal.

    .DESCRIPTION
        Returns the current permissions for the database principal.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specifies the database name.

    .PARAMETER Name
        Specifies the name of the database principal for which the permissions are
        returned.

    .PARAMETER Refresh
        Specifies that the database's principal collections (Users, Roles, and
        ApplicationRoles) should be refreshed before testing if the principal exists.
        This is helpful when principals could have been modified outside of the
        **ServerObject**, for example through T-SQL. But on databases with a large
        amount of principals it might be better to make sure the **ServerObject**
        is recent enough.

    
    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Accepts input via the pipeline.

.OUTPUTS
        `Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[`

        Returns the output object.]

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Get-SqlDscDatabasePermission -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal'

        Get the permissions for the principal 'MyPrincipal'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Get-SqlDscDatabasePermission -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal' -Refresh

        Get the permissions for the principal 'MyPrincipal'. The database's principal
        collections are refreshed before testing if the principal exists.

    .NOTES
        This command excludes fixed roles like _db_datareader_ by default, and will
        always return `$null` if a fixed role is specified as **Name**.

        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the database (parameter **DatabaseName**) is not present or the
        database principal is not present. In such case the command will return `$null`.
        If specifying `-ErrorAction 'Stop'` the command will throw an error if the
        database or database principal is missing.
#>
function Get-SqlDscDatabasePermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
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
        $Refresh
    )

    # cSpell: ignore GSDDP
    process
    {
        $getSqlDscDatabasePermissionResult = $null

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

            if ($Refresh.IsPresent)
            {
                $testSqlDscIsDatabasePrincipalParameters.Refresh = $true
            }

            $isDatabasePrincipal = Test-SqlDscIsDatabasePrincipal @testSqlDscIsDatabasePrincipalParameters

            if ($isDatabasePrincipal)
            {
                $getSqlDscDatabasePermissionResult = $sqlDatabaseObject.EnumDatabasePermissions($Name)
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

        return [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $getSqlDscDatabasePermissionResult
    }
}
