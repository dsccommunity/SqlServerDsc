#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion


$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName             = 'localhost'
            ServerName           = $env:COMPUTERNAME
            InstanceName         = 'DSCSQL2016'

            EndpointName         = 'HADR'
            Port                 = 5023
            IpAddress            = '10.10.10.10'
            Owner                = 'sa'

            CertificateFile      = $env:DscPublicCertificatePath
        }
    )
}

<#
    .SYNOPSIS
        Configuration to ensure present and specify all the parameters
#>
Configuration MSFT_SqlServerEndpoint_Add_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlServerEndpoint Integration_Test
        {
            Ensure               = 'Present'

            EndpointName         = $Node.EndpointName
            Port                 = $Node.Port
            IpAddress            = $Node.IpAddress
			#Owner                = $Node.Owner ## NOT UNCOMMENT WHEN ISSUE 1251 FIXED

            ServerName           = $Node.ServerName
			InstanceName         = $Node.InstanceName
        }
    }
}

<#
    .SYNOPSIS
        Configuration to ensure Absent and specify all the parameters
#>
Configuration MSFT_SqlServerEndpoint_Remove_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlServerEndpoint Integration_Test
        {
            Ensure               = 'Absent'

            EndpointName         = $Node.EndpointName

            ServerName           = $Node.ServerName
			InstanceName         = $Node.InstanceName
        }
    }
}


