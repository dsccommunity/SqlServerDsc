# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            ServerName                  = $env:COMPUTERNAME
            DefaultInstanceName         = 'MSSQLSERVER'
            NamedInstanceName           = 'DSCSQL2016'

            ServiceTypeDatabaseEngine   = 'DatabaseEngine'
            ServiceTypeSqlServerAgent   = 'SQLServerAgent'

            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration MSFT_SqlServiceAccount_DatabaseEngine_DefaultInstance_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceSecondaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        <#
            Run this test as SYSTEM.
        #>
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.DefaultInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            ServiceAccount = $ServiceAccountCredential
            RestartService = $true
        }
    }
}

Configuration MSFT_SqlServiceAccount_SqlServerAgent_DefaultInstance_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceSecondaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        <#
            Run this test as $SqlInstallCredential.
        #>
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.DefaultInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            ServiceAccount       = $SqlAgentServiceSecondaryCredential
            RestartService       = $true

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

Configuration MSFT_SqlServiceAccount_DatabaseEngine_DefaultInstance_Restore_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        <#
            Run this test as SYSTEM.
        #>
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.DefaultInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            ServiceAccount = $SqlServicePrimaryCredential
            RestartService = $true
        }
    }
}

Configuration MSFT_SqlServiceAccount_SqlServerAgent_DefaultInstance_Restore_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        <#
            Run this test as $SqlInstallCredential.
        #>
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.DefaultInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            ServiceAccount       = $SqlAgentServicePrimaryCredential
            RestartService       = $true

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}
