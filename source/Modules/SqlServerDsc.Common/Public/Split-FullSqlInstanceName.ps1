<#
    .SYNOPSIS
        Takes a SQL Instance name in the format of 'Server\Instance' and splits
        it into a hash table prepared to be passed into Connect-SQL.

    .PARAMETER FullSqlInstanceName
        The full SQL instance name string to be split.

    .OUTPUTS
        Hash table with the properties ServerName and InstanceName.
#>
function Split-FullSqlInstanceName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $FullSqlInstanceName
    )

    $sqlServer, $sqlInstanceName = $FullSqlInstanceName.Split('\')

    if ( [System.String]::IsNullOrEmpty($sqlInstanceName) )
    {
        $sqlInstanceName = 'MSSQLSERVER'
    }

    return @{
        ServerName   = $sqlServer
        InstanceName = $sqlInstanceName
    }
}
