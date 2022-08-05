<#
    .SYNOPSIS
        Creates a server audit.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the server audit to be added.

    .PARAMETER Filter
        Specifies the filter that should be used on the audit. See [predicate expression](https://docs.microsoft.com/en-us/sql/t-sql/statements/create-server-audit-transact-sql)
        how to write the syntax for the filter.

    .PARAMETER OnFailure
        Specifies what should happen when writing events to the store fails.
        This can be 'Continue', 'FailOperation', or 'Shutdown'.

    .PARAMETER QueueDelay
        Specifies the maximum delay before a event is written to the store.
        When set to low this could impact server performance.
        When set to high events could be missing when a server crashes.

    .PARAMETER AuditGuid
        Specifies the GUID found in the mirrored database. To support scenarios such
        as database mirroring an audit needs a specific GUID.

    .PARAMETER OperatorAudit
        Specifies if auditing will capture Microsoft support engineers operations
        during support requests. Applies to Azure SQL Managed Instance only.

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
        See the SQL Server documentation: https://docs.microsoft.com/en-us/sql/t-sql/statements/create-server-audit-transact-sql
#>
function New-SqlDscAudit
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(ParameterSetName = 'Log', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'File', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'FileWithSize', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'FileWithMaxFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'FileWithMaxRolloverFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxRolloverFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Filter,

        [Parameter()]
        [ValidateSet('Continue', 'FailOperation', 'Shutdown')]
        [System.String]
        $OnFailure,

        [Parameter()]
        [ValidateRange(1000, 2147483647)]
        [System.UInt32]
        $QueueDelay,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
        [System.String]
        $AuditGuid,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $OperatorAudit,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'Log', Mandatory = $true)]
        [ValidateSet('SecurityLog', 'ApplicationLog')]
        #[ValidateSet('File', 'SecurityLog', 'ApplicationLog')]
        [System.String]
        $Type,

        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithSize', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithMaxRolloverFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path -Path $_))
                {
                    throw ($script:localizedData.Audit_PathParameterValueInvalid -f $_)
                }

                return $true
            })]
        [System.String]
        $Path,

        [Parameter(ParameterSetName = 'FileWithSize', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [ValidateRange(2, 2147483647)]
        [System.UInt32]
        $MaximumFileSize,

        [Parameter(ParameterSetName = 'FileWithSize', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [ValidateSet('Megabyte', 'Gigabyte', 'Terabyte')]
        [System.String]
        $MaximumFileSizeUnit,

        [Parameter(ParameterSetName = 'FileWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithMaxFiles', Mandatory = $true)]
        [System.UInt32]
        $MaximumFiles,

        [Parameter(ParameterSetName = 'FileWithMaxFiles')]
        [Parameter(ParameterSetName = 'FileWithSizeAndMaxFiles')]
        [System.Management.Automation.SwitchParameter]
        $ReserveDiskSpace,

        [Parameter(ParameterSetName = 'FileWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'FileWithMaxRolloverFiles', Mandatory = $true)]
        [ValidateRange(0, 2147483647)]
        [System.UInt32]
        $MaximumRolloverFiles
    )

    if ($Force.IsPresent)
    {
        $ConfirmPreference = 'None'
    }

    $queryType = switch ($PSCmdlet.ParameterSetName)
    {
        'Log'
        {
            # Translate the value for Type.
            (
                @{
                    SecurityLog    = 'SECURITY_LOG'
                    ApplicationLog = 'APPLICATION_LOG'
                }
            ).$Type
        }

        'File'
        {
            'FILE'
        }
    }

    $query = 'CREATE SERVER AUDIT [{0}] TO {1}' -f $Name, $queryType

    if ($PSCmdlet.ParameterSetName -match 'File')
    {
        $query += (" (FILEPATH = '{0}'" -f $Path)

        if ($PSCmdlet.ParameterSetName -match 'FileWithSize')
        {
            $queryMaximumFileSizeUnit = (
                @{
                    Megabyte = 'MB'
                    Gigabyte = 'GB'
                    Terabyte = 'TB'
                }
            ).$MaximumFileSizeUnit

            # MAXSIZE: cspell: disable-line cspell: disable-next-line
            $query += (', MAXSIZE {0} {1}' -f $MaximumFileSize, $queryMaximumFileSizeUnit)
        }

        <#
            TODO: For Set-SqlDscAudit: Switching between MaximumFiles and MaximumRolloverFiles must
                  run alter() between.

                   $sqlServerObject.Audits['File1'].MaximumRolloverFiles = 0
                   $sqlServerObject.Audits['File1'].Alter()
                   $sqlServerObject.Audits['File1'].MaximumFiles = 1
                   $sqlServerObject.Audits['File1'].Alter()
        #>
        if ($PSCmdlet.ParameterSetName -in @('FileWithMaxFiles', 'FileWithSizeAndMaxFiles'))
        {
            $query += (', MAX_FILES = {0}' -f $MaximumFiles)

            if ($PSBoundParameters.ContainsKey('ReserveDiskSpace'))
            {
                # Translate the value for ReserveDiskSpace.
                $queryReservDiskSpace = (
                    @{
                        True  = 'ON'
                        False = 'OFF'
                    }
                ).($ReserveDiskSpace.IsPresent.ToString())

                $query += (', RESERVE_DISK_SPACE = {0}' -f $queryReservDiskSpace)
            }
        }

        if ($PSCmdlet.ParameterSetName -in @('FileWithMaxRolloverFiles', 'FileWithSizeAndMaxRolloverFiles'))
        {
            $query += (', MAX_ROLLOVER_FILES = {0}' -f $MaximumFiles)
        }

        $query += ')'
    }


    $needWithPart = (
        $PSBoundParameters.ContainsKey('OnFailure') -or
        $PSBoundParameters.ContainsKey('QueueDelay') -or
        $PSBoundParameters.ContainsKey('AuditGuid') -or
        $PSBoundParameters.ContainsKey('OperatorAudit')
    )

    if ($needWithPart)
    {
        $query += ' WITH ('

        $hasWithPartOption = $false

        foreach ($option in @('OnFailure', 'QueueDelay', 'AuditGuid', 'OperatorAudit'))
        {
            if ($PSBoundParameters.ContainsKey($option))
            {
                <#
                    If there was already an option added, and another need to be
                    added, split them with a comma.
                #>
                if ($hasWithPartOption)
                {
                    $query += ', '
                }

                switch ($option)
                {
                    'QueueDelay'
                    {
                        $query += ('QUEUE_DELAY = {0}' -f $QueueDelay)

                        $hasWithPartOption = $true
                    }

                    'OnFailure'
                    {
                        # Translate the value for OnFailure.
                        $queryOnFailure = (
                            @{
                                Continue      = 'CONTINUE'
                                FailOperation = 'FAIL_OPERATION'
                                ShutDown      = 'SHUTDOWN'
                            }
                        ).$OnFailure

                        $query += ('ON_FAILURE = {0}' -f $queryOnFailure)

                        $hasWithPartOption = $true
                    }

                    'AuditGuid'
                    {
                        $query += ("AUDIT_GUID = '{0}'" -f $AuditGuid)

                        $hasWithPartOption = $true
                    }

                    'OperatorAudit'
                    {
                        # Translate the value for OperatorAudit.
                        $queryOperatorAudit = (
                            @{
                                True  = 'ON'
                                False = 'OFF'
                            }
                        ).($OperatorAudit.IsPresent.ToString())

                        $query += ('OPERATOR_AUDIT = {0}' -f $queryOperatorAudit)

                        $hasWithPartOption = $true
                    }
                }
            }
        }

        $query += ')'
    }

    # TODO: This cannot allow SQL Injection
    if ($PSBoundParameters.ContainsKey('Filter'))
    {
        $query += ' WHERE ('

        # <predicate_expression>::=
        # {
        #     [NOT ] <predicate_factor>
        #     [ { AND | OR } [NOT ] { <predicate_factor> } ]
        #     [,...n ]
        # }

        # <predicate_factor>::=
        #     event_field_name { = | < > | ! = | > | > = | < | < = | LIKE } { number | ' string ' }

        # WHERE ([server_principal_name] like '%ADMINISTRATOR')

        # WHERE [Schema_Name] = 'sys' AND [Object_Name] = 'all_objects'

        # WHERE (
        #    [Schema_Name] = 'sys' AND [Object_Name] = 'all_objects'
        #) OR (
        #    [Schema_Name] = 'sys' AND [Object_Name] = 'database_permissions'
        #)

        $query += ')'
    }

    $verboseDescriptionMessage = $script:localizedData.Audit_ChangePermissionShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
    $verboseWarningMessage = $script:localizedData.Audit_ChangePermissionShouldProcessVerboseWarning -f $Name
    $captionMessage = $script:localizedData.Audit_ChangePermissionShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $invokeSqlDscQueryParameters = @{
            ServerObject = $ServerObject
            DatabaseName = 'master'
            Query        = $query
            ErrorAction  = 'Stop'
        }

        Invoke-SqlDscQuery @invokeSqlDscQueryParameters
    }
}
