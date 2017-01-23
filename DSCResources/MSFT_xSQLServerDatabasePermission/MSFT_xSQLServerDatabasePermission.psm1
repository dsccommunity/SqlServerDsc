Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1') -Force

<#
    .SYNOPSIS
    Returns the current permissions for the user in the database

    .PARAMETER Ensure
    This is The Ensure if the permission should be granted (Present) or revoked (Absent)
    Not used in Get-TargetResource

    .PARAMETER Database
    This is the SQL database

    .PARAMETER Name
    This is the name of the SQL login for the permission set

    .PARAMETER PermissionState
    This is the state of permission set. Valid values are 'Grant' or 'Deny'

    .PARAMETER Permissions
    This is a list that represents a SQL Server set of database permissions

    .PARAMETER SQLServer
    This is the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is the SQL instance for the database
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Getting permissions for user '$Name' in database '$Database'"
        $getSqlDatabasePermissionResult = Get-SqlDatabasePermission -SqlServerObject $sqlServerObject `
                                                                    -Name $Name `
                                                                    -Database $Database `
                                                                    -PermissionState $PermissionState
        
        if ($getSqlDatabasePermissionResult)
        {
            $resultOfPermissionCompare = Compare-Object -ReferenceObject $Permissions `
                                                        -DifferenceObject $getSqlDatabasePermissionResult
            if ($null -eq $resultOfPermissionCompare)
            {
                $Ensure = 'Present'
            }
            else
            {
                $Ensure = 'Absent'
            }
        }
        else 
        {
            $Ensure = 'Absent'
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType ConnectSQLError `
                                   -FormatArgs @($SQLServer,$SQLInstanceName) `
                                   -ErrorCategory InvalidOperation
    }
    
    $returnValue = @{
        Ensure          = $Ensure
        Database        = $Database
        Name            = $Name
        PermissionState = $PermissionState
        Permissions     = $getSqlDatabasePermissionResult
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}

<#
    .SYNOPSIS
    Sets the permissions for the user in the database.

    .PARAMETER Ensure
    This is The Ensure if the permission should be granted (Present) or revoked (Absent)

    .PARAMETER Database
    This is the SQL database

    .PARAMETER Name
    This is the name of the SQL login for the permission set

    .PARAMETER PermissionState
    This is the state of permission set. Valid values are 'Grant' or 'Deny'

    .PARAMETER Permissions
    This is a list that represents a SQL Server set of database permissions

    .PARAMETER SQLServer
    This is the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is the SQL instance for the database
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sqlServerObject)
    {
        Write-Verbose -Message "Setting permissions of database '$Database' for login '$Name'"

        if ($Ensure -eq 'Present')
        {
            Add-SqlDatabasePermission -SqlServerObject $sqlServerObject `
                                      -Name $Name `
                                      -Database $Database `
                                      -PermissionState $PermissionState `
                                      -Permissions $Permissions
            
            New-VerboseMessage -Message "$PermissionState - SQL Permissions for $Name, successfullly added in $Database"
        }
        else
        {
            Remove-SqlDatabasePermission -SqlServerObject $sqlServerObject `
                                         -Name $Name `
                                         -Database $Database `
                                         -PermissionState $PermissionState `
                                         -Permissions $Permissions
            
            New-VerboseMessage -Message "$PermissionState - SQL Permissions for $Name, successfullly removed in $Database"
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType ConnectSQLError `
                                   -FormatArgs @($SQLServer,$SQLInstanceName) `
                                   -ErrorCategory InvalidOperation
    }
}

<#
    .SYNOPSIS
    Tests if the permissions is set for the user in the database

    .PARAMETER Ensure
    This is The Ensure if the permission should be granted (Present) or revoked (Absent)

    .PARAMETER Database
    This is the SQL database

    .PARAMETER Name
    This is the name of the SQL login for the permission set

    .PARAMETER PermissionState
    This is the state of permission set. Valid values are 'Grant' or 'Deny'

    .PARAMETER Permissions
    This is a list that represents a SQL Server set of database permissions

    .PARAMETER SQLServer
    This is the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is the SQL instance for the database
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    Write-Verbose -Message "Evaluating permissions for user '$Name' in database '$Database'."

    $getTargetResourceResult = Get-TargetResource @PSBoundParameters

    return Test-SQLDscParameterState -CurrentValues $getTargetResourceResult `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @('Name', 'Ensure', 'PermissionState', 'Permissions')
}

Export-ModuleMember -Function *-TargetResource
