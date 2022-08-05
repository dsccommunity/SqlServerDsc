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

    .PARAMETER Force
        Specifies that the audit should be created with out any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s audits should be refreshed before creating
        the audit object. This is helpful when audits could have been modified outside
        of the **ServerObject**, for example through T-SQL. But on instances with
        a large amount of audits it might be better to make sure the ServerObject
        is recent enough.

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
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter(ParameterSetName = 'Log', Mandatory = $true)]
        [ValidateSet('SecurityLog', 'ApplicationLog')]
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

    if ($Refresh.IsPresent)
    {
        # Make sure the audits are up-to-date to get any newly created audits.
        $ServerObject.Audits.Refresh()
    }

    if ($ServerObject.Audits[$Name])
    {
        $missingDatabaseMessage = $script:localizedData.Audit_AlreadyPresent -f $Name

        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                $missingDatabaseMessage,
                'NSDA0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $DatabaseName
            )
        )
    }

    # TODO: This is for Set-SqlDscAudit
    # $auditObject = $ServerObject.Audits[$Name]
    # $auditObject.Refresh()

    $auditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($ServerObject, $Name)

    $queryType = switch ($PSCmdlet.ParameterSetName)
    {
        'Log'
        {
            $Type
        }

        default
        {
            'File'
        }
    }

    $auditObject.DestinationType = $queryType

    if ($PSCmdlet.ParameterSetName -match 'File')
    {
        $auditObject.FilePath = $Path

        if ($PSCmdlet.ParameterSetName -match 'FileWithSize')
        {
            $queryMaximumFileSizeUnit = (
                @{
                    Megabyte = 'MB'
                    Gigabyte = 'GB'
                    Terabyte = 'TB'
                }
            ).$MaximumFileSizeUnit

            $auditObject.MaximumFileSize = $MaximumFileSize
            $auditObject.MaximumFileSizeUnit = $queryMaximumFileSizeUnit
        }

        <#
            TODO: For Set-SqlDscAudit: Switching between MaximumFiles and MaximumRolloverFiles must
                  run alter() between.

                   $ServerObject.Audits['File1'].MaximumRolloverFiles = 0
                   $ServerObject.Audits['File1'].Alter()
                   $ServerObject.Audits['File1'].MaximumFiles = 1
                   $ServerObject.Audits['File1'].Alter()
        #>
        if ($PSCmdlet.ParameterSetName -in @('FileWithMaxFiles', 'FileWithSizeAndMaxFiles'))
        {
            $auditObject.MaximumFiles = $MaximumFiles

            if ($PSBoundParameters.ContainsKey('ReserveDiskSpace'))
            {
                $auditObject.ReserveDiskSpace = $ReserveDiskSpace.IsPresent
            }
        }

        if ($PSCmdlet.ParameterSetName -in @('FileWithMaxRolloverFiles', 'FileWithSizeAndMaxRolloverFiles'))
        {
            $auditObject.MaximumRolloverFiles = $MaximumRolloverFiles
        }
    }

    if ($PSBoundParameters.ContainsKey('OnFailure'))
    {
        $auditObject.OnFailure = $OnFailure
    }

    if ($PSBoundParameters.ContainsKey('QueueDelay'))
    {
        $auditObject.QueueDelay = $QueueDelay
    }

    if ($PSBoundParameters.ContainsKey('AuditGuid'))
    {
        $auditObject.Guid = $AuditGuid
    }

    if ($PSBoundParameters.ContainsKey('Filter'))
    {
        $auditObject.Filter = $Filter
    }

    $verboseDescriptionMessage = $script:localizedData.Audit_ChangePermissionShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
    $verboseWarningMessage = $script:localizedData.Audit_ChangePermissionShouldProcessVerboseWarning -f $Name
    $captionMessage = $script:localizedData.Audit_ChangePermissionShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $auditObject.Create()
    }
}
