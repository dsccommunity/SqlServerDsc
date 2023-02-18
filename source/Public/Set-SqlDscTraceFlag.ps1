<#
    .SYNOPSIS
        Sets trace flags on a Database Engine instance.

    .DESCRIPTION
        Sets trace flags on a Database Engine instance, replacing any trace flags
        currently set.

    .PARAMETER ServiceObject
        Specifies the Service object on which to set the trace flags.

    .PARAMETER ServerName
        Specifies the server name where the instance exist.

    .PARAMETER InstanceName
       Specifies the instance name on which to set the trace flags.

    .EXAMPLE
        Set-SqlDscTraceFlag -TraceFlag 4199

        Replaces the trace flags with 4199 on the Database Engine default instance
        on the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'
        Set-SqlDscTraceFlag -ServiceObject $serviceObject -TraceFlag 4199

        Replaces the trace flags with 4199 on the Database Engine default instance
        on the server where the command in run.

    .EXAMPLE
        Set-SqlDscTraceFlag -InstanceName 'SQL2022' -TraceFlag 4199,3226

        Replaces the trace flags with 4199 and 3226 on the Database Engine instance
        'SQL2022' on the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName 'SQL2022'
        Set-SqlDscTraceFlag -ServiceObject $serviceObject -TraceFlag 4199,3226

        Replaces the trace flags with 4199 and 3226 on the Database Engine instance
        'SQL2022' on the server where the command in run.

    .EXAMPLE
        Set-SqlDscTraceFlag -InstanceName 'SQL2022' -TraceFlag @()

        Removes all the trace flags from the Database Engine instance 'SQL2022'
        on the server where the command in run.

    .OUTPUTS
        None.
#>
function Set-SqlDscTraceFlag
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
        [AllowEmptyCollection()]
        [System.UInt32[]]
        $TraceFlag,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        Assert-ElevatedUser -ErrorAction 'Stop'
    }

    process
    {
        if ($Force.IsPresent)
        {
            $ConfirmPreference = 'None'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByServiceObject')
        {
            $ServiceObject | Assert-ManagedServiceType -ServiceType 'DatabaseEngine'

            $InstanceName = $ServiceObject.Name -replace '^MSSQL\$'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByServerName')
        {
            $getSqlDscManagedComputerServiceParameters = @{
                ServerName   = $ServerName
                InstanceName = $InstanceName
                ServiceType  = 'DatabaseEngine'
                ErrorAction  = 'Stop'
            }

            $ServiceObject = Get-SqlDscManagedComputerService @getSqlDscManagedComputerServiceParameters

            if (-not $ServiceObject)
            {
                $writeErrorParameters = @{
                    Message      = $script:localizedData.TraceFlag_Set_FailedToFindServiceObject
                    Category     = 'InvalidOperation'
                    ErrorId      = 'SSDTF0002' # CSpell: disable-line
                    TargetObject = $ServiceObject
                }

                Write-Error @writeErrorParameters
            }
        }

        if ($ServiceObject)
        {
            $verboseDescriptionMessage = $script:localizedData.TraceFlag_Set_ShouldProcessVerboseDescription -f $InstanceName, ($TraceFlag -join ', ')
            $verboseWarningMessage = $script:localizedData.TraceFlag_Set_ShouldProcessVerboseWarning -f $InstanceName
            $captionMessage = $script:localizedData.TraceFlag_Set_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
            {
                $startupParameters = [StartupParameters]::Parse($ServiceObject.StartupParameters)

                $startupParameters.TraceFlag = $TraceFlag

                $ServiceObject.StartupParameters = $startupParameters.ToString()
                $ServiceObject.Alter()
            }
        }
    }
}
