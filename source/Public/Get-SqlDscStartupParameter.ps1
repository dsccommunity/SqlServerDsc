<#
    .SYNOPSIS
        Get current startup parameters on a Database Engine instance.

    .DESCRIPTION
        Get current startup parameters on a Database Engine instance.

    .PARAMETER ServiceObject
        Specifies the Service object to return the trace flags from.

    .PARAMETER ServerName
       Specifies the server name to return the trace flags from.

    .PARAMETER InstanceName
       Specifies the instance name to return the trace flags for.

    .EXAMPLE
        Get-SqlDscStartupParameter

        Get the startup parameters from the Database Engine default instance on
        the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'
        Get-SqlDscStartupParameter -ServiceObject $serviceObject

        Get the startup parameters from the Database Engine default instance on
        the server where the command in run.

    .EXAMPLE
        Get-SqlDscStartupParameter -InstanceName 'SQL2022'

        Get the startup parameters from the Database Engine instance 'SQL2022' on
        the server where the command in run.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName 'SQL2022'
        Get-SqlDscStartupParameter -ServiceObject $serviceObject

        Get the startup parameters from the Database Engine instance 'SQL2022' on
        the server where the command in run.

    .OUTPUTS
        `[StartupParameters]`
#>
function Get-SqlDscStartupParameter
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([StartupParameters])]
    [CmdletBinding(DefaultParameterSetName = 'ByServerName')]
    param
    (
        [Parameter(ParameterSetName = 'ByServiceObject', Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]
        $ServiceObject,

        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName = 'MSSQLSERVER'
    )

    Assert-ElevatedUser -ErrorAction 'Stop'

    if ($PSCmdlet.ParameterSetName -eq 'ByServiceObject')
    {
        $ServiceObject | Assert-ManagedServiceType -ServiceType 'DatabaseEngine'
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByServerName')
    {
        $getSqlDscManagedComputerServiceParameters = @{
            ServerName   = $ServerName
            InstanceName = $InstanceName
            ServiceType  = 'DatabaseEngine'
        }

        $ServiceObject = Get-SqlDscManagedComputerService @getSqlDscManagedComputerServiceParameters

        if (-not $ServiceObject)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.StartupParameter_Get_FailedToFindServiceObject
                Category     = 'InvalidOperation'
                ErrorId      = 'GSDSP0001' # CSpell: disable-line
                TargetObject = $ServiceObject
            }

            Write-Error @writeErrorParameters
        }
    }

    Write-Verbose -Message (
        $script:localizedData.StartupParameter_Get_ReturnStartupParameters -f $InstanceName, $ServerName
    )

    $startupParameters = $null

    if ($ServiceObject.StartupParameters)
    {
        $startupParameters = [StartupParameters]::Parse($ServiceObject.StartupParameters)
    }
    else
    {
        Write-Debug -Message ($script:localizedData.StartupParameter_Get_FailedToFindStartupParameters -f $MyInvocation.MyCommand)
    }

    return $startupParameters
}
