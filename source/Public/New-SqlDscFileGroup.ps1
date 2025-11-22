<#
    .SYNOPSIS
        Creates a new FileGroup object for a SQL Server database.

    .DESCRIPTION
        This command creates a new FileGroup object that can be used when creating
        or modifying SQL Server databases. The FileGroup object can contain DataFile
        objects. The FileGroup can be created with or without an associated Database,
        allowing it to be added to a Database later using Add-SqlDscFileGroup.

    .PARAMETER Database
        Specifies the Database object to which this FileGroup will belong. This parameter
        is optional. If not specified, a standalone FileGroup is created that can be
        added to a Database later.

    .PARAMETER Name
        Specifies the name of the FileGroup to create.

    .PARAMETER FileGroupSpec
        Specifies a DatabaseFileGroupSpec object that defines the file group configuration
        including name, properties, and data files.

    .PARAMETER AsSpec
        Returns a DatabaseFileGroupSpec object instead of a SMO FileGroup object.
        This specification object can be passed to New-SqlDscDatabase to define
        file groups before the database is created.

    .PARAMETER Files
        Specifies an array of DatabaseFileSpec objects to include in the file group.
        Only valid when using -AsSpec.

    .PARAMETER ReadOnly
        Specifies whether the file group should be read-only. Only valid when using -AsSpec.

    .PARAMETER IsDefault
        Specifies whether this file group should be the default file group. Only valid when using -AsSpec.

    .PARAMETER Force
        Specifies that the FileGroup object should be created without prompting for
        confirmation. By default, the command prompts for confirmation when the Database
        parameter is provided.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = New-SqlDscFileGroup -Database $database -Name 'MyFileGroup'

        Creates a new FileGroup named 'MyFileGroup' for the specified database.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $database = $serverObject.Databases['MyDatabase']
        $fileGroup = New-SqlDscFileGroup -Database $database -Name 'PRIMARY'

        Creates a new PRIMARY FileGroup for the specified database.

    .EXAMPLE
        $fileGroup = New-SqlDscFileGroup -Name 'MyFileGroup'
        # Later add to database
        Add-SqlDscFileGroup -Database $database -FileGroup $fileGroup

        Creates a standalone FileGroup that can be added to a Database later.

    .EXAMPLE
        $fileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -AsSpec

        Creates a DatabaseFileGroupSpec object that can be passed to New-SqlDscDatabase.

    .EXAMPLE
        $primaryFile = New-SqlDscDataFile -Name 'MyDB_Primary' -FileName 'D:\SQLData\MyDB.mdf' -Size 102400 -IsPrimaryFile -AsSpec
        $fileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($primaryFile) -IsDefault $true -AsSpec

        Creates a DatabaseFileGroupSpec object with files and properties set directly via parameters.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.FileGroup

        When creating a FileGroup with or without an associated Database (not using -AsSpec).

    .OUTPUTS
        DatabaseFileGroupSpec

        When using the -AsSpec parameter to create a specification object.
#>
function New-SqlDscFileGroup
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(DefaultParameterSetName = 'Standalone', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([Microsoft.SqlServer.Management.Smo.FileGroup])]
    [OutputType([DatabaseFileGroupSpec])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'WithDatabase')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WithDatabaseFromSpec')]
        [Microsoft.SqlServer.Management.Smo.Database]
        $Database,

        [Parameter(Mandatory = $true, ParameterSetName = 'WithDatabase')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Standalone')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AsSpec')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'WithDatabaseFromSpec')]
        [System.Object]
        $FileGroupSpec,

        [Parameter(Mandatory = $true, ParameterSetName = 'AsSpec')]
        [System.Management.Automation.SwitchParameter]
        $AsSpec,

        [Parameter(ParameterSetName = 'AsSpec')]
        [DatabaseFileSpec[]]
        $Files,

        [Parameter(ParameterSetName = 'AsSpec')]
        [System.Management.Automation.SwitchParameter]
        $ReadOnly,

        [Parameter(ParameterSetName = 'AsSpec')]
        [System.Management.Automation.SwitchParameter]
        $IsDefault,

        [Parameter(ParameterSetName = 'WithDatabase')]
        [Parameter(ParameterSetName = 'WithDatabaseFromSpec')]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    $fileGroupObject = $null

    if ($PSCmdlet.ParameterSetName -in @('WithDatabase', 'WithDatabaseFromSpec'))
    {
        if (-not $Database.Parent)
        {
            $errorMessage = $script:localizedData.FileGroup_DatabaseMissingServerObject

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'NSDFG0003',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $Database
                )
            )
        }

        $serverObject = $Database.Parent

        # Determine the file group name based on parameter set
        $fileGroupName = if ($PSCmdlet.ParameterSetName -eq 'WithDatabaseFromSpec')
        {
            $FileGroupSpec.Name
        }
        else
        {
            $Name
        }

        $descriptionMessage = $script:localizedData.FileGroup_Create_ShouldProcessDescription -f $fileGroupName, $Database.Name, $serverObject.InstanceName
        $confirmationMessage = $script:localizedData.FileGroup_Create_ShouldProcessConfirmation -f $fileGroupName
        $captionMessage = $script:localizedData.FileGroup_Create_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            if ($PSCmdlet.ParameterSetName -eq 'WithDatabaseFromSpec')
            {
                # Convert the spec object to SMO FileGroup
                $fileGroupObject = ConvertTo-SqlDscFileGroup -DatabaseObject $Database -FileGroupSpec $FileGroupSpec
            }
            else
            {
                $fileGroupObject = [Microsoft.SqlServer.Management.Smo.FileGroup]::new($Database, $Name)
            }
        }
    }
    else
    {
        if ($AsSpec.IsPresent)
        {
            $fileGroupObject = [DatabaseFileGroupSpec]::new($Name)

            if ($PSBoundParameters.ContainsKey('Files'))
            {
                $fileGroupObject.Files = $Files
            }

            if ($ReadOnly.IsPresent)
            {
                $fileGroupObject.ReadOnly = $true
            }

            if ($IsDefault.IsPresent)
            {
                $fileGroupObject.IsDefault = $true
            }
        }
        else
        {
            $fileGroupObject = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()

            $fileGroupObject.Name = $Name
        }
    }

    return $fileGroupObject
}
