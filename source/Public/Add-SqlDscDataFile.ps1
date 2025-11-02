<#
    .SYNOPSIS
        Adds one or more DataFile objects to a SQL Server FileGroup.

    .DESCRIPTION
        This command adds one or more existing DataFile objects to a FileGroup. The DataFile
        objects must be created first using New-SqlDscDataFile or by other means.

    .PARAMETER FileGroup
        Specifies the FileGroup object to which the DataFile will be added.

    .PARAMETER DataFile
        Specifies one or more DataFile objects to add to the FileGroup. This parameter
        accepts pipeline input.

    .PARAMETER PassThru
        Returns the DataFile objects that were added to the FileGroup.

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

    .EXAMPLE
        $dataFile1 = New-SqlDscDataFile -Name 'Data1' -FileName 'C:\Data\Data1.ndf'
        $dataFile2 = New-SqlDscDataFile -Name 'Data2' -FileName 'C:\Data\Data2.ndf'
        Add-SqlDscDataFile -FileGroup $fileGroup -DataFile @($dataFile1, $dataFile2)

        Adds multiple DataFiles to the FileGroup.

    .OUTPUTS
        None. Unless -PassThru is specified, in which case it returns `[Microsoft.SqlServer.Management.Smo.DataFile[]]`.
#>
function Add-SqlDscDataFile
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.DataFile[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.FileGroup]
        $FileGroup,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.DataFile[]]
        $DataFile,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    process
    {
        foreach ($dataFileObject in $DataFile)
        {
            $FileGroup.Files.Add($dataFileObject)

            if ($PassThru.IsPresent)
            {
                $dataFileObject
            }
        }
    }
}
