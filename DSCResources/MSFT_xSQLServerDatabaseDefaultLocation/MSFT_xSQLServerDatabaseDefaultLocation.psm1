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

    .PARAMETER Type
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
        $Type
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentPath -f $Type, $SQLInstanceName)

    # Connect to the instance
    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Check which default location is being retrieved
    switch ($Type)
    {
        'Data'
        {
            $Path = $sqlServerObject.DefaultFile
        }

        'Log'
        {
            $Path = $sqlServerObject.DefaultLog
        }

        'Backup'
        {
            $Path = $sqlServerObject.BackupDirectory
        }
    }

    return @{
        SqlInstanceName     = $SQLInstanceName
        SqlServer           = $SQLServer
        Type                = $Type
        Path                = $Path
    }
}

<#
    .SYNOPSIS
    This function sets the current path for the default SQL Instance location for the Data, Log, or Backups files.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Type
    The type of database default location to be configured. { Data | Log | Backup }

    .PARAMETER Path
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
        $Type,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter()]
        [System.Boolean]
        $RestartService = $false
    )

    # Make sure the Path exists, needs to be cluster aware as well for this check
    if(-Not (Test-Path $Path))
    {
        throw ($script:localizedData.InvalidPath -f $Path )
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SettingDefaultPath -f $Type)
        $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

        # Check which default location is being updated
        switch ($Type)
        {
            'Data'
            {
                $currentValuePath = $sqlServerObject.DefaultFile
                $sqlServerObject.DefaultFile = $Path
            }

            'Log'
            {
                $currentValuePath = $sqlServerObject.DefaultLog
                $sqlServerObject.DefaultLog = $Path
            }

            'Backup'
            {
                $currentValuePath = $sqlServerObject.BackupDirectory
                $sqlServerObject.BackupDirectory = $Path
            }
        }

        # Wrap the Alter command in a try-catch in case the update doesn't work
        try
        {
            $originalErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Stop'
            $sqlServerObject.Alter()
            Write-Verbose -Message ($script:localizedData.DefaultPathChanged -f $Type, $currentValuePath, $Path)

            if ($RestartService)
            {
                Write-Verbose -Message ($script:localizedData.RestartSqlServer -f $SqlServer, $SQLInstanceName)
                Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.ChangingPathFailed
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
        finally
        {
            $ErrorActionPreference = $originalErrorActionPreference
        }
    }
}

<#
    .SYNOPSIS
    This function tests the current path to the default database location for the Data, Log, or Backups files.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Type
    The type of database default location to be configured. { Data | Log | Backup }

    .PARAMETER Path
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
        $Type,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter()]
        [System.Boolean]
        $RestartService = $false
    )

    Write-Verbose -Message ($script:localizedData.TestingCurrentPath -f $Type)

    $getTargetResourceParameters = @{
        SQLInstanceName     = $SQLInstanceName
        SQLServer           = $SQLServer
        Type                = $Type
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    $isDefaultPathInDesiredState = $true

    if ($getTargetResourceResult.Path -ne $Path)
    {
        Write-Verbose -Message ($script:localizedData.DefaultPathDifference -f $Type, $getTargetResourceResult.Path, $Path)
        $isDefaultPathInDesiredState = $false
    }

    return $isDefaultPathInDesiredState
}

