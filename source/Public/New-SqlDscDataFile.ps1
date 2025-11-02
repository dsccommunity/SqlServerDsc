<#
    .SYNOPSIS
        Creates a new DataFile object for a SQL Server FileGroup.

    .DESCRIPTION
        This command creates a new DataFile object that can be added to a FileGroup
        when creating or modifying SQL Server databases. The DataFile object represents
        a physical database file (.mdf, .ndf, or .ss for snapshots).

    .PARAMETER FileGroup
        Specifies the FileGroup object to which this DataFile will belong.

    .PARAMETER Name
        Specifies the logical name of the DataFile.

    .PARAMETER FileName
        Specifies the physical path and filename for the DataFile. For database snapshots,
        this should point to a sparse file location (typically with an .ss extension).
        For regular databases, this should be the data file path (typically with .mdf
        or .ndf extension).

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

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.DataFile]`
#>
function New-SqlDscDataFile
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([Microsoft.SqlServer.Management.Smo.DataFile])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.FileGroup]
        $FileGroup,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $FileName,

        [Parameter()]
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

        $descriptionMessage = $script:localizedData.DataFile_Create_ShouldProcessDescription -f $Name, $FileGroup.Name
        $confirmationMessage = $script:localizedData.DataFile_Create_ShouldProcessConfirmation -f $Name
        $captionMessage = $script:localizedData.DataFile_Create_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $dataFileObject = [Microsoft.SqlServer.Management.Smo.DataFile]::new($FileGroup, $Name, $FileName)
        }

        return $dataFileObject
    }
}
