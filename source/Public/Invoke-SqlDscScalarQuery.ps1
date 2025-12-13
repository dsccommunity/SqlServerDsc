<#
    .SYNOPSIS
        Executes a scalar query on the specified server.

    .DESCRIPTION
        Executes a scalar query on the specified server using the server connection
        context. This command is designed for queries that return a single value,
        such as `SELECT @@VERSION` or `SELECT SYSDATETIME()`.

        The command uses `Server.ConnectionContext.ExecuteScalar()` which is
        server-level and does not require any database to be online.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Query
        Specifies the scalar query string to execute.

    .PARAMETER StatementTimeout
        Specifies the query StatementTimeout in seconds. Default 600 seconds (10 minutes).

    .PARAMETER RedactText
        Specifies one or more text strings to redact from the query when verbose messages
        are written to the console. Strings will be escaped so they will not
        be interpreted as regular expressions (RegEx).

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Accepts input via the pipeline.

    .OUTPUTS
        `System.Object`

        Returns the scalar value returned by the query.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Invoke-SqlDscScalarQuery -ServerObject $serverObject -Query 'SELECT @@VERSION'

        Connects to the default instance and then runs a query to return the SQL Server version.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        $serverObject | Invoke-SqlDscScalarQuery -Query 'SELECT SYSDATETIME()'

        Connects to the default instance and then runs the query to return the current
        date and time from the SQL Server instance.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Invoke-SqlDscScalarQuery -ServerObject $serverObject -Query "SELECT name FROM sys.databases WHERE name = 'MyPassword123'" -RedactText @('MyPassword123') -Verbose

        Shows how to redact sensitive information in the query when the query string
        is output as verbose information when the parameter Verbose is used.
#>
function Invoke-SqlDscScalarQuery
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.Object])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RedactText
    )

    process
    {
        $redactedQuery = $Query

        if ($PSBoundParameters.ContainsKey('RedactText'))
        {
            $redactedQuery = ConvertTo-RedactedText -Text $Query -RedactPhrase $RedactText
        }

        Write-Verbose -Message (
            $script:localizedData.ScalarQuery_Invoke_ExecutingQuery -f $redactedQuery
        )

        $previousStatementTimeout = $null

        if ($PSBoundParameters.ContainsKey('StatementTimeout'))
        {
            # Make sure we can return the StatementTimeout before exiting.
            $previousStatementTimeout = $ServerObject.ConnectionContext.StatementTimeout

            $ServerObject.ConnectionContext.StatementTimeout = $StatementTimeout
        }

        try
        {
            $result = $ServerObject.ConnectionContext.ExecuteScalar($Query)

            return $result
        }
        catch
        {
            $writeErrorParameters = @{
                Message      = $_.Exception.Message
                Category     = 'InvalidOperation'
                ErrorId      = 'ISDSQ0001' # cSpell: disable-line
                TargetObject = $Query
                Exception    = $_.Exception
            }

            Write-Error @writeErrorParameters

            return
        }
        finally
        {
            if ($previousStatementTimeout)
            {
                $ServerObject.ConnectionContext.StatementTimeout = $previousStatementTimeout
            }
        }
    }
}
