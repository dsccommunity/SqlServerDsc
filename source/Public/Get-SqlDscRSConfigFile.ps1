<#
    .SYNOPSIS
        Gets the RsReportServer.config configuration file as an XML object.

    .DESCRIPTION
        Gets the RsReportServer.config configuration file for SQL Server
        Reporting Services (SSRS) or Power BI Report Server (PBIRS) as an
        XML document object. This allows programmatic access to configuration
        settings using standard XML navigation or XPath queries.

        The configuration file path is automatically determined from the
        instance's setup configuration in the registry when using the
        `InstanceName` or `SetupConfiguration` parameter. Alternatively, a direct
        file path can be specified using the `Path` parameter.

    .PARAMETER InstanceName
        Specifies the name of the Reporting Services instance. This is typically
        'SSRS' for SQL Server Reporting Services or 'PBIRS' for Power BI Report
        Server. This parameter is mandatory when not passing a configuration object
        or a direct path.

    .PARAMETER SetupConfiguration
        Specifies the configuration object from `Get-SqlDscRSSetupConfiguration`.
        This can be piped from `Get-SqlDscRSSetupConfiguration`. The object must
        have a `ConfigFilePath` property containing the path to the configuration
        file. This parameter accepts pipeline input.

    .PARAMETER Path
        Specifies the direct path to the RsReportServer.config file. Use this
        parameter to read configuration files from non-standard locations or
        backup copies.

    .EXAMPLE
        Get-SqlDscRSConfigFile -InstanceName 'SSRS'

        Returns the rsreportserver.config file content as an XML object for
        the SSRS instance.

    .EXAMPLE
        Get-SqlDscRSConfigFile -InstanceName 'PBIRS'

        Returns the rsreportserver.config file content as an XML object for
        the Power BI Report Server instance.

    .EXAMPLE
        Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' | Get-SqlDscRSConfigFile

        Gets the setup configuration for SSRS and pipes it to Get-SqlDscRSConfigFile
        to retrieve the configuration file as XML.

    .EXAMPLE
        Get-SqlDscRSConfigFile -Path 'C:\Backup\rsreportserver.config'

        Reads the configuration file from the specified path.

    .EXAMPLE
        $config = Get-SqlDscRSConfigFile -InstanceName 'SSRS'
        $config.Configuration.Service.IsSchedulingService

        Gets the config file and accesses the scheduling service setting directly
        using dot notation.

    .EXAMPLE
        $config = Get-SqlDscRSConfigFile -InstanceName 'SSRS'
        $config.SelectSingleNode('//Authentication/AuthenticationTypes')

        Uses XPath to query the authentication types configuration section.

    .EXAMPLE
        $config = Get-SqlDscRSConfigFile -InstanceName 'SSRS'
        $config.SelectNodes('//Extension[@Name]') | ForEach-Object { $_.Name }

        Uses XPath to list all extension names defined in the configuration.

    .EXAMPLE
        $config = Get-SqlDscRSConfigFile -InstanceName 'SSRS'
        $config.Configuration.URLReservations.Application |
            Where-Object { $_.Name -eq 'ReportServerWebService' } |
            Select-Object -ExpandProperty URLs

        Gets the URL reservations for the Report Server Web Service application.

    .EXAMPLE
        $config = Get-SqlDscRSConfigFile -InstanceName 'SSRS'
        $smtpServer = $config.SelectSingleNode('//RSEmailDPConfiguration/SMTPServer')
        if ($smtpServer) { $smtpServer.InnerText }

        Uses XPath to retrieve the SMTP server configuration for email delivery.

    .INPUTS
        `System.Object`

        Accepts the setup configuration object from `Get-SqlDscRSSetupConfiguration` via
        pipeline.

    .OUTPUTS
        `System.Xml.XmlDocument`

        Returns the configuration file content as an XML document object.

    .NOTES
        For more information about the RsReportServer.config configuration file,
        see the Microsoft documentation:
        https://learn.microsoft.com/en-us/sql/reporting-services/report-server/rsreportserver-config-configuration-file
#>
function Get-SqlDscRSConfigFile
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input and XPath the rule cannot validate.')]
    [CmdletBinding(DefaultParameterSetName = 'ByInstanceName')]
    [OutputType([System.Xml.XmlDocument])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByInstanceName')]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByConfiguration')]
        [System.Object]
        $SetupConfiguration,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [System.String]
        $Path
    )

    process
    {
        $configFilePath = $null

        switch ($PSCmdlet.ParameterSetName)
        {
            'ByInstanceName'
            {
                Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfigFile_GettingConfigFile -f $InstanceName)

                $setupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName $InstanceName

                if (-not $setupConfiguration)
                {
                    $errorMessage = $script:localizedData.Get_SqlDscRSConfigFile_InstanceNotFound -f $InstanceName

                    $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSCF0001' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }

                if ([System.String]::IsNullOrEmpty($setupConfiguration.ConfigFilePath))
                {
                    $errorMessage = $script:localizedData.Get_SqlDscRSConfigFile_ConfigFilePathNotFound -f $InstanceName

                    $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSCF0002' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }

                $configFilePath = $setupConfiguration.ConfigFilePath
            }

            'ByConfiguration'
            {
                Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfigFile_GettingConfigFile -f $SetupConfiguration.InstanceName)

                if ([System.String]::IsNullOrEmpty($SetupConfiguration.ConfigFilePath))
                {
                    $errorMessage = $script:localizedData.Get_SqlDscRSConfigFile_ConfigFilePathNotFound -f $SetupConfiguration.InstanceName

                    $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSCF0002' -ErrorCategory 'ObjectNotFound' -TargetObject $SetupConfiguration.InstanceName

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }

                $configFilePath = $SetupConfiguration.ConfigFilePath
            }

            'ByPath'
            {
                Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfigFile_ReadingFromPath -f $Path)

                if (-not (Test-Path -Path $Path -PathType 'Leaf'))
                {
                    $errorMessage = $script:localizedData.Get_SqlDscRSConfigFile_FileNotFound -f $Path

                    $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSCF0004' -ErrorCategory 'ObjectNotFound' -TargetObject $Path

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }

                $configFilePath = $Path
            }
        }

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfigFile_FoundConfigFile -f $configFilePath)

        try
        {
            [xml] $configXml = Get-Content -Path $configFilePath -ErrorAction 'Stop'
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfigFile_FailedToReadConfigFile -f $configFilePath, $_.Exception.Message

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -ErrorRecord $_ -PassThru) -ErrorId 'GSRSCF0003' -ErrorCategory 'ReadError' -TargetObject $configFilePath

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        return $configXml
    }
}
