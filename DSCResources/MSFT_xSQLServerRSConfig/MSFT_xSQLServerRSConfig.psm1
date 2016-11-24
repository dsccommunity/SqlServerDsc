$script:currentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Import-Module -Name (Join-Path -Path (Split-Path -Path (Split-Path -Path $script:currentPath -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1')


<#
    .SYNOPSIS
    Returns the current state of the SQL Server Reporting Services configuration.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingComputerNameHardcoded', '')]
    param
    (
        # Name of the SQL Server Reporting Services instance to be configured.
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        # Name of the SQL Server to host the Reporting Service database.
        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        # Name of the SQL Server instance to host the Reporting Service database.
        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName,

        # Credential to be used to perform the configuration.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SQLAdminCredential
    )

    if ($null -eq (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' -Name $InstanceName -ErrorAction SilentlyContinue))
    {
        throw (New-TerminatingError -ErrorType 'SSRSNotFound' -FormatArgs $InstanceName -ErrorCategory 'ObjectNotFound')
    }


    Write-Verbose "Get the SSRS configuration for $InstanceName"

    $sqlVersion = Get-SqlServerReportingServicesVersion -InstanceName $InstanceName

    # Invoke the WMI query with the SQL admin credentials by using local PowerShell Remoting
    $rsConfig = Invoke-Command -ComputerName 'localhost' -Credential $SQLAdminCredential -ArgumentList $sqlVersion, $InstanceName -ScriptBlock {
        param ($sqlVersion, $instanceName)
        Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$instanceName\v$sqlVersion\Admin"
    }

    # Workaround for the omitted default instance name
    if ($rsConfig.DatabaseServerName.Contains("\"))
    {
        $RSSQLServer       = $rsConfig.DatabaseServerName.Split("\", 2)[0]
        $RSSQLInstanceName = $rsConfig.DatabaseServerName.Split("\", 2)[1]
    }
    else
    {
        $RSSQLServer       = $rsConfig.DatabaseServerName
        $RSSQLInstanceName = "MSSQLSERVER"
    }

    Write-Output @{
        InstanceName                  = $InstanceName
        RSSQLServer                   = $RSSQLServer
        RSSQLInstanceName             = $RSSQLInstanceName
        SQLAdminCredential            = $SQLAdminCredential
        IsInitialized                 = $rsConfig.IsInitialized
        ServiceName                   = $rsConfig.ServiceName
        DatabaseName                  = $rsConfig.DatabaseName
        VirtualDirectoryReportManager = $rsConfig.VirtualDirectoryReportManager
        VirtualDirectoryReportServer  = $rsConfig.VirtualDirectoryReportServer
    }
}


<#
    .SYNOPSIS
    Configures the specified SQL Server Reporting Services instance and create
    the ReportServer database.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingComputerNameHardcoded', '')]
    param
    (
        # Name of the SQL Server Reporting Services instance to be configured.
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        # Name of the SQL Server to host the Reporting Service database.
        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        # Name of the SQL Server instance to host the Reporting Service database.
        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName,

        # Credential to be used to perform the configuration.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SQLAdminCredential
    )

    if ($null -eq (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' -Name $InstanceName -ErrorAction SilentlyContinue))
    {
        throw (New-TerminatingError -ErrorType 'SSRSNotFound' -FormatArgs $InstanceName -ErrorCategory 'ObjectNotFound')
    }

    # Check if CredSSP is enabled for client and server side on the local
    # system. It is required to execute the SQL scripts to create and update the
    # RS database on the remote database engine with the SQL admin credentials.
    if ((Get-Item -Path 'WSMan:\localhost\Client\Auth\CredSSP').Value -ne $true)
    {
        throw (New-TerminatingError -ErrorType 'SSRSPrerequisite' -FormatArgs 'CredSSP Client' -ErrorCategory 'ObjectNotFound')
    }
    if ((Get-Item -Path 'WSMan:\localhost\Service\Auth\CredSSP').Value -ne $true)
    {
        throw (New-TerminatingError -ErrorType 'SSRSPrerequisite' -FormatArgs 'CredSSP Server' -ErrorCategory 'ObjectNotFound')
    }

    if ((Get-Module -Name SQLPS -ListAvailable).Count -eq 0)
    {
        Write-Verbose "Install the 'SQL Server Management Studio' or the 'PowerShell Extensions for SQL Server' on the local system."
        throw (New-TerminatingError -ErrorType 'SSRSPrerequisite' -FormatArgs 'SQLPS PowerShell Module' -ErrorCategory 'ObjectNotFound')
    }


    $sqlVersion       = Get-SqlServerReportingServicesVersion -InstanceName $InstanceName
    $desiredConfig    = Get-SqlServerReportingServicesDesiredConfig -InstanceName $InstanceName
    $language         = (Get-WMIObject -Class Win32_OperatingSystem -Namespace root/cimv2 -ErrorAction SilentlyContinue).OSLanguage
    $rsConnection     = $RSSQLServer + $(if($RSSQLInstanceName -ne "MSSQLSERVER") { "\$RSSQLInstanceName" })
    $helperModulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $script:currentPath -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1'


    Write-Verbose 'Update the report server virutal directory, if required'

    Invoke-Command -ComputerName 'localhost' -Credential $SQLAdminCredential -ArgumentList $sqlVersion, $InstanceName, $desiredConfig.VirtualDirectoryReportServer, $language -ScriptBlock {
        param ($sqlVersion, $instanceName, $virtualDirectory, $language)
        $rsConfig = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$instanceName\v$sqlVersion\Admin"
        if($rsConfig.VirtualDirectoryReportServer -ne $virtualDirectory)
        {
            $rsConfig.SetVirtualDirectory("ReportServerWebService", $virtualDirectory, $language)
            $rsConfig.ReserveURL("ReportServerWebService" ,"http://+:80", $language)
        }
    } | Out-Null


    Write-Verbose 'Update the report manager virutal directory, if required'

    Invoke-Command -ComputerName 'localhost' -Credential $SQLAdminCredential -ArgumentList $sqlVersion, $InstanceName, $desiredConfig.VirtualDirectoryReportManager, $language -ScriptBlock {
        param ($sqlVersion, $instanceName, $virtualDirectory, $language)
        $rsConfig = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$instanceName\v$sqlVersion\Admin"
        if($rsConfig.VirtualDirectoryReportManager -ne $virtualDirectory)
        {
            $virtualDirectoryName = if ($sqlVersion -eq '13') { 'ReportServerWebApp' } else { 'ReportManager'}
            $rsConfig.SetVirtualDirectory($virtualDirectoryName, $virtualDirectory, $language)
            $rsConfig.ReserveURL($virtualDirectoryName, "http://+:80", $language)
        }
    } | Out-Null


    Write-Verbose 'Create the database for the SQL Reporting Service' 

    Invoke-Command -ComputerName 'localhost' -Credential $SQLAdminCredential -Authentication Credssp -ArgumentList $sqlVersion, $InstanceName, $desiredConfig.DatabaseName, $language, $rsConnection, $helperModulePath -ScriptBlock {
        param ($sqlVersion, $instanceName, $databaseName, $language, $rsConnection, $helperModulePath)

        Import-Module $helperModulePath
        Import-SQLPSModule

        $dbCreateFile = [IO.Path]::GetTempFileName()
        $rsConfig = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$instanceName\v$sqlVersion\Admin"
        $rsCreateScript = $RSConfig.GenerateDatabaseCreationScript($databaseName, $language, $false)
        $rsCreateScript.Script | Out-File $dbCreateFile

        Invoke-Sqlcmd -ServerInstance $rsConnection -InputFile $dbCreateFile -Verbose
    } | Out-Null


    Write-Verbose 'Update rights on the database of SQL Reporting Service' 

    $rsSvcAccountUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $desiredConfig.ServiceName}).StartName
    if(($rsSvcAccountUsername -eq "LocalSystem") -or (($rsSvcAccountUsername.Length -ge 10) -and ($rsSvcAccountUsername.SubString(0,10) -eq "NT Service")))
    {
        $rsSvcAccountUsername = $RSConfig.MachineAccountIdentity
    }

    Invoke-Command -ComputerName 'localhost' -Credential $SQLAdminCredential -Authentication Credssp -ArgumentList $sqlVersion, $InstanceName, $desiredConfig.DatabaseName, $rsSvcAccountUsername, $rsConnection, $helperModulePath -ScriptBlock {
        param ($sqlVersion, $instanceName, $databaseName, $rsSvcAccountUsername, $rsConnection, $helperModulePath)

        Import-Module $helperModulePath
        Import-SQLPSModule

        $dbRightsFile = [IO.Path]::GetTempFileName()
        $rsConfig = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$instanceName\v$sqlVersion\Admin"
        $rsRightsScript = $RSConfig.GenerateDatabaseRightsScript($rsSvcAccountUsername, $databaseName, $false, $true)
        $rsRightsScript.Script | Out-File $dbRightsFile

        Invoke-Sqlcmd -ServerInstance $rsConnection -InputFile $dbRightsFile -Verbose
    } | Out-Null


    Write-Verbose 'Update rights on the database of SQL Reporting Service' 

    Invoke-Command -ComputerName 'localhost' -Credential $SQLAdminCredential -ArgumentList $sqlVersion, $InstanceName, $rsConnection, $desiredConfig.DatabaseName -ScriptBlock {
        param ($sqlVersion, $instanceName, $rsConnection, $databaseName)
        $rsConfig = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$instanceName\v$sqlVersion\Admin"
        $rsConfig.SetDatabaseConnection($rsConnection, $databaseName, 2, '', '')
        $rsConfig.InitializeReportServer($rsConfig.InstallationID)
    } | Out-Null


    Write-Verbose "Restart the $($desiredConfig.ServiceName) service to apply the configuration"

    Restart-Service -Name $desiredConfig.ServiceName


    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


<#
    .SYNOPSIS
    Test the current configuration against the desired.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # Name of the SQL Server Reporting Services instance to be configured.
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        # Name of the SQL Server to host the Reporting Service database.
        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        # Name of the SQL Server instance to host the Reporting Service database.
        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName,

        # Credential to be used to perform the configuration.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SQLAdminCredential
    )

    Write-Verbose "Test the SSRS configuration for $InstanceName"

    $actual = Get-TargetResource @PSBoundParameters

    $desired = Get-SqlServerReportingServicesDesiredConfig -InstanceName $InstanceName

    return ($actual.IsInitialized) -and
           ($actual.ServiceName -eq $desired.ServiceName) -and
           ($actual.DatabaseName -eq $desired.DatabaseName) -and
           ($actual.VirtualDirectoryReportManager -eq $desired.VirtualDirectoryReportManager) -and
           ($actual.VirtualDirectoryReportServer -eq $desired.VirtualDirectoryReportServer)
}


<#
    .SYNOPSIS
    Helper function to return the installed SQL reporting service version.
#>
function Get-SqlServerReportingServicesVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # Name of the SQL Server Reporting Services instance.
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    try
    {
        $instanceKey = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' -Name $InstanceName).$InstanceName
        $sqlVersion  = ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup" -Name 'Version').Version).Split('.')[0]

        Write-Output $sqlVersion
    }
    catch
    {
        throw "SQL Version not found: $_"
    }
}


<#
    .SYNOPSIS
    Helper function to return the installed SQL reporting service version.
#>
function Get-SqlServerReportingServicesDesiredConfig
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # Name of the SQL Server Reporting Services instance.
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    if($InstanceName -eq "MSSQLSERVER")
    {
        Write-Output @{
            ServiceName                   = 'ReportServer'
            DatabaseName                  = 'ReportServer'
            VirtualDirectoryReportManager = 'Reports'
            VirtualDirectoryReportServer  = 'ReportServer'
        }
    }
    else
    {
        Write-Output @{
            ServiceName                   = "ReportServer`$$InstanceName"
            DatabaseName                  = "ReportServer`$$InstanceName"
            VirtualDirectoryReportManager = "Reports_$InstanceName"
            VirtualDirectoryReportServer  = "ReportServer_$InstanceName"
        }
    }
}


Export-ModuleMember -Function *-TargetResource
