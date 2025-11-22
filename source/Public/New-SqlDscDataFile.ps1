<#
    .SYNOPSIS
        Creates a new DataFile object for a SQL Server FileGroup and adds it to the FileGroup.

    .DESCRIPTION
        This command creates a new DataFile object and automatically adds it to the specified
        FileGroup's Files collection. The DataFile object represents a physical database file
        (.mdf, .ndf, or .ss for snapshots).

    .PARAMETER FileGroup
        Specifies the FileGroup object to which this DataFile will belong. The DataFile
        will be automatically added to this FileGroup's Files collection.

    .PARAMETER Name
        Specifies the logical name of the DataFile.

    .PARAMETER FileName
        Specifies the physical path and filename for the DataFile. For database snapshots,
        this should point to a sparse file location (typically with an .ss extension).
        For regular databases, this should be the data file path (typically with .mdf
        or .ndf extension).

    .PARAMETER DataFileSpec
        Specifies a DatabaseFileSpec object that defines the data file configuration
        including name, file path, size, growth, and other properties.

    .PARAMETER AsSpec
        Returns a DatabaseFileSpec object instead of a SMO DataFile object.
        This specification object can be used with New-SqlDscFileGroup -AsSpec
        or passed directly to New-SqlDscDatabase to define data files before
        the database is created.

        When this parameter is used, the command always returns a DatabaseFileSpec
        object, regardless of the PassThru parameter, and the FileGroup parameter
        is not available.

    .PARAMETER Size
        Specifies the initial size of the data file in kilobytes. Only valid when
        used with the -AsSpec parameter to create a DatabaseFileSpec object.

    .PARAMETER MaxSize
        Specifies the maximum size to which the data file can grow, in kilobytes.
        Only valid when used with the -AsSpec parameter to create a DatabaseFileSpec
        object.

    .PARAMETER Growth
        Specifies the amount by which the data file grows when it requires more space.
        The value is interpreted according to the GrowthType parameter (kilobytes or
        percentage). Only valid when used with the -AsSpec parameter to create a
        DatabaseFileSpec object.

    .PARAMETER GrowthType
        Specifies the type of growth for the data file. Valid values are 'KB', 'MB',
        or 'Percent'. Only valid when used with the -AsSpec parameter to create a
        DatabaseFileSpec object.

    .PARAMETER IsPrimaryFile
        Specifies that this data file is the primary file in the PRIMARY filegroup.
        Only valid when used with the -AsSpec parameter to create a DatabaseFileSpec
        object.

    .PARAMETER PassThru
        Returns the DataFile object that was created and added to the FileGroup.
        Only available when using the Standard or FromSpec parameter sets. When
        using the AsSpec parameter set, a DatabaseFileSpec object is always returned.

    .PARAMETER Force
        Specifies that the DataFile object should be created without prompting for
        confirmation. By default, the command prompts for confirmation when the FileGroup
        parameter is provided.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = New-SqlDscFileGroup -Database $database -Name 'PRIMARY'
        New-SqlDscDataFile -FileGroup $fileGroup -Name 'MyDatabase_Data' -FileName 'C:\Data\MyDatabase_Data.mdf' -Force

        Creates a new DataFile for a regular database with a FileGroup and adds it to the FileGroup.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = New-SqlDscFileGroup -Database $database -Name 'PRIMARY'
        $dataFile = New-SqlDscDataFile -FileGroup $fileGroup -Name 'MySnapshot_Data' -FileName 'C:\Snapshots\MySnapshot_Data.ss' -PassThru -Force

        Creates a new sparse file for a database snapshot and returns the DataFile object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = $database.FileGroups['PRIMARY']
        $dataFile = New-SqlDscDataFile -FileGroup $fileGroup -Name 'AdditionalData' -FileName 'C:\Data\AdditionalData.ndf' -PassThru -Force

        Creates an additional DataFile and returns it for further processing.

    .EXAMPLE
        $dataFileSpec = New-SqlDscDataFile -Name 'MyDB_Primary' -FileName 'D:\SQLData\MyDB.mdf' -AsSpec

        Creates a DatabaseFileSpec object that can be used with New-SqlDscFileGroup -AsSpec
        or passed to New-SqlDscDatabase.

    .EXAMPLE
        $dataFileSpec = New-SqlDscDataFile -Name 'MyDB_Primary' -FileName 'D:\SQLData\MyDB.mdf' -Size 102400 -MaxSize 5242880 -Growth 10240 -GrowthType 'KB' -IsPrimaryFile -AsSpec

        Creates a DatabaseFileSpec object with all properties set directly via parameters.

    .INPUTS
        None

        This cmdlet does not accept input from the pipeline.

    .OUTPUTS
        None

        This cmdlet does not generate output by default when using Standard or FromSpec parameter sets without PassThru.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.DataFile

        When using the Standard or FromSpec parameter sets with the PassThru parameter.

    .OUTPUTS
        DatabaseFileSpec

        When using the AsSpec parameter to create a specification object.
#>
function New-SqlDscDataFile
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(DefaultParameterSetName = 'Standard', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([Microsoft.SqlServer.Management.Smo.DataFile])]
    [OutputType([DatabaseFileSpec])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Standard')]
        [Parameter(Mandatory = $true, ParameterSetName = 'FromSpec')]
        [Microsoft.SqlServer.Management.Smo.FileGroup]
        $FileGroup,

        [Parameter(Mandatory = $true, ParameterSetName = 'Standard')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AsSpec')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'Standard')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AsSpec')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $FileName,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromSpec')]
        [ValidateNotNull()]
        [DatabaseFileSpec]
        $DataFileSpec,

        [Parameter(Mandatory = $true, ParameterSetName = 'AsSpec')]
        [System.Management.Automation.SwitchParameter]
        $AsSpec,

        [Parameter(ParameterSetName = 'AsSpec')]
        [System.Nullable[System.Double]]
        $Size,

        [Parameter(ParameterSetName = 'AsSpec')]
        [System.Nullable[System.Double]]
        $MaxSize,

        [Parameter(ParameterSetName = 'AsSpec')]
        [System.Nullable[System.Double]]
        $Growth,

        [Parameter(ParameterSetName = 'AsSpec')]
        [ValidateSet('KB', 'MB', 'Percent')]
        [System.String]
        $GrowthType,

        [Parameter(ParameterSetName = 'AsSpec')]
        [System.Management.Automation.SwitchParameter]
        $IsPrimaryFile,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'FromSpec')]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'FromSpec')]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ParameterSetName -eq 'AsSpec')
    {
        $fileSpec = [DatabaseFileSpec]::new($Name, $FileName)

        if ($PSBoundParameters.ContainsKey('Size'))
        {
            $fileSpec.Size = $Size
        }

        if ($PSBoundParameters.ContainsKey('MaxSize'))
        {
            $fileSpec.MaxSize = $MaxSize
        }

        if ($PSBoundParameters.ContainsKey('Growth'))
        {
            $fileSpec.Growth = $Growth
        }

        if ($PSBoundParameters.ContainsKey('GrowthType'))
        {
            $fileSpec.GrowthType = $GrowthType
        }

        if ($IsPrimaryFile.IsPresent)
        {
            $fileSpec.IsPrimaryFile = $true
        }

        return $fileSpec
    }

    # Validate that primary files can only be in the PRIMARY filegroup
    if ($PSCmdlet.ParameterSetName -in @('FromSpec'))
    {
        $isPrimary = $null -ne $DataFileSpec -and $DataFileSpec.IsPrimaryFile

        if ($isPrimary -and $FileGroup.Name -ne 'PRIMARY')
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.DataFile_PrimaryFileMustBeInPrimaryFileGroup),
                    'NSDDF0003',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $FileGroup
                )
            )
        }
    }

    # Determine the data file name based on parameter set
    $dataFileName = if ($PSCmdlet.ParameterSetName -eq 'FromSpec')
    {
        $DataFileSpec.Name
    }
    else
    {
        $Name
    }

    $descriptionMessage = $script:localizedData.DataFile_Create_ShouldProcessDescription -f $dataFileName, $FileGroup.Name
    $confirmationMessage = $script:localizedData.DataFile_Create_ShouldProcessConfirmation -f $dataFileName
    $captionMessage = $script:localizedData.DataFile_Create_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        if ($PSCmdlet.ParameterSetName -eq 'FromSpec')
        {
            # Convert the spec object to SMO DataFile
            $dataFileObject = ConvertTo-SqlDscDataFile -FileGroupObject $FileGroup -DataFileSpec $DataFileSpec
        }
        else
        {
            $dataFileObject = [Microsoft.SqlServer.Management.Smo.DataFile]::new($FileGroup, $Name, $FileName)
        }

        $FileGroup.Files.Add($dataFileObject)

        if ($PassThru.IsPresent)
        {
            return $dataFileObject
        }
    }
}
