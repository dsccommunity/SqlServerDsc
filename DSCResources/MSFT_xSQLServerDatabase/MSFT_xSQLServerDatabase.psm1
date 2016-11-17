function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    if (!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if ($sql)
    {
        Write-Verbose 'Getting SQL Databases'
        # Check database exists
        $sqlDatabase = $sql.Databases
        
        if ($sqlDatabase)
        {
            if ($sqlDatabase[$Name])
            {
                Write-Verbose "SQL Database name $Name is present"
                $Ensure = 'Present'
            }
            else
            {
                Write-Verbose "SQL Database name $Name is absent"
                $Ensure = 'Absent'
            }
        }
        else
        {
            Write-Verbose 'Failed getting SQL databases'
            $Ensure = 'Absent'
        }
    }
    
    $returnValue = @{
        Name = $Name
        Ensure = $Ensure
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    if (!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if ($sql)
    {
        if ($Ensure -eq "Present")
        {
            New-SqlDatabase -SQL $sql -Name $Name
            New-VerboseMessage -Message "Created Database $Name"
        }
        else
        {
            Remove-SqlDatabase -SQL $sql -Name $Name
            New-VerboseMessage -Message "Dropped Database $Name"
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )    

    $sqlDatabase = Get-TargetResource @PSBoundParameters

    $result = ($sqlDatabase.Ensure -eq $Ensure)
    
    $result
}

Export-ModuleMember -Function *-TargetResource

