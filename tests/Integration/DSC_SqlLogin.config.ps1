#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

# Suppressing this rule because Script Analyzer does not understand DSC configuration syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
# Suppressing this rule because tests are mocking passwords in clear text.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

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
                NodeName         = 'localhost'

                Admin_UserName   = "$env:COMPUTERNAME\SqlAdmin"
                Admin_Password   = 'P@ssw0rd1'

                ServerName       = $env:COMPUTERNAME
                InstanceName     = 'DSCSQLTEST'

                DefaultDbName    = 'DefaultDb'

                DscUser1Name     = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscUser1')
                DscUser1Type     = 'WindowsUser'

                DscUser2Name     = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscUser2')
                DscUser2Type     = 'WindowsUser'

                DscUser3Name     = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscUser3')
                DscUser3Type     = 'WindowsUser'

                DscUser4Name     = 'DscUser4'
                DscUser4Pass1    = 'P@ssw0rd1'
                DscUser4Pass2    = 'P@ssw0rd2'
                DscUser4Type     = 'SqlLogin'
                DscUser4Role     = 'sysadmin'

                DscUser5Name     = 'DscUser5'
                DscUser5Pass     = 'P@ssw0rd1'
                DscUser5Type     = 'SqlLogin'

                DscSqlUsers1Name = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscSqlUsers1')
                DscSqlUsers1Type = 'WindowsGroup'

                CertificateFile  = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Creates the logins that are dependencies.
#>
Configuration DSC_SqlLogin_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        xUser 'CreateDscUser1'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser1Name -Leaf
            # Only the password will be used of this credential object.
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        xUser 'CreateDscUser2'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser2Name -Leaf
            # Only the password will be used of this credential object.
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        xUser 'CreateDscUser3'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser3Name -Leaf
            # Only the password will be used of this credential object.
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        xGroup 'CreateDscSqlUsers1'
        {
            Ensure    = 'Present'
            GroupName = 'DscSqlUsers1'
            Members   = @(
                Split-Path -Path $Node.DscUser1Name -Leaf
                Split-Path -Path $Node.DscUser2Name -Leaf
            )

            DependsOn = @(
                '[xUser]CreateDscUser1'
                '[xUser]CreateDscUser2'
            )
        }

        SqlDatabase 'DefaultDb_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.DefaultDbName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a Windows User login.
#>
Configuration DSC_SqlLogin_AddLoginDscUser1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser1Name
            LoginType            = $Node.DscUser1Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a second Windows User login.
#>
Configuration DSC_SqlLogin_AddLoginDscUser2_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser2Name
            LoginType            = $Node.DscUser2Type
            DefaultDatabase      = $Node.DefaultDbName

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a third Windows User login, and creates it as disabled.
#>
Configuration DSC_SqlLogin_AddLoginDscUser3_Disabled_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser3Name
            LoginType            = $Node.DscUser3Type
            Disabled             = $true

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a SQL login.
#>
Configuration DSC_SqlLogin_AddLoginDscUser4_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser4Name
            LoginType                      = $Node.DscUser4Type
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.DscUser4Name, (ConvertTo-SecureString -String $Node.DscUser4Pass1 -AsPlainText -Force))

            DefaultDatabase                = $Node.DefaultDbName

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        # Database user is also added so the connection into database (using the login) can be tested
        SqlDatabaseUser 'Integration_Test_DatabaseUser'
        {
            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            DatabaseName                   = $Node.DefaultDbName
            Name                           = $Node.DscUser4Name
            UserType                       = 'Login'
            LoginName                      = $Node.DscUser4Name

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))

            DependsOn = @(
                '[SqlLogin]Integration_Test'
            )
        }

        SqlRole 'Integration_Test_SqlRole'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.DscUser4Role
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            MembersToInclude     = @(
                $Node.DscUser4Name
            )

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))

            DependsOn = @(
                '[SqlDatabaseUser]Integration_Test_DatabaseUser'
            )
        }
    }
}

<#
    .SYNOPSIS
        Updates a SQL login.
#>
Configuration DSC_SqlLogin_UpdateLoginDscUser4_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser4Name
            LoginType                      = $Node.DscUser4Type
            LoginMustChangePassword        = $false  # Left the same as this cannot be updated
            LoginPasswordExpirationEnabled = $false
            LoginPasswordPolicyEnforced    = $false

            # Note: This login uses the 'DscUser4Pass2' property value (and not the 'DscUser4Pass1' property value) to validate/test a password change
            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.DscUser4Name, (ConvertTo-SecureString -String $Node.DscUser4Pass2 -AsPlainText -Force))

            DefaultDatabase                = $Node.DefaultDbName

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a second SQL login to test LoginPasswordPolicyEnforced and LoginPasswordExpirationEnabled
        with default values.
#>
Configuration DSC_SqlLogin_AddLoginDscUser5_DefaultValues_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser5Name
            LoginType                      = $Node.DscUser5Type
            LoginMustChangePassword        = $false

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.DscUser4Name, (ConvertTo-SecureString -String $Node.DscUser4Pass1 -AsPlainText -Force))

            <#
                Must use a database that is available on the server,
                and to which the login has access, otherwise the password
                check will fail since it cannot connect to the database.
            #>
            DefaultDatabase                = 'master'

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a second SQL login to test LoginPasswordPolicyEnforced set to True, and
        LoginPasswordExpirationEnabled using default value.
#>
Configuration DSC_SqlLogin_AddLoginDscUser5_Set_LoginPasswordPolicyEnforced_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser5Name
            LoginType                      = $Node.DscUser5Type
            LoginMustChangePassword        = $false
            LoginPasswordPolicyEnforced    = $true

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.DscUser4Name, (ConvertTo-SecureString -String $Node.DscUser4Pass1 -AsPlainText -Force))

            <#
                Must use a database that is available on the server,
                and to which the login has access, otherwise the password
                check will fail since it cannot connect to the database.
            #>
            DefaultDatabase                = 'master'

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a second SQL login to test LoginPasswordExpirationEnabled set to True, and
        LoginPasswordPolicyEnforced using default value.
#>
Configuration DSC_SqlLogin_AddLoginDscUser5_Set_LoginPasswordExpirationEnabled_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser5Name
            LoginType                      = $Node.DscUser5Type
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.DscUser4Name, (ConvertTo-SecureString -String $Node.DscUser4Pass1 -AsPlainText -Force))

            <#
                Must use a database that is available on the server,
                and to which the login has access, otherwise the password
                check will fail since it cannot connect to the database.
            #>
            DefaultDatabase                = 'master'

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a second SQL login to test both LoginPasswordExpirationEnabled and
        LoginPasswordPolicyEnforced set to True.
#>
Configuration DSC_SqlLogin_AddLoginDscUser5_Set_LoginPasswordExpirationEnabled_LoginPasswordPolicyEnforced_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser5Name
            LoginType                      = $Node.DscUser5Type
            LoginMustChangePassword        = $false
            LoginPasswordPolicyEnforced    = $true
            LoginPasswordExpirationEnabled = $true

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.DscUser4Name, (ConvertTo-SecureString -String $Node.DscUser4Pass1 -AsPlainText -Force))

            <#
                Must use a database that is available on the server,
                and to which the login has access, otherwise the password
                check will fail since it cannot connect to the database.
            #>
            DefaultDatabase                = 'master'

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Updates the second SQL login to test LoginPasswordExpirationEnabled set to False, and
        LoginPasswordPolicyEnforced using the previous set value.
#>
Configuration DSC_SqlLogin_UpdateLoginDscUser5_Set_LoginPasswordExpirationEnabled_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser5Name
            LoginType                      = $Node.DscUser5Type
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $false

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.DscUser4Name, (ConvertTo-SecureString -String $Node.DscUser4Pass1 -AsPlainText -Force))

            <#
                Must use a database that is available on the server,
                and to which the login has access, otherwise the password
                check will fail since it cannot connect to the database.
            #>
            DefaultDatabase                = 'master'

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Updates the second SQL login to test LoginPasswordPolicyEnforced set to False, and
        LoginPasswordExpirationEnabled using the previous set value.

    .NOTES
        This test must run after the test that sets LoginPasswordExpirationEnabled
        to False above;
        "DSC_SqlLogin_UpdateLoginDscUser5_Set_LoginPasswordExpirationEnabled_Config".
#>
Configuration DSC_SqlLogin_UpdateLoginDscUser5_Set_LoginPasswordPolicyEnforced_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser5Name
            LoginType                      = $Node.DscUser5Type
            LoginMustChangePassword        = $false
            LoginPasswordPolicyEnforced    = $false

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.DscUser4Name, (ConvertTo-SecureString -String $Node.DscUser4Pass1 -AsPlainText -Force))

            <#
                Must use a database that is available on the server,
                and to which the login has access, otherwise the password
                check will fail since it cannot connect to the database.
            #>
            DefaultDatabase                = 'master'

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a Windows Group login.
#>
Configuration DSC_SqlLogin_AddLoginDscSqlUsers1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscSqlUsers1Name
            LoginType            = $Node.DscSqlUsers1Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the third Windows User login that was created.
#>
Configuration DSC_SqlLogin_RemoveLoginDscUser3_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure               = 'Absent'
            Name                 = $Node.DscUser3Name
            LoginType            = $Node.DscUser3Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the second SQL login (DscUser5Name) that was created.
#>
Configuration DSC_SqlLogin_RemoveLoginDscUser5_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlLogin 'Integration_Test'
        {
            Ensure               = 'Absent'
            Name                 = $Node.DscUser5Name
            LoginType            = $Node.DscUser5Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Clean up test resources so they are not interfering with
        the other integration tests.
#>
Configuration DSC_SqlLogin_CleanupDependencies_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabase 'Remove_DefaultDb_Test'
        {
            Ensure       = 'Absent'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.DefaultDbName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}
