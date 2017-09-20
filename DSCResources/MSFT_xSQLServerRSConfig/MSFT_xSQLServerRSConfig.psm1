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
        $reportingServicesConfiguration = $reportingServicesConfiguration | Where-Object -FilterScript {
            $_.InstanceName -eq $InstanceName
        }

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
        if (-not $isInitialized)
        {
            <#
                Make sure the value returned is false, if the value returned was
                either empty, $null or $false. Fic for issue #822.
            #>
            [System.Boolean] $isInitialized = $false
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType SSRSNotFound -FormatArgs @($InstanceName) -ErrorCategory ObjectNotFound
    }

    $returnValue = @{
        InstanceName      = $InstanceName
        RSSQLServer       = $RSSQLServer
        RSSQLInstanceName = $RSSQLInstanceName
        IsInitialized     = $isInitialized
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

    if ( Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName -ErrorAction SilentlyContinue )
    {
        <#
            Import-SQLPSModule cmdlet will import SQLPS (SQL 2012/14) or SqlServer module (SQL 2016),
            and if importing SQLPS, change directory back to the original one, since SQLPS changes the
            current directory to SQLSERVER:\ on import.
        #>
        Import-SQLPSModule

        $instanceId = (Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName).$InstanceName
        $sqlVersion = [System.Int32]((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup" -Name 'Version').Version).Split('.')[0]

        if ( $InstanceName -eq 'MSSQLSERVER' )
        {
            $reportingServicesServiceName = 'ReportServer'
            $reportServerVirtualDirectoryName = 'ReportServer'
            $reportsVirtualDirectoryName = 'Reports'
            $reportingServicesDatabaseName = 'ReportServer'
        }
        else
        {
            $reportingServicesServiceName = "ReportServer`$$InstanceName"
            $reportServerVirtualDirectoryName = "ReportServer_$InstanceName"
            $reportsVirtualDirectoryName = "Reports_$InstanceName"
            $reportingServicesDatabaseName = "ReportServer`$$InstanceName"
        }

        if ( $RSSQLInstanceName -eq 'MSSQLSERVER' )
        {
            $reportingServicesConnection = $RSSQLServer
        }
        else
        {
            $reportingServicesConnection = "$RSSQLServer\$RSSQLInstanceName"
        }

        $language = (Get-WMIObject -Class Win32_OperatingSystem -Namespace root/cimv2 -ErrorAction SilentlyContinue).OSLanguage
        $reportingServicesConfiguration = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$InstanceName\v$sqlVersion\Admin"
        $reportingServicesConfiguration = $reportingServicesConfiguration | Where-Object -FilterScript {
            $_.InstanceName -eq $InstanceName
        }

        if ( $reportingServicesConfiguration.VirtualDirectoryReportServer -ne $reportServerVirtualDirectoryName )
        {
            $null = $reportingServicesConfiguration.SetVirtualDirectory('ReportServerWebService', $reportServerVirtualDirectoryName, $language)
            $null = $reportingServicesConfiguration.ReserveURL('ReportServerWebService', 'http://+:80', $language)
        }

        if ( $reportingServicesConfiguration.VirtualDirectoryReportManager -ne $reportsVirtualDirectoryName )
        {
            <#
                SSRS Web Portal application name changed in SQL Server 2016
                https://docs.microsoft.com/en-us/sql/reporting-services/breaking-changes-in-sql-server-reporting-services-in-sql-server-2016
            #>
            if ($sqlVersion -ge 13)
            {
                $virtualDirectoryName = 'ReportServerWebApp'
            }
            else
            {
                $virtualDirectoryName = 'ReportManager'
            }

            $null = $reportingServicesConfiguration.SetVirtualDirectory($virtualDirectoryName, $reportsVirtualDirectoryName, $language)
            $null = $reportingServicesConfiguration.ReserveURL($virtualDirectoryName, 'http://+:80', $language)
        }

        $reportingServicesDatabaseScript = $reportingServicesConfiguration.GenerateDatabaseCreationScript($reportingServicesDatabaseName, $language, $false)

        # Determine RS service account
        $reportingServicesServiceAccountUserName = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $reportingServicesServiceName}).StartName
        $reportingServicesDatabaseRightsScript = $reportingServicesConfiguration.GenerateDatabaseRightsScript($reportingServicesServiceAccountUserName, $reportingServicesDatabaseName, $false, $true)

        Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseScript.Script
        Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseRightsScript.Script
        $null = $reportingServicesConfiguration.SetDatabaseConnection($reportingServicesConnection, $reportingServicesDatabaseName, 2, '', '')
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
