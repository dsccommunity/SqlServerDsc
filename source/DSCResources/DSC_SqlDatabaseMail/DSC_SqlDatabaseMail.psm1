$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the Database Mail configuration.

    .PARAMETER ServerName
        The hostname of the SQL Server to be configured.
        Default value is the current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER AccountName
        The name of the Database Mail account.

    .PARAMETER EmailAddress
        The e-mail address from which mail will originate.

    .PARAMETER MailServerName
        The fully qualified domain name of the mail server name to which e-mail are
        sent.

    .PARAMETER ProfileName
        The name of the Database Mail profile.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName
    )

    $returnValue = @{
        Ensure         = 'Absent'
        ServerName     = $ServerName
        InstanceName   = $InstanceName
        AccountName    = $null
        EmailAddress   = $null
        MailServerName = $null
        LoggingLevel   = $null
        ProfileName    = $null
        DisplayName    = $null
        ReplyToAddress = $null
        Description    = $null
        TcpPort        = $null
    }

    Write-Verbose -Message (
        $script:localizedData.ConnectToSqlInstance `
            -f $ServerName, $InstanceName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    if ($sqlServerObject)
    {
        $databaseMailEnabledRunValue = $sqlServerObject.Configuration.DatabaseMailEnabled.RunValue
        if ($databaseMailEnabledRunValue -eq 1)
        {
            Write-Verbose -Message (
                $script:localizedData.DatabaseMailEnabled `
                    -f $databaseMailEnabledRunValue
            )

            $databaseMail = $sqlServerObject.Mail

            $databaseMailAccount = $databaseMail.Accounts | Where-Object -FilterScript {
                $_.Name -eq $AccountName
            }

            if ($databaseMailAccount)
            {
                Write-Verbose -Message (
                    $script:localizedData.GetConfiguration `
                        -f $AccountName
                )

                $loggingLevelText = switch ($databaseMail.ConfigurationValues['LoggingLevel'].Value)
                {
                    1
                    {
                        'Normal'
                    }

                    2
                    {
                        'Extended'
                    }

                    3
                    {
                        'Verbose'
                    }
                }

                <#
                    AccountName exist so we set this as 'Present' regardless if
                    other properties are in desired state, the Test-TargetResource
                    function must handle that.
                #>
                $returnValue['Ensure'] = 'Present'
                $returnValue['LoggingLevel'] = $loggingLevelText
                $returnValue['AccountName'] = $databaseMailAccount.Name
                $returnValue['EmailAddress'] = $databaseMailAccount.EmailAddress
                $returnValue['DisplayName'] = $databaseMailAccount.DisplayName
                $returnValue['ReplyToAddress'] = $databaseMailAccount.ReplyToAddress

                $mailServer = $databaseMailAccount.MailServers |
                    Where-Object -FilterScript { $_.Name -eq $MailServerName }

                if ($mailServer)
                {
                    $returnValue['MailServerName'] = $mailServer.Name
                    $returnValue['TcpPort'] = $mailServer.Port
                }

                $mailProfile = $databaseMail.Profiles |
                    Where-Object -FilterScript { $_.Name -eq $ProfileName }

                if ($mailProfile)
                {
                    $returnValue['ProfileName'] = $mailProfile.Name
                }

                # SQL Server returns '' for Description property when value is not set.
                if ([System.String]::IsNullOrEmpty($databaseMailAccount.Description))
                {
                    # Convert empty value to $null
                    $returnValue['Description'] = $null
                }
                else
                {
                    $returnValue['Description'] = $databaseMailAccount.Description
                }
            }
            else
            {
                Write-Verbose -Message (
                    $script:localizedData.AccountIsMissing `
                        -f $AccountName
                )
            }
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.DatabaseMailDisabled
            )
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Creates or removes the Database Mail configuration.

    .PARAMETER Ensure
        Specifies the desired state of the Database Mail.
        When set to 'Present', the Database Mail will be created.
        When set to 'Absent', the Database Mail will be removed.
        Default value is 'Present'.

    .PARAMETER ServerName
        The hostname of the SQL Server to be configured.
        Default value is the current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER AccountName
        The name of the Database Mail account.

    .PARAMETER EmailAddress
        The e-mail address from which mail will originate.

    .PARAMETER MailServerName
        The fully qualified domain name of the mail server name to which e-mail are
        sent.

    .PARAMETER ProfileName
        The name of the Database Mail profile.

    .PARAMETER DisplayName
        The display name of the originating e-mail address.
        Default value is the same value assigned to the EmailAddress parameter.

    .PARAMETER ReplyToAddress
        The e-mail address to which the receiver of e-mails will reply to.
        Default value is the same e-mail address assigned to parameter EmailAddress.

    .PARAMETER Description
        The description for the Database Mail profile and account.

    .PARAMETER LoggingLevel
        The logging level that the Database Mail will use. If not specified the
        default logging level is 'Extended'. { Normal | *Extended* | Verbose }.

    .PARAMETER TcpPort
        The TCP port used for communication. Default value is port 25.

    .NOTES
        Information about the different properties can be found here
        https://docs.microsoft.com/en-us/sql/relational-databases/database-mail/configure-database-mail.

#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [System.String]
        $DisplayName = $EmailAddress,

        [Parameter()]
        [System.String]
        $ReplyToAddress = $EmailAddress,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        [ValidateSet('Normal', 'Extended', 'Verbose')]
        $LoggingLevel,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 25
    )

    Write-Verbose -Message (
        $script:localizedData.ConnectToSqlInstance `
            -f $ServerName, $InstanceName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    if ($sqlServerObject)
    {
        if ($Ensure -eq 'Present')
        {
            $databaseMailEnabledRunValue = $sqlServerObject.Configuration.DatabaseMailEnabled.RunValue
            if ($databaseMailEnabledRunValue -eq 1)
            {
                $databaseMail = $sqlServerObject.Mail

                if ($PSBoundParameters.ContainsKey('LoggingLevel'))
                {
                    $loggingLevelValue = switch ($LoggingLevel)
                    {
                        'Normal'
                        {
                            1
                        }

                        'Extended'
                        {
                            2
                        }

                        'Verbose'
                        {
                            3
                        }
                    }

                    $currentLoggingLevelValue = $databaseMail.ConfigurationValues['LoggingLevel'].Value
                    if ($loggingLevelValue -ne $currentLoggingLevelValue)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.ChangingLoggingLevel `
                                -f $LoggingLevel, $loggingLevelValue
                        )

                        $databaseMail.ConfigurationValues['LoggingLevel'].Value = $loggingLevelValue
                        $databaseMail.ConfigurationValues['LoggingLevel'].Alter()
                    }
                    else
                    {
                        Write-Verbose -Message (
                            $script:localizedData.CurrentLoggingLevel `
                                -f $LoggingLevel, $loggingLevelValue
                        )
                    }
                }

                $databaseMailAccount = $databaseMail.Accounts | Where-Object -FilterScript {
                    $_.Name -eq $AccountName
                }

                if (-not $databaseMailAccount)
                {
                    Write-Verbose -Message (
                        $script:localizedData.CreatingMailAccount `
                            -f $AccountName
                    )

                    $databaseMailAccount = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Mail.MailAccount -ArgumentList @($databaseMail, $AccountName)
                    $databaseMailAccount.Description = $Description
                    $databaseMailAccount.DisplayName = $DisplayName
                    $databaseMailAccount.EmailAddress = $EmailAddress
                    $databaseMailAccount.ReplyToAddress = $ReplyToAddress
                    $databaseMailAccount.Create()

                    # The previous Create() method will always create a first mail server.
                    $mailServer = $databaseMailAccount.MailServers | Select-Object -First 1

                    if ($mailServer)
                    {
                        $mailServer.Rename($MailServerName)

                        if ($PSBoundParameters.ContainsKey('TcpPort'))
                        {
                            $mailServer.Port = $TcpPort
                        }

                        $mailServer.Alter()
                    }
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.MailAccountExist `
                            -f $AccountName
                    )

                    $currentDisplayName = $databaseMailAccount.DisplayName
                    if ($PSBoundParameters.ContainsKey('DisplayName') -and $currentDisplayName -ne $DisplayName)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.UpdatingPropertyOfMailServer -f @(
                                $currentDisplayName
                                $DisplayName
                                $script:localizedData.MailServerPropertyDisplayName
                            )
                        )

                        $databaseMailAccount.DisplayName = $DisplayName
                        $databaseMailAccount.Alter()
                    }

                    $currentDescription = $databaseMailAccount.Description
                    if ($PSBoundParameters.ContainsKey('Description') -and $currentDescription -ne $Description)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.UpdatingPropertyOfMailServer -f @(
                                $currentDescription
                                $Description
                                $script:localizedData.MailServerPropertyDescription
                            )
                        )

                        $databaseMailAccount.Description = $Description
                        $databaseMailAccount.Alter()
                    }

                    $currentEmailAddress = $databaseMailAccount.EmailAddress
                    if ($PSBoundParameters.ContainsKey('EmailAddress') -and $currentEmailAddress -ne $EmailAddress)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.UpdatingPropertyOfMailServer -f @(
                                $currentEmailAddress
                                $EmailAddress
                                $script:localizedData.MailServerPropertyEmailAddress
                            )
                        )

                        $databaseMailAccount.EmailAddress = $EmailAddress
                        $databaseMailAccount.Alter()
                    }

                    $currentReplyToAddress = $databaseMailAccount.ReplyToAddress
                    if ($PSBoundParameters.ContainsKey('ReplyToAddress') -and $currentReplyToAddress -ne $ReplyToAddress)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.UpdatingPropertyOfMailServer -f @(
                                $currentReplyToAddress
                                $ReplyToAddress
                                $script:localizedData.MailServerPropertyReplyToEmailAddress
                            )
                        )

                        $databaseMailAccount.ReplyToAddress = $ReplyToAddress
                        $databaseMailAccount.Alter()
                    }

                    $mailServer = $databaseMailAccount.MailServers | Select-Object -First 1

                    $currentMailServerName = $mailServer.Name
                    if ($PSBoundParameters.ContainsKey('MailServerName') -and $currentMailServerName -ne $MailServerName)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.UpdatingPropertyOfMailServer -f @(
                                $currentMailServerName
                                $MailServerName
                                $script:localizedData.MailServerPropertyServerName
                            )
                        )

                        $mailServer.Rename($MailServerName)
                        $mailServer.Alter()
                    }

                    $currentTcpPort = $mailServer.Port
                    if ($PSBoundParameters.ContainsKey('TcpPort') -and $currentTcpPort -ne $TcpPort)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.UpdatingPropertyOfMailServer -f @(
                                $currentTcpPort
                                $TcpPort
                                $script:localizedData.MailServerPropertyTcpPort
                            )
                        )

                        $mailServer.Port = $TcpPort
                        $mailServer.Alter()
                    }
                }

                $databaseMailProfile = $databaseMail.Profiles | Where-Object -FilterScript {
                    $_.Name -eq $ProfileName
                }

                if (-not $databaseMailProfile)
                {
                    Write-Verbose -Message (
                        $script:localizedData.CreatingMailProfile `
                            -f $ProfileName
                    )

                    $databaseMailProfile = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Mail.MailProfile -ArgumentList @($databaseMail, $ProfileName)
                    $databaseMailProfile.Description = $Description
                    $databaseMailProfile.Create()

                    <#
                        A principal refers to a database user, a database role or
                        server role, an application role, or a SQL Server login.
                        You can add these types of users to the mail profile.
                        https://msdn.microsoft.com/en-us/library/ms208094.aspx
                    #>
                    $databaseMailProfile.AddPrincipal('public', $true) # $true means the default profile.
                    $databaseMailProfile.AddAccount($AccountName, 0) # Sequence number zero (0).
                    $databaseMailProfile.Alter()
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.MailProfileExist `
                            -f $ProfileName
                    )
                }

                if ($sqlServerObject.JobServer.AgentMailType -ne 'DatabaseMail' -or $sqlServerObject.JobServer.DatabaseMailProfile -ne $ProfileName)
                {
                    Write-Verbose -Message (
                        $script:localizedData.ConfigureSqlAgent
                    )

                    $sqlServerObject.JobServer.AgentMailType = 'DatabaseMail'
                    $sqlServerObject.JobServer.DatabaseMailProfile = $ProfileName
                    $sqlServerObject.JobServer.Alter()
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.SqlAgentAlreadyConfigured
                    )
                }
            }
            else
            {
                $errorMessage = $script:localizedData.DatabaseMailDisabled
                New-InvalidOperationException -Message $errorMessage
            }
        }
        else
        {
            if ($sqlServerObject.JobServer.AgentMailType -eq 'DatabaseMail' -or $sqlServerObject.JobServer.DatabaseMailProfile -eq $ProfileName)
            {
                Write-Verbose -Message (
                    $script:localizedData.RemovingSqlAgentConfiguration
                )

                $sqlServerObject.JobServer.AgentMailType = 'SqlAgentMail'
                $sqlServerObject.JobServer.DatabaseMailProfile = $null
                $sqlServerObject.JobServer.Alter()
            }

            $databaseMail = $sqlServerObject.Mail

            $databaseMailProfile = $databaseMail.Profiles | Where-Object -FilterScript {
                $_.Name -eq $ProfileName
            }

            if ($databaseMailProfile)
            {
                Write-Verbose -Message (
                    $script:localizedData.RemovingMailProfile `
                        -f $ProfileName
                )

                $databaseMailProfile.Drop()
            }

            $databaseMailAccount = $databaseMail.Accounts | Where-Object -FilterScript {
                $_.Name -eq $AccountName
            }

            if ($databaseMailAccount)
            {
                Write-Verbose -Message (
                    $script:localizedData.RemovingMailAccount `
                        -f $AccountName
                )

                $databaseMailAccount.Drop()
            }
        }
    }
}

<#
    .SYNOPSIS
        Determines if the Database Mail is in the desired state.

    .PARAMETER Ensure
        Specifies the desired state of the Database Mail.
        When set to 'Present', the Database Mail will be created.
        When set to 'Absent', the Database Mail will be removed.
        Default value is 'Present'.

    .PARAMETER ServerName
        The hostname of the SQL Server to be configured.
        Default value is the current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER AccountName
        The name of the Database Mail account.

    .PARAMETER EmailAddress
        The e-mail address from which mail will originate.

    .PARAMETER MailServerName
        The fully qualified domain name of the mail server name to which e-mail are
        sent.

    .PARAMETER ProfileName
        The name of the Database Mail profile.

    .PARAMETER DisplayName
        The display name of the originating e-mail address.

    .PARAMETER ReplyToAddress
        The e-mail address to which the receiver of e-mails will reply to.
        Default value is the same e-mail address assigned to parameter EmailAddress.

    .PARAMETER Description
        The description for the Database Mail profile and account.

    .PARAMETER LoggingLevel
        The logging level that the Database Mail will use. If not specified the
        default logging level is 'Extended'. { Normal | *Extended* | Verbose }.

    .PARAMETER TcpPort
        The TCP port used for communication. Default value is port 25.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification = 'The command Connect-Sql is called when Get-TargetResource is called')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [System.String]
        $DisplayName = $EmailAddress,

        [Parameter()]
        [System.String]
        $ReplyToAddress = $EmailAddress,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        [ValidateSet('Normal', 'Extended', 'Verbose')]
        $LoggingLevel,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 25
    )

    $getTargetResourceParameters = @{
        ServerName     = $ServerName
        InstanceName   = $InstanceName
        AccountName    = $AccountName
        EmailAddress   = $EmailAddress
        MailServerName = $MailServerName
        ProfileName    = $ProfileName
    }

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration
    )

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $returnValue = $true

    if ($Ensure -eq 'Present' -and $getTargetResourceResult.Ensure -eq 'Present')
    {
        $compareDscParameterStateParameters = @{
            CurrentValues       = $getTargetResourceResult
            DesiredValues       = $PSBoundParameters
            Properties          = @(
                'AccountName'
                'EmailAddress'
                'MailServerName'
                'ProfileName'
                'Ensure'
                'ReplyToAddress'
                'TcpPort'
                'DisplayName'
                'Description'
                'LoggingLevel'
            )
            TurnOffTypeChecking = $true
            Verbose             = $VerbosePreference
        }

        $resultCompare = Compare-DscParameterState @compareDscParameterStateParameters

        if ($resultCompare.InDesiredState -contains $false)
        {
            $returnValue = $false
        }
    }
    else
    {
        if ($Ensure -ne $getTargetResourceResult.Ensure)
        {
            $returnValue = $false
        }
    }

    return $returnValue
}
