$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL database roles

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

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

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
        if(!($SQLDatabase = $SQL.Databases[$Database]))
        {
            throw New-TerminatingError -ErrorType NoDatabase -FormatArgs @($Database,$SQLServer,$SQLInstanceName) -ErrorCategory InvalidResult
        }

        $Name = $SQLDatabase.Owner
    }
    else
    {
        $Name = $null
    }

    $returnValue = @{
        Database = $Database
        Name = $Name
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

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

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
        $SQLDatabase = $SQL.Databases[$Database]
        $SQLDatabase.SetOwner($Name)
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
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

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    $result = ((Get-TargetResource @PSBoundParameters).Name -eq $Name)
    
    $result
}


Export-ModuleMember -Function *-TargetResource