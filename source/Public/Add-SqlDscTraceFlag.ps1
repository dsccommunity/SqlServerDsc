<#
    .SYNOPSIS
        Add trace flags to a Database Engine instance.

    .DESCRIPTION
        Add trace flags on a Database Engine instance, keeping any trace flags
        currently set.

    .PARAMETER ServiceObject
        Specifies the Service object on which to add the trace flags.

    .PARAMETER ServerName
        Specifies the server name where the instance exist.

    .PARAMETER InstanceName
       Specifies the instance name on which to remove the trace flags.

    .PARAMETER TraceFlag
        Specifies the trace flags to add.

    .PARAMETER Force
        Specifies that the trace flag should be added without any confirmation.

    .EXAMPLE
        Add-SqlDscTraceFlag -TraceFlag 4199

        Adds the trace flag 4199 on the Database Engine default instance
        on the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'
        Add-SqlDscTraceFlag -ServiceObject $serviceObject -TraceFlag 4199

        Adds the trace flag 4199 on the Database Engine default instance
        on the server where the command in run.

    .EXAMPLE
        Add-SqlDscTraceFlag -InstanceName 'SQL2022' -TraceFlag 4199,3226

        Adds the trace flags 4199 and 3226 on the Database Engine instance
        'SQL2022' on the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName 'SQL2022'
        Add-SqlDscTraceFlag -ServiceObject $serviceObject -TraceFlag 4199,3226

        Adds the trace flags 4199 and 3226 on the Database Engine instance
        'SQL2022' on the server where the command in run.

    .OUTPUTS
        None.
#>
function Add-SqlDscTraceFlag
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

        $desiredTraceFlags = [System.UInt32[]] $currentTraceFlags + @(
            $TraceFlag |
                ForEach-Object -Process {
                    # Add only when it does not already exist.
                    if ($_ -notin $currentTraceFlags)
                    {
                        $_
                    }
                }
        )

        $verboseDescriptionMessage = $script:localizedData.TraceFlag_Add_ShouldProcessVerboseDescription -f $InstanceName, ($TraceFlag -join ', ')
        $verboseWarningMessage = $script:localizedData.TraceFlag_Add_ShouldProcessVerboseWarning -f $InstanceName
        $captionMessage = $script:localizedData.TraceFlag_Add_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Copy $PSBoundParameters to keep it intact.
            $setSqlDscTraceFlagParameters = @{} + $PSBoundParameters

            $setSqlDscTraceFlagParameters.TraceFLag = $desiredTraceFlags

            Set-SqlDscTraceFlag @setSqlDscTraceFlagParameters -ErrorAction 'Stop'
        }
    }
}
