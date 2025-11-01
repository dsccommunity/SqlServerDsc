<#
    .SYNOPSIS
        Adds one or more FileGroup objects to a Database object.

    .DESCRIPTION
        This command adds one or more FileGroup objects to a Database object's FileGroups
        collection. This is useful when you have created FileGroup objects using
        New-SqlDscFileGroup and want to associate them with a Database.

    .PARAMETER Database
        Specifies the Database object to which the FileGroups will be added.

    .PARAMETER FileGroup
        Specifies one or more FileGroup objects to add to the Database. This parameter
        accepts pipeline input.

    .PARAMETER PassThru
        Returns the FileGroup objects that were added to the Database.

    .OUTPUTS
        None, or [Microsoft.SqlServer.Management.Smo.FileGroup[]] if PassThru is specified.

    .EXAMPLE
        Add-SqlDscFileGroup -Database $database -FileGroup $fileGroup

        Adds a single FileGroup to the Database.

    .EXAMPLE
        $fileGroups | Add-SqlDscFileGroup -Database $database -PassThru

        Adds multiple FileGroups to the Database via pipeline and returns the FileGroup objects.
#>
function Add-SqlDscFileGroup
{
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.FileGroup[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $Database,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.FileGroup[]]
        $FileGroup,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    process
    {
        foreach ($fileGroupObject in $FileGroup)
        {
            $Database.FileGroups.Add($fileGroupObject)

            if ($PassThru.IsPresent)
            {
                $fileGroupObject
            }
        }
    }
}
