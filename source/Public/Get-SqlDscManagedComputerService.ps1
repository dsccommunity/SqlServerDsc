<#
    .SYNOPSIS
        Returns one or more managed computer service objects.

    .DESCRIPTION
        Returns one or more managed computer service objects, by default for the
        node the command is run on.

    .PARAMETER ManagedComputerObject
        Specifies the Managed Computer object to return the services from.

    .PARAMETER ServerName
       Specifies the server name to return the services from.

    .PARAMETER InstanceName
       Specifies the instance name to return the services for, this will exclude
       any service that does not have the instance name in the service name.

    .PARAMETER ServiceType
       Specifies one or more service types to return the services for.

    .EXAMPLE
        Get-SqlDscManagedComputer | Get-SqlDscManagedComputerService

        Returns all the managed computer service objects for the current node.

    .EXAMPLE
        Get-SqlDscManagedComputerService

        Returns all the managed computer service objects for the current node.

    .EXAMPLE
        Get-SqlDscManagedComputerService -ServerName 'MyServer'

        Returns all the managed computer service objects for the server 'MyServer'.

    .EXAMPLE
        Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine','AnalysisServices'

        Returns all the managed computer service objects for service types
        'DatabaseEngine' and 'AnalysisServices'.

    .EXAMPLE
        Get-SqlDscManagedComputerService -InstanceName 'SQL2022'

        Returns all the managed computer service objects for instance SQL2022.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Wmi.Service[]]`
#>
function Get-SqlDscManagedComputerService
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when the output type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]    [OutputType([Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer])]
    [OutputType([Microsoft.SqlServer.Management.Smo.Wmi.Service[]])]
    [CmdletBinding(DefaultParameterSetName = 'ByServerName')]
    param
    (
        [Parameter(ParameterSetName = 'ByServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer]
        $ManagedComputerObject,

        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.String[]]
        $InstanceName,

        [Parameter()]
        [ValidateSet('DatabaseEngine', 'SQLServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String[]]
        $ServiceType
    )

    begin
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByServerName')
        {
            $ManagedComputerObject = Get-SqlDscManagedComputer -ServerName $ServerName
        }

        Write-Verbose -Message (
            $script:localizedData.ManagedComputerService_GetState -f $ServerName
        )

        $serviceObject = $null
    }

    process
    {
        if ($ManagedComputerObject)
        {
            if ($serviceObject)
            {
                $serviceObject += $ManagedComputerObject.Services
            }
            else
            {
                $serviceObject = $ManagedComputerObject.Services
            }
        }
    }

    end
    {
        if ($serviceObject)
        {
            if ($PSBoundParameters.ContainsKey('ServiceType'))
            {
                $managedServiceType = $ServiceType |
                    ConvertTo-ManagedServiceType

                $serviceObject = $serviceObject |
                    Where-Object -FilterScript {
                        $_.Type -in $managedServiceType
                    }
            }

            if ($PSBoundParameters.ContainsKey('InstanceName'))
            {
                $serviceObject = $serviceObject |
                    Where-Object -FilterScript {
                        $_.Name -match ('\${0}$' -f $InstanceName)
                    }
            }
        }

        return $serviceObject
    }
}
