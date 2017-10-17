Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'xSQLServerHelper.psm1') `
    -Force

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_xSQLServerDatabaseDefaultLocation'

<#
    .SYNOPSIS
    Returns the current path to the the desired default location for the Data, Log, or Backup files.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER DefaultLocationType
    The type of database default location to be configured. { Data | Log | Backup }
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

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
        'Data'
        {
            $DefaultLocationPath = $sqlServerObject.DefaultFile
        }

        'Log'
        {
            $DefaultLocationPath = $sqlServerObject.DefaultLog
        }

        'Backup'
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

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER DefaultLocationType
    The type of database default location to be configured. { Data | Log | Backup }

    .PARAMETER DefaultLocationPath
    The path to the default directory to be configured.

    .PARAMETER RestartService
    If set to $true then SQL Server and dependent services will be restarted if a change to the default location
    is made.  The default value is $false.
#>
Function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Data', 'Log', 'Backup')]
        [System.String]
        $DefaultLocationType,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultLocationPath,

        [Parameter()]
        [System.Boolean]
        $RestartService = $false
    )

    Write-Verbose -Message ($script:localizedData.InfoOnSettingDefaultLocationType -f $DefaultLocationType)
    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Check which default location is being updated
    switch ($DefaultLocationType)
    {
        'Data'
        {
            $currentValueDefaultLocationPath = $sqlServerObject.DefaultFile
            $sqlServerObject.DefaultFile = $DefaultLocationPath
        }

        'Log'
        {
            $currentValueDefaultLocationPath = $sqlServerObject.DefaultLog
            $sqlServerObject.DefaultLog = $DefaultLocationPath
        }

        'Backup'
        {
            $currentValueDefaultLocationPath = $sqlServerObject.BackupDirectory
            $sqlServerObject.BackupDirectory = $DefaultLocationPath
        }
    }

    # Wrap the Alter command in a try-catch in case the update doesn't work
    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $sqlServerObject.Alter()
        Write-Verbose -Message ($script:localizedData.DefaultLocationChanged -f $DefaultLocationType, $currentValueDefaultLocationPath, $DefaultLocationPath)

        if ($RestartService)
        {
            Write-Verbose -Message ($script:localizedData.RestartSqlServer -f $SqlServer, $SQLInstanceName)
            Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
        }
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
}

<#
    .SYNOPSIS
    This function tests the current path to the default database location for the Data, Log, or Backups files.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER DefaultLocationType
    The type of database default location to be configured. { Data | Log | Backup }

    .PARAMETER DefaultLocationPath
    The path to the default directory to be configured.

    .PARAMETER RestartService
    If set to $true then SQL Server and dependent services will be restarted if a change to the default location
    is made.  The default value is $false.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Data', 'Log', 'Backup')]
        [System.String]
        $DefaultLocationType,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultLocationPath,

        [Parameter()]
        [System.Boolean]
        $RestartService = $false
    )

    Write-Verbose -Message ($script:localizedData.DefaultLocationTypeTestInfo -f $DefaultLocationType)

    $getTargetResourceParameters = @{
        SQLInstanceName     = $SQLInstanceName
        SQLServer           = $SQLServer
        DefaultLocationType = $DefaultLocationType
        DefaultLocationPath = $DefaultLocationPath
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    $isDefaultLocationInDesiredState = $true

    if ($getTargetResourceResult.DefaultLocationPath -ne $DefaultLocationPath)
    {
        Write-Verbose -Message ($script:localizedData.DefaultLocationTestPathDifference -f $DefaultLocationType, $getTargetResourceResult.DefaultLocationPath, $DefaultLocationPath)
        $isDefaultLocationInDesiredState = $false
    }

    return $isDefaultLocationInDesiredState
}

