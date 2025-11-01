<#
    .SYNOPSIS
        Creates a new DataFile object for a SQL Server FileGroup.

    .DESCRIPTION
        This command creates a new DataFile object that can be added to a FileGroup
        when creating or modifying SQL Server databases. The DataFile object represents
        a physical database file (.mdf, .ndf, or .ss for snapshots).

    .PARAMETER FileGroup
        Specifies the FileGroup object to which this DataFile will belong. If not
        specified, the DataFile can be added to a FileGroup later.

    .PARAMETER Name
        Specifies the logical name of the DataFile.

    .PARAMETER FileName
        Specifies the physical path and filename for the DataFile. For database
        snapshots, this should point to a sparse file location (typically with
        .ss extension). For regular databases, this should be the data file
        path (typically with .mdf or .ndf extension).

    .PARAMETER Force
        Specifies that the DataFile object should be created without prompting for
        confirmation. By default, the command prompts for confirmation when the FileGroup
        parameter is provided.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = New-SqlDscFileGroup -Database $database -Name 'PRIMARY'
        $dataFile = New-SqlDscDataFile -FileGroup $fileGroup -Name 'MyDatabase_Data' -FileName 'C:\Data\MyDatabase_Data.mdf'

        Creates a new DataFile for a regular database with a FileGroup.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = New-SqlDscFileGroup -Database $database -Name 'PRIMARY'
        $dataFile = $fileGroup | New-SqlDscDataFile -Name 'MySnapshot_Data' -FileName 'C:\Snapshots\MySnapshot_Data.ss'

        Creates a new sparse file for a database snapshot using pipeline input.

    .EXAMPLE
        $dataFile = New-SqlDscDataFile -Name 'MyDatabase_Data' -FileName 'C:\Data\MyDatabase_Data.mdf'

        Creates a standalone DataFile object without assigning it to a FileGroup.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.DataFile]`
#>
function New-SqlDscDataFile
{
    [OutputType([Microsoft.SqlServer.Management.Smo.DataFile])]
    [CmdletBinding(DefaultParameterSetName = 'Standalone', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'WithFileGroup', ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.FileGroup]
        $FileGroup,

        [Parameter(Mandatory = $true, ParameterSetName = 'WithFileGroup')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Standalone')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'WithFileGroup')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Standalone')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $FileName,

        [Parameter(ParameterSetName = 'WithFileGroup')]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $dataFileObject = $null

        if ($PSCmdlet.ParameterSetName -eq 'WithFileGroup')
        {
            $descriptionMessage = $script:localizedData.DataFile_Create_ShouldProcessDescription -f $Name, $FileGroup.Name
            $confirmationMessage = $script:localizedData.DataFile_Create_ShouldProcessConfirmation -f $Name
            $captionMessage = $script:localizedData.DataFile_Create_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
            {
                $dataFileObject = [Microsoft.SqlServer.Management.Smo.DataFile]::new($FileGroup, $Name, $FileName)
            }
        }
        else
        {
            $dataFileObject = [Microsoft.SqlServer.Management.Smo.DataFile]::new()
            $dataFileObject.Name = $Name
            $dataFileObject.FileName = $FileName
        }

        return $dataFileObject
    }
}
