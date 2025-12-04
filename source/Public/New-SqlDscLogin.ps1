<#
    .SYNOPSIS
        Creates a new login on a SQL Server Database Engine instance.

    .DESCRIPTION
        This command creates a new login on a SQL Server Database Engine instance.
        The login can be a SQL Server login, a Windows login (user or group),
        a certificate-based login, or an asymmetric key-based login.
    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the login to be created.

    .PARAMETER SqlLogin
        Specifies that a SQL Server login should be created.

    .PARAMETER WindowsUser
        Specifies that a Windows user login should be created.

    .PARAMETER WindowsGroup
        Specifies that a Windows group login should be created.

    .PARAMETER Certificate
        Specifies that a certificate-based login should be created.

    .PARAMETER AsymmetricKey
        Specifies that an asymmetric key-based login should be created.

    .PARAMETER SecurePassword
        Specifies the password as a SecureString for SQL Server logins. This
        parameter is required when creating a SQL Server login.

    .PARAMETER CertificateName
        Specifies the certificate name when creating a certificate-based login.

    .PARAMETER AsymmetricKeyName
        Specifies the asymmetric key name when creating an asymmetric key-based login.

    .PARAMETER DefaultDatabase
        Specifies the default database for the login. If not specified,
        'master' will be used as the default database.

    .PARAMETER DefaultLanguage
        Specifies the default language for the login.

    .PARAMETER PasswordExpirationEnabled
        Specifies whether password expiration is enabled for SQL Server logins.
        Only applies when creating a SQL Server login.

    .PARAMETER PasswordPolicyEnforced
        Specifies whether password policy is enforced for SQL Server logins.
        Only applies when creating a SQL Server login.

    .PARAMETER MustChangePassword
        Specifies whether the user must change the password on next login.
        Only applies when creating a SQL Server login.

    .PARAMETER IsHashed
        Specifies whether the provided password is already hashed.
        Only applies when creating a SQL Server login.

    .PARAMETER Disabled
        Specifies whether the login should be created in a disabled state.

    .PARAMETER Force
        Specifies that the login should be created without any confirmation.

    .PARAMETER PassThru
        If specified, the created login object will be returned.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $securePassword = ConvertTo-SecureString -String 'MyPassword123!' -AsPlainText -Force
        $serverObject | New-SqlDscLogin -Name 'MyLogin' -SqlLogin -SecurePassword $securePassword

        Creates a new SQL Server login named 'MyLogin' with the specified password.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $securePassword = ConvertTo-SecureString -String 'MyPassword123!' -AsPlainText -Force
        $serverObject | New-SqlDscLogin -Name 'MyLogin' -SqlLogin -SecurePassword $securePassword -MustChangePassword

        Creates a new SQL Server login named 'MyLogin' with a SecureString password that must be changed on first login.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscLogin -Name 'DOMAIN\MyUser' -WindowsUser

        Creates a new Windows user login for 'DOMAIN\MyUser'.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscLogin -Name 'DOMAIN\MyGroup' -WindowsGroup

        Creates a new Windows group login for 'DOMAIN\MyGroup'.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscLogin -Name 'MyCertLogin' -Certificate -CertificateName 'MyCertificate'

        Creates a new certificate-based login using the specified certificate.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $hashedPassword = ConvertTo-SecureString -String '0x020012345678...' -AsPlainText -Force
        $serverObject | New-SqlDscLogin -Name 'MyHashedLogin' -SqlLogin -SecurePassword $hashedPassword -IsHashed

        Creates a new SQL Server login with a pre-hashed password. Note that password
        policy options (PasswordExpirationEnabled, PasswordPolicyEnforced, MustChangePassword)
        cannot be used with hashed passwords.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $securePassword = ConvertTo-SecureString -String 'MyPassword123!' -AsPlainText -Force
        $loginObject = $serverObject | New-SqlDscLogin -Name 'MyLogin' -SqlLogin -SecurePassword $securePassword -PassThru

        Creates a new SQL Server login and returns the Login object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscLogin -Name 'MyAsymmetricKeyLogin' -AsymmetricKey -AsymmetricKeyName 'MyAsymmetricKey'

        Creates a new asymmetric key-based login using the specified asymmetric key.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscLogin -Name 'MyAsymmetricKeyLogin' -AsymmetricKey -AsymmetricKeyName 'MyAsymmetricKey' -PassThru

        Creates a new asymmetric key-based login and returns the Login object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $securePassword = ConvertTo-SecureString -String 'NewPassword123!' -AsPlainText -Force
        $serverObject | New-SqlDscLogin -Name 'ExistingLogin' -SqlLogin -SecurePassword $securePassword -Force

        Creates a SQL Server login named 'ExistingLogin' without confirmation prompts.
        Note: If the login already exists, the command throws a terminating error.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $securePassword = ConvertTo-SecureString -String 'MyPassword123!' -AsPlainText -Force
        $serverObject | New-SqlDscLogin -Name 'DisabledLogin' -SqlLogin -SecurePassword $securePassword -Disabled

        Creates a new SQL Server login in a disabled state.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscLogin -Name 'DOMAIN\DisabledUser' -WindowsUser -Disabled -PassThru

        Creates a new disabled Windows user login and returns the Login object.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Login`

        When passing parameter **PassThru**.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Accepted from the pipeline. This cmdlet accepts a SMO Server
        object (for example, the output of `Connect-SqlDscDatabaseEngine`) via the pipeline.

    .NOTES
        This command has the confirm impact level set to medium since a login is
        created but by default it does not have any special permissions.
#>
function New-SqlDscLogin
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Login])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'WindowsUser')]
    param
    (
        [Parameter(ParameterSetName = 'WindowsUser', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'WindowsGroup', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'SqlLogin', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'SqlLoginHashed', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'Certificate', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AsymmetricKey', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'SqlLogin', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SqlLoginHashed', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $SqlLogin,

        [Parameter(ParameterSetName = 'WindowsUser', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $WindowsUser,

        [Parameter(ParameterSetName = 'WindowsGroup', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $WindowsGroup,

        [Parameter(ParameterSetName = 'Certificate', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Certificate,

        [Parameter(ParameterSetName = 'AsymmetricKey', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $AsymmetricKey,

        [Parameter(ParameterSetName = 'SqlLogin', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SqlLoginHashed', Mandatory = $true)]
        [System.Security.SecureString]
        $SecurePassword,

        [Parameter(ParameterSetName = 'Certificate', Mandatory = $true)]
        [System.String]
        $CertificateName,

        [Parameter(ParameterSetName = 'AsymmetricKey', Mandatory = $true)]
        [System.String]
        $AsymmetricKeyName,

        [Parameter()]
        [System.String]
        $DefaultDatabase = 'master',

        [Parameter()]
        [System.String]
        $DefaultLanguage,

        [Parameter(ParameterSetName = 'SqlLogin')]
        [System.Management.Automation.SwitchParameter]
        $PasswordExpirationEnabled,

        [Parameter(ParameterSetName = 'SqlLogin')]
        [System.Management.Automation.SwitchParameter]
        $PasswordPolicyEnforced,

        [Parameter(ParameterSetName = 'SqlLogin')]
        [System.Management.Automation.SwitchParameter]
        $MustChangePassword,

        [Parameter(ParameterSetName = 'SqlLoginHashed', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $IsHashed,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Disabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        # Determine login type from parameter set
        $loginType = $PSCmdlet.ParameterSetName

        # Check if login already exists
        if (Test-SqlDscIsLogin -ServerObject $ServerObject -Name $Name)
        {
            $errorMessage = $script:localizedData.Login_Add_LoginAlreadyExists -f $Name, $ServerObject.InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'NSDL0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $Name
                )
            )
        }

        $verboseDescriptionMessage = $script:localizedData.Login_Add_ShouldProcessVerboseDescription -f $Name, $loginType, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.Login_Add_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.Login_Add_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Create the login object
            $loginObject = [Microsoft.SqlServer.Management.Smo.Login]::new($ServerObject, $Name)

            # Set login type
            switch ($loginType)
            {
                { $_ -in 'SqlLogin', 'SqlLoginHashed' }
                {
                    $loginObject.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
                }

                'WindowsUser'
                {
                    $loginObject.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::WindowsUser
                }

                'WindowsGroup'
                {
                    $loginObject.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::WindowsGroup
                }

                'Certificate'
                {
                    $loginObject.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::Certificate
                    $loginObject.Certificate = $CertificateName
                }

                'AsymmetricKey'
                {
                    $loginObject.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::AsymmetricKey
                    $loginObject.AsymmetricKey = $AsymmetricKeyName
                }
            }

            # Set default database
            $loginObject.DefaultDatabase = $DefaultDatabase

            # Set default language if specified
            if ($PSBoundParameters.ContainsKey('DefaultLanguage'))
            {
                $loginObject.Language = $DefaultLanguage
            }

            # Set SQL Server login specific properties
            if ($loginType -in 'SqlLogin', 'SqlLoginHashed')
            {
                # Prepare login creation options
                $loginCreateOptions = [Microsoft.SqlServer.Management.Smo.LoginCreateOptions]::None

                if ($loginType -eq 'SqlLogin')
                {
                    # Regular SQL login - can use password policy options
                    $loginObject.PasswordExpirationEnabled = $PasswordExpirationEnabled.IsPresent
                    $loginObject.PasswordPolicyEnforced = $PasswordPolicyEnforced.IsPresent

                    if ($MustChangePassword.IsPresent)
                    {
                        $loginCreateOptions = $loginCreateOptions -bor [Microsoft.SqlServer.Management.Smo.LoginCreateOptions]::MustChange
                    }
                }
                elseif ($loginType -eq 'SqlLoginHashed')
                {
                    # Hashed SQL login - cannot use password policy options
                    $loginCreateOptions = $loginCreateOptions -bor [Microsoft.SqlServer.Management.Smo.LoginCreateOptions]::IsHashed
                }

                # Create the login with password
                $loginObject.Create($SecurePassword, $loginCreateOptions)
            }
            else
            {
                # Create login without password for Windows logins, Certificate, and AsymmetricKey
                $loginObject.Create()
            }

            # Disable login if requested
            if ($Disabled.IsPresent)
            {
                $loginObject.Disable()
            }

            Write-Verbose -Message ($script:localizedData.Login_Add_LoginCreated -f $Name, $ServerObject.InstanceName)

            if ($PassThru.IsPresent)
            {
                return $loginObject
            }
        }
    }
}
