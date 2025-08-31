<#
    .SYNOPSIS
        Executes a query on the specified database.

    .DESCRIPTION
        Executes a query on the specified database.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER ServerName
        Specifies the server name where the instance exist.

    .PARAMETER InstanceName
       Specifies the instance name on which to execute the T-SQL query.

    .PARAMETER Credential
        Specifies the credentials to use to impersonate a user when connecting.
        If this is not provided then the current user will be used to connect
        to the SQL Server Database Engine instance.

    .PARAMETER LoginType
        Specifies which type of credentials are specified. The valid types are
        Integrated, WindowsUser, and SqlLogin. If WindowsUser or SqlLogin are
        specified then the Credential needs to be specified as well. Defaults
        to `Integrated`.

    .PARAMETER DatabaseName
        Specifies the name of the database to execute the T-SQL query in.

    .PARAMETER Query
        The query string to execute.

    .PARAMETER PassThru
        Specifies if the command should return any result the query might return.

    .PARAMETER StatementTimeout
        Set the query StatementTimeout in seconds. Default 600 seconds (10 minutes).

    .PARAMETER RedactText
        One or more text strings to redact from the query when verbose messages
        are written to the console. Strings will be escaped so they will not
        be interpreted as regular expressions (RegEx).

    .PARAMETER Encrypt
        Specifies if encryption should be used.

    .PARAMETER Force
        Specifies that the query should be executed without any confirmation.

    .OUTPUTS
        `[System.Data.DataSet]` when passing parameter **PassThru**, otherwise
        outputs none.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Invoke-SqlDscQuery -ServerObject $serverObject -DatabaseName 'master' `
            -Query 'SELECT name FROM sys.databases' -PassThru

        Connects to the default instance and then runs a query to return all the
        database names in the instance.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        $serverObject | Invoke-SqlDscQuery -DatabaseName 'master' `
            -Query 'RESTORE DATABASE [NorthWinds] WITH RECOVERY'

        Connects to the default instance and then runs the query to restore the
        database NorthWinds.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Invoke-SqlDscQuery -ServerObject $serverObject -DatabaseName 'master' `
            -Query "select * from MyTable where password = 'PlaceholderPa\ssw0rd1' and password = 'placeholder secret passphrase'" `
            -RedactText @('PlaceholderPa\sSw0rd1','Placeholder Secret PassPhrase') `
            -PassThru -Verbose

        Shows how to redact sensitive information in the query when the query string
        is output as verbose information when the parameter Verbose is used. For it
        to work the sensitiv information must be known and passed into the parameter
        RedactText. If any single character is wrong the sensitiv information will
        not be redacted. The redaction is case-insensitive.

    .EXAMPLE
        Invoke-SqlDscQuery -ServerName Server1 -InstanceName MSSQLSERVER -DatabaseName 'master' `
            -Query 'SELECT name FROM sys.databases' -PassThru

        Connects to the default instance and then runs a query to return all the
        database names in the instance.
#>
function Invoke-SqlDscQuery
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.Data.DataSet])]
    [CmdletBinding(DefaultParameterSetName = 'ByServerName', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ByServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(ParameterSetName = 'ByServerName')]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter(ParameterSetName = 'ByServerName')]
        [Alias('SetupCredential')]
        [Alias('DatabaseCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateSet('Integrated', 'WindowsUser', 'SqlLogin')]
        [System.String]
        $LoginType = 'Integrated',

        [Parameter(ParameterSetName = 'ByServerName')]
        [System.Management.Automation.SwitchParameter]
        $Encrypt,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter()]
        [Alias('WithResults')]
        [Switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RedactText,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByServerName')
        {
            $connectSqlDscDatabaseEngineParameters = @{
                ServerName       = $ServerName
                InstanceName     = $InstanceName
                StatementTimeout = $StatementTimeout
                ErrorAction      = 'Stop'
                Verbose          = $VerbosePreference
            }

            if ($Encrypt.IsPresent)
            {
                $connectSqlDscDatabaseEngineParameters.Encrypt = $true
            }

            if ($LoginType -ne 'Integrated')
            {
                $connectSqlDscDatabaseEngineParameters['LoginType'] = $LoginType
            }

            if ($PSBoundParameters.ContainsKey('Credential'))
            {
                $connectSqlDscDatabaseEngineParameters.Credential = $Credential
            }

            $ServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByServerObject')
        {
            $InstanceName = $ServerObject.InstanceName
        }

        $redactedQuery = $Query

        if ($PSBoundParameters.ContainsKey('RedactText'))
        {
            $redactedQuery = ConvertTo-RedactedText -Text $Query -RedactPhrase $RedactText
        }
    }

    process
    {
        $result = $null

        $verboseDescriptionMessage = $script:localizedData.Query_Invoke_ShouldProcessVerboseDescription -f $InstanceName
        $verboseWarningMessage = $script:localizedData.Query_Invoke_ShouldProcessVerboseWarning -f $InstanceName
        $captionMessage = $script:localizedData.Query_Invoke_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            $previousStatementTimeout = $null

            if ($PSCmdlet.ParameterSetName -eq 'ByServerObject')
            {
                if ($PSBoundParameters.ContainsKey('StatementTimeout'))
                {
                    # Make sure we can return the StatementTimeout before exiting.
                    $previousStatementTimeout = $ServerObject.ConnectionContext.StatementTimeout

                    $ServerObject.ConnectionContext.StatementTimeout = $StatementTimeout
                }
            }

            try
            {
                if ($PassThru)
                {
                    Write-Verbose -Message (
                        $script:localizedData.Query_Invoke_ExecuteQueryWithResults -f $redactedQuery
                    )

                    $result = $ServerObject.Databases[$DatabaseName].ExecuteWithResults($Query)

                    return $result
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.Query_Invoke_ExecuteNonQuery -f $redactedQuery
                    )

                    $null = $ServerObject.Databases[$DatabaseName].ExecuteNonQuery($Query)
                }
            }
            catch
            {
                $writeErrorParameters = @{
                    Message      = $_.Exception.ToString()
                    Category     = 'InvalidOperation'
                    ErrorId      = 'ISDQ0001' # cSpell: disable-line
                    TargetObject = $DatabaseName
                }

                Write-Error @writeErrorParameters
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

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByServerName')
        {
            $ServerObject | Disconnect-SqlDscDatabaseEngine -Force -Verbose:$VerbosePreference
        }
    }
}
