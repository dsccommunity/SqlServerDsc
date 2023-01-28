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
    Import-SQLPSModule

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
                    $script:localizedData.DebugFoundTraceFlags -f $MyInvocation.MyCommand, ($startupParameterTraceFlagValues -join ',')
                )

                $traceFlags = @(
                    $startupParameterTraceFlagValues |
                        ForEach-Object {
                            $_.TrimStart('-T')
                        }
                )

                Write-Debug -Message (
                    $script:localizedData.DebugReturningTraceFlags -f $MyInvocation.MyCommand, ($traceFlags -join ',')
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

    return @{
        ServerName          = $ServerName
        InstanceName        = $InstanceName
        TraceFlags          = [System.UInt32[]] $traceFlags
        TraceFlagsToInclude = [System.UInt32[]] @()
        TraceFlagsToExclude = [System.UInt32[]] @()
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
        $RestartService = $false,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout = 120
    )

    # Import SqlServer module.
    Import-SQLPSModule

    Write-Verbose -Message (
        $script:localizedData.SetConfiguration -f $InstanceName
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

    $desiredTraceFlags = [System.Collections.ArrayList]::new()

    if ($PSBoundParameters.ContainsKey('TraceFlags'))
    {
        if ($null -ne $TraceFlags)
        {
            $desiredTraceFlags.AddRange(@($TraceFlags))
        }
    }
    else
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

    .PARAMETER RestartService
        If set, the sql server instance gets a reset after setting parameters.
        after restart the sql server agent is in the original state as before restart.

    .PARAMETER RestartTimeout
        The time the resource waits while the sql server services are restarted.
        Defaults to 120 seconds.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Import-SQLPSModule is called when Get-TargetResource is called')]
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
        $RestartService = $false,

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
            'TraceFlagsToInclude', 'TraceFlagsToExclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    Write-Debug -Message (
        '{0}: TraceFlags in current state ({2}): {1}' -f $MyInvocation.MyCommand, $getTargetResourceResult.TraceFlags, $getTargetResourceResult.TraceFlags.Count
    )

    Write-Debug -Message (
        '{0}: TraceFlags in desired state ({2}): {1}' -f $MyInvocation.MyCommand, $TraceFlags, $TraceFlags.Count
    )

    $isInDesiredState = $true

    if ($PSBoundParameters.ContainsKey('TraceFlags'))
    {
        if ($TraceFlags.Count -eq 0)
        {
            if ($getTargetResourceResult.TraceFlags.Count -gt 0)
            {
                $isInDesiredState = $false
            }
        }
        else
        {
            $currentStateTraceFlags = [System.Collections.ArrayList]::new()

            if (-not [System.String]::IsNullOrEmpty($getTargetResourceResult.TraceFlags))
            {
                $currentStateTraceFlags.AddRange(@($getTargetResourceResult.TraceFlags))
            }

            $desiredStateTraceFlags = [System.Collections.ArrayList]::new()

            if (-not [System.String]::IsNullOrEmpty($TraceFlags))
            {
                $desiredStateTraceFlags.AddRange($TraceFlags)
            }

            # Returns $null if desired state and current state is the same.
            $compareObjectResult = Compare-Object -ReferenceObject $currentStateTraceFlags -DifferenceObject $desiredStateTraceFlags

            if ($null -ne $compareObjectResult)
            {
                $isInDesiredState = $false
            }
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

    if (-not $isInDesiredState)
    {
        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState -f @(
                (($TraceFlags + $TraceFlagsToInclude) -join ','),
                ($getTargetResourceResult.TraceFlags -join ',')
            )
        )
    }
    else
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
