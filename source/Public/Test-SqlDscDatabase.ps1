<#
    .SYNOPSIS
        Tests if a database on a SQL Server Database Engine instance is in the desired state.

    .DESCRIPTION
        This command tests if a database on a SQL Server Database Engine instance is in the desired state.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to test.

    .PARAMETER Ensure
        When set to 'Present', the database must exist.
        When set to 'Absent', the database must not exist.

    .PARAMETER Collation
        The name of the SQL collation that the database should have.

    .PARAMETER CompatibilityLevel
        The version of the SQL compatibility level that the database should have.

    .PARAMETER RecoveryModel
        The recovery model that the database should have.

    .PARAMETER OwnerName
        Specifies the name of the login that should be the owner of the database.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        testing the database state. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscDatabase -Name 'MyDatabase' -Ensure 'Present'

        Tests if the database named **MyDatabase** exists.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscDatabase -Name 'MyDatabase' -Ensure 'Present' -RecoveryModel 'Simple' -OwnerName 'sa'

        Tests if the database named **MyDatabase** exists and has the specified recovery model and owner.

    .OUTPUTS
        `[System.Boolean]`
#>
function Test-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Collation,

        [Parameter()]
        [ValidateSet('Version80', 'Version90', 'Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150', 'Version160')]
        [System.String]
        $CompatibilityLevel,

        [Parameter()]
        [ValidateSet('Simple', 'Full', 'BulkLogged')]
        [System.String]
        $RecoveryModel,

        [Parameter()]
        [System.String]
        $OwnerName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    $ErrorActionPreference = 'Stop'

    process
    {
        if ($Refresh.IsPresent)
        {
            # Refresh the server object's databases collection
            $ServerObject.Databases.Refresh()
        }

        Write-Verbose -Message ($script:localizedData.Database_Test -f $Name, $ServerObject.InstanceName)

        $isDatabaseInDesiredState = $true

        # Check database exists
        $sqlDatabaseObject = $ServerObject.Databases[$Name]

        switch ($Ensure)
        {
            'Absent'
            {
                if ($sqlDatabaseObject)
                {
                    Write-Verbose -Message ($script:localizedData.Database_NotInDesiredStateAbsent -f $Name)
                    $isDatabaseInDesiredState = $false
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.Database_InDesiredStateAbsent -f $Name)
                }
            }

            'Present'
            {
                if (-not $sqlDatabaseObject)
                {
                    Write-Verbose -Message ($script:localizedData.Database_NotInDesiredStatePresent -f $Name)
                    $isDatabaseInDesiredState = $false
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.Database_InDesiredStatePresent -f $Name)

                    if ($PSBoundParameters.ContainsKey('Collation') -and $sqlDatabaseObject.Collation -ne $Collation)
                    {
                        Write-Verbose -Message ($script:localizedData.Database_CollationWrong -f $Name, $sqlDatabaseObject.Collation, $Collation)
                        $isDatabaseInDesiredState = $false
                    }

                    if ($PSBoundParameters.ContainsKey('CompatibilityLevel') -and $sqlDatabaseObject.CompatibilityLevel -ne $CompatibilityLevel)
                    {
                        Write-Verbose -Message ($script:localizedData.Database_CompatibilityLevelWrong -f $Name, $sqlDatabaseObject.CompatibilityLevel, $CompatibilityLevel)
                        $isDatabaseInDesiredState = $false
                    }

                    if ($PSBoundParameters.ContainsKey('RecoveryModel') -and $sqlDatabaseObject.RecoveryModel -ne $RecoveryModel)
                    {
                        Write-Verbose -Message ($script:localizedData.Database_RecoveryModelWrong -f $Name, $sqlDatabaseObject.RecoveryModel, $RecoveryModel)
                        $isDatabaseInDesiredState = $false
                    }

                    if ($PSBoundParameters.ContainsKey('OwnerName') -and $sqlDatabaseObject.Owner -ne $OwnerName)
                    {
                        Write-Verbose -Message ($script:localizedData.Database_OwnerNameWrong -f $Name, $sqlDatabaseObject.Owner, $OwnerName)
                        $isDatabaseInDesiredState = $false
                    }
                }
            }
        }

        return $isDatabaseInDesiredState
    }
}
