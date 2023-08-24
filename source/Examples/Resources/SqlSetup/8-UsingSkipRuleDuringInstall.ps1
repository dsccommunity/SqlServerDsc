<#
    .DESCRIPTION
        This example shows how to ad skip rules to setup.exe.

    .NOTES
        Using skip rules is not recommended in a production environment.
#>
Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential = $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceCredential = $SqlServiceCredential
    )

    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        #region Install prerequisites for SQL Server
        WindowsFeature 'NetFramework35'
        {
            Name   = 'NET-Framework-Core'
            Source = '\\fileserver.company.local\images$\Win2k12R2\Sources\Sxs' # Assumes built-in Everyone has read permission to the share and path.
            Ensure = 'Present'
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
        #endregion Install prerequisites for SQL Server

        #region Install SQL Server Failover Cluster
        SqlSetup 'InstallNamedInstanceNode1-INST2016'
        {
            Action                     = 'InstallFailoverCluster'
            ForceReboot                = $false
            UpdateEnabled              = 'False'
            SourcePath                 = '\\fileserver.company.local\images$\SQL2016RTM'
            SourceCredential           = $SqlInstallCredential

            InstanceName               = 'INST2016'
            Features                   = 'SQLENGINE'

            InstallSharedDir           = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir        = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir                = 'C:\Program Files\Microsoft SQL Server'

            SQLCollation               = 'Finnish_Swedish_CI_AS'
            SQLSvcAccount              = $SqlServiceCredential
            AgtSvcAccount              = $SqlAgentServiceCredential
            SQLSysAdminAccounts        = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName

            # Drive D: must be a shared disk.
            InstallSQLDataDir          = 'D:\MSSQL\Data'
            SQLUserDBDir               = 'D:\MSSQL\Data'
            SQLUserDBLogDir            = 'D:\MSSQL\Log'
            SQLTempDBDir               = 'D:\MSSQL\Temp'
            SQLTempDBLogDir            = 'D:\MSSQL\Temp'
            SQLBackupDir               = 'D:\MSSQL\Backup'

            FailoverClusterNetworkName = 'TESTCLU01A'
            FailoverClusterIPAddress   = '192.168.0.46'
            FailoverClusterGroupName   = 'TESTCLU01A'

            # Not recommended to use in production.
            SkipRule                   = 'Cluster_VerifyForErrors'

            PsDscRunAsCredential       = $SqlInstallCredential

            DependsOn                  = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45'
        }
        #region Install SQL Server Failover Cluster
    }
}
