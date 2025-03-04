<#
    .SYNOPSIS
        Updates a server audit.

    .DESCRIPTION
        This command updates and existing server audit on a SQL Server Database Engine
        instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER AuditObject
        Specifies an audit object to update.

    .PARAMETER Name
        Specifies the name of the server audit to be updated.

    .PARAMETER AuditFilter
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
        Specifies that the audit should be updated without any confirmation.

    .PARAMETER Refresh
        Specifies that the audit object should be refreshed before updating. This
        is helpful when audits could have been modified outside of the **ServerObject**,
        for example through T-SQL. But on instances with a large amount of audits
        it might be better to make sure the ServerObject is recent enough.

    .PARAMETER Path
        Specifies the location where te log files wil be placed.

    .PARAMETER ReserveDiskSpace
        Specifies if the needed file space should be reserved. To use this parameter
        the parameter **MaximumFiles** must also be used.

    .PARAMETER MaximumFiles
        Specifies the number of files on disk.

    .PARAMETER MaximumFileSize
        Specifies the maximum file size in units by parameter MaximumFileSizeUnit.
        Minimum allowed value is 2 (MB). It also allowed to set the value to 0 which
        mean unlimited file size.

    .PARAMETER MaximumFileSizeUnit
        Specifies the unit that is used for the file size. this can be KB, MB or GB.

    .PARAMETER MaximumRolloverFiles
        Specifies the amount of files on disk before SQL Server starts reusing
        the files. If not specified then it is set to unlimited.

    .PARAMETER PassThru
        If specified the changed audit object will be returned.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Audit]` is passing parameter **PassThru**,
         otherwise none.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $sqlServerObject | Set-SqlDscAudit -Name 'MyFileAudit' -Path 'E:\auditFolder' -QueueDelay 1000

        Updates the file audit named **MyFileAudit** by setting the path to ''E:\auditFolder'
        and the queue delay to 1000.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $sqlServerObject | New-SqlDscAudit -Name 'MyAppLogAudit' -QueueDelay 1000

        Updates the application log audit named **MyAppLogAudit** by setting the
        queue delay to 1000.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $sqlServerObject | Set-SqlDscAudit -Name 'MyFileAudit' -Path 'E:\auditFolder' -QueueDelay 1000 -PassThru

        Updates the file audit named **MyFileAudit** by setting the path to ''E:\auditFolder'
        and the queue delay to 1000, and returns the Audit object.

    .NOTES
        This command has the confirm impact level set to high since an audit is
        unknown to be enable at the point when the command is issued.

        See the SQL Server documentation for more information for the possible
        parameter values to pass to this command: https://docs.microsoft.com/en-us/sql/t-sql/statements/create-server-audit-transact-sql
#>
function Set-SqlDscAudit
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Audit])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSize', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithMaxFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithMaxRolloverFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxRolloverFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'AuditObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSize', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithMaxFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithMaxRolloverFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxRolloverFiles', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Audit]
        $AuditObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSize', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithMaxRolloverFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $AuditFilter,

        [Parameter()]
        [ValidateSet('Continue', 'FailOperation', 'Shutdown')]
        [System.String]
        $OnFailure,

        [Parameter()]
        [ValidateScript({
                if ($_ -in 1..999 -or $_ -gt 2147483647)
                {
                    throw ($script:localizedData.Audit_QueueDelayParameterValueInvalid -f $_)
                }

                return $true
            })]
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

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter(ParameterSetName = 'ServerObject')]
        [Parameter(ParameterSetName = 'ServerObjectWithSize')]
        [Parameter(ParameterSetName = 'ServerObjectWithMaxFiles')]
        [Parameter(ParameterSetName = 'ServerObjectWithMaxRolloverFiles')]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxFiles')]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxRolloverFiles')]
        [Parameter(ParameterSetName = 'AuditObject')]
        [Parameter(ParameterSetName = 'AuditObjectWithSize')]
        [Parameter(ParameterSetName = 'AuditObjectWithMaxFiles')]
        [Parameter(ParameterSetName = 'AuditObjectWithMaxRolloverFiles')]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxFiles')]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxRolloverFiles')]
        [ValidateScript({
                if (-not (Test-Path -Path $_))
                {
                    throw ($script:localizedData.Audit_PathParameterValueInvalid -f $_)
                }

                return $true
            })]
        [System.String]
        $Path,

        [Parameter(ParameterSetName = 'ServerObjectWithSize', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSize', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [ValidateScript({
                if ($_ -eq 1 -or $_ -gt 2147483647)
                {
                    throw ($script:localizedData.Audit_MaximumFileSizeParameterValueInvalid -f $_)
                }

                return $true
            })]
        [System.UInt32]
        $MaximumFileSize,

        [Parameter(ParameterSetName = 'ServerObjectWithSize', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSize', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [ValidateSet('Megabyte', 'Gigabyte', 'Terabyte')]
        [System.String]
        $MaximumFileSizeUnit,

        [Parameter(ParameterSetName = 'ServerObjectWithMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithMaxFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxFiles', Mandatory = $true)]
        [System.UInt32]
        $MaximumFiles,

        [Parameter(ParameterSetName = 'ServerObjectWithMaxFiles')]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxFiles')]
        [Parameter(ParameterSetName = 'AuditObjectWithMaxFiles')]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxFiles')]
        [System.Management.Automation.SwitchParameter]
        $ReserveDiskSpace,

        [Parameter(ParameterSetName = 'ServerObjectWithMaxRolloverFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithMaxRolloverFiles', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AuditObjectWithSizeAndMaxRolloverFiles', Mandatory = $true)]
        [ValidateRange(0, 2147483647)]
        [System.UInt32]
        $MaximumRolloverFiles
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            $getSqlDscAuditParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                Refresh      = $Refresh
                ErrorAction  = 'Stop'
            }

            # If this command does not find the audit it will throw an exception.
            $auditObjectArray = Get-SqlDscAudit @getSqlDscAuditParameters

            # Pick the only object in the array.
            $AuditObject = $auditObjectArray | Select-Object -First 1
        }

        if ($Refresh.IsPresent)
        {
            $AuditObject.Refresh()
        }

        $verboseDescriptionMessage = $script:localizedData.Audit_Update_ShouldProcessVerboseDescription -f $AuditObject.Name, $AuditObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Audit_Update_ShouldProcessVerboseWarning -f $AuditObject.Name
        $captionMessage = $script:localizedData.Audit_Update_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            if ($PSBoundParameters.ContainsKey('Path'))
            {
                $AuditObject.FilePath = $Path
            }

            if ($PSCmdlet.ParameterSetName -match 'WithSize')
            {
                $queryMaximumFileSizeUnit = (
                    @{
                        Megabyte = 'MB'
                        Gigabyte = 'GB'
                        Terabyte = 'TB'
                    }
                ).$MaximumFileSizeUnit

                $AuditObject.MaximumFileSize = $MaximumFileSize
                $AuditObject.MaximumFileSizeUnit = $queryMaximumFileSizeUnit
            }

            if ($PSCmdlet.ParameterSetName -match 'MaxFiles')
            {
                if ($AuditObject.MaximumRolloverFiles)
                {
                    # Switching to MaximumFiles instead of MaximumRolloverFiles.
                    $AuditObject.MaximumRolloverFiles = 0

                    # Must run method Alter() before setting MaximumFiles.
                    $AuditObject.Alter()
                }

                $AuditObject.MaximumFiles = $MaximumFiles

                if ($PSBoundParameters.ContainsKey('ReserveDiskSpace'))
                {
                    $AuditObject.ReserveDiskSpace = $ReserveDiskSpace.IsPresent
                }
            }

            if ($PSCmdlet.ParameterSetName -match 'MaxRolloverFiles')
            {
                if ($AuditObject.MaximumFiles)
                {
                    # Switching to MaximumRolloverFiles instead of MaximumFiles.
                    $AuditObject.MaximumFiles = 0

                    # Must run method Alter() before setting MaximumRolloverFiles.
                    $AuditObject.Alter()
                }

                $AuditObject.MaximumRolloverFiles = $MaximumRolloverFiles
            }

            if ($PSBoundParameters.ContainsKey('OnFailure'))
            {
                $AuditObject.OnFailure = $OnFailure
            }

            if ($PSBoundParameters.ContainsKey('QueueDelay'))
            {
                $AuditObject.QueueDelay = $QueueDelay
            }

            if ($PSBoundParameters.ContainsKey('AuditGuid'))
            {
                $AuditObject.Guid = $AuditGuid
            }

            if ($PSBoundParameters.ContainsKey('AuditFilter'))
            {
                $AuditObject.Filter = $AuditFilter
            }

            $AuditObject.Alter()

            if ($PassThru.IsPresent)
            {
                return $AuditObject
            }
        }
    }
}
