<#
    .SYNOPSIS
        Gets the list of files contained in a SQL Server backup file.

    .DESCRIPTION
        This command reads and returns the list of database files contained in
        a SQL Server backup file using SQL Server Management Objects (SMO). This
        is useful for understanding the file structure of a backup before
        performing a restore operation, especially when file relocation is needed.

    .PARAMETER ServerObject
        Specifies the current server connection object.

    .PARAMETER BackupFile
        Specifies the full path to the backup file to read.

    .PARAMETER FileNumber
        Specifies the backup set number to read when the backup file contains
        multiple backup sets. Default is 1.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscBackupFileList -BackupFile 'C:\Backups\MyDatabase.bak'

        Gets the list of files contained in the specified backup file.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $files = $serverObject | Get-SqlDscBackupFileList -BackupFile 'C:\Backups\MyDatabase.bak'
        $relocateFiles = $files | ForEach-Object {
            $newPath = if ($_.Type -eq 'L') { 'L:\SQLLogs' } else { 'D:\SQLData' }
            [Microsoft.SqlServer.Management.Smo.RelocateFile]::new(
                $_.LogicalName,
                (Join-Path -Path $newPath -ChildPath ([System.IO.Path]::GetFileName($_.PhysicalName)))
            )
        }
        $serverObject | Restore-SqlDscDatabase -Name 'MyDatabase' -BackupFile 'C:\Backups\MyDatabase.bak' -RelocateFile $relocateFiles

        Gets the file list and creates RelocateFile objects for a restore
        operation that moves files to different directories.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Server object accepted from the pipeline.

    .OUTPUTS
        `BackupFileSpec[]`

        Returns an array of BackupFileSpec objects describing each file in the backup.
#>
function Get-SqlDscBackupFileList
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([BackupFileSpec[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $BackupFile,

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [System.Int32]
        $FileNumber
    )

    process
    {
        Write-Debug -Message ($script:localizedData.Get_SqlDscBackupFileList_Reading -f $BackupFile)

        try
        {
            # Create the restore object to read file list
            $restore = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Restore'

            # Create and add the backup device
            $backupDevice = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.BackupDeviceItem' -ArgumentList $BackupFile, 'File'
            $restore.Devices.Add($backupDevice)

            if ($PSBoundParameters.ContainsKey('FileNumber'))
            {
                $restore.FileNumber = $FileNumber
            }

            # Read the file list from the backup
            $fileList = $restore.ReadFileList($ServerObject)

            # Convert DataTable rows to BackupFileSpec objects
            $result = foreach ($row in $fileList.Rows)
            {
                [BackupFileSpec]::new(
                    $row['LogicalName'],
                    $row['PhysicalName'],
                    $row['Type'],
                    $row['FileGroupName'],
                    [System.Int64] $row['Size'],
                    [System.Int64] $row['MaxSize']
                )
            }

            return $result
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscBackupFileList_Failed -f $BackupFile

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                    'GSBFL0002', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $BackupFile
                )
            )
        }
    }
}
