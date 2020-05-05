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
                NodeName            = 'localhost'

                UserName            = "$env:COMPUTERNAME\SqlInstall"
                Password            = 'P@ssw0rd1'

                DefaultInstanceName = 'MSSQLSERVER'
                InstanceName        = 'DSCSQLTEST'

                CertificateFile     = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Starting the default instance because it is a prerequisites.
#>
Configuration DSC_SqlServerReplication_StartSqlServerDefaultInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'

    node $AllNodes.NodeName
    {
        Service ('StopSqlServerInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = $Node.DefaultInstanceName
            State = 'Running'
        }

        Service ('StopSqlServerAgentForInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Running'
        }
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
            RemoteDistributor    = ('{0}' -f $env:COMPUTERNAME)
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
        Stopping the default instance to save memory on the build worker.
#>
Configuration DSC_SqlServerReplication_StopSqlServerDefaultInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'

    node $AllNodes.NodeName
    {
        Service ('StopSqlServerAgentForInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Stopped'
        }

        Service ('StopSqlServerInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = $Node.DefaultInstanceName
            State = 'Stopped'
        }
    }
}
