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

                ServerName       = $env:COMPUTERNAME
                InstanceName    = 'DSCSQLTEST'

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Sets a single trace flag.
#>
Configuration DSC_SqlTraceFlag_SetSingleTraceFlag_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlTraceFlag 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            TraceFlags           = @(2371)
            RestartService       = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Sets multiple trace flags.
#>
Configuration DSC_SqlTraceFlag_SetMultipleTraceFlags_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlTraceFlag 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            TraceFlags           = @(3226, 4199)
            RestartService       = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Excludes one existing trace flag.

    .NOTES
        This test requires that the test *SetMultipleTraceFlags_Config was run
        prior.

        This configuration also run after all trace flags is removed, to test
        that the resource can tst to exclude a trace flag when there are no
        current trace flags.

        It is also run to verify that it can exclude a trace flag and which will
        leave the current state with no trace flags set.
#>
Configuration DSC_SqlTraceFlag_ExcludeOneExistingTraceFlag_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlTraceFlag 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            TraceFlagsToExclude  = @(4199)
            RestartService       = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Include one additional trace flag.

    .NOTES
        This test requires that the test *ExcludeOneExistingTraceFlag_Config was
        run prior.

        This configuration also run after all trace flags is removed, to test
        that the resource can add one additional when there are no current trace
        flags.
#>
Configuration DSC_SqlTraceFlag_IncludeOneAdditionalTraceFlag_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlTraceFlag 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            TraceFlagsToInclude  = @(4199)
            RestartService       = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Remove all trace flags.
#>
Configuration DSC_SqlTraceFlag_RemoveAllTraceFlags_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlTraceFlag 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            ClearAllTraceFlags   = $true
            RestartService       = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
