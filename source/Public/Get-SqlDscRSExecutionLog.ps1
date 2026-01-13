<#
    .SYNOPSIS
        Gets execution log entries from the SQL Server Reporting Services or
        Power BI Report Server database.

    .DESCRIPTION
        Gets execution log entries from the `ExecutionLog3` view in the report
        server database for SQL Server Reporting Services (SSRS) or Power BI
        Report Server (PBIRS). This view provides detailed records of report
        executions, including users, execution times, parameters, and rendering
        data.

        The command automatically retrieves the database connection information
        (server name and database name) from the Reporting Services configuration
        CIM instance.

        The `ExecutionLog3` view is available in SQL Server 2016 and later versions.

    .PARAMETER InstanceName
        Specifies the name of the Reporting Services instance. This is typically
        'SSRS' for SQL Server Reporting Services or 'PBIRS' for Power BI Report
        Server. This is a mandatory parameter.

    .PARAMETER StartTime
        Specifies the start time to filter execution log entries. Only entries
        with a TimeStart greater than or equal to this value will be returned.

    .PARAMETER EndTime
        Specifies the end time to filter execution log entries. Only entries
        with a TimeStart less than or equal to this value will be returned.

    .PARAMETER UserName
        Specifies the user name to filter execution log entries. Supports SQL
        LIKE pattern matching (e.g., 'DOMAIN\%' or '%admin%').

    .PARAMETER ReportPath
        Specifies the report path to filter execution log entries. Supports SQL
        LIKE pattern matching (e.g., '/Sales/%' or '%Revenue%').

    .PARAMETER MaxRows
        Specifies the maximum number of rows to return. Defaults to 1000.
        Set to 0 to return all rows (use with caution on large databases).

    .PARAMETER Credential
        Specifies the credentials to use to impersonate a user when connecting
        to the report server database. If not provided, the current user's
        Windows credentials will be used.

    .PARAMETER LoginType
        Specifies which type of credentials are specified. The valid types are
        Integrated, WindowsUser, and SqlLogin. If WindowsUser or SqlLogin are
        specified then the Credential needs to be specified as well. Defaults
        to 'Integrated'.

    .PARAMETER Encrypt
        Specifies whether encryption should be used for the database connection.

    .PARAMETER StatementTimeout
        Specifies the query statement timeout in seconds. Default is 600 seconds
        (10 minutes).

    .PARAMETER Force
        Specifies that the query should be executed without any confirmation.

    .EXAMPLE
        Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -Force

        Returns the last 1000 execution log entries from the SSRS report server
        database.

    .EXAMPLE
        Get-SqlDscRSExecutionLog -InstanceName 'PBIRS' -MaxRows 100 -Force

        Returns the last 100 execution log entries from the Power BI Report
        Server database.

    .EXAMPLE
        Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -StartTime (Get-Date).AddDays(-7) -Force

        Returns execution log entries from the last 7 days.

    .EXAMPLE
        Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -UserName 'DOMAIN\%' -Force

        Returns execution log entries for all users in the DOMAIN domain.

    .EXAMPLE
        Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -ReportPath '/Sales/%' -MaxRows 500 -Force

        Returns up to 500 execution log entries for reports in the /Sales/ folder.

    .EXAMPLE
        $cred = Get-Credential
        Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -Credential $cred -LoginType 'SqlLogin' -Force

        Returns execution log entries using SQL Server authentication.

    .INPUTS
        None.

    .OUTPUTS
        `System.Data.DataRow`

        Returns DataRow objects containing execution log entries with columns
        such as InstanceName, ItemPath, UserName, ExecutionId, RequestType,
        Format, Parameters, ItemAction, TimeStart, TimeEnd, TimeDataRetrieval,
        TimeProcessing, TimeRendering, Source, Status, ByteCount, RowCount,
        and AdditionalInfo.
#>
function Get-SqlDscRSExecutionLog
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([System.Data.DataRow])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.DateTime]
        $StartTime,

        [Parameter()]
        [System.DateTime]
        $EndTime,

        [Parameter()]
        [System.String]
        $UserName,

        [Parameter()]
        [System.String]
        $ReportPath,

        [Parameter()]
        [ValidateRange(0, [System.Int32]::MaxValue)]
        [System.Int32]
        $MaxRows = 1000,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [ValidateSet('Integrated', 'WindowsUser', 'SqlLogin')]
        [System.String]
        $LoginType = 'Integrated',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Encrypt,

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    Write-Verbose -Message ($script:localizedData.Get_SqlDscRSExecutionLog_GettingConfiguration -f $InstanceName)

    $rsConfiguration = Get-SqlDscRSConfiguration -InstanceName $InstanceName

    $databaseServerName = $rsConfiguration.DatabaseServerName
    $databaseName = $rsConfiguration.DatabaseName

    Write-Verbose -Message ($script:localizedData.Get_SqlDscRSExecutionLog_DatabaseInfo -f $databaseName, $databaseServerName)

    # Parse the database server name to extract server and instance
    $serverName = $databaseServerName
    $sqlInstanceName = 'MSSQLSERVER'

    if ($databaseServerName -match '^(?<server>[^\\]+)\\(?<instance>.+)$')
    {
        $serverName = $Matches['server']
        $sqlInstanceName = $Matches['instance']
    }

    # Build the WHERE clause based on filter parameters
    $whereConditions = @()

    if ($PSBoundParameters.ContainsKey('StartTime'))
    {
        $startTimeString = $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
        $whereConditions += "TimeStart >= '$startTimeString'"
    }

    if ($PSBoundParameters.ContainsKey('EndTime'))
    {
        $endTimeString = $EndTime.ToString('yyyy-MM-dd HH:mm:ss')
        $whereConditions += "TimeStart <= '$endTimeString'"
    }

    if ($PSBoundParameters.ContainsKey('UserName'))
    {
        $escapedUserName = $UserName -replace "'", "''"
        $whereConditions += "UserName LIKE '$escapedUserName'"
    }

    if ($PSBoundParameters.ContainsKey('ReportPath'))
    {
        $escapedReportPath = $ReportPath -replace "'", "''"
        $whereConditions += "ItemPath LIKE '$escapedReportPath'"
    }

    # Build the query
    $topClause = ''

    if ($MaxRows -gt 0)
    {
        $topClause = "TOP ($MaxRows)"
    }

    $whereClause = ''

    if ($whereConditions.Count -gt 0)
    {
        $whereClause = 'WHERE ' + ($whereConditions -join ' AND ')
    }

    $query = @"
SELECT $topClause
    InstanceName,
    ItemPath,
    UserName,
    ExecutionId,
    RequestType,
    Format,
    Parameters,
    ItemAction,
    TimeStart,
    TimeEnd,
    TimeDataRetrieval,
    TimeProcessing,
    TimeRendering,
    Source,
    Status,
    ByteCount,
    [RowCount],
    AdditionalInfo
FROM ExecutionLog3
$whereClause
ORDER BY TimeStart DESC
"@

    Write-Verbose -Message ($script:localizedData.Get_SqlDscRSExecutionLog_ExecutingQuery -f $databaseName)

    $verboseDescriptionMessage = $script:localizedData.Get_SqlDscRSExecutionLog_ShouldProcessDescription -f $databaseName, $databaseServerName
    $verboseWarningMessage = $script:localizedData.Get_SqlDscRSExecutionLog_ShouldProcessConfirmation -f $databaseName
    $captionMessage = $script:localizedData.Get_SqlDscRSExecutionLog_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $invokeSqlDscQueryParameters = @{
            ServerName       = $serverName
            InstanceName     = $sqlInstanceName
            DatabaseName     = $databaseName
            Query            = $query
            PassThru         = $true
            StatementTimeout = $StatementTimeout
            Force            = $true
            ErrorAction      = 'Stop'
            Verbose          = $VerbosePreference
        }

        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $invokeSqlDscQueryParameters.Credential = $Credential
        }

        if ($LoginType -ne 'Integrated')
        {
            $invokeSqlDscQueryParameters.LoginType = $LoginType
        }

        if ($Encrypt.IsPresent)
        {
            $invokeSqlDscQueryParameters.Encrypt = $true
        }

        try
        {
            $result = Invoke-SqlDscQuery @invokeSqlDscQueryParameters

            if ($result -and $result.Tables -and $result.Tables[0].Rows)
            {
                return $result.Tables[0].Rows
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSExecutionLog_QueryFailed -f $InstanceName, $_.Exception.Message

            Write-Error -Message $errorMessage -Category 'InvalidOperation' -ErrorId 'GSRSEL0001' -TargetObject $InstanceName -Exception $_.Exception

            return
        }
    }
}
