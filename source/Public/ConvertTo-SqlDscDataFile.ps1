<#
    .SYNOPSIS
        Converts a DatabaseFileSpec object to a SMO DataFile object.

    .DESCRIPTION
        This command takes a DatabaseFileSpec specification object and converts it
        to a SMO (SQL Server Management Objects) DataFile object. This is used
        internally when creating databases with custom file configurations.

    .PARAMETER FileGroupObject
        The SMO FileGroup object to which the DataFile will belong.

    .PARAMETER DataFileSpec
        The DatabaseFileSpec object containing the data file configuration.

    .INPUTS
        None.

        This command does not accept pipeline input.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.DataFile`

        Returns a SMO DataFile object bound to the provided FileGroup.

    .EXAMPLE
        $fileSpec = New-SqlDscDataFile -Name 'TestDB_Data' -FileName 'C:\SQLData\TestDB.mdf' -AsSpec
        $fileGroup = [Microsoft.SqlServer.Management.Smo.FileGroup]::new($database, 'PRIMARY')
        $dataFile = ConvertTo-SqlDscDataFile -FileGroupObject $fileGroup -DataFileSpec $fileSpec

        Converts a DatabaseFileSpec to a SMO DataFile object.
#>
function ConvertTo-SqlDscDataFile
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.DataFile])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.FileGroup]
        $FileGroupObject,

        [Parameter(Mandatory = $true)]
        [DatabaseFileSpec]
        $DataFileSpec
    )

    # Create SMO DataFile object
    $smoDataFile = [Microsoft.SqlServer.Management.Smo.DataFile]::new($FileGroupObject, $DataFileSpec.Name)
    $smoDataFile.FileName = $DataFileSpec.FileName

    # Set optional data file properties
    if ($DataFileSpec.Size -gt 0)
    {
        $smoDataFile.Size = $DataFileSpec.Size
    }

    if ($DataFileSpec.MaxSize -gt 0)
    {
        $smoDataFile.MaxSize = $DataFileSpec.MaxSize
    }

    if ($DataFileSpec.Growth -gt 0)
    {
        $smoDataFile.Growth = $DataFileSpec.Growth
    }

    if ($DataFileSpec.GrowthType)
    {
        $smoDataFile.GrowthType = $DataFileSpec.GrowthType
    }

    if ($DataFileSpec.IsPrimaryFile)
    {
        $smoDataFile.IsPrimaryFile = $DataFileSpec.IsPrimaryFile
    }

    return $smoDataFile
}
