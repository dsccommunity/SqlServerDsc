<#
    .NOTES
        There are integration tests in the file DSC_SqlPermission.Integration.Tests.ps1
        that is using the command Invoke-DscResource to run tests. Those test does
        not have a configuration in this file, but do use the $ConfigurationData.

        The tests using the command Invoke-DscResource assumes that only permission
        left for test user 'User1' after running the configurations in this file is
        a grant for permission 'ConnectSql'.
#>
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
                NodeName          = 'localhost'
                CertificateFile   = $env:DscPublicCertificatePath

                <#
                    This must be either the UPN username (e.g. username@domain.local)
                    or the user name without the NetBIOS name (e.g. username). Using
                    the NetBIOS name (e.g. DOMAIN\username) will not work.
                #>
                UserName          = 'SqlAdmin'
                Password          = 'P@ssw0rd1'

                ServerName        = $env:COMPUTERNAME
                InstanceName      = 'DSCSQLTEST'

                # This is created by the SqlLogin integration tests.
                User1_Name        = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscUser1')
            }
        )
    }
}

<#
    .SYNOPSIS
        Grant rights for a user.
#>
Configuration DSC_SqlPermission_Grant_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlPermission 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Name                 = $Node.User1_Name
            Permission   = @(
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @(
                        'ConnectSql'
                        'AlterAnyAvailabilityGroup'
                        'CreateEndpoint'
                    )
                }
                ServerPermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                ServerPermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
            )

            Credential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Remove granted rights for a user.
#>
Configuration DSC_SqlPermission_RemoveGrant_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlPermission 'Integration_Test'
        {
            InstanceName         = $Node.InstanceName
            Name                 = $Node.User1_Name
            Permission   = @(
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @(
                        'ConnectSql'
                    )
                }
                ServerPermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                ServerPermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
            )
        }
    }
}

<#
    .SYNOPSIS
        Deny rights for a user.
#>
Configuration DSC_SqlPermission_Deny_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlPermission 'Integration_Test'
        {
            InstanceName         = $Node.InstanceName
            Name                 = $Node.User1_Name
            Permission   = @(
                ServerPermission
                {
                    State      = 'Deny'
                    Permission = @(
                        'AlterAnyAvailabilityGroup'
                        'CreateEndpoint'
                    )
                }
                ServerPermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @(
                        'ConnectSql'
                    )
                }
            )
        }
    }
}

<#
    .SYNOPSIS
        Remove deny rights for a user.
#>
Configuration DSC_SqlPermission_RemoveDeny_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlPermission 'Integration_Test'
        {
            InstanceName         = $Node.InstanceName
            Name                 = $Node.User1_Name
            Permission   = @(
                ServerPermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
                ServerPermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @(
                        'ConnectSql'
                    )
                }
            )
        }
    }
}
