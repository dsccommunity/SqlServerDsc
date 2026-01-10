<#
    .SYNOPSIS
        Retrieves the current date and time from a SQL Server instance.

    .DESCRIPTION
        Retrieves the current date and time from a SQL Server instance using the
        specified T-SQL date/time function. This command helps eliminate clock-skew
        and timezone issues when coordinating time-sensitive operations between the
        client and SQL Server.

        The command queries SQL Server using the server connection context, which
        does not require any database to be online.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DateTimeFunction
        Specifies which T-SQL date/time function to use for retrieving the date and time.
        Valid values are:
        - `SYSDATETIME` (default): Returns datetime2(7) with server local time
        - `SYSDATETIMEOFFSET`: Returns datetimeoffset(7) with server local time and timezone offset
        - `SYSUTCDATETIME`: Returns datetime2(7) with UTC time
        - `GETDATE`: Returns datetime with server local time
        - `GETUTCDATE`: Returns datetime with UTC time

    .PARAMETER StatementTimeout
        Specifies the query StatementTimeout in seconds. Default 600 seconds (10 minutes).

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Accepts input via the pipeline.

    .OUTPUTS
        `System.DateTime`

        Returns the current date and time from the SQL Server instance.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Get-SqlDscDateTime -ServerObject $serverObject

        Connects to the default instance and retrieves the current date and time
        using the default SYSDATETIME function.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        $serverObject | Get-SqlDscDateTime -DateTimeFunction 'SYSUTCDATETIME'

        Connects to the default instance and retrieves the current UTC date and time
        from the SQL Server instance.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        $serverTime = Get-SqlDscDateTime -ServerObject $serverObject
        Restore-SqlDscDatabase -ServerObject $serverObject -Name 'MyDatabase' -StopAt $serverTime.AddHours(-1)

        Demonstrates using the server's clock for a point-in-time restore operation,
        avoiding clock skew issues between client and server.
#>
function Get-SqlDscDateTime
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.DateTime])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [ValidateSet('SYSDATETIME', 'SYSDATETIMEOFFSET', 'SYSUTCDATETIME', 'GETDATE', 'GETUTCDATE')]
        [System.String]
        $DateTimeFunction = 'SYSDATETIME',

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600
    )

    process
    {
        Write-Verbose -Message (
            $script:localizedData.Get_SqlDscDateTime_RetrievingDateTime -f $DateTimeFunction
        )

        $query = "SELECT $DateTimeFunction()"

        $invokeSqlDscScalarQueryParameters = @{
            ServerObject     = $ServerObject
            Query            = $query
            StatementTimeout = $StatementTimeout
            ErrorAction      = 'Stop'
            Verbose          = $VerbosePreference
        }

        try
        {
            $result = Invoke-SqlDscScalarQuery @invokeSqlDscScalarQueryParameters

            # Convert the result to DateTime if it's a DateTimeOffset
            if ($result -is [System.DateTimeOffset])
            {
                $result = $result.DateTime
            }

            return $result
        }
        catch
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Get_SqlDscDateTime_FailedToRetrieve -f $DateTimeFunction, $_.Exception.Message
                Category     = 'InvalidOperation'
                ErrorId      = 'GSDD0001' # cSpell: disable-line
                TargetObject = $DateTimeFunction
                Exception    = $_.Exception
            }

            Write-Error @writeErrorParameters

            return
        }
    }
}
