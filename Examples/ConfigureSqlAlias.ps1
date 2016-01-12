configuration ContosoSqlAliasConfig
{
    param ()

    Import-DscResource -ModuleName xSQLServer;

    node $AllNodes.NodeName
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndMonitor';

            RebootNodeIfNeeded = $true;
        }

        
        xSqlAlias Config_SqlAlias1
        {
            Ensure = 'Present';
            SQLServerName = 'SQLProd';
            Protocol = 'tcp';
            ServerName = 'sqlnode01.contoso.com';
            TCPPort = 52001;
        };


        xSqlAlias Config_SqlAliasNP
        {
            Ensure = 'Absent';
            SQLServerName = 'SQLProdNP';
            Protocol = 'np';
            ServerName = 'localhost';
        };

    }
}

$ConfigData=    @{
    AllNodes = @(    
        @{ 
            # The name of the node we are describing
            NodeName = "localhost"
        };
    );   
} 

Set-Location 'C:\dscconfig';

ContosoSqlAliasConfig -ConfigurationData $ConfigData -OutputPath .\Mof;

Start-DscConfiguration -Path .\Mof -ComputerName localhost -Wait -Verbose

