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

    .OUTPUTS
        [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]]

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Get-SqlDscDatabasePermission -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal'

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
    <#
        The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error
        in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8
        When QA test run it loads the stub SMO classes so that the rule passes.
        To get the rule to pass in the editor, in the Integrated Console run:
        Add-Type -Path 'Tests/Unit/Stubs/SMO.cs'
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([System.Object[]])]
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
        $Name
    )

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

    return , $getSqlDscDatabasePermissionResult
}