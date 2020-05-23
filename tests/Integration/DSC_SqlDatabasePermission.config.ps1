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
                NodeName          = 'localhost'
                CertificateFile   = $env:DscPublicCertificatePath

                UserName          = "$env:COMPUTERNAME\SqlAdmin"
                Password          = 'P@ssw0rd1'

                ServerName        = $env:COMPUTERNAME
                InstanceName      = 'DSCSQLTEST'

                # This is created by the SqlDatabase integration tests.
                DatabaseName      = 'Database1'

                # This is created by the SqlDatabaseUser integration tests.
                User1_Name        = 'User1'
            }
        )
    }
}

<#
    .SYNOPSIS
        Grant rights in a database for a user.
#>
Configuration DSC_SqlDatabasePermission_Grant_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabasePermission 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.User1_Name
            DatabaseName         = $Node.DatabaseName
            PermissionState      = 'Grant'
            Permissions          = @(
                'Select'
                'CreateTable'
            )

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Remove granted rights in the database for a user.
#>
Configuration DSC_SqlDatabasePermission_RemoveGrant_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabasePermission 'Integration_Test'
        {
            Ensure               = 'Absent'
            Name                 = $Node.User1_Name
            DatabaseName         = $Node.DatabaseName
            PermissionState      = 'Grant'
            Permissions          = @(
                'Select'
                'CreateTable'
            )

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Deny rights in a database for a user.
#>
Configuration DSC_SqlDatabasePermission_Deny_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabasePermission 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.User1_Name
            DatabaseName         = $Node.DatabaseName
            PermissionState      = 'Deny'
            Permissions          = @(
                'Select'
                'CreateTable'
            )

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Remove deny rights in a database for a user.
#>
Configuration DSC_SqlDatabasePermission_RemoveDeny_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabasePermission 'Integration_Test'
        {
            Ensure               = 'Absent'
            Name                 = $Node.User1_Name
            DatabaseName         = $Node.DatabaseName
            PermissionState      = 'Deny'
            Permissions          = @(
                'Select'
                'CreateTable'
            )

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
