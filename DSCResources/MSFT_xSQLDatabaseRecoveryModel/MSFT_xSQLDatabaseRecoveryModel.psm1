Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1') -Force

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Full','Simple','BulkLogged')]
        [System.String]
        $RecoveryModel = 'Full',

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName
    )
    
    $SqlServerInstance = $SqlServerInstance.Replace('\MSSQLSERVER','')  
    New-VerboseMessage -Message "Checking Database $DatabaseName recovery mode for $RecoveryModel"

    $db = Get-SqlDatabase -ServerInstance $SqlServerInstance -Name $DatabaseName
    $value = ($db.RecoveryModel -eq $RecoveryModel)
    New-VerboseMessage -Message "Database $DatabaseName recovery mode comparison $value."
    
    $returnValue = @{
        RecoveryModel = $db.RecoveryModel
        SqlServerInstance = $SqlServerInstance
        DatabaseName = $DatabaseName
    }
    
    $returnValue
}

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Full','Simple','BulkLogged')]
        [System.String]
        $RecoveryModel = 'Full',

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName
    )
 
    $SqlServerInstance = $SqlServerInstance.Replace('\MSSQLSERVER','')  
    $db = Get-SqlDatabase -ServerInstance $SqlServerInstance -Name $DatabaseName    
    New-VerboseMessage -Message "Database $DatabaseName recovery mode is $db.RecoveryModel."
    
    if($db.RecoveryModel -ne $RecoveryModel)
    {
        $db.RecoveryModel = $RecoveryModel;
        $db.Alter();
        New-VerboseMessage -Message "DB $DatabaseName recovery mode is changed to $RecoveryModel."
    }
    
    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }    
}

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Full','Simple','BulkLogged')]
        [System.String]
        $RecoveryModel = 'Full',

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName
    )
     
    $SqlServerInstance = $SqlServerInstance.Replace('\MSSQLSERVER','')  
    $result = ((Get-TargetResource @PSBoundParameters).RecoveryModel -eq $RecoveryModel)
    
    $result
}

Export-ModuleMember -Function *-TargetResource
