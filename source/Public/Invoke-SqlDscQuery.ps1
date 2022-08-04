<#
    .SYNOPSIS
        Executes a query on the specified database.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specify the name of the database to execute the query on.

    .PARAMETER Query
        The query string to execute.

    .PARAMETER PassThru
        Specifies if the command should return any result the query might return.

    .PARAMETER StatementTimeout
        Set the query StatementTimeout in seconds. Default 600 seconds (10 minutes).

    .PARAMETER RedactText
        One or more strings to redact from the query when verbose messages are
        written to the console. Strings here will be escaped so they will not
        be interpreted as regular expressions (RegEx).

    .OUTPUTS
        `[System.Data.DataSet]` when passing parameter **PassThru**, otherwise
        outputs none.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Invoke-SqlDscQuery -ServerObject $serverInstance -Database master `
            -Query 'SELECT name FROM sys.databases' -PassThru

        Runs the query and returns all the database names in the instance.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Invoke-SqlDscQuery -ServerObject $serverInstance -Database master `
            -Query 'RESTORE DATABASE [NorthWinds] WITH RECOVERY'

        Runs the query to restores the database NorthWinds.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Invoke-SqlDscQuery -ServerObject $serverInstance -Database master `
            -Query "select * from MyTable where password = 'PlaceholderPa\ssw0rd1' and password = 'placeholder secret passphrase'" `
            -PassThru -RedactText @('PlaceholderPa\sSw0rd1','Placeholder Secret PassPhrase') `
            -Verbose

        Shows how to redact sensitive information in the query when the query string
        is output as verbose information when the parameter Verbose is used.

    .NOTES
        This is a wrapper for private function Invoke-Query, until it move into
        this public function.
#>
function Invoke-SqlDscQuery
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.Data.DataSet])]
    [CmdletBinding()]
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
        $Query,

        [Parameter()]
        [Switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600,

        [Parameter()]
        [System.String[]]
        $RedactText
    )

    $invokeQueryParameters = @{
        SqlServerObject  = $ServerObject
        Database         = $DatabaseName
        Query            = $Query
    }

    if ($PSBoundParameters.ContainsKey('PassThru'))
    {
        $invokeQueryParameters.WithResults = $PassThru
    }

    if ($PSBoundParameters.ContainsKey('StatementTimeout'))
    {
        $invokeQueryParameters.StatementTimeout = $StatementTimeout
    }

    if ($PSBoundParameters.ContainsKey('RedactText'))
    {
        $invokeQueryParameters.RedactText = $RedactText
    }

    return (Invoke-Query @invokeQueryParameters)
}
