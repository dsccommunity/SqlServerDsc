<#
    .SYNOPSIS
        Defines a file group specification for a database.

    .DESCRIPTION
        This class represents a file group specification that can be used when
        creating a new database. It contains the properties needed to define
        a file group and its associated data files without requiring an existing
        database SMO object.

    .PARAMETER Name
        The name of the file group. For the primary file group, this should be 'PRIMARY'.

    .PARAMETER Files
        An array of DatabaseFileSpec objects that define the data files belonging
        to this file group. At least one file must be specified for each file group.

    .PARAMETER ReadOnly
        Specifies whether the file group is read-only. If not specified, defaults
        to $false (read-write).

    .PARAMETER IsDefault
        Specifies whether this file group should be the default file group for
        new objects. If not specified, defaults to $false. Typically, only the
        PRIMARY file group or one custom file group should be marked as default.

    .NOTES
        This class is used to specify file group configurations when creating a new
        database via New-SqlDscDatabase. Unlike SMO FileGroup objects, these
        specification objects can be created without an existing database context.

        When creating a database, you typically need at least one file group named
        'PRIMARY' which contains the primary data file. Additional file groups can
        be added for organizing data files.

    .EXAMPLE
        $primaryFile = [DatabaseFileSpec] @{
            Name = 'MyDatabase_Primary'
            FileName = 'C:\SQLData\MyDatabase.mdf'
            IsPrimaryFile = $true
        }

        $primaryFileGroup = [DatabaseFileGroupSpec]::new()
        $primaryFileGroup.Name = 'PRIMARY'
        $primaryFileGroup.Files = @($primaryFile)

        Creates a PRIMARY file group specification with one primary data file.

    .EXAMPLE
        $dataFile1 = [DatabaseFileSpec] @{
            Name = 'MyDatabase_Data1'
            FileName = 'D:\SQLData\MyDatabase_Data1.ndf'
            Size = 204800  # 200 MB
        }

        $dataFile2 = [DatabaseFileSpec] @{
            Name = 'MyDatabase_Data2'
            FileName = 'D:\SQLData\MyDatabase_Data2.ndf'
            Size = 204800  # 200 MB
        }

        $secondaryFileGroup = [DatabaseFileGroupSpec] @{
            Name = 'SECONDARY'
            Files = @($dataFile1, $dataFile2)
        }

        Creates a SECONDARY file group specification with two data files.

    .EXAMPLE
        [DatabaseFileGroupSpec] @{
            Name = 'PRIMARY'
            Files = @(
                [DatabaseFileSpec] @{
                    Name = 'MyDB_Primary'
                    FileName = 'C:\SQLData\MyDB.mdf'
                }
            )
        }

        Creates a PRIMARY file group using hashtable syntax with an embedded file spec.
#>
class DatabaseFileGroupSpec
{
    [System.String]
    $Name

    [DatabaseFileSpec[]]
    $Files

    [System.Boolean]
    $ReadOnly = $false

    [System.Boolean]
    $IsDefault = $false

    DatabaseFileGroupSpec()
    {
    }

    DatabaseFileGroupSpec([System.String] $name)
    {
        $this.Name = $name
    }

    DatabaseFileGroupSpec([System.String] $name, [DatabaseFileSpec[]] $files)
    {
        $this.Name = $name
        $this.Files = $files
    }
}
