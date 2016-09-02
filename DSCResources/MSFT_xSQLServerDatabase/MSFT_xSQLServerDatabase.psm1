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
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,
        [System.String]
        $SQLServer = $env:COMPUTERNAME,
        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )
    if(!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($sql)
    {
        # Check database exists
        $sqlDatabase = $sql.Databases.Contains($Database)
        $Present = $sqlDatabase
    }
        $returnValue = @{
        Database = $Database
        Ensure = $Present
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
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    if(!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($sql)
    {
        if($Ensure -eq "Present")
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
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )
    

    if(!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($sql)
    {
        # Check database exists
        $sqlDatabase = $sql.Databases.Contains($Database)
        $Present = $sqlDatabase
    }
    if($ensure -eq "Present")
    {$result =  $Present}
    if($ensure -eq "Absent")
    {$result = !$present}

    $result
}

Export-ModuleMember -Function *-TargetResource

