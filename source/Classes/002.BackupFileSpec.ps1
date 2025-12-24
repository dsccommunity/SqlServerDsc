<#
    .SYNOPSIS
        Defines a file specification from a SQL Server backup file.

    .DESCRIPTION
        This class represents a file specification that is returned when reading
        the file list from a SQL Server backup file. It contains the properties
        describing each file stored in the backup, which is useful for planning
        file relocations during database restores.

    .PARAMETER LogicalName
        The logical name of the file as stored in the backup. This name is used
        when specifying file relocations during restore operations.

    .PARAMETER PhysicalName
        The original physical file path where the file was located when the
        backup was created.

    .PARAMETER Type
        The type of file. Common values are 'D' for data files and 'L' for
        log files.

    .PARAMETER FileGroupName
        The name of the file group that contains the file. This is typically
        'PRIMARY' for the primary file group.

    .PARAMETER Size
        The size of the file in bytes.

    .PARAMETER MaxSize
        The maximum size to which the file can grow in bytes.

    .NOTES
        This class is returned by the Get-SqlDscBackupFileList command and can
        be used to understand the file structure of a backup before performing
        a restore operation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $files = $serverObject | Get-SqlDscBackupFileList -BackupFile 'C:\Backups\MyDatabase.bak'
        $files | ForEach-Object { Write-Host "$($_.LogicalName): $($_.Type)" }

        Gets the file list from a backup and displays each file's logical name
        and type.
#>
class BackupFileSpec
{
    [System.String]
    $LogicalName

    [System.String]
    $PhysicalName

    [System.String]
    $Type

    [System.String]
    $FileGroupName

    [System.Int64]
    $Size

    [System.Int64]
    $MaxSize

    BackupFileSpec()
    {
    }

    BackupFileSpec(
        [System.String] $logicalName,
        [System.String] $physicalName,
        [System.String] $type,
        [System.String] $fileGroupName,
        [System.Int64] $size,
        [System.Int64] $maxSize
    )
    {
        $this.LogicalName = $logicalName
        $this.PhysicalName = $physicalName
        $this.Type = $type
        $this.FileGroupName = $fileGroupName
        $this.Size = $size
        $this.MaxSize = $maxSize
    }
}
