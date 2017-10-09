# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            ComputerName                = $env:COMPUTERNAME
            InstanceName                = 'DSCSQL2016'
            RestartTimeout              = 120

            PSDscAllowPlainTextPassword = $true

            DataFilePath                = 'C:\SQLData'
            LogFilePath                 = 'C:\SQLLog'
            BackupFilePath              = 'C:\Backups'
        }
    )
}

Configuration MSFT_xSQLServerDatabaseDefaultLocation_Data_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xSQLServer'

    node localhost {
        File 'SQLDataPath'
        {
            DestinationPath = $Node.DataFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        xSQLServerDatabaseDefaultLocation 'Integration_Test'
        {
            DefaultLocationType  = 'Data'
            DefaultLocationPath  = $Node.DataFilePath
            SQLServer            = $Node.ComputerName
            SQLInstanceName      = $Node.InstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn = '[File]SQLDataPath'
        }
    }
}

Configuration MSFT_xSQLServerDatabaseDefaultLocation_Log_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xSQLServer'

    node localhost {
        File 'SQLLogPath'
        {
            DestinationPath = $Node.LogFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        xSQLServerDatabaseDefaultLocation 'Integration_Test'
        {
            DefaultLocationType  = 'Log'
            DefaultLocationPath  = $Node.LogFilePath
            SQLServer            = $Node.ComputerName
            SQLInstanceName      = $Node.InstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn = '[File]SQLLogPath'
        }
    }
}

Configuration MSFT_xSQLServerDatabaseDefaultLocation_Backup_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xSQLServer'

    node localhost {
        File 'SQLBackupPath'
        {
            DestinationPath = $Node.BackupFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        xSQLServerDatabaseDefaultLocation 'Integration_Test'
        {
            DefaultLocationType  = 'Backup'
            DefaultLocationPath  = $Node.BackupFilePath
            SQLServer            = $Node.ComputerName
            SQLInstanceName      = $Node.InstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn = '[File]SQLBackupPath'
        }
    }
}
