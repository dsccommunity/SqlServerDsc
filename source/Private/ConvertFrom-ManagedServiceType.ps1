<#
    .SYNOPSIS
        Converts a managed service type name to a normalized service type name.

    .DESCRIPTION
        Converts a managed service type name to its normalized service type name
        equivalent.

    .PARAMETER ServiceType
        Specifies the managed service type to convert to the correct normalized
        service type name.

    .EXAMPLE
        ConvertFrom-ManagedServiceType -ServiceType 'SqlServer'

        Returns the normalized service type name 'DatabaseEngine' .
#>
function ConvertFrom-ManagedServiceType
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType]
        $ServiceType
    )

    process
    {
        # Map the normalized service type to a valid value from the managed service type.
        switch ($ServiceType)
        {
            'SqlServer'
            {
                $serviceTypeValue = 'DatabaseEngine'

                break
            }

            'SqlAgent'
            {
                $serviceTypeValue = 'SqlServerAgent'

                break
            }

            'Search'
            {
                $serviceTypeValue = 'Search'

                break
            }

            'SqlServerIntegrationService'
            {
                $serviceTypeValue = 'IntegrationServices'

                break
            }

            'AnalysisServer'
            {
                $serviceTypeValue = 'AnalysisServices'

                break
            }

            'ReportServer'
            {
                $serviceTypeValue = 'ReportingServices'

                break
            }

            'SqlBrowser'
            {
                $serviceTypeValue = 'SQLServerBrowser'

                break
            }

            'NotificationServer'
            {
                $serviceTypeValue = 'NotificationServices'

                break
            }

            default
            {
                <#
                    This catches any future values in the enum ManagedServiceType
                    that are not yet supported.
                #>
                $writeErrorParameters = @{
                    Message      = $script:localizedData.ManagedServiceType_ConvertFrom_UnknownServiceType -f $ServiceType
                    Category     = 'InvalidOperation'
                    ErrorId      = 'CFMST0001' # CSpell: disable-line
                    TargetObject = $ServiceType
                }

                Write-Error @writeErrorParameters

                break
            }
        }

        return $serviceTypeValue
    }
}
