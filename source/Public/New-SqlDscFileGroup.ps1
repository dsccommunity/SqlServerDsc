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
        $fileGroup = $database | New-SqlDscFileGroup -Name 'PRIMARY'

        Creates a new PRIMARY FileGroup using pipeline input.

    .EXAMPLE
        $fileGroup = New-SqlDscFileGroup -Name 'MyFileGroup'
        # Later add to database
        Add-SqlDscFileGroup -Database $database -FileGroup $fileGroup

        Creates a standalone FileGroup that can be added to a Database later.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.FileGroup]`
#>
function New-SqlDscFileGroup
{
    [OutputType([Microsoft.SqlServer.Management.Smo.FileGroup])]
    [CmdletBinding(DefaultParameterSetName = 'Standalone', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'WithDatabase')]
        [Microsoft.SqlServer.Management.Smo.Database]
        $Database,

        [Parameter(Mandatory = $true, ParameterSetName = 'WithDatabase')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Standalone')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'WithDatabase')]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $fileGroupObject = $null

        if ($PSCmdlet.ParameterSetName -eq 'WithDatabase')
        {
            $serverObject = $Database.Parent

            $descriptionMessage = $script:localizedData.FileGroup_Create_ShouldProcessDescription -f $Name, $Database.Name, $serverObject.InstanceName
            $confirmationMessage = $script:localizedData.FileGroup_Create_ShouldProcessConfirmation -f $Name
            $captionMessage = $script:localizedData.FileGroup_Create_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
            {
                $fileGroupObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList $Database, $Name
            }
        }
        else
        {
            $fileGroupObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup'

            $fileGroupObject.Name = $Name
        }

        return $fileGroupObject
    }
}
