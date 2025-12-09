<#
    .SYNOPSIS
        Restores a SQL Server database from a backup file.

    .DESCRIPTION
        This command restores a SQL Server database from a backup file using SQL
        Server Management Objects (SMO). It supports full, differential, transaction
        log, and file restores with options for file relocation, point-in-time
        recovery, and various recovery states.

    .PARAMETER ServerObject
        Specifies the current server connection object.

    .PARAMETER DatabaseObject
        Specifies a database object to restore to. This is used when restoring
        differential or log backups to an existing database.

    .PARAMETER Name
        Specifies the name of the database to restore to.

    .PARAMETER BackupFile
        Specifies the full path to the backup file. For full and differential
        restores, use the `.bak` extension. For transaction log restores, use
        the `.trn` extension.

    .PARAMETER RestoreType
        Specifies the type of restore to perform. Valid values are 'Full',
        'Differential', 'Log', and 'Files'. Default value is 'Full'.

    .PARAMETER NoRecovery
        Specifies that the database should be left in a restoring state after
        the restore operation. This allows additional differential or log
        backups to be restored. Cannot be used together with Standby.

    .PARAMETER Standby
        Specifies the path to the standby (undo) file. When specified, the
        database is left in standby mode, which allows read-only access while
        additional log backups can still be applied. Cannot be used together
        with NoRecovery.

    .PARAMETER ReplaceDatabase
        Specifies that the existing database should be replaced. This is
        equivalent to the WITH REPLACE option in T-SQL.

    .PARAMETER RelocateFile
        Specifies an array of RelocateFile objects that define how to relocate
        database files during restore. Each RelocateFile object contains a
        LogicalFileName and PhysicalFileName property.

    .PARAMETER DataFilePath
        Specifies the directory path where data files should be relocated during
        restore. This is a simpler alternative to RelocateFile when you want all
        data files in one directory. Cannot be used together with RelocateFile.

    .PARAMETER LogFilePath
        Specifies the directory path where log files should be relocated during
        restore. This is a simpler alternative to RelocateFile when you want all
        log files in one directory. Cannot be used together with RelocateFile.

    .PARAMETER Checksum
        Specifies that checksums should be verified during the restore operation.

    .PARAMETER RestrictedUser
        Specifies that access to the restored database should be restricted to
        members of the db_owner, dbcreator, or sysadmin roles.

    .PARAMETER KeepReplication
        Specifies that replication settings should be preserved during restore.

    .PARAMETER FileNumber
        Specifies the backup set number to restore when the backup file contains
        multiple backup sets. Default is 1.

    .PARAMETER ToPointInTime
        Specifies a point in time to restore the database to. This parameter
        is only valid for transaction log restores when the database uses
        the Full or Bulk-Logged recovery model.

    .PARAMETER StopAtMarkName
        Specifies the name of a marked transaction to stop at during restore.
        The restore includes the marked transaction.

    .PARAMETER StopAtMarkAfterDate
        Specifies the date/time after which to look for the mark specified by
        StopAtMarkName. If not specified, the restore stops at the first mark
        with the specified name.

    .PARAMETER StopBeforeMarkName
        Specifies the name of a marked transaction to stop before during restore.
        The restore does not include the marked transaction.

    .PARAMETER StopBeforeMarkAfterDate
        Specifies the date/time after which to look for the mark specified by
        StopBeforeMarkName. If not specified, the restore stops before the first
        mark with the specified name.

    .PARAMETER BlockSize
        Specifies the physical block size in bytes. Supported sizes are 512,
        1024, 2048, 4096, 8192, 16384, 32768, and 65536 bytes.

    .PARAMETER BufferCount
        Specifies the number of I/O buffers to use for the restore operation.

    .PARAMETER MaxTransferSize
        Specifies the maximum transfer size in bytes between SQL Server and
        the backup media.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        accessing the database. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL.

    .PARAMETER Force
        Specifies that the restore should be performed without any confirmation.

    .PARAMETER PassThru
        Specifies that the restored database object should be returned.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak'

        Performs a full restore of the database named **MyDatabase** from the
        specified backup file.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak' -ReplaceDatabase -Force

        Performs a full restore of the database named **MyDatabase**, replacing
        the existing database without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak' -NoRecovery
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase_Diff.bak' -RestoreType 'Differential' -NoRecovery
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.trn' -RestoreType 'Log'

        Performs a restore sequence: full backup with NORECOVERY, differential
        backup with NORECOVERY, and finally a transaction log backup with RECOVERY.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak' -DataFilePath 'D:\SQLData' -LogFilePath 'L:\SQLLogs'

        Performs a full restore with all data files relocated to D:\SQLData and
        all log files relocated to L:\SQLLogs.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $relocateFiles = @(
            [Microsoft.SqlServer.Management.Smo.RelocateFile]::new('MyDatabase', 'D:\SQLData\MyDatabase.mdf')
            [Microsoft.SqlServer.Management.Smo.RelocateFile]::new('MyDatabase_log', 'L:\SQLLogs\MyDatabase_log.ldf')
        )
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak' -RelocateFile $relocateFiles

        Performs a full restore with specific file relocations using RelocateFile
        objects.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.trn' -RestoreType 'Log' -ToPointInTime '2024-01-15T14:30:00'

        Performs a point-in-time restore of a transaction log backup.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Server object accepted from the pipeline (ServerObject parameter sets).

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Database`

        Database object accepted from the pipeline (DatabaseObject parameter sets).

    .OUTPUTS
        None. By default, this command returns no output.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Database`

        When PassThru is specified, returns the restored database object.
#>
function Restore-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(DefaultParameterSetName = 'ServerObject', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ServerObjectSimpleRelocate', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'DatabaseObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'DatabaseObjectSimpleRelocate', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectSimpleRelocate', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $BackupFile,

        [Parameter()]
        [ValidateSet('Full', 'Differential', 'Log', 'Files')]
        [System.String]
        $RestoreType = 'Full',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoRecovery,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Standby,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ReplaceDatabase,

        [Parameter(ParameterSetName = 'ServerObject')]
        [Parameter(ParameterSetName = 'DatabaseObject')]
        [Microsoft.SqlServer.Management.Smo.RelocateFile[]]
        $RelocateFile,

        [Parameter(ParameterSetName = 'ServerObjectSimpleRelocate', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatabaseObjectSimpleRelocate', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DataFilePath,

        [Parameter(ParameterSetName = 'ServerObjectSimpleRelocate', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatabaseObjectSimpleRelocate', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LogFilePath,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Checksum,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RestrictedUser,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $KeepReplication,

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [System.Int32]
        $FileNumber,

        [Parameter()]
        [System.DateTime]
        $ToPointInTime,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $StopAtMarkName,

        [Parameter()]
        [System.DateTime]
        $StopAtMarkAfterDate,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $StopBeforeMarkName,

        [Parameter()]
        [System.DateTime]
        $StopBeforeMarkAfterDate,

        [Parameter()]
        [ValidateSet(512, 1024, 2048, 4096, 8192, 16384, 32768, 65536)]
        [System.Int32]
        $BlockSize,

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [System.Int32]
        $BufferCount,

        [Parameter()]
        [ValidateRange(1, 4194304)]
        [System.Int32]
        $MaxTransferSize,

        [Parameter(ParameterSetName = 'ServerObject')]
        [Parameter(ParameterSetName = 'ServerObjectSimpleRelocate')]
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
        # Validate that NoRecovery and Standby are not both specified
        if ($NoRecovery.IsPresent -and $PSBoundParameters.ContainsKey('Standby'))
        {
            $errorMessage = $script:localizedData.Restore_SqlDscDatabase_StandbyConflict

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.ArgumentException]::new($errorMessage),
                    'RSDD0006', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $null
                )
            )
        }

        if ($PSCmdlet.ParameterSetName -in @('ServerObject', 'ServerObjectSimpleRelocate'))
        {
            if ($Refresh.IsPresent)
            {
                # Refresh the server object's databases collection
                $ServerObject.Databases.Refresh()
            }
        }
        else
        {
            $Name = $DatabaseObject.Name
            $ServerObject = $DatabaseObject.Parent
        }

        # Check if database exists when not using ReplaceDatabase
        $existingDatabase = $ServerObject.Databases[$Name]

        if ($existingDatabase -and -not $ReplaceDatabase.IsPresent)
        {
            $errorMessage = $script:localizedData.Restore_SqlDscDatabase_DatabaseExists -f $Name

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'RSDD0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $Name
                )
            )
        }

        # Determine the restore type description for messages
        $restoreTypeDescription = switch ($RestoreType)
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
            'Files'
            {
                'file'
            }
        }

        # Validate that point-in-time and mark parameters are not used with non-log restore types
        if ($RestoreType -in @('Full', 'Differential', 'Files'))
        {
            $assertBoundParameterParameters = @{
                BoundParameterList = $PSBoundParameters
                NotAllowedList = @(
                    'ToPointInTime'
                    'StopAtMarkName'
                    'StopBeforeMarkName'
                )
                IfParameterPresent = @{
                    RestoreType = $RestoreType
                }
            }

            Assert-BoundParameter @assertBoundParameterParameters
        }

        $descriptionMessage = $script:localizedData.Restore_SqlDscDatabase_ShouldProcessVerboseDescription -f $restoreTypeDescription, $Name, $BackupFile, $ServerObject.InstanceName
        $confirmationMessage = $script:localizedData.Restore_SqlDscDatabase_ShouldProcessVerboseWarning -f $restoreTypeDescription, $Name
        $captionMessage = $script:localizedData.Restore_SqlDscDatabase_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            Write-Debug -Message ($script:localizedData.Restore_SqlDscDatabase_Restoring -f $restoreTypeDescription, $Name, $BackupFile)

            try
            {
                # Create the restore object
                $restore = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Restore'

                # Set the database name
                $restore.Database = $Name

                # Set the restore action type based on RestoreType parameter
                switch ($RestoreType)
                {
                    'Full'
                    {
                        $restore.Action = [Microsoft.SqlServer.Management.Smo.RestoreActionType]::Database
                    }

                    'Differential'
                    {
                        $restore.Action = [Microsoft.SqlServer.Management.Smo.RestoreActionType]::Database
                    }

                    'Log'
                    {
                        $restore.Action = [Microsoft.SqlServer.Management.Smo.RestoreActionType]::Log
                    }

                    'Files'
                    {
                        $restore.Action = [Microsoft.SqlServer.Management.Smo.RestoreActionType]::Files
                    }
                }

                # Create and add the backup device
                $backupDevice = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.BackupDeviceItem' -ArgumentList $BackupFile, 'File'
                $restore.Devices.Add($backupDevice)

                # Set recovery options
                if ($NoRecovery.IsPresent)
                {
                    $restore.NoRecovery = $true
                }

                if ($PSBoundParameters.ContainsKey('Standby'))
                {
                    $restore.StandbyFile = $Standby
                }

                if ($ReplaceDatabase.IsPresent)
                {
                    $restore.ReplaceDatabase = $true
                }

                # Handle file relocation
                if ($PSCmdlet.ParameterSetName -in @('ServerObjectSimpleRelocate', 'DatabaseObjectSimpleRelocate'))
                {
                    # Get the file list from the backup to perform simple relocation
                    $fileList = $restore.ReadFileList($ServerObject)

                    foreach ($row in $fileList.Rows)
                    {
                        $logicalName = $row['LogicalName']
                        $fileType = $row['Type']
                        $originalFileName = [System.IO.Path]::GetFileName($row['PhysicalName'])

                        if ($fileType -eq 'L')
                        {
                            $newPhysicalName = Join-Path -Path $LogFilePath -ChildPath $originalFileName
                        }
                        else
                        {
                            $newPhysicalName = Join-Path -Path $DataFilePath -ChildPath $originalFileName
                        }

                        $relocateFileObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.RelocateFile' -ArgumentList $logicalName, $newPhysicalName
                        $restore.RelocateFiles.Add($relocateFileObject)
                    }
                }
                elseif ($PSBoundParameters.ContainsKey('RelocateFile'))
                {
                    foreach ($file in $RelocateFile)
                    {
                        $restore.RelocateFiles.Add($file)
                    }
                }

                # Set optional properties
                if ($Checksum.IsPresent)
                {
                    $restore.Checksum = $true
                }

                if ($RestrictedUser.IsPresent)
                {
                    $restore.RestrictedUser = $true
                }

                if ($KeepReplication.IsPresent)
                {
                    $restore.KeepReplication = $true
                }

                if ($PSBoundParameters.ContainsKey('FileNumber'))
                {
                    $restore.FileNumber = $FileNumber
                }

                if ($PSBoundParameters.ContainsKey('ToPointInTime'))
                {
                    $restore.ToPointInTime = $ToPointInTime.ToString('yyyy-MM-ddTHH:mm:ss')
                }

                if ($PSBoundParameters.ContainsKey('StopAtMarkName'))
                {
                    $restore.StopAtMarkName = $StopAtMarkName

                    if ($PSBoundParameters.ContainsKey('StopAtMarkAfterDate'))
                    {
                        $restore.StopAtMarkAfterDate = $StopAtMarkAfterDate.ToString('yyyy-MM-ddTHH:mm:ss')
                    }
                }

                if ($PSBoundParameters.ContainsKey('StopBeforeMarkName'))
                {
                    $restore.StopBeforeMarkName = $StopBeforeMarkName

                    if ($PSBoundParameters.ContainsKey('StopBeforeMarkAfterDate'))
                    {
                        $restore.StopBeforeMarkAfterDate = $StopBeforeMarkAfterDate.ToString('yyyy-MM-ddTHH:mm:ss')
                    }
                }

                # Performance options
                if ($PSBoundParameters.ContainsKey('BlockSize'))
                {
                    $restore.BlockSize = $BlockSize
                }

                if ($PSBoundParameters.ContainsKey('BufferCount'))
                {
                    $restore.BufferCount = $BufferCount
                }

                if ($PSBoundParameters.ContainsKey('MaxTransferSize'))
                {
                    $restore.MaxTransferSize = $MaxTransferSize
                }

                # Perform the restore
                $restore.SqlRestore($ServerObject)

                Write-Debug -Message ($script:localizedData.Restore_SqlDscDatabase_Success -f $restoreTypeDescription, $Name)

                if ($PassThru.IsPresent)
                {
                    # Refresh the databases collection to get the restored database
                    $ServerObject.Databases.Refresh()
                    $ServerObject.Databases[$Name]
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.Restore_SqlDscDatabase_Failed -f $restoreTypeDescription, $Name, $ServerObject.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'RSDD0003', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Name
                    )
                )
            }
        }
    }
}
