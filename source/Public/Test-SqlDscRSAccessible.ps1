<#
    .SYNOPSIS
        Tests if SQL Server Reporting Services sites are accessible.

    .DESCRIPTION
        Tests if SQL Server Reporting Services or Power BI Report Server
        web sites are accessible by making HTTP requests to the configured
        URLs.

        This command can be used to verify that a Reporting Services instance
        is fully configured and responding to web requests after initialization.

        The command supports two modes:
        - Configuration mode: Uses a CIM configuration instance to automatically
          detect the configured URLs from URL reservations.
        - URI mode: Uses explicitly specified URIs for the ReportServer and/or
          Reports sites.

        When using the Configuration parameter set, a dynamic `-Site` parameter
        becomes available that allows selecting which sites to test. The available
        sites are determined from the URL reservations configured for the instance.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER ServerName
        Specifies the server name to use when constructing URLs from the
        configuration. Defaults to `$env:COMPUTERNAME`.

    .PARAMETER ReportServerUri
        Specifies the explicit URI for the ReportServer web service to test.
        This parameter is used in the Uri parameter set.

    .PARAMETER ReportsUri
        Specifies the explicit URI for the Reports web portal to test.
        This parameter is used in the Uri parameter set.

    .PARAMETER TimeoutSeconds
        Specifies the maximum time in seconds to wait for the sites to become
        accessible. Defaults to 120 seconds.

    .PARAMETER RetryIntervalSeconds
        Specifies the interval in seconds between retry attempts. Defaults to
        5 seconds.

    .PARAMETER Detailed
        When specified, returns a detailed object containing accessibility
        status, HTTP status codes, and URIs for each site instead of a
        simple boolean.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Test-SqlDscRSAccessible

        Tests if all configured sites for the SSRS instance are accessible.
        Returns `$true` if all sites return HTTP 200, `$false` otherwise.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Test-SqlDscRSAccessible -Configuration $config -Site 'ReportServerWebService'

        Tests if only the ReportServerWebService site is accessible for the
        SSRS instance.

    .EXAMPLE
        Test-SqlDscRSAccessible -ReportServerUri 'http://localhost/ReportServer' -ReportsUri 'http://localhost/Reports'

        Tests if the specified ReportServer and Reports URIs are accessible
        using explicit URIs.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Test-SqlDscRSAccessible -Detailed

        Tests if all configured sites are accessible and returns a detailed
        object with status information for each site.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.Boolean`

        Returns `$true` if all specified sites return HTTP 200, `$false` otherwise.

    .OUTPUTS
        `System.Management.Automation.PSCustomObject`

        When `-Detailed` is specified, returns an object containing:
        - `ReportServerAccessible`: Boolean indicating if ReportServer is accessible.
        - `ReportsAccessible`: Boolean indicating if Reports is accessible.
        - `ReportServerStatusCode`: HTTP status code from ReportServer.
        - `ReportsStatusCode`: HTTP status code from Reports.
        - `ReportServerUri`: The URI tested for ReportServer.
        - `ReportsUri`: The URI tested for Reports.

    .NOTES
        This command uses `Invoke-WebRequest` with `-UseDefaultCredentials`
        to authenticate to the Reporting Services sites.
#>
function Test-SqlDscRSAccessible
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(DefaultParameterSetName = 'Configuration')]
    [OutputType([System.Boolean])]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Configuration')]
        [System.Object]
        $Configuration,

        [Parameter(ParameterSetName = 'Configuration')]
        [System.String]
        $ServerName,

        [Parameter(ParameterSetName = 'Uri')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ReportServerUri,

        [Parameter(ParameterSetName = 'Uri')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ReportsUri,

        [Parameter()]
        [System.Int32]
        $TimeoutSeconds = 120,

        [Parameter()]
        [System.Int32]
        $RetryIntervalSeconds = 5,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Detailed
    )

    dynamicparam
    {
        if ($PSBoundParameters.ContainsKey('Configuration'))
        {
            $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

            # Get URL reservations to populate ValidateSet
            try
            {
                $urlReservations = Get-SqlDscRSUrlReservation -Configuration $PSBoundParameters['Configuration'] -ErrorAction 'Stop'

                if ($urlReservations -and $urlReservations.Application)
                {
                    $availableSites = $urlReservations.Application | Select-Object -Unique
                }
                else
                {
                    $availableSites = @()
                }
            }
            catch
            {
                $availableSites = @()
            }

            if ($availableSites.Count -gt 0)
            {
                $siteAttribute = [System.Management.Automation.ParameterAttribute]::new()
                $siteAttribute.ParameterSetName = 'Configuration'
                $siteAttribute.Mandatory = $false

                $validateSetAttribute = [System.Management.Automation.ValidateSetAttribute]::new($availableSites)

                $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
                $attributeCollection.Add($siteAttribute)
                $attributeCollection.Add($validateSetAttribute)

                $siteParameter = [System.Management.Automation.RuntimeDefinedParameter]::new(
                    'Site',
                    [System.String[]],
                    $attributeCollection
                )

                $paramDictionary.Add('Site', $siteParameter)
            }

            return $paramDictionary
        }
    }

    process
    {
        $urisToTest = @{}

        if ($PSCmdlet.ParameterSetName -eq 'Configuration')
        {
            # Use Get-ComputerName for cross-platform compatibility if ServerName not specified
            if (-not $PSBoundParameters.ContainsKey('ServerName'))
            {
                $ServerName = Get-ComputerName
            }

            $instanceName = $Configuration.InstanceName

            Write-Verbose -Message ($script:localizedData.Test_SqlDscRSAccessible_Testing -f $instanceName)

            # Get URL reservations
            $urlReservations = Get-SqlDscRSUrlReservation -Configuration $Configuration -ErrorAction 'Stop'

            if (-not $urlReservations -or -not $urlReservations.Application)
            {
                $errorMessage = $script:localizedData.Test_SqlDscRSAccessible_NoUrlReservations -f $instanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'TSRSA0001',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Configuration
                    )
                )
            }

            # Determine which sites to test
            $sitesToTest = if ($PSBoundParameters.ContainsKey('Site'))
            {
                $PSBoundParameters['Site']
            }
            else
            {
                $urlReservations.Application | Select-Object -Unique
            }

            # Build URIs for each site
            foreach ($site in $sitesToTest)
            {
                $siteIndex = [System.Array]::IndexOf($urlReservations.Application, $site)

                if ($siteIndex -lt 0)
                {
                    $errorMessage = $script:localizedData.Test_SqlDscRSAccessible_SiteNotConfigured -f $site, $instanceName

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage),
                            'TSRSA0002',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $site
                        )
                    )
                }

                $urlPattern = $urlReservations.UrlString[$siteIndex]

                # Determine virtual directory based on site type
                $virtualDirectory = switch -Regex ($site)
                {
                    'ReportServerWebService'
                    {
                        $Configuration.VirtualDirectoryReportServer
                    }

                    'ReportServerWebApp|ReportManager'
                    {
                        $Configuration.VirtualDirectoryReportManager
                    }

                    default
                    {
                        $site
                    }
                }

                # Parse URL pattern (e.g., 'http://+:80') to construct full URL
                if ($urlPattern -match '^(https?):\/\/[^:]+:(\d+)')
                {
                    $protocol = $Matches[1]
                    $port = $Matches[2]

                    if ($port -eq '80' -and $protocol -eq 'http')
                    {
                        $uri = '{0}://{1}/{2}' -f $protocol, $ServerName, $virtualDirectory
                    }
                    elseif ($port -eq '443' -and $protocol -eq 'https')
                    {
                        $uri = '{0}://{1}/{2}' -f $protocol, $ServerName, $virtualDirectory
                    }
                    else
                    {
                        $uri = '{0}://{1}:{2}/{3}' -f $protocol, $ServerName, $port, $virtualDirectory
                    }

                    $urisToTest[$site] = $uri
                }
            }
        }
        else
        {
            # Uri parameter set
            Write-Verbose -Message $script:localizedData.Test_SqlDscRSAccessible_TestingExplicitUris

            if ($PSBoundParameters.ContainsKey('ReportServerUri'))
            {
                $urisToTest['ReportServerWebService'] = $ReportServerUri
            }

            if ($PSBoundParameters.ContainsKey('ReportsUri'))
            {
                $urisToTest['ReportServerWebApp'] = $ReportsUri
            }

            if ($urisToTest.Count -eq 0)
            {
                $errorMessage = $script:localizedData.Test_SqlDscRSAccessible_NoUrisSpecified

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'TSRSA0003',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $null
                    )
                )
            }
        }

        # Test each URI with retry logic
        $maxRetries = [System.Math]::Ceiling($TimeoutSeconds / $RetryIntervalSeconds)
        $results = @{}
        $allAccessible = $true

        foreach ($siteEntry in $urisToTest.GetEnumerator())
        {
            $siteName = $siteEntry.Key
            $siteUri = $siteEntry.Value
            $statusCode = 0
            $accessible = $false

            Write-Verbose -Message ($script:localizedData.Test_SqlDscRSAccessible_TestingSite -f $siteName, $siteUri)

            for ($attempt = 1; $attempt -le $maxRetries; $attempt++)
            {
                try
                {
                    $webRequest = Invoke-WebRequest -Uri $siteUri -UseDefaultCredentials -UseBasicParsing -ErrorAction 'Stop'
                    $statusCode = $webRequest.StatusCode -as [System.Int32]

                    if ($statusCode -eq 200)
                    {
                        Write-Verbose -Message ($script:localizedData.Test_SqlDscRSAccessible_SiteAccessible -f $siteName, $attempt)
                        $accessible = $true

                        break
                    }
                }
                catch
                {
                    $webRequestResponse = $_.Exception.Response
                    $statusCode = $webRequestResponse.StatusCode -as [System.Int32]

                    if ($statusCode -eq 0 -and $attempt -lt $maxRetries)
                    {
                        Write-Verbose -Message ($script:localizedData.Test_SqlDscRSAccessible_RetryingAccess -f $siteName, $attempt, $maxRetries, $RetryIntervalSeconds)

                        Start-Sleep -Seconds $RetryIntervalSeconds
                    }
                    elseif ($statusCode -ne 0)
                    {
                        Write-Verbose -Message ($script:localizedData.Test_SqlDscRSAccessible_SiteReturnedError -f $siteName, $statusCode)

                        break
                    }
                }
            }

            if (-not $accessible)
            {
                Write-Verbose -Message ($script:localizedData.Test_SqlDscRSAccessible_SiteNotAccessible -f $siteName, $maxRetries)
                $allAccessible = $false
            }

            $results[$siteName] = @{
                Accessible = $accessible
                StatusCode = $statusCode
                Uri        = $siteUri
            }
        }

        if ($Detailed.IsPresent)
        {
            $detailedResult = [PSCustomObject] @{
                ReportServerAccessible = $results['ReportServerWebService'].Accessible
                ReportsAccessible      = $results['ReportServerWebApp'].Accessible -or $results['ReportManager'].Accessible
                ReportServerStatusCode = $results['ReportServerWebService'].StatusCode
                ReportsStatusCode      = ($results['ReportServerWebApp'].StatusCode, $results['ReportManager'].StatusCode | Where-Object -FilterScript { $_ }) | Select-Object -First 1
                ReportServerUri        = $results['ReportServerWebService'].Uri
                ReportsUri             = ($results['ReportServerWebApp'].Uri, $results['ReportManager'].Uri | Where-Object -FilterScript { $_ }) | Select-Object -First 1
            }

            return $detailedResult
        }

        return $allAccessible
    }
}
