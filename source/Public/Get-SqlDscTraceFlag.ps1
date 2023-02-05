<#
    .SYNOPSIS
        Get current trace flags on a Database Engine instance.

    .DESCRIPTION
        Get current trace flags on a Database Engine instance.

    .PARAMETER ServiceObject
        Specifies the Service object to return the trace flags from.

    .PARAMETER ServerName
       Specifies the server name to return the trace flags from.

    .PARAMETER InstanceName
       Specifies the instance name to return the trace flags for.

    .EXAMPLE
        Get-SqlDscTraceFlag

        Get all the trace flags from the Database Engine default instance on the
        server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'
        Get-SqlDscTraceFlag -ServiceObject $serviceObject

        Get all the trace flags from the Database Engine default instance on the
        server where the command in run.

    .EXAMPLE
        Get-SqlDscTraceFlag -InstanceName 'SQL2022'

        Get all the trace flags from the Database Engine instance 'SQL2022' on the
        server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName 'SQL2022'
        Get-SqlDscTraceFlag -ServiceObject $serviceObject

        Get all the trace flags from the Database Engine instance 'SQL2022' on the
        server where the command in run.

    .OUTPUTS
        `[System.UInt32[]]`
#>
function Get-SqlDscTraceFlag
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Because the rule does not understands that the command returns [System.UInt32[]] when using , (comma) in the return statement')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.UInt32[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'ByServiceObject', Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]
        $ServiceObject,

        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLSERVER'
    )

    Assert-ElevatedUser -ErrorAction 'Stop'

    if ($PSCmdlet.ParameterSetName -eq 'ByServerName')
    {
        $getSqlDscManagedComputerServiceParameters = @{
            ServerName = $ServerName
            InstanceName = $InstanceName
            ServiceType = 'DatabaseEngine'
        }

        $ServiceObject = Get-SqlDscManagedComputerService @getSqlDscManagedComputerServiceParameters
    }

    Write-Verbose -Message (
        $script:localizedData.TraceFlag_GetState -f $InstanceName, $ServerName
    )

    $traceFlags = [System.UInt32[]] @()

    if ($ServiceObject -and $ServiceObject.StartupParameters)
    {
        Write-Debug -Message (
            $script:localizedData.TraceFlag_DebugParsingStartupParameters -f $MyInvocation.MyCommand, $ServiceObject.StartupParameters
        )

        $startupParameterValues = $ServiceObject.StartupParameters.Split(';')

        $startupParameterTraceFlagValues = $startupParameterValues |
            Where-Object -FilterScript {
                $_ -match '^-T\d+'
            }

        if ($startupParameterTraceFlagValues)
        {
            Write-Debug -Message (
                $script:localizedData.TraceFlag_DebugFoundTraceFlags -f $MyInvocation.MyCommand, ($startupParameterTraceFlagValues -join ', ')
            )

            $traceFlags = @(
                $startupParameterTraceFlagValues |
                    ForEach-Object {
                        [System.UInt32] $_.TrimStart('-T')
                    }
            )
        }
        else
        {
            Write-Debug -Message ($script:localizedData.TraceFlag_DebugNoTraceFlags -f $MyInvocation.MyCommand)
        }
    }
    else
    {
        Write-Debug -Message ($script:localizedData.TraceFlag_FailedToFindStartupParameters -f $MyInvocation.MyCommand)
    }

    Write-Debug -Message (
        $script:localizedData.TraceFlag_DebugReturningTraceFlags -f $MyInvocation.MyCommand, ($traceFlags -join ', ')
    )

    return , [System.UInt32[]] $traceFlags
}
