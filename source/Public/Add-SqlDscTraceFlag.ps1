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
       Specifies the instance name on which to add the trace flags.

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
        $getSqlDscTraceFlagParameters = Remove-CommonParameter -Hashtable $PSBoundParameters

        # Remove parameters that Get-SqlDscTraceFlag does not have/support.
        @('Force', 'TraceFlag') |
            ForEach-Object -Process {
                $getSqlDscTraceFlagParameters.Remove($_)
            }

        $originalErrorActionPreference = $ErrorActionPreference

        $ErrorActionPreference = 'Stop'

        $currentTraceFlags = Get-SqlDscTraceFlag @getSqlDscTraceFlagParameters -ErrorAction 'Stop'

        $ErrorActionPreference = $originalErrorActionPreference

        # Normalize current trace flags: ensure array, remove nulls, cast to UInt32, sort uniquely
        $normalizedCurrentTraceFlags = @($currentTraceFlags) |
            Where-Object -FilterScript { $null -ne $_ } |
            ForEach-Object -Process { [System.UInt32] $_ } |
            Sort-Object -Unique

        # Normalize input trace flags: ensure array, remove nulls, cast to UInt32, sort uniquely
        $normalizedInputTraceFlags = @($TraceFlag) |
            Where-Object -FilterScript { $null -ne $_ } |
            ForEach-Object -Process { [System.UInt32] $_ } |
            Sort-Object -Unique

        # Combine normalized current and input trace flags to get the desired state
        $desiredTraceFlags = @(
            $normalizedCurrentTraceFlags
            $normalizedInputTraceFlags
        ) |
            Sort-Object -Unique
        $desiredTraceFlags = [System.UInt32[]] $desiredTraceFlags

        # Compare normalized current and desired trace flags to determine if there's an effective change
        $compareResult = Compare-Object -ReferenceObject $normalizedCurrentTraceFlags -DifferenceObject $desiredTraceFlags

        if ($compareResult)
        {
            $verboseDescriptionMessage = $script:localizedData.TraceFlag_Add_ShouldProcessVerboseDescription -f $InstanceName, ($desiredTraceFlags -join ', ')
            $verboseWarningMessage = $script:localizedData.TraceFlag_Add_ShouldProcessVerboseWarning -f $InstanceName
            $captionMessage = $script:localizedData.TraceFlag_Add_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
            {
                # Copy $PSBoundParameters to keep it intact.
                $setSqlDscTraceFlagParameters = Remove-CommonParameter -Hashtable $PSBoundParameters

                $setSqlDscTraceFlagParameters.TraceFlag = $desiredTraceFlags

                $originalErrorActionPreference = $ErrorActionPreference

                $ErrorActionPreference = 'Stop'

                Set-SqlDscTraceFlag @setSqlDscTraceFlagParameters -ErrorAction 'Stop'

                $ErrorActionPreference = $originalErrorActionPreference
            }
        }
    }
}
