Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
              -ChildPath 'SqlServerDscHelper.psm1') `
              -Force

$logMessage = "RAISERROR('PowerShell Desired State Configuration Updated database {0} to recovery model {1} because it matched pattern {2}',1,1,1) with log"

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER ServerName
    This is a the SQL Server for the database

    .PARAMETER InstanceName
    This is a the SQL instance for the database
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Full', 'Simple', 'BulkLogged')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RecoveryModel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        $databases = $sqlServerObject.Databases.Where{$_.Name -like "$Name"}

        if(!$databases)
        {
            throw New-TerminatingError -ErrorType NoDatabase `
                    -FormatArgs @($Name, $ServerName, $InstanceName) `
                    -ErrorCategory InvalidResult
        }

        $sqlDatabaseRecoveryModel = ""
        foreach($sqlDatabaseObject in $databases)
        {
            if($sqlDatabaseObject.Name -eq "tempdb")
            {
                New-VerboseMessage -Message "Skipping 'tempdb', recovery model for this DB cannot be changed"

                Continue
            }

            New-VerboseMessage -Message "The current recovery model used by database $($sqlDatabaseObject.Name) is '$($sqlDatabaseObject.RecoveryModel)'"

            if($sqlDatabaseRecoveryModel -notlike "*$($sqlDatabaseObject.RecoveryModel)*")
            {
                $sqlDatabaseRecoveryModel += ",$($sqlDatabaseObject.RecoveryModel)"
            }
        }
    }

    if([string]::IsNullOrWhiteSpace($sqlDatabaseRecoveryModel) -eq $false)
    {
        $sqlDatabaseRecoveryModel = $sqlDatabaseRecoveryModel.SubString(1, $sqlDatabaseRecoveryModel.Length - 1)
    }

    $returnValue = @{
        Name          = $Name
        RecoveryModel = $sqlDatabaseRecoveryModel
        ServerName    = $ServerName
        InstanceName  = $InstanceName
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

    .PARAMETER ServerName
    This is a the SQL Server for the database

    .PARAMETER InstanceName
    This is a the SQL instance for the database
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Full', 'Simple', 'BulkLogged')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RecoveryModel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        $databases = $sqlServerObject.Databases.Where{$_.Name -like "$Name"}

        if(!$databases)
        {
            throw New-TerminatingError -ErrorType NoDatabase `
                    -FormatArgs @($Name, $ServerName, $InstanceName) `
                    -ErrorCategory InvalidResult
        }

        foreach($sqlDatabaseObject in $databases)
        {
            if($sqlDatabaseObject.Name -eq "tempdb")
            {
                New-VerboseMessage -Message "Skipping 'tempdb', recovery model because this DB cannot be changed"

                Continue
            }

            Write-Verbose -Message "Setting RecoveryModel of SQL database '$($sqlDatabaseObject.Name)'"

            if ($sqlDatabaseObject.RecoveryModel -ne $RecoveryModel)
            {
                $sqlDatabaseObject.RecoveryModel = $RecoveryModel
                $sqlDatabaseObject.Alter()
                New-VerboseMessage -Message "The recovery model for the database $($sqlDatabaseObject.Name) is changed to '$RecoveryModel'."

                try
                {
                    $null = Invoke-Query -SQLServer $ServerName `
                                         -SQLInstanceName $InstanceName `
                                         -Database $sqlDatabaseObject.Name `
                                         -Query $($logMessage -f $sqlDatabaseObject.Name, $RecoveryModel, $Name) `
                                         -ErrorAction stop
                }
                catch
                {
                    Write-Warning "Failed to log DSC database recovery model to SQL and event logs."
                }
            }
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

    .PARAMETER ServerName
    This is a the SQL Server for the database

    .PARAMETER InstanceName
    This is a the SQL instance for the database
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Full', 'Simple', 'BulkLogged')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RecoveryModel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    Write-Verbose -Message "Testing RecoveryModel of database '$Name'"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SQLDscParameterState -CurrentValues $currentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('Name', 'RecoveryModel')
}

Export-ModuleMember -Function *-TargetResource
