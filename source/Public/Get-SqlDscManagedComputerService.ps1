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

    .PARAMETER WithExtendedProperties
       Specifies that extended properties should be added to each returned service
       object. This includes ManagedServiceType, ServiceExecutableVersion,
       ServiceStartupType, and ServiceInstanceName properties. Note that retrieving
       the executable version may take additional time.

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

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer`

        Accepts input via the pipeline.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Wmi.Service[]`

        An array of managed computer service objects.

    .EXAMPLE
        Get-SqlDscManagedComputerService -WithExtendedProperties

        Returns all the managed computer service objects for the current node
        with extended properties (ManagedServiceType, ServiceExecutableVersion,
        ServiceStartupType, and ServiceInstanceName) added to each service object.
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
        $ServiceType,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $WithExtendedProperties
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

            if ($WithExtendedProperties.IsPresent)
            {
                foreach ($service in $serviceObject)
                {
                    $convertedType = $service.Type | ConvertFrom-ManagedServiceType -ErrorAction 'SilentlyContinue'

                    $service | Add-Member -MemberType 'NoteProperty' -Name 'ManagedServiceType' -Value $convertedType -Force

                    $fileProductVersion = $null

                    $serviceExecutablePath = (($service.PathName -replace '"') -split ' -')[0]

                    if ((Test-Path -Path $serviceExecutablePath))
                    {
                        $fileProductVersion = [System.Version] (Get-FileVersionInformation -FilePath $serviceExecutablePath).ProductVersion
                    }

                    $service | Add-Member -MemberType 'NoteProperty' -Name 'ServiceExecutableVersion' -Value $fileProductVersion -Force

                    $serviceStartupType = $service.StartMode | ConvertFrom-ServiceStartMode

                    $service | Add-Member -MemberType 'NoteProperty' -Name 'ServiceStartupType' -Value $serviceStartupType -Force

                    # Get InstanceName from the service name if it exists.
                    $serviceInstanceName = if ($service.Name -match '\$(.*)$')
                    {
                        $Matches[1]
                    }

                    $service | Add-Member -MemberType 'NoteProperty' -Name 'ServiceInstanceName' -Value $serviceInstanceName -Force
                }
            }
        }

        return $serviceObject
    }
}
