<#
    .SYNOPSIS
        Defines a data file specification for a database file group.

    .DESCRIPTION
        This class represents a data file specification that can be used when
        creating a new database. It contains the properties needed to define
        a data file without requiring an existing database or file group SMO object.

    .PARAMETER Name
        The logical name of the data file.

    .PARAMETER FileName
        The physical file path for the data file. This must be a valid path
        on the SQL Server instance.

    .PARAMETER Size
        The initial size of the data file in kilobytes. If not specified,
        SQL Server will use its default initial size.

    .PARAMETER MaxSize
        The maximum size to which the data file can grow in kilobytes.
        If not specified, the file can grow without limit (or up to disk space).

    .PARAMETER Growth
        The amount by which the data file grows when it needs more space.
        The value is in kilobytes if GrowthType is KB, or a percentage if
        GrowthType is Percent. If not specified, SQL Server will use its
        default growth setting.

    .PARAMETER GrowthType
        Specifies whether the Growth value is in kilobytes (KB) or percent (Percent).
        If not specified, defaults to KB.

    .PARAMETER IsPrimaryFile
        Specifies whether this file is the primary file in the PRIMARY file group.
        Only one file in the PRIMARY file group should be marked as the primary file.
        This property is typically used for the first file in the PRIMARY file group.

    .NOTES
        This class is used to specify data file configurations when creating a new
        database via New-SqlDscDatabase. Unlike SMO DataFile objects, these
        specification objects can be created without an existing database context.

    .EXAMPLE
        $fileSpec = [DatabaseFileSpec]::new()
        $fileSpec.Name = 'MyDatabase_Data'
        $fileSpec.FileName = 'C:\SQLData\MyDatabase.mdf'
        $fileSpec.Size = 102400  # 100 MB in KB
        $fileSpec.Growth = 10240  # 10 MB in KB
        $fileSpec.GrowthType = 'KB'

        Creates a new data file specification with a specific size and growth settings.

    .EXAMPLE
        [DatabaseFileSpec] @{
            Name = 'MyDatabase_Data'
            FileName = 'C:\SQLData\MyDatabase.mdf'
            IsPrimaryFile = $true
        }

        Creates a new primary data file specification using hashtable syntax.
#>
class DatabaseFileSpec
{
    [System.String]
    $Name

    [System.String]
    $FileName

    [System.Nullable[System.Double]]
    $Size

    [System.Nullable[System.Double]]
    $MaxSize

    [System.Nullable[System.Double]]
    $Growth

    [ValidateSet('KB', 'MB', 'Percent')]
    [System.String]
    $GrowthType

    [System.Boolean]
    $IsPrimaryFile = $false

    DatabaseFileSpec()
    {
    }

    DatabaseFileSpec([System.String] $name, [System.String] $fileName)
    {
        $this.Name = $name
        $this.FileName = $fileName
    }
}
