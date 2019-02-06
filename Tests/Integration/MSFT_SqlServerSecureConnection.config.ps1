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
                NodeName        = 'localhost'

                ServiceAccount  = "$env:COMPUTERNAME\svc-SqlPrimary"

                ServerName      = $env:COMPUTERNAME
                InstanceName    = 'DSCSQL2016'

                Thumbprint      = $env:SqlCertificateThumbprint

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

Configuration MSFT_SqlServerSecureConnection_AddSecureConnection_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerSecureConnection 'Integration_Test'
        {
            InstanceName = $Node.InstanceName
            Ensure = 'Present'
            Thumbprint = $Node.Thumbprint
            ServiceAccount = $Node.ServiceAccount
            ForceEncryption = $true
        }
    }
}

Configuration MSFT_SqlServerSecureConnection_RemoveSecureConnection_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerSecureConnection 'Integration_Test'
        {
            InstanceName = $Node.InstanceName
            Ensure = 'Absent'
            Thumbprint = ''
            ServiceAccount = $Node.ServiceAccount
        }
    }
}
