<#
    .SYNOPSIS
        Assert that a computer managed service is of a certain type.

    .DESCRIPTION
        Assert that a computer managed service is of a certain type. If it is the
        wrong type an exception is thrown.

    .PARAMETER ServiceObject
        Specifies the Service object to evaluate.

    .PARAMETER ServiceType
        Specifies the normalized service type to evaluate.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'
        Assert-ManagedServiceType -ServiceObject $serviceObject -ServiceType 'DatabaseEngine'

        Asserts that the computer managed service object is of the type Database Engine.

    .EXAMPLE
        $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'
        $serviceObject | Assert-ManagedServiceType -ServiceType 'DatabaseEngine'

        Asserts that the computer managed service object is of the type Database Engine.

    .OUTPUTS
        None.
#>
function Assert-ManagedServiceType
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.Service]
        $ServiceObject,

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseEngine', 'SqlServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String]
        $ServiceType
    )

    process
    {
        $normalizedServiceType = ConvertFrom-ManagedServiceType -ServiceType $ServiceObject.Type

        if ($normalizedServiceType -ne $ServiceType)
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.ManagedServiceType_Assert_WrongServiceType -f $ServiceType, $normalizedServiceType),
                    'AMST0001', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $ServiceObject
                )
            )
        }
    }
}
