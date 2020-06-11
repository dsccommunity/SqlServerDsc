<#
    .DESCRIPTION
        This example will enable Database Mail on a SQL Server instance and
        create a mail account with a default public profile.
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

    node localhost
    {
        SqlConfiguration 'EnableDatabaseMailXPs'
        {

            ServerName     = $Node.NodeName
            InstanceName   = 'DSCSQLTEST'
            OptionName     = 'Database Mail XPs'
            OptionValue    = 1
            RestartService = $false
        }

        SqlDatabaseMail 'EnableDatabaseMail'
        {
            Ensure               = 'Present'
            ServerName           = $Node.NodeName
            InstanceName         = 'DSCSQLTEST'
            AccountName          = 'MyMail'
            ProfileName          = 'MyMailProfile'
            EmailAddress         = 'NoReply@company.local'
            ReplyToAddress       = 'NoReply@company.local'
            DisplayName          = 'mail.company.local'
            MailServerName       = 'mail.company.local'
            Description          = 'Default mail account and profile.'
            LoggingLevel         = 'Normal'
            TcpPort              = 25

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

