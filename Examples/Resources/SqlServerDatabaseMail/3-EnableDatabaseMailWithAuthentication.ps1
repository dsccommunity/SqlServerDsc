<#
    .EXAMPLE
        This example will enable Database Mail with Basic Authentication on a
        SQL Server instance and create a mail account with a default public
        profile.
#>
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName       = 'localhost'
            ServerName     = $env:COMPUTERNAME
            InstanceName   = 'DSCSQLTEST'

            MailServerName = 'mail.company.local'
            AccountName    = 'MyMail'
            ProfileName    = 'MyMailProfile'
            EmailAddress   = 'NoReply@company.local'
            Description    = 'Default mail account and profile.'
            LoggingLevel   = 'Normal'
            TcpPort        = 25
            Authentication = 'Basic'
        }
    )
}

Configuration EnableDatabaseMailWithAuthentication
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SMTPAccountCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {

        SqlServerConfiguration 'EnableDatabaseMailXPs'
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.InstanceName
            OptionName     = 'Database Mail XPs'
            OptionValue    = 1
            RestartService = $false
        }

        SqlServerDatabaseMail 'EnableDatabaseMail'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = $Node.AccountName
            ProfileName          = $Node.ProfileName
            EmailAddress         = $Node.EmailAddress
            ReplyToAddress       = $Node.EmailAddress
            DisplayName          = $Node.MailServerName
            MailServerName       = $Node.MailServerName
            Description          = $Node.Description
            LoggingLevel         = $Node.LoggingLevel
            TcpPort              = $Node.TcpPort
            Authentication       = $Node.Authentication
            SMTPAccount          = $SMTPAccountCredential

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

