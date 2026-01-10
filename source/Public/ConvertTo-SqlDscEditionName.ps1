<#
    .SYNOPSIS
        Converts a SQL Server Reporting Services or Power BI Report Server edition
        ID to an edition name.

    .DESCRIPTION
        Converts a SQL Server Reporting Services or Power BI Report Server edition
        ID. The command returns a PSCustomObject containing the EditionId, Edition,
        and EditionName based on a predefined mapping table.

    .PARAMETER Id
        Specifies the edition ID that should be converted.

    .EXAMPLE
        ConvertTo-SqlDscEditionName -Id 2176971986

        Returns information about the edition ID 2176971986.

    .EXAMPLE
        ConvertTo-SqlDscEditionName -Id 2017617798

        Returns information about the edition ID 2017617798.

    .INPUTS
        None.

    .OUTPUTS
        `System.Management.Automation.PSCustomObject`

        Returns a custom object with EditionId, Edition, and EditionName properties.

#>
function ConvertTo-SqlDscEditionName
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Id
    )

    Write-Debug -Message ($script:localizedData.ConvertTo_EditionName_ConvertingEditionId -f $Id)

    $resultObject = [PSCustomObject] @{
        EditionId = $Id
        Edition = ''
        EditionName = ''
    }

    switch ($Id)
    {
        2176971986
        {
            $resultObject.Edition = 'Developer'
            $resultObject.EditionName = 'SQL Server Developer'
        }

        2017617798
        {
            $resultObject.Edition = 'Developer'
            $resultObject.EditionName = 'Power BI Report Server - Developer'
        }

        1369084056
        {
            $resultObject.Edition = 'Evaluation'
            $resultObject.EditionName = 'Power BI Report Server - Evaluation'
        }

        default
        {
            Write-Debug -Message ($script:localizedData.ConvertTo_EditionName_UnknownEditionId -f $Id)

            $resultObject.Edition = 'Unknown'
            $resultObject.EditionName = 'Unknown'
        }
    }

    return $resultObject
}
