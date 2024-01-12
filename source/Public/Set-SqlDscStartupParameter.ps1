<#
    .SYNOPSIS
        Sets startup parameters on a Database Engine instance.

    .DESCRIPTION
        Sets startup parameters on a Database Engine instance.

    .PARAMETER ServiceObject
        Specifies the Service object on which to set the startup parameters.

    .PARAMETER ServerName
        Specifies the server name where the instance exist.

    .PARAMETER InstanceName
       Specifies the instance name on which to set the startup parameters.

    .PARAMETER TraceFlag
        Specifies the trace flags to set.

    .PARAMETER InternalTraceFlag
        Specifies the internal trace flags to set.

        From the [Database Engine Service Startup Options](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/database-engine-service-startup-options)
        documentation: "...this sets other internal trace flags that are required
        only by SQL Server support engineers."

    .PARAMETER Force
        Specifies that the startup parameters should be set without any confirmation.

    .EXAMPLE
        Set-SqlDscStartupParameters -TraceFlag 4199

        Replaces the trace flags with 4199 on the Database Engine default instance
        on the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'
        Set-SqlDscTraceFlag -ServiceObject $serviceObject -TraceFlag 4199

        Replaces the trace flags with 4199 on the Database Engine default instance
        on the server where the command in run.

    .EXAMPLE
        Set-SqlDscTraceFlag -InstanceName 'SQL2022' -TraceFlag @()

        Removes all the trace flags from the Database Engine instance 'SQL2022'
        on the server where the command in run.

    .OUTPUTS
        None.

    .NOTES
        This command should support setting the values according to this documentation:
        https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/database-engine-service-startup-options
#>
function Set-SqlDscStartupParameter
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

        [Parameter()]
        [AllowEmptyCollection()]
        [System.UInt32[]]
        $TraceFlag,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.UInt32[]]
        $InternalTraceFlag,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        Assert-ElevatedUser -ErrorAction 'Stop'

        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
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
                    Message      = $script:localizedData.StartupParameter_Set_FailedToFindServiceObject
                    Category     = 'InvalidOperation'
                    ErrorId      = 'SSDSP0002' # CSpell: disable-line
                    TargetObject = $ServiceObject
                }

                Write-Error @writeErrorParameters
            }
        }

        if ($ServiceObject)
        {
            $verboseDescriptionMessage = $script:localizedData.StartupParameter_Set_ShouldProcessVerboseDescription -f $InstanceName
            $verboseWarningMessage = $script:localizedData.StartupParameter_Set_ShouldProcessVerboseWarning -f $InstanceName
            $captionMessage = $script:localizedData.StartupParameter_Set_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
            {
                $startupParameters = [StartupParameters]::Parse($ServiceObject.StartupParameters)

                if ($PSBoundParameters.ContainsKey('TraceFlag'))
                {
                    $startupParameters.TraceFlag = $TraceFlag
                }

                if ($PSBoundParameters.ContainsKey('InternalTraceFlag'))
                {
                    $startupParameters.InternalTraceFlag = $InternalTraceFlag
                }

                $ServiceObject.StartupParameters = $startupParameters.ToString()
                $ServiceObject.Alter()
            }
        }
    }
}
