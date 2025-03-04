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

                InstanceName    = 'DSCSQLTEST'
                SourcePath      = '{0}:\' -f $env:IsoDriveLetter

                # Properties for mounting media
                ImagePath       = $env:IsoImagePath
                DriveLetter     = $env:IsoDriveLetter

                Thumbprint      = $env:SqlCertificateThumbprint

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Setting up the dependencies to test firewall rules.
#>
Configuration DSC_SqlWindowsFirewall_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'StorageDsc' -ModuleVersion '5.1.0'

    node $AllNodes.NodeName
    {
        MountImage 'MountIsoMedia'
        {
            ImagePath   = $Node.ImagePath
            DriveLetter = $Node.DriveLetter
            Ensure      = 'Present'
        }

        WaitForVolume 'WaitForMountOfIsoMedia'
        {
            DriveLetter      = $Node.DriveLetter
            RetryIntervalSec = 5
            RetryCount       = 10
        }
    }
}
<#
    .SYNOPSIS
        Enable firewall rules for Database Engine.
#>
Configuration DSC_SqlWindowsFirewall_SetFirewallRules_SQLENGINE_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlWindowsFirewall 'Integration_Test'
        {
            Ensure = 'Present'
            InstanceName = $Node.InstanceName
            Features = 'SQLENGINE'
            SourcePath = $Node.SourcePath
        }
    }
}
