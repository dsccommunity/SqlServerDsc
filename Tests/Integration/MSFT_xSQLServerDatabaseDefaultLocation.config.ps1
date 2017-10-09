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
            Checksum        = 'SHA-256'
            DestinationPath = $Node.DataFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        xSQLServerDatabaseDefaultLocation 'Integration_Test'
        {
            DefaultLocationType  = 'Data'
            DefaultLocationPath  = $Node.DataFilePath
            RestartService       = $true
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
            Checksum        = 'SHA-256'
            DestinationPath = $Node.LogFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        xSQLServerDatabaseDefaultLocation 'Integration_Test'
        {
            DefaultLocationType  = 'Log'
            DefaultLocationPath  = $Node.LogFilePath
            RestartService       = $true
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
            Checksum        = 'SHA-256'
            DestinationPath = $Node.BackupFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        xSQLServerDatabaseDefaultLocation 'Integration_Test'
        {
            DefaultLocationType  = 'Backup'
            DefaultLocationPath  = $Node.BackupFilePath
            RestartService       = $true
            SQLServer            = $Node.ComputerName
            SQLInstanceName      = $Node.InstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn = '[File]SQLBackupPath'
        }
    }
}
