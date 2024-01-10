<#
    .SYNOPSIS
        Removes trace flags from a Database Engine instance.

    .DESCRIPTION
        Removes trace flags from a Database Engine instance, keeping any other
        trace flags currently set.

    .PARAMETER ServiceObject
        Specifies the Service object on which to remove the trace flags.

    .PARAMETER ServerName
        Specifies the server name where the instance exist.

    .PARAMETER InstanceName
       Specifies the instance name on which to remove the trace flags.

    .PARAMETER TraceFlag
        Specifies the trace flags to remove.

    .PARAMETER Force
        Specifies that the trace flag should be removed without any confirmation.

    .EXAMPLE
        Remove-SqlDscTraceFlag -TraceFlag 4199

        Removes the trace flag 4199 from the Database Engine default instance
        on the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'
        Remove-SqlDscTraceFlag -ServiceObject $serviceObject -TraceFlag 4199

        Removes the trace flag 4199 from the Database Engine default instance
        on the server where the command in run.

    .EXAMPLE
        Remove-SqlDscTraceFlag -InstanceName 'SQL2022' -TraceFlag 4199,3226

        Removes the trace flags 4199 and 3226 from the Database Engine instance
        'SQL2022' on the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName 'SQL2022'
        Remove-SqlDscTraceFlag -ServiceObject $serviceObject -TraceFlag 4199,3226

        Removes the trace flags 4199 and 3226 from the Database Engine instance
        'SQL2022' on the server where the command in run.

    .OUTPUTS
        None.
#>
function Remove-SqlDscTraceFlag
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(DefaultParameterSetName = 'ByServerName', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ByServiceObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]
        $ServiceObject,

        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [System.UInt32[]]
        $TraceFlag,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByServiceObject')
        {
            $InstanceName = $ServiceObject.Name -replace '^MSSQL\$'
        }

        # Copy $PSBoundParameters to keep it intact.
        $getSqlDscTraceFlagParameters = @{} + $PSBoundParameters

        $commonParameters = [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

        # Remove parameters that Get-SqlDscTraceFLag does not have/support.
        $commonParameters + @('Force', 'TraceFlag') |
            ForEach-Object -Process {
                $getSqlDscTraceFlagParameters.Remove($_)
            }

        $currentTraceFlags = Get-SqlDscTraceFlag @getSqlDscTraceFlagParameters -ErrorAction 'Stop'

        if ($currentTraceFlags)
        {
            # Must always return an array. An empty array when removing the last value.
            $desiredTraceFlags = [System.UInt32[]] @(
                $currentTraceFlags |
                    ForEach-Object -Process {
                        # Keep values that should not be removed.
                        if ($_ -notin $TraceFlag)
                        {
                            $_
                        }
                    }
            )

            $verboseDescriptionMessage = $script:localizedData.TraceFlag_Remove_ShouldProcessVerboseDescription -f $InstanceName, ($TraceFlag -join ', ')
            $verboseWarningMessage = $script:localizedData.TraceFlag_Remove_ShouldProcessVerboseWarning -f $InstanceName
            $captionMessage = $script:localizedData.TraceFlag_Remove_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
            {
                # Copy $PSBoundParameters to keep it intact.
                $setSqlDscTraceFlagParameters = @{} + $PSBoundParameters

                $setSqlDscTraceFlagParameters.TraceFLag = $desiredTraceFlags

                Set-SqlDscTraceFlag @setSqlDscTraceFlagParameters -ErrorAction 'Stop'
            }
        }
        else
        {
            Write-Debug -Message $script:localizedData.TraceFlag_Remove_NoCurrentTraceFlags
        }
    }
}
