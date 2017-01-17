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
        $RecoveryModel,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        Write-Verbose -Message "Getting RecoveryModel of SQL database '$Name'"
        $sqlDatabase = $sql.Databases
        
        if ($sqlDatabase)
        {
            if ($sqlDatabase[$Name])
            {
                $getSqlDatabaseRecoveryModel = Get-SqlDatabaseRecoveryModel -SqlServerObject $sql -DatabaseName $Name
                New-VerboseMessage -Message "RecoveryModel of SQL Database name $Name is $getSqlDatabaseRecoveryModel"
            }
            else
            {
                New-VerboseMessage -Message "SQL Database name $Name does not exist"
                $null = $getSqlDatabaseRecoveryModel
            }
        }
        else
        {
            New-WarningMessage -Message 'Failed getting SQL databases'
            $null = $getSqlDatabaseRecoveryModel
        }
    }
    
    $returnValue = @{
        Name            = $Name
        RecoveryModel   = $getSqlDatabaseRecoveryModel
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
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
        $RecoveryModel,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
 
     $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sql)
    {
        $sqlDatabase = $Sql.Databases[$Name]
        if ($sqlDatabase)
        {
            Write-Verbose -Message "Setting database '$Name' with RecoveryModel '$RecoveryModel'"
            Set-SqlDatabaseRecoveryModel -SqlServerObject $sql -DatabaseName $Name -RecoveryModel $RecoveryModel
        }
        else
        {
            New-VerboseMessage -Message "SQL Database name $Name does not exist"
        }
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
        $RecoveryModel,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message "Testing RecoveryModel of database '$Name'"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SQLDscParameterState -CurrentValues $CurrentValues `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @('Name','RecoveryModel')
}

Export-ModuleMember -Function *-TargetResource
