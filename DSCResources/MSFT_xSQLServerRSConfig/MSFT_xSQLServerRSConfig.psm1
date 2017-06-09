Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force



<#
    .SYNOPSIS
    Gets the SQL Reporting Services initialization status.

    .PARAMETER InstanceName
    Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER RSSQLServer
    Name of the SQL Server to host the Reporting Service database.

    .PARAMETER RSSQLInstanceName
    Name of the SQL Server instance to host the Reporting Service database.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName
    )

    $instanceNamesRegistryKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

    if ( Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName -ErrorAction SilentlyContinue )
    {
        $instanceId = (Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName).$InstanceName
        $sqlVersion = ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup" -Name 'Version').Version).Split('.')[0]

        $reportingServicesConfiguration = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$InstanceName\v$sqlVersion\Admin"
        if ( $reportingServicesConfiguration.DatabaseServerName.Contains('\') )
        {
            $RSSQLServer = $reportingServicesConfiguration.DatabaseServerName.Split('\')[0]
            $RSSQLInstanceName = $reportingServicesConfiguration.DatabaseServerName.Split('\')[1]
        }
        else
        {
            $RSSQLServer = $reportingServicesConfiguration.DatabaseServerName
            $RSSQLInstanceName = 'MSSQLSERVER'
        }

        $isInitialized = $reportingServicesConfiguration.IsInitialized
    }
    else
    {
        throw New-TerminatingError -ErrorType SSRSNotFound -FormatArgs @($InstanceName) -ErrorCategory ObjectNotFound
    }

    $returnValue = @{
        InstanceName = $InstanceName
        RSSQLServer = $RSSQLServer
        RSSQLInstanceName = $RSSQLInstanceName
        IsInitialized = $isInitialized
    }

    $returnValue
}

<#
    .SYNOPSIS
    Initializes SQL Reporting Services.

    .PARAMETER InstanceName
    Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER RSSQLServer
    Name of the SQL Server to host the Reporting Service database.

    .PARAMETER RSSQLInstanceName
    Name of the SQL Server instance to host the Reporting Service database.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName
    )

    $instanceNamesRegistryKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

    if ( Get-ItemProperty -Path  -Name $InstanceName -ErrorAction SilentlyContinue )
    {
        # smart import of the SQL module
        Import-SQLPSModule

        $instanceId = (Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName).$InstanceName
        $sqlVersion = [System.Int32]((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup" -Name 'Version').Version).Split('.')[0]

        if ( $InstanceName -eq 'MSSQLSERVER' )
        {
            $RSServiceName = 'ReportServer'
            $RSVirtualDirectory = 'ReportServer'
            $RMVirtualDirectory = 'Reports'
            $RSDatabase = 'ReportServer'
        }
        else
        {
            $RSServiceName = "ReportServer`$$InstanceName"
            $RSVirtualDirectory = "ReportServer_$InstanceName"
            $RMVirtualDirectory = "Reports_$InstanceName"
            $RSDatabase = "ReportServer`$$InstanceName"
        }

        if ( $RSSQLInstanceName -eq 'MSSQLSERVER' )
        {
            $reportingServicesConnnection = "$RSSQLServer"
        }
        else
        {
            $reportingServicesConnnection = "$RSSQLServer\$RSSQLInstanceName"
        }

        $language = (Get-WMIObject -Class Win32_OperatingSystem -Namespace root/cimv2 -ErrorAction SilentlyContinue).OSLanguage
        $reportingServicesConfiguration = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$InstanceName\v$sqlVersion\Admin"

        if ( $reportingServicesConfiguration.VirtualDirectoryReportServer -ne $RSVirtualDirectory )
        {
            $null = $reportingServicesConfiguration.SetVirtualDirectory('ReportServerWebService',$RSVirtualDirectory,$language)
            $null = $reportingServicesConfiguration.ReserveURL('ReportServerWebService','http://+:80',$language)
        }

        if ( $reportingServicesConfiguration.VirtualDirectoryReportManager -ne $RMVirtualDirectory )
        {
            # SSRS Web Portal application name changed in SQL Server 2016
            # https://docs.microsoft.com/en-us/sql/reporting-services/breaking-changes-in-sql-server-reporting-services-in-sql-server-2016
            $virtualDirectoryName = if ($sqlVersion -ge 13) { 'ReportServerWebApp' } else { 'ReportManager'}
            $null = $reportingServicesConfiguration.SetVirtualDirectory($virtualDirectoryName,$RMVirtualDirectory,$language)
            $null = $reportingServicesConfiguration.ReserveURL($virtualDirectoryName,'http://+:80',$language)
        }

        $RSCreateScript = $reportingServicesConfiguration.GenerateDatabaseCreationScript($RSDatabase,$language,$false)

        # Determine RS service account
        $RSSvcAccountUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $RSServiceName}).StartName
        $RSRightsScript = $reportingServicesConfiguration.GenerateDatabaseRightsScript($RSSvcAccountUsername,$RSDatabase,$false,$true)

        Invoke-Sqlcmd -ServerInstance $reportingServicesConnnection -Query $RSCreateScript.Script
        Invoke-Sqlcmd -ServerInstance $reportingServicesConnnection -Query $RSRightsScript.Script
        $null = $reportingServicesConfiguration.SetDatabaseConnection($reportingServicesConnnection,$RSDatabase,2,'','')
        $null = $reportingServicesConfiguration.InitializeReportServer($reportingServicesConfiguration.InstallationID)
    }

    if ( !(Test-TargetResource @PSBoundParameters) )
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    Tests the SQL Reporting Services initialization status.

    .PARAMETER InstanceName
    Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER RSSQLServer
    Name of the SQL Server to host the Reporting Service database.

    .PARAMETER RSSQLInstanceName
    Name of the SQL Server instance to host the Reporting Service database.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName
    )

    $result = (Get-TargetResource @PSBoundParameters).IsInitialized

    $result
}

Export-ModuleMember -Function *-TargetResource
