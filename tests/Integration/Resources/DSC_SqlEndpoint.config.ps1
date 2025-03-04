#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                   = 'localhost'
                ServerName                 = $env:COMPUTERNAME
                InstanceName               = 'DSCSQLTEST'

                EndpointName               = 'HADR'
                Port                       = 5022
                SsbrPort                   = 5023
                IpAddress                  = '0.0.0.0'
                Owner                      = 'sa'

                CertificateFile            = $env:DscPublicCertificatePath

                SsbrEndpointName           = 'Ssbr'
                IsMessageForwardingEnabled = $true
                MessageForwardingSize      = 2
            }
        )
    }
}

<#
    .SYNOPSIS
        Configuration to ensure present and specify all the parameters
#>
Configuration DSC_SqlEndpoint_Add_HADR_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlEndpoint 'Integration_Test'
        {
            Ensure               = 'Present'

            EndpointName         = $Node.EndpointName
            EndpointType         = 'DatabaseMirroring'
            Port                 = $Node.Port
            IpAddress            = $Node.IpAddress
            Owner                = $Node.Owner
            State                = 'Started'

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
        }
    }
}

<#
    .SYNOPSIS
        Configuration to ensure Absent and specify all the parameters
#>
Configuration DSC_SqlEndpoint_Remove_HADR_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlEndpoint 'Integration_Test'
        {
            Ensure               = 'Absent'

            EndpointName         = $Node.EndpointName
            EndpointType         = 'DatabaseMirroring'

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
        }
    }
}

<#
    .SYNOPSIS
        Configuration to ensure present and specify all the parameters
#>
Configuration DSC_SqlEndpoint_Add_ServiceBroker_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlEndpoint 'Integration_Test'
        {
            Ensure                  = 'Present'

            EndpointName            = $Node.SsbrEndpointName
            EndpointType            = 'ServiceBroker'
            Port                    = $Node.SsbrPort
            IpAddress               = $Node.IpAddress
            Owner                   = $Node.Owner
            State                   = 'Started'

            InstanceName            = $Node.InstanceName
            ServerName              = $Node.ServerName

            IsMessageForwardingEnabled = $Node.IsMessageForwardingEnabled
            MessageForwardingSize   = $Node.MessageForwardingSize
        }
    }
}

<#
    .SYNOPSIS
        Configuration to ensure Absent and specify all the parameters
#>
Configuration DSC_SqlEndpoint_Remove_ServiceBroker_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlEndpoint 'Integration_Test'
        {
            Ensure               = 'Absent'

            EndpointName         = $Node.SsbrEndpointName
            EndpointType         = 'ServiceBroker'

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
        }
    }
}
