Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'xSQLServerHelper.psm1') `
    -Force

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_xSQLServerDatabaseDefaultLocation'

<#
    .SYNOPSIS
        Returns the current path to the the desired default location for the Data, Log, or Backup files.

    .PARAMETER SQLInstanceName
        The name of the SQL instance to be configured.

    .PARAMETER SQLServer
        The host name of the SQL Server to be configured.

    .PARAMETER DefaultLocationType
        The default location type to set. Valid values are 'Data','Log', and 'Backup'.
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Data', 'Log', 'Backup')]
        [System.String]
        $DefaultLocationType,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultLocationPath
    )

    Write-Verbose -Message ($script:localizedData.DefaultLocationTypeInformation -f $DefaultLocationType, $SQLInstanceName)

    # Connect to the instance
    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Check which default location is being retrieved
    switch ($DefaultLocationType)
    {
        "Data"
        {
            $DefaultLocationPath = $sqlServerObject.DefaultFile
        }

        "Log"
        {
            $DefaultLocationPath = $sqlServerObject.DefaultLog
        }

        "Backup"
        {
            $DefaultLocationPath = $sqlServerObject.BackupDirectory
        }
    }

    return @{
        SqlInstanceName     = $SQLInstanceName
        SqlServer           = $SQLServer
        DefaultLocationType = $DefaultLocationType
        DefaultLocationPath = $DefaultLocationPath
    }
}

<#
    .SYNOPSIS
    This function sets the current path for the default SQL Instance location for the Data, Log, or Backups files.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER DefaultLocationType
    The default location type. Valid states are Data, Log, or Backups.

    .PARAMETER DefaultLocationPath
    The path for the default location of the Data, Log, or Backups.

    .PARAMETER RestartService
    If set to $true then SQL Server and dependent services will be restarted if a change to the default location
    is made.  The defaul value is $false.

#>
Function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Data', 'Log', 'Backup')]
        [System.String]
        $DefaultLocationType,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultLocationPath,

        [Parameter()]
        [System.boolean]
        $RestartService = $false
    )

    Write-Verbose -Message ($script:localizedData.InfoOnSettingDefaultLocationType -f $DefaultLocationType)

    $isRestartNeeded = $false

    Write-Verbose -Message ($script:localizedData.VerifyChangeDefaultLocationType -f $DefaultLocationType)

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Check which default location is being updated
    Switch ($DefaultLocationType)
    {
        "Data"
        {
            $sqlServerObject.DefaultFile = $DefaultLocationPath
        }

        "Log"
        {
            $sqlServerObject.DefaultLog = $DefaultLocationPath
        }

        "Backup"
        {
            $sqlServerObject.BackupDirectory = $DefaultLocationPath
        }

    }

    # Wrap the Alter command in a try-catch in case the update doesn't work
    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $sqlServerObject.Alter()
        Write-Verbose -Message ($script:localizedData.DefaultLocationChanged -f $DefaultLocationType, $getDefaultLocationPath, $DefaultLocationPath)
        $isRestartNeeded = $true
    }
    catch
    {
        $errorMessage = $script:localizedData.DefaultLocationAlterFailed
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }

    if ($RestartService -and $isRestartNeeded)
    {
        Write-Verbose -Message ($script:localizedData.RestartSQLServer -f $SqlServer, $SQLInstanceName)
        Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

}

<#
    .SYNOPSIS
    This function tests the current path to the  default database location for the Data, Log, or Backups files.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER DefaultLocationType
    The default location type. Valid states are Data, Log, or Backups.

    .PARAMETER DefaultLocationPath
    The path for the default location of the Data, Log, or Backups.

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
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Data', 'Log', 'Backup')]
        [System.String]
        $DefaultLocationType,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultLocationPath,

        [Parameter()]
        [System.boolean]
        $RestartService = $false
    )

    Write-Verbose -Message ($script:localizedData.DefaultLocationTypeTestInfo -f $DefaultLocationType)

    $parameters = @{
        SQLInstanceName     = $SQLInstanceName
        SQLServer           = $SQLServer
        DefaultLocationType = $DefaultLocationType
        DefaultLocationPath = $DefaultLocationPath
    }

    $currentValues = Get-TargetResource @parameters
    $getDefaultLocationPath = $currentValues.DefaultLocationPath
    $isMDefaultLocationInDesiredState = $true

    if ($getDefaultLocationPath -ne $DefaultLocationPath)
    {
        New-VerboseMessage -Message ($script:localizedData.DefaultLocationTestPathDifference -f $DefaultLocationType, $getDefaultLocationPath, $DefaultLocationPath)
        $isMDefaultLocationInDesiredState = $false
    }

    return $isMDefaultLocationInDesiredState
}

