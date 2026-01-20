<#
    .SYNOPSIS
        Converts the combination of server name and instance name to
        the correct server instance name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance on the host.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server.
#>
function ConvertTo-ServerInstanceName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $serverInstance = $ServerName
    }
    else
    {
        $serverInstance = '{0}\{1}' -f $ServerName, $InstanceName
    }

    return $serverInstance
}
