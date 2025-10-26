<#
    .SYNOPSIS
        Tests if a database exists on a SQL Server Database Engine instance.

    .DESCRIPTION
        This command tests if a database exists on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to test for existence.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        testing the database existence. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscIsDatabase -Name 'MyDatabase'

        Tests if the database named **MyDatabase** exists on the instance.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscIsDatabase -ServerObject $serverObject -Name 'MyDatabase' -Refresh

        Tests if the database named **MyDatabase** exists on the instance, refreshing
        the server object's databases collection first.

    .OUTPUTS
        `[System.Boolean]`

    .INPUTS
        `[Microsoft.SqlServer.Management.Smo.Server]`

        The server object can be provided via the pipeline to **ServerObject**.
#>
function Test-SqlDscIsDatabase
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
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        Write-Verbose -Message ($script:localizedData.IsDatabase_Test -f $Name, $ServerObject.InstanceName)

        # Check if database exists using Get-SqlDscDatabase
        $sqlDatabaseObject = Get-SqlDscDatabase -ServerObject $ServerObject -Name $Name -Refresh:$Refresh -ErrorAction 'SilentlyContinue'

        if ($sqlDatabaseObject)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
}
