<#
    .DESCRIPTION
        This example will remove the mail profile and the mail account and
        disable Database Mail on a SQL Server instance.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlDatabaseMail 'DisableDatabaseMail'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.NodeName
            InstanceName         = 'DSCSQLTEST'
            AccountName          = 'MyMail'
            ProfileName          = 'MyMailProfile'
            EmailAddress         = 'NoReply@company.local'
            MailServerName       = 'mail.company.local'

            PsDscRunAsCredential = $SqlInstallCredential
        }

        <#
            Don't disable the Database Mail XPs if there are still mail accounts
            left configured.
        #>
        SqlConfiguration 'DisableDatabaseMailXPs'
        {

            ServerName     = $Node.NodeName
            InstanceName   = 'DSCSQLTEST'
            OptionName     = 'Database Mail XPs'
            OptionValue    = 0
            RestartService = $false
        }
    }
}
