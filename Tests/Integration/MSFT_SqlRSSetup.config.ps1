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
                NodeName           = 'localhost'
                InstanceName       = 'SSRS'
                IAcceptLicensTerms = 'Yes'
                SourcePath         = Join-Path -Path $env:TEMP -ChildPath 'SQLServerReportingServices.exe'
                Edition            = 'Development'

                UserName           = "$env:COMPUTERNAME\SqlInstall"
                Password           = 'P@ssw0rd1'

                CertificateFile    = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Installs a Microsoft SQL Server 2017 Reporting Services.
#>
Configuration MSFT_SqlSetup_InstallReportingServicesAsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRSSetup 'Integration_Test'
        {
            InstanceName         = $Node.InstanceName
            IAcceptLicensTerms   = $Node.IAcceptLicensTerms
            SourcePath           = $Node.SourcePath
            Edition              = $Node.Edition

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
