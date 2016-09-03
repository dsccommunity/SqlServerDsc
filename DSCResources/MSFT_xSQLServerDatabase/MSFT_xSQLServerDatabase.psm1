$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL database

# NOTE: This resource requires WMF5 and PsDscRunAsCredential

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

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
        $sqlDatabase = $sql.Databases.Contains($Database)
        if ($sqlDatabase)
        {
            Write-Verbose "SQL Database $Database is present"
            $Ensure = 'Present'
        }
        else
        {
            Write-Verbose "SQL Database $Database is Absent"
            $Ensure = 'Absent'
        }
    }
    
    $returnValue = @{
        Database = $Database
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
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

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
            $db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $sql,$Database
            $db.Create()
            New-VerboseMessage -Message "Created Database $Database"
        }
        else
        {
            $sql.Databases[$Database].Drop()
            New-VerboseMessage -Message "Dropped Database $Database"
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
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

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

