<#
    .EXAMPLE
        This example will remove the mail profile and the mail account and
        disable Database Mail on a SQL Server instance.

#>
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName       = 'localhost'
            ServerName     = $env:COMPUTERNAME
            InstanceName   = 'DSCSQL2016'

            MailServerName = 'mail.company.local'
            AccountName    = 'MyMail'
            ProfileName    = 'MyMailProfile'
            EmailAddress   = 'NoReply@company.local'
            Description    = 'Default mail account and profile.'
            LoggingLevel   = 'Normal'
            TcpPort        = 25
        }
    )
}

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
        SqlServerDatabaseMail 'DisableDatabaseMail'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = $Node.AccountName
            ProfileName          = $Node.ProfileName
            EmailAddress         = $Node.EmailAddress
            MailServerName       = $Node.MailServerName

            PsDscRunAsCredential = $SqlInstallCredential
        }

        <#
            Don't disable the Database Mail XPs if there are still mail accounts
            left configured.
        #>
        SqlServerConfiguration 'DisableDatabaseMailXPs'
        {

            ServerName     = $Node.ServerName
            InstanceName   = $Node.InstanceName
            OptionName     = 'Database Mail XPs'
            OptionValue    = 0
            RestartService = $false
        }
    }
}
