<#
    .SYNOPSIS
        Creates a server audit.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the server audit to be added.

    .PARAMETER Filter
        Specifies the filter that should be used on the audit.

    .PARAMETER OnFailure
        Specifies what should happen when writing events to the store fails.
        This can be 'Continue', 'FailOperation', or 'Shutdown'.

    .PARAMETER QueueDelay
        Specifies the maximum delay before a event is written to the store.
        When set to low this could impact server performance.
        When set to high events could be missing when a server crashes.

    .PARAMETER Type
        Specifies the log location where the audit should write to.
        This can be SecurityLog or ApplicationLog.

    .PARAMETER FilePath
        Specifies the location where te log files wil be placed.

    .PARAMETER ReserveDiskSpace
        Specifies if the needed file space should be reserved. only needed
        when writing to a file log.

    .PARAMETER MaximumFiles
        Specifies the number of files on disk.

    .PARAMETER MaximumFileSize
        Specifies the maximum file size in units by parameter MaximumFileSizeUnit.

    .PARAMETER MaximumFileSizeUnit
        Specifies the unit that is used for the file size. this can be KB, MB or GB.

    .PARAMETER MaximumRolloverFiles
        Specifies the amount of files on disk before SQL Server starts reusing
        the files. If not specified then it is set to unlimited.

    .OUTPUTS
        None.

    .NOTES
        TODO: Update comment-based help from here: https://docs.microsoft.com/en-us/sql/t-sql/statements/create-server-audit-transact-sql?view=sql-server-ver16
#>
function New-SqlDscAudit
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Filter,

        # TODO:Maybe not use default it the parameter inte not necessary?
        [Parameter()]
        [ValidateSet('Continue', 'FailOperation', 'Shutdown')]
        [System.String]
        $OnFailure = 'Continue',

        # TODO:Maybe not use default it the parameter inte not necessary?
        [Parameter()]
        [System.UInt32]
        $QueueDelay = 1000,

        [Parameter(ParameterSetName = 'Log', Mandatory = $true)]
        [ValidateSet('SecurityLog', 'ApplicationLog')]
        #[ValidateSet('File', 'SecurityLog', 'ApplicationLog')]
        [System.String]
        $Type,

        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter(ParameterSetName = 'File')]
        [System.Management.Automation.SwitchParameter]
        $ReserveDiskSpace,

        [Parameter(ParameterSetName = 'File')]
        [System.UInt32]
        $MaximumFiles,

        # TODO:Maybe not use default it the parameter inte not necessary?
        [Parameter(ParameterSetName = 'File')]
        [System.UInt32]
        $MaximumFileSize = 10,

        # TODO:Maybe not use default it the parameter inte not necessary?
        [Parameter(ParameterSetName = 'File')]
        [ValidateSet('KB', 'MB', 'GB')]
        [System.String]
        $MaximumFileSizeUnit = 'MB',

        [Parameter(ParameterSetName = 'File')]
        [System.UInt32]
        $MaximumRolloverFiles
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'Log'
        {
            # Translate the value for Type.
            $queryType = (
                @{
                    SecurityLog = 'SECURITY_LOG'
                    ApplicationLog = 'APPLICATION_LOG'
                }
            ).$Type
        }

        'File'
        {
            $queryType = 'FILE'
        }
    }

    $query = 'CREATE SERVER AUDIT [{0}] TO {1}' -f $Name, $queryType

    # Translate the value for OnFailure.
    $queryOnFailure = (
        @{
            Continue = 'CONTINUE'
            FailOperation = 'FAIL_OPERATION'
            ShutDown = 'SHUTDOWN'
        }
    ).$OnFailure

    # 'File'
    # {
    #     $strReserveDiskSpace = 'OFF'
    #     if ($ReserveDiskSpace)
    #     {
    #         $strReserveDiskSpace = 'ON'
    #     }

    #     $strFiles = ''
    #     if ($MaximumFiles)
    #     {
    #         $strFiles = 'MAX_FILES = {0},' -f $MaximumFiles
    #     }
    #     if ($MaximumRolloverFiles)
    #     {
            # TODO: If not passed then UNLIMITED should be used (it is default when not adding MAX_ROLLOVER_FILES to the query).
    #         $strFiles = 'MAX_ROLLOVER_FILES = {0},' -f $MaximumRolloverFiles
    #     }

    #     # TODO: Should handle Filter (WHERE-clause)

    #     $target = 'FILE (
    #             FILEPATH = N''{0}'',
    #             MAXSIZE = {1} {2},
    #             {3}
    #             RESERVE_DISK_SPACE = {4} )' -f
    #     $FilePath,
    #     $MaximumFileSize,
    #     $MaximumFileSizeUnit,
    #     $strFiles,
    #     $strReserveDiskSpace
    # }

    # $withPart = 'QUEUE_DELAY = {0}, ON_FAILURE = {1}' -f @(
    #     $QueueDelay,
    #     $queryOnFailure
    # )

    # $invokeQueryParameters = @{
    #     ServerName   = $ServerName
    #     InstanceName = $InstanceName
    #     Database     = 'MASTER'
    # }

    Invoke-Query @invokeQueryParameters -Query $query

    #     'CREATE SERVER AUDIT [{0}] TO {1}
    #     WITH (
    #         {2}
    #     );' -f
    #     $Name,
    #     $Target,
    #     $WithPart
    # )
}
