<#
    .SYNOPSIS
        Adds a DataFile to a SQL Server FileGroup.

    .DESCRIPTION
        This command adds an existing DataFile object to a FileGroup. The DataFile
        must be created first using New-SqlDscDataFile or by other means.

    .PARAMETER FileGroup
        Specifies the FileGroup object to which the DataFile will be added.

    .PARAMETER DataFile
        Specifies the DataFile object to add to the FileGroup.

    .PARAMETER PassThru
        Returns the DataFile object that was added to the FileGroup.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = $database.FileGroups['PRIMARY']
        $dataFile = New-SqlDscDataFile -Name 'MyDatabase_Data' -FileName 'C:\Data\MyDatabase_Data.mdf'
        Add-SqlDscDataFile -FileGroup $fileGroup -DataFile $dataFile

        Creates a DataFile and adds it to the PRIMARY FileGroup.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = $database.FileGroups['PRIMARY']
        $dataFile = New-SqlDscDataFile -Name 'MyDatabase_Data' -FileName 'C:\Data\MyDatabase_Data.mdf' |
            Add-SqlDscDataFile -FileGroup $fileGroup -PassThru

        Creates a DataFile, adds it to the PRIMARY FileGroup, and returns the DataFile object using pipeline input.

    .OUTPUTS
        None. Unless -PassThru is specified, in which case it returns `[Microsoft.SqlServer.Management.Smo.DataFile]`.
#>
function Add-SqlDscDataFile
{
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.DataFile])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.FileGroup]
        $FileGroup,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.DataFile]
        $DataFile,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    process
    {
        $FileGroup.Files.Add($DataFile)

        if ($PassThru.IsPresent)
        {
            return $DataFile
        }
    }
}
