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

    .NOTES
        Author: SqlServerDsc
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

    # Maps the EditionId integer value to each respective edition and edition name.
    $EditionIdMap = @{
        # Reporting Services v16
        ID_2176971986 = @{
            Edition = 'Developer'
            EditionName = 'SQL Server Developer'
        }

        # Power BI Report Server v15
        ID_2017617798 = @{
            Edition = 'Developer'
            EditionName = 'Power BI Report Server - Developer'
        }
        ID_1369084056 = @{
            Edition = 'Evaluation'
            EditionName = 'Power BI Report Server - Evaluation'
        }
    }

    Write-Debug -Message ($script:localizedData.ConvertTo_EditionName_ConvertingEditionId -f $Id)

    $mappingID = 'ID_' + $Id

    if ($EditionIdMap.ContainsKey($mappingID))
    {
        $editionInfo = $EditionIdMap[$mappingID]

        $resultObject = [PSCustomObject]@{
            EditionId = $Id
            Edition = $editionInfo.Edition
            EditionName = $editionInfo.EditionName
        }

        return $resultObject
    }
    else
    {
        Write-Debug -Message ($script:localizedData.ConvertTo_EditionName_UnknownEditionId -f $Id)

        return [PSCustomObject]@{
            EditionId = $Id
            Edition = 'Unknown'
            EditionName = 'Unknown'
        }
    }
}
