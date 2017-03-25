<#
.EXAMPLE
    This example shows how to install a named instance of SQL Server on a single server, from an UNC path.
.NOTES
    For this to work the credentials assigned to SourceCredential must have read permission on the share and on the UNC path.
#>
Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PsCredential]$SqlInstallCredential,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [PsCredential]$SqlAdministratorCredential = $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PsCredential]$SqlServiceCredential,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [PsCredential]$SqlAgentServiceCredential = $SqlServiceCredential
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

        xSQLServerSetup 'InstallNamedInstance-INST2016'
        {
            InstanceName = 'INST2016'
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
            InstallSQLDataDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data"
            SQLUserDBDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data\User"
            SQLUserDBLogDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data\User"
            SQLTempDBDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data\Temp"
            SQLTempDBLogDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data\Temp"
            SQLBackupDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data\Backup"
            SourcePath = '\\fileserver.compant.local\images$\SQL2016RTM'
            SourceCredential = $SqlInstallCredential
            UpdateEnabled = 'False'
            ForceReboot = $false
            BrowserSvcStartupType = 'Automatic'

            DependsOn = '[WindowsFeature]NetFramework35','[WindowsFeature]NetFramework45'
        }
    }
}
