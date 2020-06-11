<#
    .DESCRIPTION
        This example shows how to ensure that the Windows user 'CONTOSO\WindowsUser',
        Windows group 'CONTOSO\WindowsGroup', and the SQL Login 'SqlLogin' exists.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $LoginCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlLogin 'Add_WindowsUser'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\WindowsUser'
            LoginType            = 'WindowsUser'
            ServerName           = 'TestServer.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlLogin 'Add_DisabledWindowsUser'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\WindowsUser2'
            LoginType            = 'WindowsUser'
            ServerName           = 'TestServer.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
            Disabled             = $true
        }

        SqlLogin 'Add_WindowsUser_Set_Default_Database'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\WindowsUser3'
            LoginType            = 'WindowsUser'
            ServerName           = 'TestServer.company.local'
            InstanceName         = 'DSC'
            DefaultDatabase      = 'contoso'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlLogin 'Add_WindowsGroup'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\WindowsGroup'
            LoginType            = 'WindowsGroup'
            ServerName           = 'TestServer.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlLogin 'Add_SqlLogin'
        {
            Ensure                         = 'Present'
            Name                           = 'SqlLogin'
            LoginType                      = 'SqlLogin'
            ServerName                     = 'TestServer.company.local'
            InstanceName                   = 'DSC'
            LoginCredential                = $LoginCredential
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true
            PsDscRunAsCredential           = $SqlAdministratorCredential
        }
    }
}
