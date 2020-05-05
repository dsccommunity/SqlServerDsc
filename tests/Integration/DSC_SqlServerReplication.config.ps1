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

                UserName        = "$env:COMPUTERNAME\SqlInstall"
                Password        = 'P@ssw0rd1'

                InstanceName    = 'DSCSQLTEST'

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Adds the instance as a distributor.
#>
Configuration DSC_SqlServerReplication_AddDistributor_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerReplication 'Integration_Test'
        {
            Ensure               = 'Present'
            InstanceName         = $Node.InstanceName
            DistributorMode      = 'Local'
            DistributionDBName   = 'Database1'
            WorkingDirectory     = 'C:\Temp'

            AdminLinkCredentials = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the instance as a distributor.
#>
Configuration DSC_SqlServerReplication_RemoveDistributor_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerReplication 'Integration_Test'
        {
            Ensure               = 'Absent'
            InstanceName         = $Node.InstanceName
            DistributorMode      = 'Local'

            AdminLinkCredentials = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds the instance as a publisher.
#>
Configuration DSC_SqlServerReplication_AddPublisher_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerReplication 'Integration_Test'
        {
            Ensure               = 'Present'
            InstanceName         = $Node.InstanceName
            DistributorMode      = 'Remote'
            RemoteDistributor    = 'distsqlsrv.company.local'
            WorkingDirectory     = 'C:\Temp'

            AdminLinkCredentials = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the instance as a publisher.
#>
Configuration DSC_SqlServerReplication_RemovePublisher_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerReplication 'Integration_Test'
        {
            Ensure               = 'Absent'
            InstanceName         = $Node.InstanceName
            DistributorMode      = 'Remote'

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
