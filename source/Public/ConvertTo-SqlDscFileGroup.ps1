<#
    .SYNOPSIS
        Converts a DatabaseFileGroupSpec object to a SMO FileGroup object.

    .DESCRIPTION
        This command takes a DatabaseFileGroupSpec specification object and converts it
        to a SMO (SQL Server Management Objects) FileGroup object with all configured
        data files. This is used internally when creating databases with custom file
        group configurations.

    .PARAMETER DatabaseObject
        The SMO Database object to which the FileGroup will belong.

    .PARAMETER FileGroupSpec
        The DatabaseFileGroupSpec object containing the file group configuration.

    .INPUTS
        None.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.FileGroup`

        Returns a FileGroup object configured with the specified properties and data files.

    .EXAMPLE
        $fileSpec = New-SqlDscDataFile -Name 'TestDB_Data' -FileName 'C:\SQLData\TestDB.mdf' -AsSpec
        $fileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($fileSpec) -AsSpec
        $smoFileGroup = ConvertTo-SqlDscFileGroup -DatabaseObject $database -FileGroupSpec $fileGroupSpec

        Converts a DatabaseFileGroupSpec to a SMO FileGroup object with data files.
#>
function ConvertTo-SqlDscFileGroup
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.FileGroup])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        [Parameter(Mandatory = $true)]
        [DatabaseFileGroupSpec]
        $FileGroupSpec
    )

    # Create SMO FileGroup object
    $smoFileGroup = [Microsoft.SqlServer.Management.Smo.FileGroup]::new($DatabaseObject, $FileGroupSpec.Name)

    # Set file group properties
    if ($null -ne $FileGroupSpec.ReadOnly)
    {
        $smoFileGroup.ReadOnly = $FileGroupSpec.ReadOnly
    }

    if ($null -ne $FileGroupSpec.IsDefault)
    {
        $smoFileGroup.IsDefault = $FileGroupSpec.IsDefault
    }

    # Add data files to the file group
    if ($FileGroupSpec.Files -and $FileGroupSpec.Files.Count -gt 0)
    {
        foreach ($fileSpec in $FileGroupSpec.Files)
        {
            $smoDataFile = ConvertTo-SqlDscDataFile -FileGroupObject $smoFileGroup -DataFileSpec $fileSpec
            $smoFileGroup.Files.Add($smoDataFile)
        }
    }

    return $smoFileGroup
}
