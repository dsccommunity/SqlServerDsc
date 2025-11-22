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

    .PARAMETER Force
        Specifies that the FileGroup should be added without confirmation.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.FileGroup

        FileGroup objects that will be added to the Database.

    .OUTPUTS
        None

        This cmdlet does not generate output by default.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.FileGroup[]

        When the PassThru parameter is specified, returns the FileGroup objects that were added.

    .EXAMPLE
        Add-SqlDscFileGroup -Database $database -FileGroup $fileGroup

        Adds a single FileGroup to the Database.

    .EXAMPLE
        $fileGroups | Add-SqlDscFileGroup -Database $database -PassThru

        Adds multiple FileGroups to the Database via pipeline and returns the FileGroup objects.
#>
function Add-SqlDscFileGroup
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
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
        $PassThru,

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

        foreach ($fileGroupObject in $FileGroup)
        {
            $descriptionMessage = $script:localizedData.AddSqlDscFileGroup_Add_ShouldProcessDescription -f $fileGroupObject.Name, $Database.Name
            $confirmationMessage = $script:localizedData.AddSqlDscFileGroup_Add_ShouldProcessConfirmation -f $fileGroupObject.Name
            $captionMessage = $script:localizedData.AddSqlDscFileGroup_Add_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
            {
                $Database.FileGroups.Add($fileGroupObject)

                if ($PassThru.IsPresent)
                {
                    $fileGroupObject
                }
            }
        }
    }
}
