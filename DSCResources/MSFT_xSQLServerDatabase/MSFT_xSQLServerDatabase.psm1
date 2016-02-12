$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL database

# NOTE: This resource requires WMF5 and PsDscRunAsCredential

function ConnectSQL
{
    param
    (
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )
    
    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
    
    if($SQLInstanceName -eq "MSSQLSERVER")
    {
        $ConnectSQL = $SQLServer
    }
    else
    {
        $ConnectSQL = "$SQLServer\$SQLInstanceName"
    }

    Write-Verbose "Connecting to SQL $ConnectSQL"
    $SQL = New-Object Microsoft.SqlServer.Management.Smo.Server $ConnectSQL

    if($SQL)
    {
        Write-Verbose "Connected to SQL $ConnectSQL"
        $SQL
    }
    else
    {
        Write-Verbose "Failed connecting to SQL $ConnectSQL"
    }
}

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
    if(!$SQL)
    {
        $SQL = ConnectSQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        # Check database exists
        $SQLDatabase = $sql.Databases.Contains($Database)
        $Present = $SQLDatabase
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

    if(!$SQL)
    {
        $SQL = ConnectSQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        if($Ensure -eq "Present")
        {
            Write-Verbose "Ensure = $Ensure so Create Database requested"
            $Db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $SQL,$Database
            $db.Create()
        }
        else
        {
            Write-Verbose "Drop Database $Database requested"
            $sql.Databases[$Database].Drop()
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
    

    if(!$SQL)
    {
        $SQL = ConnectSQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        # Check database exists
        $SQLDatabase = $sql.Databases.Contains($Database)
        $Present = $SQLDatabase
    }
    if($ensure -eq "Present")
    {$result =  $Present}
    if($ensure -eq "Absent")
    {$result = !$present}

    $result
}


Export-ModuleMember -Function *-TargetResource

