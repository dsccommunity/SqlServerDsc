<#
    .EXAMPLE
        This example shows how to install a default instance of SQL Server on a single server.
    .NOTES
        SQL Server setup.exe is run using the SYSTEM account. Even if SetupCredential is provided
        it is not used to install SQL Server at this time (see issue #139).
#>
Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $SqlInstallCredential,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [PsCredential] $SqlAdministratorCredential = $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $SqlServiceCredential,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [PsCredential] $SqlAgentServiceCredential = $SqlServiceCredential
    )

    Import-DscResource -ModuleName xSQLServer

    node localhost
    {
        #region Install prerequisites for SQL Server
        WindowsFeature 'NetFramework35' {
           Name = 'NET-Framework-Core'
           Source = $node.WindowsSourceSxs
           Ensure = 'Present'
        }

        WindowsFeature 'NetFramework45' {
           Name = 'NET-Framework-45-Core'
           Ensure = 'Present'
        }
        #endregion Install prerequisites for SQL Server

        xSQLServerSetup 'InstallDefaultInstance'
        {
            InstanceName = 'MSSQLSERVER'
            Features = 'SQLENGINE,AS'
            SQLCollation = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount = $SqlServiceCredential
            AgtSvcAccount = $SqlAgentServiceCredential
            ASSvcAccount = $SqlServiceCredential
            SQLSysAdminAccounts = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName
            SetupCredential = $SqlInstallCredential
            InstallSharedDir = "C:\Program Files\Microsoft SQL Server"
            InstallSharedWOWDir = "C:\Program Files (x86)\Microsoft SQL Server"
            InstanceDir = "C:\Program Files\Microsoft SQL Server"
            InstallSQLDataDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data"
            SQLUserDBDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data\User"
            SQLUserDBLogDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data\User"
            SQLTempDBDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data\Temp"
            SQLTempDBLogDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data\Temp"
            SQLBackupDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data\Backup"
            SourcePath = 'C:\InstallMedia\SQL2016RTM'
            UpdateEnabled = 'False'
            ForceReboot = $false

            DependsOn = '[WindowsFeature]NetFramework35','[WindowsFeature]NetFramework45'
        }
    }
}
