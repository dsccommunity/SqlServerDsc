$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets the actual sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

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
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    # Import SqlServer module.
    Import-SqlDscPreferredModule

    Write-Verbose -Message (
        $script:localizedData.GetConfiguration -f $InstanceName
    )

    $sqlManagement = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' -ArgumentList $ServerName

    $serviceNames = Get-SqlServiceName -InstanceName $InstanceName

    if ($sqlManagement)
    {
        $databaseEngineService = $sqlManagement.Services |
            Where-Object -FilterScript {
                $_.Name -eq $serviceNames.SQLEngineName
            }

        if ($databaseEngineService)
        {
            Write-Debug -Message (
                $script:localizedData.DebugParsingStartupParameters -f $MyInvocation.MyCommand, $databaseEngineService.StartupParameters
            )

            $startupParameterValues = $databaseEngineService.StartupParameters.Split(';')

            $startupParameterTraceFlagValues = $startupParameterValues |
                Where-Object -FilterScript {
                    $_ -match '^-T\d+'
                }

            $traceFlags = @()

            if ($startupParameterTraceFlagValues)
            {
                Write-Debug -Message (
                    $script:localizedData.DebugFoundTraceFlags -f $MyInvocation.MyCommand, ($startupParameterTraceFlagValues -join ', ')
                )

                $traceFlags = @(
                    $startupParameterTraceFlagValues |
                        ForEach-Object {
                            $_.TrimStart('-T')
                        }
                )
           }
           else
           {
               Write-Debug -Message ($script:localizedData.DebugNoTraceFlags -f $MyInvocation.MyCommand)
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

    Write-Debug -Message (
        $script:localizedData.DebugReturningTraceFlags -f $MyInvocation.MyCommand, ($traceFlags -join ', ')
    )

    return @{
        ServerName          = $ServerName
        InstanceName        = $InstanceName
        TraceFlags          = [System.UInt32[]] $traceFlags
        TraceFlagsToInclude = [System.UInt32[]] @()
        TraceFlagsToExclude = [System.UInt32[]] @()
        ClearAllTraceFlags  = $false
        RestartService      = $null
        RestartTimeout      = $null
    }
}

<#
    .SYNOPSIS
        This function sets the sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER TraceFlags
        The TraceFlags the SQL server engine startup parameters should contain.
        This parameter can not be used together with TraceFlagsToInclude and TraceFlagsToExclude.
        This parameter will replace all the current trace flags with the specified trace flags.

    .PARAMETER TraceFlagsToInclude
        The TraceFlags the SQL server engine startup parameters should include.
        This parameter can not be used together with TraceFlags.

    .PARAMETER TraceFlagsToExclude
        The TraceFlags the SQL server engine startup parameters should exclude.
        This parameter can not be used together with TraceFlags.

    .PARAMETER ClearAllTraceFlags
        Specifies that there should be no trace flags set on the instance.

    .PARAMETER RestartService
        If set, the sql server instance gets a reset after setting parameters.
        after restart the sql server agent is in the original state as before restart.

    .PARAMETER RestartTimeout
        The time the resource waits while the sql server services are restarted.
        Defaults to 120 seconds.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

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
        $ClearAllTraceFlags,

        [Parameter()]
        [System.Boolean]
        $RestartService,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout = 120
    )

    # Import SqlServer module.
    Import-SqlDscPreferredModule

    Write-Verbose -Message (
        $script:localizedData.SetConfiguration -f $InstanceName
    )

    $assertBoundParameterParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'TraceFlags'
        )
        MutuallyExclusiveList2 = @(
            'TraceFlagsToInclude',
            'TraceFlagsToExclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $desiredTraceFlags = [System.Collections.ArrayList]::new()

    if ($PSBoundParameters.ContainsKey('TraceFlags'))
    {
        if ($null -ne $TraceFlags)
        {
            $desiredTraceFlags.AddRange(@($TraceFlags))
        }
    }
    elseif ($PSBoundParameters.ContainsKey('TraceFlagsToInclude') -or $PSBoundParameters.ContainsKey('TraceFlagsToExclude'))
    {
        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

        if ($null -ne $getTargetResourceResult.TraceFlags)
        {
            $desiredTraceFlags.AddRange(@($getTargetResourceResult.TraceFlags))
        }

        if ($PSBoundParameters.ContainsKey('TraceFlagsToInclude'))
        {
            foreach ($currentTraceFlagToInclude in $TraceFlagsToInclude)
            {
                if ($desiredTraceFlags -notcontains $currentTraceFlagToInclude)
                {
                    $desiredTraceFlags.Add($currentTraceFlagToInclude)
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('TraceFlagsToExclude'))
        {
            foreach ($currentTraceFlagToExclude in $TraceFlagsToExclude)
            {
                if ($desiredTraceFlags -contains $currentTraceFlagToExclude)
                {
                    $desiredTraceFlags.Remove($currentTraceFlagToExclude)
                }
            }
        }
    }
    elseif ($PSBoundParameters.ContainsKey('ClearAllTraceFlags'))
    {
        Write-Verbose -Message $script:localizedData.ClearingAllTraceFlags

        $desiredTraceFlags = @()
    }
    else
    {
        Write-Verbose -Message $script:localizedData.NoTraceFlagParameter

        return
    }

    # Add '-T' dash to flag.
    $startupParameterTraceFlagValues = @(
        $desiredTraceFlags |
            ForEach-Object {
                '-T{0}' -f $_
            }
    )

    $serviceNames = Get-SqlServiceName -InstanceName $InstanceName

    $sqlManagement = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' -ArgumentList $ServerName

    if ($sqlManagement)
    {
        $databaseEngineService = $sqlManagement.Services |
            Where-Object -FilterScript {
                $_.Name -eq $serviceNames.SQLEngineName
            }

        if ($databaseEngineService)
        {
            # Extract startup parameters.
            $currentStartupParameters = $databaseEngineService.StartupParameters.Split(';')

            [System.Collections.ArrayList] $parameterList = $currentStartupParameters

            # Remove all current trace flags
            foreach ($parameter in $currentStartupParameters)
            {
                if ($parameter -match '^-T\d+')
                {
                    $parameterList.Remove($parameter) | Out-Null
                }
            }

            # Set all desired trace flags
            foreach ($desiredTraceFlag in $startupParameterTraceFlagValues)
            {
                $parameterList.Add($desiredTraceFlag) | Out-Null
            }

            # Merge parameter list back into startup parameters.
            $databaseEngineService.StartupParameters = $parameterList -join ';'

            Write-Debug -Message (
                $script:localizedData.DebugSetStartupParameters -f $MyInvocation.MyCommand, $databaseEngineService.StartupParameters
            )

            $databaseEngineService.Alter()

            if ($PSBoundParameters.ContainsKey('RestartService'))
            {
                if ($RestartService -eq $true)
                {
                    Restart-SqlService -ServerName $ServerName -InstanceName $InstanceName -Timeout $RestartTimeout
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        This function tests the sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER TraceFlags
        The TraceFlags the SQL server engine startup parameters should contain.
        This parameter can not be used together with TraceFlagsToInclude and TraceFlagsToExclude.
        This parameter will replace all the current trace flags with the specified trace flags.

    .PARAMETER TraceFlagsToInclude
        The TraceFlags the SQL server engine startup parameters should include.
        This parameter can not be used together with TraceFlags.

    .PARAMETER TraceFlagsToExclude
        The TraceFlags the SQL server engine startup parameters should exclude.
        This parameter can not be used together with TraceFlags.

    .PARAMETER ClearAllTraceFlags
        Specifies that there should be no trace flags set on the instance.

    .PARAMETER RestartService
        If set, the sql server instance gets a reset after setting parameters.
        after restart the sql server agent is in the original state as before restart.

    .PARAMETER RestartTimeout
        The time the resource waits while the sql server services are restarted.
        Defaults to 120 seconds.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Import-SqlDscPreferredModule is called when Get-TargetResource is called')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

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
        $ClearAllTraceFlags,

        [Parameter()]
        [System.Boolean]
        $RestartService,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout = 120
    )

    Write-Verbose -Message (
        $script:localizedData.TestConfiguration -f $InstanceName
    )

    $assertBoundParameterParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'TraceFlags'
        )
        MutuallyExclusiveList2 = @(
            'TraceFlagsToInclude',
            'TraceFlagsToExclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $assertBoundParameterParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'ClearAllTraceFlags'
        )
        MutuallyExclusiveList2 = @(
            'TraceFlags'
            'TraceFlagsToInclude',
            'TraceFlagsToExclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $isInDesiredState = $true

    if ($PSBoundParameters.ContainsKey('ClearAllTraceFlags') -and $ClearAllTraceFlags)
    {
        if ($getTargetResourceResult.TraceFlags.Count -gt 0)
        {
            Write-Verbose -Message (
                $script:localizedData.ClearNotInDesiredState -f @(
                    ($getTargetResourceResult.TraceFlags -join ', ')
                )
            )

            $isInDesiredState = $false
        }
    }
    elseif ($PSBoundParameters.ContainsKey('TraceFlags'))
    {
        $currentStateTraceFlags = [System.Collections.ArrayList]::new()

        if (-not [System.String]::IsNullOrEmpty($getTargetResourceResult.TraceFlags))
        {
            $currentStateTraceFlags.AddRange(@($getTargetResourceResult.TraceFlags))
        }

        $desiredStateTraceFlags = [System.Collections.ArrayList]::new()

        if (-not [System.String]::IsNullOrEmpty($TraceFlags))
        {
            $desiredStateTraceFlags.AddRange(@($TraceFlags))
        }

        # Returns $null if desired state and current state is the same.
        $compareObjectResult = Compare-Object -ReferenceObject $currentStateTraceFlags -DifferenceObject $desiredStateTraceFlags

        if ($null -ne $compareObjectResult)
        {
            $isInDesiredState = $false

            Write-Verbose -Message (
                $script:localizedData.NotInDesiredState -f @(
                    ($desiredStateTraceFlags -join ', '),
                    ($currentStateTraceFlags -join ', ')
                )
            )
        }
    }
    else
    {
        if ($PSBoundParameters.ContainsKey('TraceFlagsToInclude'))
        {
            foreach ($currentTraceFlagToInclude in $TraceFlagsToInclude)
            {
                if ($getTargetResourceResult.TraceFlags -notcontains $currentTraceFlagToInclude)
                {
                    Write-Verbose -Message (
                        $script:localizedData.TraceFlagNotPresent `
                            -f $currentTraceFlagToInclude
                    )

                    $isInDesiredState = $false

                    break
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('TraceFlagsToExclude'))
        {
            foreach ($currentTraceFlagToExclude in $TraceFlagsToExclude)
            {
                if ($getTargetResourceResult.TraceFlags -contains $currentTraceFlagToExclude)
                {
                    Write-Verbose -Message (
                        $script:localizedData.TraceFlagPresent `
                            -f $currentTraceFlagToExclude
                    )

                    $isInDesiredState = $false

                    break
                }
            }
        }
    }

    if ($isInDesiredState)
    {
        Write-Verbose -Message $script:localizedData.InDesiredState
    }

    return $isInDesiredState
}

<#
    .SYNOPSIS
        This function returns the serviceNames of an sql instance.

    .PARAMETER InstanceName
        The name of the SQL instance of who's service names are being returned.
#>
function Get-SqlServiceName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $sqlEngineName = 'MSSQLSERVER'
        $sqlAgentName = 'SQLSERVERAGENT' # cSpell: disable-line
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
