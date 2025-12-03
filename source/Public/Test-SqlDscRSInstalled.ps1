<#
    .SYNOPSIS
        Tests if a SQL Server Reporting Services or Power BI Report Server instance
        is installed.

    .DESCRIPTION
        Tests if a SQL Server Reporting Services or Power BI Report Server instance
        is installed on the local server. The command returns $true if the specified
        instance exists and $false if it does not.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server Reporting Services or Power BI Report Server
        instance to check for. This parameter is required.

    .EXAMPLE
        Test-SqlDscRSInstalled -InstanceName 'SSRS'

        Tests if a SQL Server Reporting Services instance named 'SSRS' is installed.
        Returns $true if the instance exists and $false if it does not.

    .EXAMPLE
        Test-SqlDscRSInstalled -InstanceName 'PBIRS'

        Tests if a Power BI Report Server instance named 'PBIRS' is installed.
        Returns $true if the instance exists and $false if it does not.

    
    .INPUTS
        None.

.OUTPUTS
        System.Boolean

        Returns $true if the specified instance exists and $false if it does not.
#>
function Test-SqlDscRSInstalled
{
    # cSpell: ignore PBIRS
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message ($script:localizedData.Test_SqlDscRSInstalled_Checking -f $InstanceName)

    $reportingServices = Get-SqlDscRSSetupConfiguration -InstanceName $InstanceName -ErrorAction 'SilentlyContinue'

    if ($reportingServices)
    {
        Write-Verbose -Message ($script:localizedData.Test_SqlDscRSInstalled_Found -f $InstanceName)

        return $true
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.Test_SqlDscRSInstalled_NotFound -f $InstanceName)

        return $false
    }
}
