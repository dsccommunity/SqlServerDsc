<#
    .SYNOPSIS
        Get databases from a SQL Server Database Engine instance.

    .DESCRIPTION
        This command gets one or more databases from a SQL Server Database Engine instance.
        If no name is specified, all databases are returned.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to get. If not specified, all
        databases are returned.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        trying to get the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscDatabase

        Get all databases from the instance.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'

        Get the database named **MyDatabase**.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Database[]]`
#>
function Get-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        if ($Refresh.IsPresent)
        {
            # Refresh the server object's databases collection
            $ServerObject.Databases.Refresh()
        }

        Write-Verbose -Message ($script:localizedData.Database_Get -f $ServerObject.InstanceName)

        $databaseObject = @()

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $databaseObject = $ServerObject.Databases[$Name]

            if (-not $databaseObject)
            {
                Write-Verbose -Message ($script:localizedData.Database_NotFound -f $Name)

                $missingDatabaseMessage = $script:localizedData.Database_NotFound -f $Name

                $writeErrorParameters = @{
                    Message      = $missingDatabaseMessage
                    Category     = 'ObjectNotFound'
                    ErrorId      = 'GSDD0001' # cspell: disable-line
                    TargetObject = $Name
                }

                Write-Error @writeErrorParameters
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Database_Found -f $Name)
            }
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.Database_GetAll)

            $databaseObject = $ServerObject.Databases
        }

        return [Microsoft.SqlServer.Management.Smo.Database[]] $databaseObject
    }
}
