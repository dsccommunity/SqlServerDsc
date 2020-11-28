$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets the actual sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.GetConfiguration -f $Name
    )

    $sqlManagement = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' -ArgumentList $ServerName

    $serviceNames = Get-SqlServiceName -InstanceName $InstanceName

    if ($sqlManagement)
    {
        $wmiService = $sqlManagement.Services |
            Where-Object -FilterScript { $PSItem.Name -eq $serviceNames.SQLEngineName }

        if ($wmiService)
        {
            $actualTraceFlags = $wmiService.StartupParameters.Split(';') |
                Where-Object -FilterScript { $PSItem -like '-T*' } |
                ForEach-Object {
                    $PSItem.TrimStart('-T')
                }
        }
        else
        {
            $errorMessage = $script:localizedData.NotConnectedToWMI -f $InstanceName, $ServerName
            New-InvalidOperationException -Message $errorMessage
        }
    }
    else
    {
        $errorMessage = $script:localizedData.NotConnectedToComputerManagement -f $ServerName
        New-InvalidOperationException -Message $errorMessage
    }

    return @{
        ServerName          = $ServerName
        InstanceName        = $InstanceName
        ActualTraceFlags    = $actualTraceFlags
        TraceFlags          = $null
        TraceFlagsToInclude = $null
        TraceFlagsToExclude = $null
    }
}

<#
    .SYNOPSIS
        This function sets the sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER TraceFlags
        The TraceFlags the SQL server engine startup parameters should contain.
        This parameter can not be used together with TraceFlagsToInclude and TraceFlagsToExclude.

    .PARAMETER TraceFlagsToInclude
        The TraceFlags the SQL server engine startup parameters should include.
        This parameter can not be used together with TraceFlags.

    .PARAMETER TraceFlagsToExclude
        The TraceFlags the SQL server engine startup parameters should exclude.
        This parameter can not be used together with TraceFlags.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.UInt32[]]
        $TraceFlags,

        [Parameter()]
        [System.UInt32[]]
        $TraceFlagsToInclude,

        [Parameter()]
        [System.UInt32[]]
        $TraceFlagsToExclude,

        [Parameter()]
        [System.Boolean]
        $RestartInstance = $false
    )

    Write-Verbose -Message (
        $script:localizedData.SetConfiguration -f $Name, $RetryCount, ($RetryIntervalSec * $RetryCount)
    )

    $assertBoundParameterParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'TraceFlags'
        )
        MutuallyExclusiveList2 = @(
            'TraceFlagsToInclude', 'TraceFlagsToExclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $wishTraceFlags = [System.Collections.ArrayList]::new()

    if ($PSBoundParameters.ContainsKey('TraceFlags'))
    {
        $wishTraceFlags.AddRange($TraceFlags)
    }
    else
    {
        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

        $wishTraceFlags.AddRange($getTargetResourceResult.ActualTraceFlags)

        if ($PSBoundParameters.ContainsKey('TraceFlagsToInclude'))
        {
            foreach ($traceFlagToInclude in $TraceFlagsToInclude)
            {
                if ($getTargetResourceResult.ActualTraceFlags -notcontains $traceFlagToInclude)
                {
                    $wishTraceFlags.Add($traceFlagToInclude)
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('TraceFlagsToExclude'))
        {
            foreach ($traceFlagToExclude in $TraceFlagsToExclude)
            {
                if ($getTargetResourceResult.ActualTraceFlags -contains $traceFlagToExclude)
                {
                    $wishTraceFlags.Remove([string]$traceFlagToExclude)
                }
            }
        }
    }

    # Add '-T' dash to flag
    $traceFlagList = $wishTraceFlags |
        ForEach-Object {
            "-T$PSItem"
        }

    if ($traceFlagList -eq '')
    {
        $traceFlagList = $null
    }

    $serviceNames = Get-SqlServiceName -InstanceName $InstanceName

    $sqlManagement = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' -ArgumentList $ServerName

    if ($sqlManagement)
    {
        $wmiService = $sqlManagement.Services |
            Where-Object -FilterScript { $PSItem.Name -eq $serviceNames.SQLEngineName }

        if ($wmiService)
        {
            # Extract startup parameters
            [System.Collections.ArrayList] $parameterList = $wmiService.StartupParameters.Split(';')

            # Removing flags that are not wanted
            foreach ($parameter in $wmiService.StartupParameters.Split(';'))
            {
                if ($parameter -like '-T*' -and $parameter -notin $traceFlagList)
                {
                    $parameterList.Remove($parameter) | Out-Null
                }
            }

            # Add missing flags
            foreach ($flag in $traceFlagList)
            {
                if ($flag -notin $parameterList)
                {
                    $parameterList.Add($flag) | Out-Null
                }
            }

            # Merge flags back into startup parameters
            $wmiService.StartupParameters = $parameterList -join ';'
            $wmiService.Alter()

            if ($PSBoundParameters.ContainsKey('RestartInstance'))
            {
                if ($RestartInstance -eq $true)
                {
                    # Get the current status of the sql agent. After restart of the instance, the status of the agent should be the same.
                    $agentServiceStatus = (
                        $sqlManagement.Services |
                            Where-Object -FilterScript { $PSItem.Name -eq $serviceNames.SQLAgentName }
                    ).ServiceState

                    $wmiService.Stop()

                    Start-Sleep -Seconds 10

                    $wmiService.Start()

                    if ($agentServiceStatus -ne 'Stopped')
                    {
                        (
                            $sqlManagement.Services |
                                Where-Object -FilterScript { $PSItem.Name -eq $serviceNames.SQLAgentName }
                        ).Start()
                    }
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        This function tests the sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER TraceFlags
        The TraceFlags the SQL server engine startup parameters should contain.
        This parameter can not be used together with TraceFlagsToInclude and TraceFlagsToExclude.

    .PARAMETER TraceFlagsToInclude
        The TraceFlags the SQL server engine startup parameters should include.
        This parameter can not be used together with TraceFlags.

    .PARAMETER TraceFlagsToExclude
        The TraceFlags the SQL server engine startup parameters should exclude.
        This parameter can not be used together with TraceFlags.
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
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Uint32[]]
        $TraceFlags,

        [Parameter()]
        [System.Uint32[]]
        $TraceFlagsToInclude,

        [Parameter()]
        [System.Uint32[]]
        $TraceFlagsToExclude,

        [Parameter()]
        [System.Boolean]
        $RestartInstance = $false
    )

    Write-Verbose -Message (
        $script:localizedData.TestConfiguration -f $Name
    )

    $assertBoundParameterParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'TraceFlags'
        )
        MutuallyExclusiveList2 = @(
            'TraceFlagsToInclude', 'TraceFlagsToExclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $isInDesiredState = $true

    if ($PSBoundParameters.ContainsKey('TraceFlags'))
    {
        if ($TraceFlags.Length -eq 0)
        {
            if ($getTargetResourceResult.ActualTraceFlags.Count -gt 0)
            {
                $isInDesiredState = $false
            }
        }
        else
        {
            #Compare $TraceFlags to ActualTraceFlags to see if they contain the same values.
            $nullIfTheSame = Compare-Object -ReferenceObject $getTargetResourceResult.ActualTraceFlags -DifferenceObject $TraceFlags
            if ( $null -ne $nullIfTheSame)
            {
                Write-Verbose -Message (
                    $script:localizedData.DesiredTraceFlagNotPresent `
                        -f $ServerRoleName
                )

                $isInDesiredState = $false
            }
        }
    }
    else
    {
        if ($PSBoundParameters.ContainsKey('TraceFlagsToInclude'))
        {
            foreach ($traceFlagToInclude in $TraceFlagsToInclude)
            {
                if ($getTargetResourceResult.ActualTraceFlags -notcontains $traceFlagToInclude)
                {
                    Write-Verbose -Message (
                        $script:localizedData.TraceFlagNotPresent `
                            -f $traceFlagToInclude
                    )

                    $isInDesiredState = $false
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('TraceFlagsToExclude'))
        {
            foreach ($traceFlagToExclude in $TraceFlagsToExclude)
            {
                if ($getTargetResourceResult.ActualTraceFlags -contains $traceFlagToExclude)
                {
                    Write-Verbose -Message (
                        $script:localizedData.TraceFlagPresent `
                            -f $traceFlagToExclude
                    )

                    $isInDesiredState = $false
                }
            }
        }
    }

    return $isInDesiredState
}

<#
    .SYNOPSIS
        This function returns the serviceNames of an sql instance.

    .PARAMETER InstanceName
        The name of the SQL instance of whoose service names are beeing returned.
#>
function Get-SqlServiceName
{
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLServer'
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $sqlEngineName = 'MSSQLSERVER'
        $sqlAgentName = 'SQLSERVERAGENT'
    }
    else
    {
        $sqlEngineName = 'MSSQL${0}' -f $InstanceName
        $sqlAgentName = 'SQLAgent${0}' -f $InstanceName
    }

    return @{
        SQLEngineName = $sqlEngineName
        SQLAgentName  = $sqlAgentName
    }
}
