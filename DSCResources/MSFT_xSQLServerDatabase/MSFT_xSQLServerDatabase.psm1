Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force
<#
    .SYNOPSIS
    This function gets the sql database.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of database to be created or dropped.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
#>

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Getting SQL Databases'
        # Check database exists
        $sqlDatabase = $sqlServerObject.Databases
        
        if ($sqlDatabase)
        {
            if ($sqlDatabase[$Name])
            {
                Write-Verbose -Message "SQL Database name $Name is present"
                $Ensure = 'Present'
            }
            else
            {
                Write-Verbose -Message "SQL Database name $Name is absent"
                $Ensure = 'Absent'
            }
        }
        else
        {
            Write-Verbose -Message 'Failed getting SQL databases'
            $Ensure = 'Absent'
        }
    }
    
    $returnValue = @{
        Name            = $Name
        Ensure          = $Ensure
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function create or delete a database in the SQL Server instance provided.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of database to be created or dropped.
    
    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        if ($Ensure -eq "Present")
        {
            try
            {
                $newDatabase = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $sqlServerObject,$Name
                if ($newDatabase)
                {
                    Write-Verbose -Message "Adding to SQL the database $Name"
                    $newDatabase.Create()
                    New-VerboseMessage -Message "Created Database $Name"
                }
            }
            catch
            {
                throw New-TerminatingError -ErrorType CreateDatabaseSetError `
                                           -FormatArgs @($SQLServer,$SQLInstanceName,$Name) `
                                           -ErrorCategory InvalidOperation `
                                           -InnerException $_.Exception
            }
        }
        else
        {
            try 
            {
                $getDatabase = $sqlServerObject.Databases[$Name]
                if ($getDatabase)
                {
                    Write-Verbose -Message "Deleting to SQL the database $Name"
                    $getDatabase.Drop()
                    New-VerboseMessage -Message "Dropped Database $Name"
                }
            }
            catch
            {
                throw New-TerminatingError -ErrorType DropDatabaseSetError `
                                           -FormatArgs @($SQLServer,$SQLInstanceName,$Name) `
                                           -ErrorCategory InvalidOperation `
                                           -InnerException $_.Exception
            }
        }
    }
}

<#
    .SYNOPSIS
    This function tests if the sql database is already created or dropped.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of database to be created or dropped.
    
    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )   

    Write-Verbose -Message "Checking if database named $Name is present or absent"

    $currentValues = Get-TargetResource @PSBoundParameters
    $isDatabaseInDesiredState = $true
    
    switch ($Ensure)
    {
        'Absent'
        {
            if ($currentValues.Ensure -ne 'Present')
            {
                New-VerboseMessage -Message "Ensure is set to Absent. The database $Name should be dropped"
                $isDatabaseInDesiredState = $false
            }
        }
        'Present'
        {
            if ($currentValues.Ensure -ne 'Absent')
            {
                New-VerboseMessage -Message "Ensure is set to Present. The database $Name should be created"
                $isDatabaseInDesiredState = $false
            }
        }
    }

    $isDatabaseInDesiredState 
}

Export-ModuleMember -Function *-TargetResource
