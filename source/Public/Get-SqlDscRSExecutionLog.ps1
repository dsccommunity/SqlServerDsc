<#
    .SYNOPSIS
        Gets execution log entries from the SQL Server Reporting Services or
        Power BI Report Server database.
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
