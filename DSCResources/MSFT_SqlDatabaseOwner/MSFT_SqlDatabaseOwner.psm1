$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SqlServerDsc.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SqlServerDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlDatabaseOwner'

<#
    .SYNOPSIS
    This function gets the owner of the desired sql database.

    .PARAMETER Database
    The name of database to be configured.

    .PARAMETER Name
    The name of the login that will become a owner of the desired sql database.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.GetCurrentDatabaseOwner -f $Database, $InstanceName
    )

    try
    {
        $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
        if ($sqlServerObject)
        {
            # Check database exists
            if ( -not ($sqlDatabaseObject = $sqlServerObject.Databases[$Database]) )
            {
                $errorMessage = $script:localizedData.DatabaseNotFound -f $Database
                New-ObjectNotFoundException -Message $errorMessage
            }

            $sqlDatabaseOwner = $sqlDatabaseObject.Owner

            Write-Verbose -Message (
                $script:localizedData.CurrentDatabaseOwner -f $Database, $sqlDatabaseOwner
            )
        }
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToGetOwnerDatabase -f $Database
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    $returnValue = @{
        Database     = $Database
        Name         = $sqlDatabaseOwner
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function sets the owner of the desired sql database.

    .PARAMETER Database
    The name of database to be configured.

    .PARAMETER Name
    The name of the login that will become a owner of the desired sql database.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    if ($sqlServerObject)
    {
        # Check database exists
        if ( -not ($sqlDatabaseObject = $sqlServerObject.Databases[$Database]) )
        {
            $errorMessage = $script:localizedData.DatabaseNotFound -f $Database
            New-ObjectNotFoundException -Message $errorMessage
        }

        # Check login exists
        if ( -not ($sqlServerObject.Logins[$Name]) )
        {
            $errorMessage = $script:localizedData.LoginNotFound -f $Name
            New-ObjectNotFoundException -Message $errorMessage
        }

        Write-Verbose -Message (
            $script:localizedData.SetDatabaseOwner -f $Database, $InstanceName
        )

        try
        {
            $sqlDatabaseObject.SetOwner($Name)

            Write-Verbose -Message (
                $script:localizedData.NewOwner -f $Name
            )
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedToSetOwnerDatabase -f $Database
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }
}

<#
    .SYNOPSIS
    This function tests the owner of the desired sql database.

    .PARAMETER Database
    The name of database to be configured.

    .PARAMETER Name
    The name of the login that will become a owner of the desired sql database.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration -f $Database, $InstanceName
    )

    $currentValues = Get-TargetResource @PSBoundParameters
    return Test-DscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('Name', 'Database')
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]

    $InformationPreference = 'Continue'

    $sqlDatabaseObject = Connect-SQL
    $databases = $sqlDatabaseObject.Databases
    $sb = [System.Text.StringBuilder]::new()

    $valueInstanceName = $sqlDatabaseObject.InstanceName
    if ([System.String]::IsNullOrEmpty($valueInstanceName))
    {
        $valueInstanceName = 'MSSQLSERVER'
    }

    $i = 1
    foreach ($database in $databases)
    {
        Write-Information "    [$i/$($databases.Count)] Extracting Owners for Database {$($database.Name)}"
        $params = @{
            Database     = $database.Name
            Name         = '*'
            InstanceName = $valueInstanceName
        }
        $results = Get-TargetResource @params
        [void]$sb.AppendLine('        SqlDatabaseOwner ' + (New-GUID).ToString())
        [void]$sb.AppendLine('        {')
        $dscBlock = Get-DSCBlock -Params $results -ModulePath $PSScriptRoot
        [void]$sb.Append($dscBlock)
        [void]$sb.AppendLine('        }')
        $i++
    }

    return $sb.ToString()
}

Export-ModuleMember -Function *-TargetResource
