<#
    .SYNOPSIS
        Gets the log file path for SQL Server Reporting Services or Power BI
        Report Server.

    .DESCRIPTION
        Gets the log file folder path for SQL Server Reporting Services (SSRS)
        or Power BI Report Server (PBIRS). The returned path is the ErrorDumpDirectory
        from the instance's setup configuration, which contains the LogFiles folder
        where service logs, portal logs, and memory dumps are stored.

        The returned path can be used with `Get-ChildItem` and `Get-Content` to
        access and read the log files.

        Common log file types in this folder:
        - ReportingServicesService*.log - Web service activity logs
        - RSPortal*.log - Portal access and activity logs
        - SQLDumpr*.mdmp - Memory dumps for error analysis

    .PARAMETER InstanceName
        Specifies the name of the Reporting Services instance. This is typically
        'SSRS' for SQL Server Reporting Services or 'PBIRS' for Power BI Report
        Server. This parameter is mandatory when not passing a configuration object.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .EXAMPLE
        Get-SqlDscRSLogPath -InstanceName 'SSRS'

        Returns the log file folder path for the SQL Server Reporting Services
        instance 'SSRS'.

    .EXAMPLE
        Get-SqlDscRSLogPath -InstanceName 'PBIRS'

        Returns the log file folder path for the Power BI Report Server
        instance 'PBIRS'.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSLogPath

        Gets the configuration for SSRS and pipes it to Get-SqlDscRSLogPath to
        retrieve the log folder path.

    .EXAMPLE
        Get-SqlDscRSLogPath -InstanceName 'SSRS' | Get-ChildItem -Filter '*.log'

        Gets the log path for SSRS and lists all .log files in that folder.

    .EXAMPLE
        $logPath = Get-SqlDscRSLogPath -InstanceName 'SSRS'
        Get-ChildItem -Path $logPath -Filter 'ReportingServicesService*.log' |
            Sort-Object -Property LastWriteTime -Descending |
            Select-Object -First 1 |
            Get-Content -Tail 100

        Gets the most recent web service log file and displays the last 100 lines.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.String`

        Returns the path to the log files folder for the specified Reporting
        Services instance.
#>
function Get-SqlDscRSLogPath
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(DefaultParameterSetName = 'ByInstanceName')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByInstanceName')]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByConfiguration')]
        [System.Object]
        $Configuration
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByConfiguration')
        {
            $InstanceName = $Configuration.InstanceName
        }

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSLogPath_GettingPath -f $InstanceName)

        $setupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName $InstanceName

        if (-not $setupConfiguration)
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSLogPath_InstanceNotFound -f $InstanceName

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSLP0001' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        if ([System.String]::IsNullOrEmpty($setupConfiguration.ErrorDumpDirectory))
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSLogPath_LogPathNotFound -f $InstanceName

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSLP0002' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSLogPath_FoundPath -f $setupConfiguration.ErrorDumpDirectory)

        return $setupConfiguration.ErrorDumpDirectory
    }
}
