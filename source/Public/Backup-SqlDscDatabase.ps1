<#
    .SYNOPSIS
        Performs a backup of a SQL Server database.

    .DESCRIPTION
        This command performs a backup of a SQL Server database using SQL Server
        Management Objects (SMO). It supports full, differential, and transaction
        log backups with options for compression, verification, and copy-only
        backups.

    .PARAMETER ServerObject
        Specifies the current server connection object.

    .PARAMETER DatabaseObject
        Specifies a database object to backup.

    .PARAMETER Name
        Specifies the name of the database to backup.

    .PARAMETER BackupFile
        Specifies the full path to the backup file. For full and differential
        backups, use the `.bak` extension. For transaction log backups, use
        the `.trn` extension.

    .PARAMETER BackupType
        Specifies the type of backup to perform. Valid values are 'Full',
        'Differential', and 'Log'. Default value is 'Full'.

    .PARAMETER CopyOnly
        Specifies that a copy-only backup should be performed. Copy-only backups
        do not affect the sequence of conventional backups and are useful for
        taking backups for special purposes without disrupting the normal backup
        chain. This is particularly useful in AlwaysOn Availability Group scenarios.

    .PARAMETER Compress
        Specifies that the backup should be compressed. Backup compression requires
        SQL Server 2008 Enterprise or later, or SQL Server 2008 R2 Standard or later.

    .PARAMETER Checksum
        Specifies that checksums should be calculated and verified during the
        backup operation to help detect backup media errors.

    .PARAMETER Description
        Specifies a description for the backup set. This description is stored
        in the backup media and can be useful for identifying backups.

    .PARAMETER RetainDays
        Specifies the number of days that must elapse before the backup media
        can be overwritten. This provides protection against accidental overwrites.

    .PARAMETER Initialize
        Specifies that the backup media should be initialized (overwritten) rather
        than appending to existing backup sets. Use with caution as this will
        destroy any existing backups on the media.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        accessing the database. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough, or pass in **DatabaseObject**.

    .PARAMETER Force
        Specifies that the backup should be performed without any confirmation.

    .PARAMETER PassThru
        Returns the database object that was backed up. By default, this command
        does not generate any output.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Backup-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak'

        Performs a full backup of the database named **MyDatabase** to the specified
        backup file.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        $databaseObject | Backup-SqlDscDatabase -BackupFile 'C:\Backups\MyDatabase.bak' -Force

        Performs a full backup of the database named **MyDatabase** using a
        database object from the pipeline, without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Backup-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase_Diff.bak' -BackupType 'Differential'

        Performs a differential backup of the database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Backup-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.trn' -BackupType 'Log'

        Performs a transaction log backup of the database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Backup-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase_CopyOnly.bak' -CopyOnly

        Performs a copy-only full backup of the database named **MyDatabase**.
        This backup does not affect the normal backup chain.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Backup-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak' -Compress -Checksum

        Performs a compressed full backup with checksum verification of the
        database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Backup-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak' -PassThru -Force
        $databaseObject | Set-SqlDscDatabaseProperty -RecoveryModel 'Simple' -Force

        Performs a full backup of the database named **MyDatabase** and returns
        the database object for further pipeline operations.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Server object accepted from the pipeline (ServerObject parameter set).

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Database`

        Database object accepted from the pipeline (DatabaseObject parameter set).

    .OUTPUTS
        None.

        No output when the **PassThru** parameter is not specified.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Database`

        Returns the database object that was backed up when using the **PassThru** parameter.
#>
function Backup-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(DefaultParameterSetName = 'ServerObject', SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'DatabaseObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $BackupFile,

        [Parameter()]
        [ValidateSet('Full', 'Differential', 'Log')]
        [System.String]
        $BackupType = 'Full',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $CopyOnly,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Compress,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Checksum,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateRange(0, 99999)]
        [System.Int32]
        $RetainDays,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Initialize,

        [Parameter(ParameterSetName = 'ServerObject')]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            if ($Refresh.IsPresent)
            {
                # Refresh the server object's databases collection
                $ServerObject.Databases.Refresh()
            }

            # Get the database object
            $DatabaseObject = $ServerObject.Databases[$Name]

            if (-not $DatabaseObject)
            {
                $errorMessage = $script:localizedData.Backup_SqlDscDatabase_NotFound -f $Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.Management.Automation.ItemNotFoundException]::new($errorMessage),
                        'BSDD0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $Name
                    )
                )
            }
        }
        else
        {
            $Name = $DatabaseObject.Name
            $ServerObject = $DatabaseObject.Parent
        }

        # Validate that log backups are only performed on databases with FULL or BULK_LOGGED recovery model
        if ($BackupType -eq 'Log')
        {
            $recoveryModel = $DatabaseObject.RecoveryModel

            if ($recoveryModel -eq [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple)
            {
                $errorMessage = $script:localizedData.Database_Backup_LogBackupSimpleRecoveryModel -f $Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'BSDD0002', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $DatabaseObject
                    )
                )
            }
        }

        # Validate that the database is online
        if ($DatabaseObject.Status -ne [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        {
            $errorMessage = $script:localizedData.Database_Backup_DatabaseNotOnline -f $Name, $DatabaseObject.Status

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'BSDD0003', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DatabaseObject
                )
            )
        }

        # Determine the backup type description for messages
        $backupTypeDescription = switch ($BackupType)
        {
            'Full'
            {
                'full'
            }
            'Differential'
            {
                'differential'
            }
            'Log'
            {
                'transaction log'
            }
        }

        $descriptionMessage = $script:localizedData.Database_Backup_ShouldProcessVerboseDescription -f $backupTypeDescription, $Name, $BackupFile
        $confirmationMessage = $script:localizedData.Database_Backup_ShouldProcessVerboseWarning -f $backupTypeDescription, $Name
        $captionMessage = $script:localizedData.Database_Backup_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            Write-Debug -Message ($script:localizedData.Database_Backup_BackingUp -f $backupTypeDescription, $Name, $BackupFile)

            try
            {
                # Create the backup object
                $backup = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Backup'

                # Set the database name
                $backup.Database = $Name

                # Set the backup action type based on BackupType parameter
                switch ($BackupType)
                {
                    'Full'
                    {
                        $backup.Action = [Microsoft.SqlServer.Management.Smo.BackupActionType]::Database
                        $backup.Incremental = $false
                    }

                    'Differential'
                    {
                        $backup.Action = [Microsoft.SqlServer.Management.Smo.BackupActionType]::Database
                        $backup.Incremental = $true
                    }

                    'Log'
                    {
                        $backup.Action = [Microsoft.SqlServer.Management.Smo.BackupActionType]::Log
                    }
                }

                # Create and add the backup device
                $backupDevice = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.BackupDeviceItem' -ArgumentList $BackupFile, 'File'
                $backup.Devices.Add($backupDevice)

                # Set optional properties
                if ($CopyOnly.IsPresent)
                {
                    $backup.CopyOnly = $true
                }

                if ($Compress.IsPresent)
                {
                    $backup.CompressionOption = [Microsoft.SqlServer.Management.Smo.BackupCompressionOptions]::On
                }

                if ($Checksum.IsPresent)
                {
                    $backup.Checksum = $true
                }

                if ($PSBoundParameters.ContainsKey('Description'))
                {
                    $backup.BackupSetDescription = $Description
                }

                if ($PSBoundParameters.ContainsKey('RetainDays'))
                {
                    $backup.RetainDays = $RetainDays
                }

                if ($Initialize.IsPresent)
                {
                    $backup.Initialize = $true
                }

                # Perform the backup
                $backup.SqlBackup($ServerObject)

                Write-Debug -Message ($script:localizedData.Database_Backup_Success -f $backupTypeDescription, $Name)

                if ($PassThru.IsPresent)
                {
                    return $DatabaseObject
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.Database_Backup_Failed -f $backupTypeDescription, $Name, $ServerObject.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'BSDD0004', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $DatabaseObject
                    )
                )
            }
        }
    }
}
