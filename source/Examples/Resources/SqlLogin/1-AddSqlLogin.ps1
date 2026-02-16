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

        SqlLogin 'Add_SqlLogin_Set_Login_Sid'
        {
            Ensure                         = 'Present'
            Name                           = 'SqlLogin2'
            LoginType                      = 'SqlLogin'
            ServerName                     = 'TestServer.company.local'
            InstanceName                   = 'DSC'
            LoginCredential                = $LoginCredential
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true
            PsDscRunAsCredential           = $SqlAdministratorCredential
            Sid                            = '0x5283175DBF354E508FB7582940E87500'
        }
    }
}
