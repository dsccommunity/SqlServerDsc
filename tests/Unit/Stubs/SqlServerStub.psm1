# Name: SqlServer
# Version: 22.0.49
# CreatedOn: 2023-01-21 03:09:14Z

function Decode-SqlName
{
    <#
    .SYNOPSIS
        Returns the original SQL Server identifier when given an identifier that has been encoded into a format usable in Windows PowerShell paths.
    .PARAMETER SqlName
        Specifies the SQL Server identifier that this cmdlet reformats.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${SqlName}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Encode-SqlName
{
    <#
    .SYNOPSIS
        Encodes extended characters in SQL Server names to formats usable in Windows PowerShell paths.
    .PARAMETER SqlName
        Specifies the SQL Server identifier to be encoded.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${SqlName}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-SqlNotebook
{
    <#
    .SYNOPSIS
        Executes a SQL Notebook file (.ipynb) and outputs the materialized notebook.
    .PARAMETER ServerInstance
        Specifies a character string or SQL Server Management Objects (SMO) object that specifies the name of an instance of the Database Engine.
    .PARAMETER Database
        This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.
    .PARAMETER Username
        Specifies the login ID for making a SQL Server Authentication connection to an instance of the Database Engine.

        The password must be specified through the Password parameter.

        If Username and Password are not specified, this cmdlet attempts a Windows Authentication connection using the Windows account running the Windows PowerShell session. When possible, use Windows Authentication.
    .PARAMETER Password
        Specifies the password for the SQL Server Authentication login ID that was specified in the Username parameter.

        Passwords are case-sensitive. When possible, use Windows Authentication, or consider using the -Credential parameter instead.

        If you specify the Password parameter followed by your password, the password is visible to anyone who can see your monitor.

        If you code Password followed by your password in a .ps1 script, anyone reading the script file will see your password.

        Assign the appropriate NTFS permissions to the file to prevent other users from being able to read the file.
    .PARAMETER ConnectionString
        Specifies a connection string to connect to the server.
    .PARAMETER Credential
        The PSCredential object whose Username and Password fields will be used to connect to the SQL instance.
    .PARAMETER InputFile
        Specifies a Notebook File (.ipynb) that will be executed through the cmdlet.
    .PARAMETER InputObject
        Specifies the Notebook as a Json string that will be used as the input notebook.
    .PARAMETER OutputFile
        Specifies the desired output Notebook file for which the executed Notebook will be saved.
    .PARAMETER AccessToken
        A valid access token to be used to authenticate to SQL Server, in alternative to user/password or Windows Authentication.

        This can be used, for example, to connect to `SQL Azure DB` and `SQL Azure Managed Instance`  using a `Service Principal` or a `Managed Identity` (see references at the bottom of this page)

        Do not specify UserName , Password , or Credential when using this parameter.
    .PARAMETER Force
        By default, when the cmdlet writes the materialized notebook to a file, a check is performed to prevent the user from accidentally overwriting an existing file. Use `-Force` to bypass this check and allow the cmdlet to overwrite the existing file.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByConnectionParameters')]
    param (
        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [System.Object]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [System.Object]
        ${Database},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Username},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Password},

        [Parameter(ParameterSetName = 'ByConnectionString')]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByConnectionString')]
        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [Parameter(ParameterSetName = 'ByInputFile', Mandatory = $true)]
        [System.Object]
        ${InputFile},

        [Parameter(ParameterSetName = 'ByConnectionString')]
        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [Parameter(ParameterSetName = 'ByInputObject', Mandatory = $true)]
        [System.Object]
        ${InputObject},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${OutputFile},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${AccessToken},

        [switch]
        ${Force}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function SQLSERVER:
{
    <#
    .SYNOPSIS
        SQLSERVER:
    #>

    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Add-RoleMember
{
    <#
    .SYNOPSIS
        Adds a member to a specific Role of a specific database.
    .PARAMETER MemberName
        Name of the member who should be added to the role.
    .PARAMETER Database
        Database name to which the Role belongs to.
    .PARAMETER RoleName
        Name of the Role to which the member should be added.
    .PARAMETER DatabaseRole
        The Microsoft.AnalysisServices.Role to add a member to. This not applicable to tabular databases with compatibility level 1200 or higher.
    .PARAMETER ModelRole
        The model role to add the member to.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance. If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true)]
        [string]
        ${MemberName},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 2)]
        [string]
        ${RoleName},

        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${DatabaseRole},

        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${ModelRole},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Add-SqlAvailabilityDatabase
{
    <#
    .SYNOPSIS
        Adds primary databases to an availability group or joins secondary databases to an availability group.
    .PARAMETER Database
        Specifies an array of user databases. This cmdlet adds or joins  the databases that this parameter specifies to the availability group. The databases that you specify must reside on the local instance of SQL Server.
    .PARAMETER Path
        Specifies the path of an availability group to which this cmdlet adds or joins databases. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER InputObject
        Specifies availability group, as an AvailabilityGroup object, to which this cmdlet adds or joins databases.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Database},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Add-SqlAvailabilityGroupListenerStaticIp
{
    <#
    .SYNOPSIS
        Adds a static IP address to an availability group listener.
    .PARAMETER StaticIp
        Specifies an array of addresses. Each address entry is either an IPv4 address and subnet mask or an IPv6 address. The listener listens on the addresses that this parameter specifies.
    .PARAMETER Path
        Specifies the path of the availability group listener that this cmdlet modifies. If you do not specify this parameter, this cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies the listener, as an AvailabilityGroupListener object, that this cmdlet modifies.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${StaticIp},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Add-SqlAzureAuthenticationContext
{
    <#
    .SYNOPSIS
        Performs authentication to Azure and acquires an authentication token.
    .PARAMETER Interactive
        Indicates that this cmdlet prompts the user for credentials.
    .PARAMETER ClientID
        Specifies the application client ID.
    .PARAMETER Secret
        Specifies the application secret.
    .PARAMETER CertificateThumbprint
        Specifies thumbprint to be used to identify the certificate to use. The cmdlet will search both `CurrentUser` and `LocalMachine` certificate stores.
    .PARAMETER Tenant
        Specifies a tenant in Azure.
    .PARAMETER ActiveDirectoryAuthority
        Specifies the base authority for Azure Active Directory authentication. Same value as the ActiveDirectoryAuthority property from the Azure PowerShell Environment object.
    .PARAMETER AzureKeyVaultResourceId
        Specifies the resource ID for Azure Key Vault services. Same value as the AzureKeyVaultServiceEndpointResourceId property from the Azure PowerShell Environment object.
    .PARAMETER AzureManagedHsmResourceId
        Specifies the resource ID for the Azure Managed HSM service. Use this parameter to override the default value (https://managedhsm.azure.net) when your managed HSM resource is in an Azure instance other than the Azure public cloud.
    #>

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Interactive Public', Mandatory = $true, Position = 0)]
        [Parameter(ParameterSetName = 'Interactive Private', Mandatory = $true, Position = 0)]
        [switch]
        ${Interactive},

        [Parameter(ParameterSetName = 'ClientIdSecret Public', Mandatory = $true, Position = 0)]
        [Parameter(ParameterSetName = 'ClientIdSecret Private', Mandatory = $true, Position = 0)]
        [Parameter(ParameterSetName = 'ClientIdCertificate Public', Mandatory = $true, Position = 0)]
        [Parameter(ParameterSetName = 'ClientIdCertificate Private', Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ClientID},

        [Parameter(ParameterSetName = 'ClientIdSecret Public', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ClientIdSecret Private', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Secret},

        [Parameter(ParameterSetName = 'ClientIdCertificate Public', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ClientIdCertificate Private', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint},

        [Parameter(ParameterSetName = 'ClientIdSecret Public', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ClientIdSecret Private', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ClientIdCertificate Public', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ClientIdCertificate Private', Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Tenant},

        [Parameter(ParameterSetName = 'Interactive Private', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ClientIdSecret Private', Mandatory = $true, Position = 3)]
        [Parameter(ParameterSetName = 'ClientIdCertificate Private', Mandatory = $true, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ActiveDirectoryAuthority},

        [Parameter(ParameterSetName = 'Interactive Private', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ClientIdSecret Private', Mandatory = $true, Position = 4)]
        [Parameter(ParameterSetName = 'ClientIdCertificate Private', Mandatory = $true, Position = 4)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${AzureKeyVaultResourceId},

        [Parameter(ParameterSetName = 'Interactive Private', Position = 2)]
        [Parameter(ParameterSetName = 'ClientIdSecret Private', Position = 4)]
        [Parameter(ParameterSetName = 'ClientIdCertificate Private', Position = 4)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${AzureManagedHsmResourceId}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Add-SqlColumnEncryptionKeyValue
{
    <#
    .SYNOPSIS
        Adds an encrypted value for an existing column encryption key object in the database.
    .PARAMETER ColumnMasterKeyName
        Specifies the name of the column master key that is used to produce the encrypted value that this cmdlet adds to the database.
    .PARAMETER EncryptedValue
        Specifies the encrypted value that this cmdlet adds to the database. You are responsible that the encrypted value,  if specified, has been generated using the specified column master key.
    .PARAMETER Name
        Specifies the name of the column encryption key object that this cmdlet modifies.
    .PARAMETER InputObject
        Specifies the SQL database object for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database for which this cmdlet runs the operation. If you do not specify the value of this parameter, this cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet runs a script to add the SQL column encryption key value.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ColumnMasterKeyName},

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${EncryptedValue},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Add-SqlLogin
{
    <#
    .SYNOPSIS
        Creates a Login object in an instance of SQL Server.
    .PARAMETER LoginName
        Specifies a name for the Login object. The case sensitivity is the same as that of the instance of SQL Server.
    .PARAMETER LoginType
        Specifies the type of the Login object as a Microsoft.SqlServer.Management.Smo.LoginType value. The acceptable values for this parameter are: - AsymmetricKey

        - Certificate

        - SqlLogin

        - WindowsGroup

        - WindowsUser

        At this time, the cmdlet does not support ExternalUser or ExternalGroup.

    .PARAMETER DefaultDatabase
        Specify the default database for the Login object. The default value is master.
    .PARAMETER EnforcePasswordPolicy
        Indicates that the password policy is enforced for the Login object. This parameter applies only SqlLogin type objects.
    .PARAMETER EnforcePasswordExpiration
        Indicates that the password expiration policy is enforced for the Login object. This parameter applies only SqlLogin type objects. This parameter implies the EnforcePasswordPolicy parameter. You do not have to specify both.
    .PARAMETER MustChangePasswordAtNextLogin
        Indicates that the user must change the password at the next login. This parameter applies only SqlLogin type objects. This parameter implies the EnforcePasswordExpiration parameter. You do not have to specify both.
    .PARAMETER Certificate
        Specify the name of the certificate for the Login object. If LoginType has the value Certificate, specify a certificate.
    .PARAMETER AsymmetricKey
        Specify the name of the asymmetric key for the Login object. If the LoginType parameter has the value AsymmetricKey, specify an asymmetric key.
    .PARAMETER CredentialName
        Specify the name of the credential for the Login object.
    .PARAMETER LoginPSCredential
        Specifies a PSCredential object that allows the Login object to provide name and password without a prompt.
    .PARAMETER Enable
        Indicates that the Login object is enabled. By default, Login objects are disabled.

        WindowsGroup type objects are always enabled. This parameter does not affect them.
    .PARAMETER GrantConnectSql
        Indicates that the Login object is not denied permissions to connect to the database engine. By default, Login objects are denied permissions to connect to the database engine.
    .PARAMETER InputObject
        Specifies an SQL Server Management Objects (SMO) object the SQL Server on which this cmdlet operates.
    .PARAMETER Path
        Specifies the path of the SQL Server on which this cmdlet runs the operation. The default value is the current working directory.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server. For the default instance, specify the computer name. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER Credential
        Specifies a PSCredential object for the connection to SQL Server. To obtain a credential object, use the Get-Credential cmdlet. For more information, type Get-Help Get-Credential.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${LoginName},

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${LoginType},

        [string]
        ${DefaultDatabase},

        [switch]
        ${EnforcePasswordPolicy},

        [switch]
        ${EnforcePasswordExpiration},

        [switch]
        ${MustChangePasswordAtNextLogin},

        [ValidateNotNullOrEmpty()]
        [string]
        ${Certificate},

        [ValidateNotNullOrEmpty()]
        [string]
        ${AsymmetricKey},

        [ValidateNotNullOrEmpty()]
        [string]
        ${CredentialName},

        [ValidateNotNullOrEmpty()]
        [pscredential]
        ${LoginPSCredential},

        [switch]
        ${Enable},

        [switch]
        ${GrantConnectSql},

        [Parameter(ParameterSetName = 'ByObject', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Backup-ASDatabase
{
    <#
    .SYNOPSIS
        Enables a database administrator to take the backup of Analysis Service Database to a file.
    .PARAMETER BackupFile
        The backup file path/name where database will be backed up. If only backup file name is mentioned without the location, the default backup location specified during the installation will be considered. This parameter will only be used if the database to backup is specified with the Name parameter, not if it is passed in with the Database parameter.
    .PARAMETER Name
        Analysis Services Database Name that has to be backed up.
    .PARAMETER AllowOverwrite
        Indicates whether the destination files can be overwritten during backup.
    .PARAMETER BackupRemotePartitions
        Indicates whether remote partitions will be backed up or not.
    .PARAMETER ApplyCompression
        Indicates whether the backup file will be compressed or not.
    .PARAMETER FilePassword
        The password to be used with backup file encryption
    .PARAMETER Database
        The Database or Databases to be backed up. The filename of the backup will be the same as the database.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance. If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${BackupFile},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParamsetInput')]
        [switch]
        ${AllowOverwrite},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParamsetInput')]
        [switch]
        ${BackupRemotePartitions},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParamsetInput')]
        [switch]
        ${ApplyCompression},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParamsetInput')]
        [securestring]
        ${FilePassword},

        [Parameter(ParameterSetName = 'ParamsetInput', Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object[]]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Backup-SqlDatabase
{
    <#
    .SYNOPSIS
        Backs up SQL Server database objects.
    .PARAMETER BackupContainer
        Specifies the folder or location where the cmdlet stores backups. This can be a folder on a disk or URL for an Azure Blob container. This parameter can be useful when backing up multiple databases in a given instance. This parameter cannot be used with a BackupDevice parameter. The BackupContainer parameter cannot be used with the BackupFile parameter.

        The path used to specify the location should end with a forward slash (/).
    .PARAMETER MirrorDevices
        Specifies an array of BackupDeviceList objects used by the mirrored backup.
    .PARAMETER BackupAction
        Specifies the type of backup operation to perform. Valid values are:

        - Database. Backs up all the data files in the database.

        - Files. Backs up data files specified in the DatabaseFile or DatabaseFileGroup parameters.

        - Log. Backs up the transaction log.
    .PARAMETER BackupSetName
        Specifies the name of the backup set.
    .PARAMETER BackupSetDescription
        Specifies the description of the backup set. This parameter is optional.
    .PARAMETER CompressionOption
        Specifies the compression options for the backup operation.
    .PARAMETER CopyOnly
        Indicates that the backup is a copy-only backup. A copy-only backup does not affect the normal sequence of your regularly scheduled conventional backups.
    .PARAMETER ExpirationDate
        Specifies the date and time when the backup set expires and the backup data is no longer considered valid. This can only be used for backup data stored on disk or tape devices. Backup sets older than the expiration date are available to be overwritten by a later backup.
    .PARAMETER FormatMedia
        Indicates that the tape is formatted as the first step of the backup operation. This doesnot apply to a disk backup.
    .PARAMETER Incremental
        Indicates that a differential backup is performed.
    .PARAMETER Initialize
        Indicates that devices associated with the backup operation are initialized. This overwrites any existing backup sets on the media and makes this backup the first backup set on the media.
    .PARAMETER LogTruncationType
        Specifies the truncation behavior for log backups. Valid values are:

        -- TruncateOnly

        -- NoTruncate

        -- Truncate

        The default value is Truncate.

    .PARAMETER MediaDescription
        Specifies the description for the medium that contains the backup set. This parameter is optional.
    .PARAMETER RetainDays
        Specifies the number of days that must elapse before a backup set can be overwritten. This can only be used for backup data stored on disk or tape devices.
    .PARAMETER SkipTapeHeader
        Indicates that the tape header is not read.
    .PARAMETER UndoFileName
        Specifies the name of the undo file used to store uncommitted transactions that are rolled back during recovery.
    .PARAMETER EncryptionOption
        Specifies the encryption options for the backup operation.
    .PARAMETER StatementTimeout
        Set the timeout (in seconds) for the back-up operation.

        If the value is 0 or the StatementTimeout parameter is not specified, the restore operation is not going to timeout.
    .PARAMETER Database
        Specifies the name of the database to back up. This parameter cannot be used with the DatabaseObject parameter. When this parameter is specified, the Path, InputObject, or ServerInstance parameters must also be specified.
    .PARAMETER DatabaseObject
        Specifies the database object for the backup operation.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server to execute the backup operation. This is an optional parameter. If not specified, the value of this parameter defaults to the current working location.
    .PARAMETER InputObject
        Specifies the server object for the backup location.
    .PARAMETER ServerInstance
        Specifies the name of a SQL Server instance. This server instance becomes the target of the backup operation.
    .PARAMETER Credential
        Specifies a PSCredential object that contains the credentials for a SQL Server login that has permission to perform this operation. This is not the SQL credential object that is used to store authentication information internally by SQL Server when accessing resources outside SQL Server.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a timeout failure. The timeout value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not timeout.
    .PARAMETER BackupFile
        Specifies the location and file name of the backup. This is an optional parameter. If not specified, the backups are stored in the default backup location of the server under the name  databasename.bak for full and file backups, or databasename.trn for log backups. This parameter cannot be used with the BackupDevice or BackupContainer parameters.
    .PARAMETER SqlCredential
        Specifies an SQL Server credential object that stores authentication information. If you are backing up to Blob storage service, you must specify this parameter. The authentication information stored includes the Storage account name and the associated access key values. Do not specify this parameter for disk or tape.
    .PARAMETER BackupDevice
        Specifies the devices where the backups are stored. This parameter cannot be used with the BackupFile parameter. Use this parameter if you are backing up to tape.
    .PARAMETER PassThru
        Indicates that the cmdlet outputs the Smo.Backup object that performed the backup.
    .PARAMETER Checksum
        Indicates that a checksum value is calculated during the backup operation.
    .PARAMETER ContinueAfterError
        Indicates that the operation continues when a checksum error occurs. If not set, the operation will fail after a checksum error.
    .PARAMETER NoRewind
        Indicates that a tape drive is left open at the ending position when the backup completes. When not set, the tape is rewound after the operation completes. This does not apply to disk or URL backups.
    .PARAMETER Restart
        Indicates that the cmdlet continues processing a partially completed backup operation. If not set, the cmdlet restarts an interrupted backup operation at the beginning of the backup set.
    .PARAMETER UnloadTapeAfter
        Indicates that the tape device is rewound and unloaded when the operation finishes. If not set, no attempt is made to rewind and unload the tape medium. This does not apply to disk or URL backups.
    .PARAMETER NoRecovery
        Indicates that the tail end of the log is not backed up. When restored, the database is in the restoring state. When not set, the tail end of the log is backed up. This only applies when the BackupAction parameter is set to Log.
    .PARAMETER DatabaseFile
        Specifies one or more database files to back up. This parameter is only used when BackupAction is set to Files. When BackupAction is set to Files, either the DatabaseFileGroups or DatabaseFiles parameter must be specified.
    .PARAMETER DatabaseFileGroup
        Specifies the database file groups targeted by the backup operation. This parameter is only used when BackupAction property is set to Files. When BackupAction parameter is set to Files, either the DatabaseFileGroups or DatabaseFiles parameter must be specified.
    .PARAMETER BlockSize
        Specifies the physical block size for the backup, in bytes. The supported sizes are 512, 1024, 2048, 4096, 8192, 16384, 32768, and 65536 (64 KB) bytes. The default is 65536 for tape devices and 512 for all other devices.
    .PARAMETER BufferCount
        Specifies the number of I/O buffers to use for the backup operation. You can specify any positive integer. If there is insufficient virtual address space in the Sqlservr.exe process for the buffers, you will receive an out of memory error.
    .PARAMETER MaxTransferSize
        Specifies the maximum number of bytes to be transferred between the backup media and the instance of SQL Server. The possible values are multiples of 65536 bytes (64 KB), up to 4194304 bytes (4 MB).
    .PARAMETER MediaName
        Specifies the name used to identify the media set.
    .PARAMETER Script
        Indicates that this cmdlet outputs a Transact-SQL script that performs the backup operation.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByDBObject')]
        [Parameter(ParameterSetName = 'ByPath')]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByObject')]
        [Parameter(ParameterSetName = 'ByBackupContainer')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${BackupContainer},

        [System.Object[]]
        ${MirrorDevices},

        [System.Object]
        ${BackupAction},

        [string]
        ${BackupSetName},

        [string]
        ${BackupSetDescription},

        [System.Object]
        ${CompressionOption},

        [switch]
        ${CopyOnly},

        [datetime]
        ${ExpirationDate},

        [switch]
        ${FormatMedia},

        [switch]
        ${Incremental},

        [switch]
        ${Initialize},

        [System.Object]
        ${LogTruncationType},

        [string]
        ${MediaDescription},

        [ValidateRange(0, 2147483647)]
        [int]
        ${RetainDays},

        [switch]
        ${SkipTapeHeader},

        [string]
        ${UndoFileName},

        [System.Object]
        ${EncryptionOption},

        [int]
        ${StatementTimeout},

        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ByDBObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${DatabaseObject},

        [Parameter(ParameterSetName = 'ByPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${BackupFile},

        [ValidateNotNullOrEmpty()]
        [psobject]
        ${SqlCredential},

        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${BackupDevice},

        [switch]
        ${PassThru},

        [switch]
        ${Checksum},

        [switch]
        ${ContinueAfterError},

        [switch]
        ${NoRewind},

        [switch]
        ${Restart},

        [switch]
        ${UnloadTapeAfter},

        [switch]
        ${NoRecovery},

        [ValidateNotNullOrEmpty()]
        [string[]]
        ${DatabaseFile},

        [ValidateNotNullOrEmpty()]
        [string[]]
        ${DatabaseFileGroup},

        [int]
        ${BlockSize},

        [int]
        ${BufferCount},

        [int]
        ${MaxTransferSize},

        [string]
        ${MediaName},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Complete-SqlColumnMasterKeyRotation
{
    <#
    .SYNOPSIS
        Completes the rotation of a column master key.
    .PARAMETER SourceColumnMasterKeyName
        Specifies the name of the source column master key.
    .PARAMETER InputObject
        Specifies the SQL database object for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path to the SQL database, for which this cmdlet runs the operation. If you do not specify a value for the parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet runs a script to complete the rotation of a column master key.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${SourceColumnMasterKeyName},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function ConvertFrom-EncodedSqlName
{
    <#
    .SYNOPSIS
        Returns the original SQL Server identifier when given an identifier that has been encoded into a format usable in Windows PowerShell paths.
    .PARAMETER SqlName
        Specifies the SQL Server identifier that this cmdlet reformats.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${SqlName}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function ConvertTo-EncodedSqlName
{
    <#
    .SYNOPSIS
        Encodes extended characters in SQL Server names to formats usable in Windows PowerShell paths.
    .PARAMETER SqlName
        Specifies the SQL Server identifier to be encoded.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${SqlName}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Convert-UrnToPath
{
    <#
    .SYNOPSIS
        Converts a SQL Server Management Object URN to a Windows PowerShell provider path.
    .PARAMETER Urn
        Specifies a SQL Server URN that identifies the location of an object in the SQL Server hierarchy.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Urn}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Disable-SqlAlwaysOn
{
    <#
    .SYNOPSIS
        Disables the Always On Availability Groups feature for a server.
    .PARAMETER Path
        Specifies the path to the instance of the SQL Server. This is an optional parameter. If not specified, the value of the current working location is used.
    .PARAMETER InputObject
        Specifies the server object of the instance of SQL Server where the Always On Availability Groups setting is disabled.
    .PARAMETER ServerInstance
        Specifies the name of the instance of the SQL Server where Always On is disabled. The format should be MACHINENAME\INSTANCE. Use the Credential parameter to change the Always On setting on a remote server.
    .PARAMETER NoServiceRestart
        Indicates that the user is not prompted to restart the SQL Server service. You must manually restart the SQL Server service for changes to take effect. When this parameter is set, Force is ignored.
    .PARAMETER Force
        Forces the command to run without asking for user confirmation. This parameter is provided to permit the construction of scripts.
    .PARAMETER Credential
        Specifies a windows credential that has permission to alter the Always On setting on the SQL Server instance.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ServerInstance},

        [switch]
        ${NoServiceRestart},

        [switch]
        ${Force},

        [pscredential]
        ${Credential}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Enable-SqlAlwaysOn
{
    <#
    .SYNOPSIS
        Enables the Always On Availability Groups feature.
    .PARAMETER Path
        Specifies the path to the SQL Server instance. This is an optional parameter. If not specified, the current working location is used.
    .PARAMETER InputObject
        Specifies the server object of the SQL Server instance.
    .PARAMETER ServerInstance
        Specifies the name of the SQL Server instance. The format is MACHINENAME\INSTANCE. To enable this setting on a remote server, use this along with the Credential parameter.
    .PARAMETER NoServiceRestart
        Indicates that the user is not prompted to restart the SQL Server service. You must manually restart the SQL Server service for changes to take effect. When this parameter is set, Force is ignored.
    .PARAMETER Force
        Forces the command to run without asking for user confirmation. This parameter is provided to permit the construction of scripts.
    .PARAMETER Credential
        Specifies the name of the SQL Server instance on which to enable the Always On Availability Groups feature. The format is MACHINENAME\INSTANCE. To enable this setting on a remote server, use this along with the Credential parameter.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ServerInstance},

        [switch]
        ${NoServiceRestart},

        [switch]
        ${Force},

        [pscredential]
        ${Credential}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Export-SqlVulnerabilityAssessmentBaselineSet
{
    <#
    .SYNOPSIS
        Exports a Vulnerability Assessment baseline set to a file.
    .PARAMETER BaselineSet
        The baseline set to export
    .PARAMETER FolderPath
        Where the exported file will be saved
    .PARAMETER Force
        Whether to force overwrite of the file if it already exists. If this parameter is not present, you will be prompted before the operation continues.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${BaselineSet},

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${FolderPath},

        [switch]
        ${Force}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Export-SqlVulnerabilityAssessmentScan
{
    <#
    .SYNOPSIS
        Exports a Vulnerability Assessment scan to a file.
    .PARAMETER ScanResult
        The Vulnerability Assessment scan result to export. The scan result must contain the relevant security checks' metadata.
    .PARAMETER FolderPath
        Where the exported file will be saved
    .PARAMETER Force
        Whether to force overwrite of the file if it already exists. If this parameter is not present, you will be prompted before the operation continues.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${ScanResult},

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${FolderPath},

        [switch]
        ${Force}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlAgent
{
    <#
    .SYNOPSIS
        Gets a SQL Agent object that is present in the target instance of SQL Server.
    .PARAMETER InputObject
        Specifies the server object of the target instance.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server, as an array, that becomes the target of the operation.
    .PARAMETER Credential
        Specifies a PSCredential object used to specify the credentials for a SQL Server login that has permission to perform this operation.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a SQL Server connection before a timeout failure. The timeout value must be an integer value between 0 and 65534. If 0 is specified, connection attempts do not time out.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(ParameterSetName = 'ByObject', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlAgentJob
{
    <#
    .SYNOPSIS
        Gets a SQL Agent Job object for each job that is present in the target instance of SQL Agent.
    .PARAMETER ServerInstance
        Specifies, as a string array, the name of an instance of SQL Serverwhere the SQL Agent is running. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER Credential
        Specifies a PSCredential object used to specify the credentials for a SQL Server login that has permission to perform this operation.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer Value between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Name
        Specifies the name of the Job object that this cmdlet gets. The name may or may not be case-sensitive, depending on the collation of the SQL Server where the SQL Agent is running.
    .PARAMETER InputObject
        Specifies a SQL Management Objects (SMO) object representing the SQL Server Agent being targeted.
    .PARAMETER Path
        Specifies the path to the Agent of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(ParameterSetName = 'ByName', Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlAgentJobHistory
{
    <#
    .SYNOPSIS
        Gets the job history present in the target instance of SQL Agent.
    .PARAMETER StartRunDate
        Specifies a job filter constraint that restricts the values returned to the date the job started.
    .PARAMETER EndRunDate
        Specifies a job filter constraint that restricts the values returned to the date the job completed.
    .PARAMETER JobID
        Specifies a job filter constraint that restricts the values returned to the job specified by the job ID value.
    .PARAMETER JobName
        Specifies a job filter constraint that restricts the values returned to the job specified by the name of the job.
    .PARAMETER MinimumRetries
        Specifies the job filter constraint that restricts the values returned to jobs that have failed and been retried for minimum number of times.
    .PARAMETER MinimumRunDurationInSeconds
        Specifies a job filter constraint that restricts the values returned to jobs that have completed in the minimum length of time specified, in seconds.
    .PARAMETER OldestFirst
        Indicates that this cmdlet lists jobs in oldest-first order. If you do not specify this parameter, the cmdlet uses newest-first order.
    .PARAMETER OutcomesType
        Specifies a job filter constraint that restricts the values returned to jobs that have the specified outcome at completion.

        The acceptable values for this parameter are:

        -- Failed

        -- Succeeded

        -- Retry

        -- Cancelled

        -- InProgress

        -- Unknown
    .PARAMETER SqlMessageID
        Specifies a job filter constraint that restricts the values returned to jobs that have generated the specified message during runtime.
    .PARAMETER SqlSeverity
        Specifies a job filter constraint that restricts the values returned to jobs that have generated an error of the specified severity during runtime.
    .PARAMETER Since
        Specifies an abbreviation that you can instead of the StartRunDate parameter.

        It can be specified with the EndRunDate parameter.

        You cannot use the StartRunDate parameter, if you use this parameter.

        The acceptable values for this parameter are:

        - Midnight (gets all the job history information generated after midnight)

        - Yesterday (gets all the job history information generated in the last 24 hours)

        - LastWeek (gets all the job history information generated in the last week)

        - LastMonth (gets all the job history information generated in the last month)
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server, as an array, where the SQL Agent runs. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER Credential
        Specifies a PSCredential object that is used to specify the credentials for a SQL Server login that has permission to perform this operation.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer value between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Path
        Specifies the path to the Agent of SQL Server, as an array, on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies an array of SQL Server Management Object (SMO) objects that represent the SQL Server Agent being targeted.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [datetime]
        ${StartRunDate},

        [datetime]
        ${EndRunDate},

        [guid]
        ${JobID},

        [string]
        ${JobName},

        [int]
        ${MinimumRetries},

        [int]
        ${MinimumRunDurationInSeconds},

        [switch]
        ${OldestFirst},

        [System.Object]
        ${OutcomesType},

        [int]
        ${SqlMessageID},

        [int]
        ${SqlSeverity},

        [System.Object]
        ${Since},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlAgentJobSchedule
{
    <#
    .SYNOPSIS
        Gets a job schedule object for each schedule that is present in the target instance of SQL Agent Job.
    .PARAMETER Name
        Specifies the name of the JobSchedule object that this cmdlet gets.
    .PARAMETER InputObject
        Specifies the Job object of the target instance.
    .PARAMETER Path
        Specifies the path to the Job object on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlAgentJobStep
{
    <#
    .SYNOPSIS
        Gets a SQL JobStep object for each step that is present in the target instance of SQL Agent Job.
    .PARAMETER Name
        Specifies the name of the JobStep object that this cmdlet gets.
    .PARAMETER InputObject
        Specifies the job object of the target instance.
    .PARAMETER Path
        Specifies the path to the job object on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlAgentSchedule
{
    <#
    .SYNOPSIS
        Gets a SQL job schedule object for each schedule that is present in the target instance of SQL Agent.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server, as an array, where the SQL Agent is running. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER Credential
        Specifies a PSCredential object used to specify the credentials for a SQL Server login that has permission to perform this operation.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds that this cmdlet waits for a server connection before a time-out failure. The time-out value must be an integer value between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Name
        Specifies the name of the JobSchedule object that this cmdlet gets.
    .PARAMETER InputObject
        Specifies the SQL Server Agent of the target instance.
    .PARAMETER Path
        Specifies the path to the Agent of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(ParameterSetName = 'ByName', Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlAssessmentItem
{
    <#
    .SYNOPSIS
        Gets SQL Assessment best practice checks available for a chosen SQL Server object.
    .PARAMETER Check
        One or more checks, check IDs, or tags.

        For every check object, Get-SqlAssessmentItem returns that check if it supports the input object.

        For every check ID, Get-SqlAssessmentItem returns the corresponding check if it supports the input object.

        For tags, Get-SqlAssessmentItem returns checks with any of those tags.
    .PARAMETER InputObject
        Specifies a SQL Server object or a path to such an object.  The cmdlet returns appropriate checks for this object.  When this parameter is omitted, current location is used as input object.  If current location is not a supported SQL Server object, the cmdlet signals an error.
    .PARAMETER Configuration
        Specifies paths to files containing custom configuration.  Customization files will be applied to default configuration in specified order.  The scope is limited to this cmdlet invocation only.
    .PARAMETER MinSeverity
        Specifies minimum severity level for checks to be found.  For example, checks of Medium, Low, or Information levels will not be returned when -MinSeverity High.
    .PARAMETER FlattenOutput
        Indicates that this cmdlet produces simple objects of type Microsoft.SqlServer.Management.Assessment.Cmdlets.AssessmentNoteFlat instead of Microsoft.SqlServer.Management.Assessment.Cmdlets.AssessmentNote .
    #>

    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Assessment.Checks.ICheck])]
    param (
        [string[]]
        ${Check},

        [Parameter(Position = 10, ValueFromPipeline = $true)]
        [Alias('Target')]
        [psobject]
        ${InputObject},

        [psobject]
        ${Configuration},

        [Alias('Severity')]
        [System.Object]
        ${MinSeverity},

        [switch]
        ${FlattenOutput}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlBackupHistory
{
    <#
    .SYNOPSIS
        Gets backup information about databases and returns SMO BackupSet objects for each Backup record found based on the parameters specified to this cmdlet.
    .PARAMETER Since
        Specifies an abbreviation that you can instead of the StartTime parameter.

        It can be specified with the EndTime parameter.

        You cannot use the StartTime parameter, if you use this parameter.

        The acceptable values for this parameter are:

        - Midnight (gets all the job history information generated after midnight)

        - Yesterday (gets all the job history information generated in the last 24 hours)

        - LastWeek (gets all the job history information generated in the last week)

        - LastMonth (gets all the job history information generated in the last month)
    .PARAMETER StartTime
        Gets the backup records which started after this specified time.
    .PARAMETER EndTime
        The time before which all backup records to be retrieved should have completed.
    .PARAMETER BackupType
        The type of backup to filter on. If not specified then gets all backup types.  Accepted values are defined below.
    .PARAMETER IncludeSnapshotBackups
        This switch will make the cmdlet obtain records for snapshot backups as well. By default such backups are not retrieved.
    .PARAMETER TimeSpan
        If specified, it causes the cmdlet to filter records generated more than 'Timespan' ago.
    .PARAMETER IgnoreProviderContext
        Indicates that this cmdlet does not use the current context to override the values of the ServerInstance , DatabaseName parameters. If you do not specify this parameter, the cmdlet ignores the values of these parameters, if possible, in favor of the context in which you run the cmdlet.
    .PARAMETER SuppressProviderContextWarning
        Suppresses the warning when the cmdlet is using the provider context.
    .PARAMETER ServerInstance
        The name of the server instances which this cmdlet will target.
    .PARAMETER Credential
        The PSCredential object whose username and password fields are used to connect to the SQL instance.
    .PARAMETER ConnectionTimeout
        The time to wait in seconds for a connection to be established and the dynamically generated -DatabaseName parameter to be populated.
    .PARAMETER Path
        Specifies the SQL provider path to either a server instance or a database for this cmdlet to use to obtain BackupSets for. If not specified uses the current working location.
    .PARAMETER InputObject
        Specifies SMO Server objects to get the backup records for.
    .PARAMETER DatabaseName
        The names of the databases whose backup records are to be retrieved. This is a dynamically populated field and so provides auto-complete suggestions on database names.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [System.Object]
        ${Since},

        [datetime]
        ${StartTime},

        [datetime]
        ${EndTime},

        [System.Object]
        ${BackupType},

        [switch]
        ${IncludeSnapshotBackups},

        [timespan]
        ${TimeSpan},

        [switch]
        ${IgnoreProviderContext},

        [switch]
        ${SuppressProviderContextWarning},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )

    dynamicparam
    {
        $parameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # DatabaseName
        $attributes = New-Object System.Collections.Generic.List[Attribute]

        $attribute = New-Object System.Management.Automation.ParameterAttribute
        $attributes.Add($attribute)

        $parameter = New-Object System.Management.Automation.RuntimeDefinedParameter('DatabaseName', [System.Collections.Generic.List`1[System.String]], $attributes)
        $parameters.Add('DatabaseName', $parameter)

        return $parameters
    }

    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlColumnEncryptionKey
{
    <#
    .SYNOPSIS
        Gets all column encryption key objects defined in the database, or gets one column encryption key object with the specified name.
    .PARAMETER Name
        Specifies the name of the column encryption key object.
    .PARAMETER InputObject
        Specifies the SQL database object for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database for which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet runs a script to get the SQL column encryption key value.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlColumnMasterKey
{
    <#
    .SYNOPSIS
        Gets the column master key objects defined in the database or gets one column master key object with the specified name.
    .PARAMETER Name
        Specifies the name of the column master key object.
    .PARAMETER InputObject
        Specifies the SQL database object for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database for which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet runs a script to get the SQL column master key value.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlCredential
{
    <#
    .SYNOPSIS
        Gets a SQL credential object.
    .PARAMETER Name
        Specifies the name of the credential.
    .PARAMETER InputObject
        Specifies the Server object where the credential is located.
    .PARAMETER Path
        Specifies the path of the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet runs a Transact-SQL script that performs the task.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlDatabase
{
    <#
    .SYNOPSIS
        Gets a SQL database object for each database that is present in the target instance of SQL Server.
    .PARAMETER Name
        Specifies the name of the database that this cmdlet gets the SQL database object.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server, as a string array, that becomes the target of the operation.
    .PARAMETER Credential
        Specifies a user account with Windows Administrator credentials on the target machine.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a SQL Server connection before a timeout failure. The timeout value must be an integer value between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER ConnectionString
        Specifies a connection string to connect to the server.
    .PARAMETER InputObject
        Specifies the server object of the target instance.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet generates a Transact-SQL script that runs the task.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Position = 1)]
        [Alias('Database')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, Position = 2, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [System.Nullable[int]]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ByConnectionString', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlErrorLog
{
    <#
    .SYNOPSIS
        Gets the SQL Server error logs.
    .PARAMETER Timespan
        Specifies a TimeSpan object that this cmdlet filters out of the error logs that do are outside of the time span.

        The format of this parameter is d.HH:mm:ss.

        This parameter is ignored if you use the Since, After, or Before parameters.
    .PARAMETER Before
        Specifies that this cmdlet only gets error logs generated before the given time.

        If the After parameter is specified, the cmdlet defaults to now, meaning that the cmdlet gets all the error logs generated after what you specified for this parameter until the present time.

        Do not specify a value for this parameter if you intend to use the Since or Timespan parameters. The format is defined according to the rules of .Net System.Datatime.Parse().
    .PARAMETER After
        Specifies that this cmdlet only gets error logs generated after the given time.

        If you specify the Before parameter, then this cmdlet gets all the error logs generated before the specified.

        Do not specify this parameter if you intend to use the Since or Timespan parameters.

        The format is defined according to the rules of .Net System.DataTime.Parse().
    .PARAMETER Since
        Specifies an abbreviation for the Timespan parameter.

        Do not specify this parameter if you intend to use the After or Before parameter.

        The acceptable values for this parameter are:

        - Midnight (gets all the logs generated after midnight)

        - Yesterday (gets all the logs generated in the last 24 hours).

        - LastWeek (gets all the logs generated in the last week)

        - LastMonth (gets all the logs generated in the last month)
    .PARAMETER Ascending
        Indicates that the cmdlet sorts the collection of error logs by the log date in ascending order. If you do not specify this parameter, the cmdlet sorts the error logs in descending order.

        When this cmdlet gets error logs multiple sources, the sorting is applied to all the error logs from the same source. The logs this cmdlet get are grouped by source first and then sorted by log date.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server, as an array. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER Credential
        Specifies a PSCredential object used to specify the credentials for a SQL Server login that has permission to perform this operation.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Path
        Specifies the path, as an array, to the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies the server object, as an array, of the target instance that this cmdlet get the logs from.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [timespan]
        ${Timespan},

        [datetime]
        ${Before},

        [datetime]
        ${After},

        [System.Object]
        ${Since},

        [switch]
        ${Ascending},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlInstance
{
    <#
    .SYNOPSIS
        Gets a SQL Instance object for each instance of SQL Server that is present on the target computer.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server. For the default instance, specify the computer name. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER Credential
        Specifies a PSCredential object for the connection to the SQL Server. To obtain a credential object, use the Get-Credential cmdlet. For more information, type Get-Help Get-Credential.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Path
        Specifies the path of the SQL Server on which this cmdlet runs the operation. The default value is the current working directory.
    .PARAMETER InputObject
        Specifies a SQL Server Management Objects (SMO) object that represent the SQL Server on which this cmdlet operates.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlLogin
{
    <#
    .SYNOPSIS
        Returns Login objects in an instance of SQL Server.
    .PARAMETER LoginName
        Specifies an array of names of Login objects that this cmdlet gets. The case sensitivity is the same as that of the instance of SQL Server.
    .PARAMETER Disabled
        Indicates that this cmdlet gets only disabled Login objects.
    .PARAMETER Locked
        Indicates that this cmdlet gets only locked Login objects.
    .PARAMETER PasswordExpired
        Indicates that this cmdlet gets only Login objects that have expired passwords.
    .PARAMETER HasAccess
        Indicates that this cmdlet gets only Login objects that have access to the instance of SQL Server.
    .PARAMETER RegEx
        Indicates that this cmdlet treats the value of the LoginName parameter as a regular expression.
    .PARAMETER Wildcard
        Indicates that this cmdlet interprets wildcard characters in the value of the LoginName parameter.
    .PARAMETER LoginType
        Specifies the type of the Login objects that this cmdlet gets.
    .PARAMETER InputObject
        Specifies a SQL Server Management Objects (SMO) object the SQL Server for which this cmdlet gets Login objects.
    .PARAMETER Path
        Specifies the path of the SQL Server on which this cmdlet runs the operation. The default value is the current working directory.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server. For the default instance, specify the computer name. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER Credential
        Specifies a PSCredential object for the connection to SQL Server. To obtain a credential object, use the Get-Credential cmdlet. For more information, type Get-Help Get-Credential.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Alias('Name')]
        [string]
        ${LoginName},

        [switch]
        ${Disabled},

        [switch]
        ${Locked},

        [switch]
        ${PasswordExpired},

        [switch]
        ${HasAccess},

        [switch]
        ${RegEx},

        [Alias('Like')]
        [switch]
        ${Wildcard},

        [System.Object]
        ${LoginType},

        [Parameter(ParameterSetName = 'ByObject', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlSensitivityClassification
{
    <#
    .SYNOPSIS
        Get the sensitivity label and information type of columns in the database.
    .PARAMETER ColumnName
        Name(s) of columns for which information type and sensitivity label is fetched.
    .PARAMETER ConnectionString
        Specifies a connection string to connect to the database. If this parameter is present, other connection parameters will be ignored.
    .PARAMETER ServerInstance
        Specifies either the name of the server instance (a string) or SQL Server Management Objects (SMO) object that specifies the name of an instance of the Database Engine. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER DatabaseName
        Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.

        If the DatabaseName parameter is not specified, the database that is used depends on whether the current path specifies both the SQLSERVER:\SQL folder and a database name. If the path specifies both the SQL folder and a database name, this cmdlet connects to the database that is specified in the path.
    .PARAMETER Credential
        Specifies a credential used to connect to the database.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies a SQL Server Management Object (SMO) that represent the database that this cmdlet uses.
    .PARAMETER SuppressProviderContextWarning
        Indicates that this cmdlet suppresses the warning that this cmdlet has used in the database context from the current SQLSERVER:\SQL path setting to establish the database context for the cmdlet.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByContext')]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ColumnName},

        [Parameter(ParameterSetName = 'ByConnectionString', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByDBObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByContext')]
        [switch]
        ${SuppressProviderContextWarning}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlSensitivityRecommendations
{
    <#
    .SYNOPSIS
        Get recommended sensitivity labels and information types for columns in the database.
    .PARAMETER ConnectionString
        Specifies a connection string to connect to the database. If this parameter is present, other connection parameters will be ignored
    .PARAMETER ServerInstance
        Specifieseither the name of the server instance (a string) or SQL Server Management Objects (SMO) object that specifies the name of an instance of the Database Engine. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER DatabaseName
        Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.

        If the DatabaseName parameter is not specified, the database that is used depends on whether the current path specifies both the SQLSERVER:\SQL folder and a database name. If the path specifies both the SQL folder and a database name, this cmdlet connects to the database that is specified in the path.
    .PARAMETER Credential
        Specifies a credential used to connect to the database.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies a SQL Server Management Object (SMO) that represent the database that this cmdlet uses.
    .PARAMETER SuppressProviderContextWarning
        Indicates that this cmdlet suppresses the warning that this cmdlet has used in the database context from the current SQLSERVER:\SQL path setting to establish the database context for the cmdlet.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByContext')]
    param (
        [Parameter(ParameterSetName = 'ByConnectionString', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByDBObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByContext')]
        [switch]
        ${SuppressProviderContextWarning}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Get-SqlSmartAdmin
{
    <#
    .SYNOPSIS
        Gets the SQL Smart Admin object and its properties.
    .PARAMETER Name
        Specifies the name of the instance of the SQL Server in this format: Computer\Instance.
    .PARAMETER DatabaseName
        Specifies the name of the database that this cmdlet gets the SQL Smart Admin object.
    .PARAMETER ServerInstance
        Specifies the name of an instance of the SQL Server. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName. Both the Name and the ServerInstance parameters allow you to specify the name of the instance, but ServerInstance also accepts pipeline input of the Server instance name, or the SqInstanceInfo object.
    .PARAMETER InputObject
        Specifies the instance of the Server object.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server. If you do not specify a value for this parameter, the cmdlet sets the path to the current working location.
    .PARAMETER Script
        Indicates that this cmdlet runs a Transact-SQL script that performs the task.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Position = 1)]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByObject')]
        [Parameter(ParameterSetName = 'ByPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [string]
        ${DatabaseName},

        [Parameter(ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ByName')]
        [psobject]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Grant-SqlAvailabilityGroupCreateAnyDatabase
{
    <#
    .SYNOPSIS
        Grants the `CREATE ANY DATABASE` permission to an Always On Availability Group.
    .PARAMETER Path
        Specifies the path to the availability group on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies the target Availability Group object.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Import-SqlVulnerabilityAssessmentBaselineSet
{
    <#
    .SYNOPSIS
        Imports a Vulnerability Assessment baseline set from a file.
    .PARAMETER FolderPath
        The path of the file which contains the persisted baseline set.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${FolderPath}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-ASCmd
{
    <#
    .SYNOPSIS
        Enables database administrators to execute an XMLA script, TMSL script, Data Analysis Expressions (DAX) query,  Multidimensional Expressions (MDX) query, or Data Mining Extensions (DMX) statement against an instance of Analysis Services.
    .PARAMETER Database
        Specifies the database against which an MDX query or DMX statement will execute. The database parameter is ignored when the cmdlet executes an XMLA script, because the database name is embedded in the XMLA script.
    .PARAMETER Query
        Specifies the actual script, query, or statement directly on the command line instead of in a file.
    .PARAMETER ConnectionString
        Specifies the connection string.

        Note that other connection-level properties like Server, Database, etc. are ignored when this property is specified and therefore these properties must be included in the connection string.
    .PARAMETER InputFile
        Identifies the file that contains the XMLA script, MDX query, DMX statement, or TMSL script (in JSON). You must specify a value for either the InputFile or the Query parameter when using Invoke-AsCmd.
    .PARAMETER QueryTimeout
        Specifies the number of seconds before the queries time out. If a timeout value is not specified, the queries do not time out. The timeout must be an integer between 1 and 65535.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds before the connection to the Analysis Services instance times out. The timeout value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER TraceFile
        Identifies a file that receives Analysis Services trace events while executing the XMLA script, MDX query, or DMX statement. If the file already exists, it is automatically overwritten (except for the trace files that are created by using the -TraceLevel:Duration and -TraceLevel:DurationResult parameter settings).

        File names that contain spaces must be enclosed in quotation marks ("").

        If the file name is not valid, an error message is generated.
    .PARAMETER Variables
        Specifies additional scripting variables. Each variable is a name- value pair. If the value contains embedded spaces or control characters, it must be enclosed in double-quotation marks. Use a PowerShell array to specify multiple variables and their values.
    .PARAMETER TraceTimeout
        Specifies the number of seconds the Analysis Services engine waits before ending the trace (if you specify the -TraceFile parameter).

        The trace is considered finished if no trace messages have been recorded during the specified time period.

        The default trace time-out value is 5 seconds.
    .PARAMETER TraceLevel
        Specifies what data is collected and recorded in the trace file. Possible values are High, Medium, Low, Duration, DurationResult.
    .PARAMETER TraceFileFormat
        Specifies the file format for the -TraceFile parameter (if this parameter is specified).

        The default value is "Csv".
    .PARAMETER TraceFileDelimiter
        Specifies a single character as the trace file delimiter when you specify csv as the format for the trace file that use the  -TraceFileFormat parameter.

        Default is | (pipe, or vertical bar).
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance. If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'QuerySet', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [string]
        ${Query},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [string]
        ${InputFile},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [ValidateRange(0, 2147483647)]
        [int]
        ${QueryTimeout},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [ValidateRange(0, 2147483647)]
        [int]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [string]
        ${TraceFile},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [string[]]
        ${Variables},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [int]
        ${TraceTimeout},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [System.Object]
        ${TraceLevel},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [System.Object]
        ${TraceFileFormat},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [ValidateLength(1, 1)]
        [string]
        ${TraceFileDelimiter},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-PolicyEvaluation
{
    <#
    .SYNOPSIS
        Invokes one or more SQL Server policy-based management policy evaluations.
    .PARAMETER Policy
        Specifies one or more policies to evaluate.

        Policies can be stored in an instance of the SQL Server database engine or as exported XML files.

        For policies that are stored in an instance of the database engine, use a path that is based on the SQLSERVER:\SQLPolicy folder to  specify the location of the polices.

        For policies that are stored as XML files, use a file system path to specify the location the policies.

        This parameter can take a string that specifies the names of one or more policies to evaluate.

        If only a file or policy name is specified in the string, this cmdlet uses the current path.

        For policies that are stored in an instance of the database engine, use the policy name, such as "Database Status" or  "SQLSERVER:\SQLPolicy\MyComputer\DEFAULT\Policies\Database Status." For policies that are exported as XML files, use the name of the file, such as "Database Status.xml" or "C:\MyPolicyFolder\Database Status.xml."

        This parameter can take a set of FileInfo objects, such as the output of Get-ChildItem run against a folder that contains exported XML policies.

        This parameter can also take a set of Policy objects, such as the output of Get-ChildItem run against a SQLSERVER:\SQLPolicy path.
    .PARAMETER AdHocPolicyEvaluationMode
        Specifies the adhoc policy evaluation mode. Valid values are:

        - Check. Report the compliance status of the target set by using the credentials of your login account and without reconfiguring any objects.

        - CheckSqlScriptAsProxy. Run a check report by using the ##MS_PolicyTSQLExecutionLogin## proxy account credentials.

        - Configure. Reconfigure the target set objects that do not comply with the policies and report the resulting status. This cmdlet only reconfigures properties that are settable and deterministic.
    .PARAMETER TargetServerName
        Specifies the instance of the database engine that contains the target set.

        You can specify a variable that contains a Microsoft.SqlServer.Management.Sfc.Sdk.SQLStoreConnection object.

        You can also specify a string that complies with the formats that are used in the ConnectionString property of the System.Data.SqlClient.SqlConnection class (v21 of the module) or the Microsoft.Data.SqlClient.SqlConnection class (v22+ of the module) in .Net.

        These include strings such as those created by using either System.Data.SqlClient.SqlConnectionStringBuilder or the Microsoft.Data.SqlClient.SqlConnectionStringBuilder.

        By default, this cmdlet connects by using Windows Authentication.
    .PARAMETER TargetExpression
        Specifies a query that returns the list of objects that define the target set.

        The queries are specified as a string that has nodes which are separated by the '/' character.

        Each node is in the format ObjectType[Filter].

        ObjectType is one of the objects in the SQL Server Management Objects (SMO) object model, and Filter is an expression that filters for specific objects  at that node. The nodes must follow the hierarchy of the SMO objects. For example, the following query expression returns the AdventureWorks sample database:

        [@Name='MyComputer']/Database[@Name='AdventureWorks']

        If TargetExpression is specified, do not specify TargetObject.

    .PARAMETER TargetObjects
        Specifies the set of SQL Server objects against which the policy is evaluated. To connect to an instance of SQL Server analysis services, specify a Microsoft.AnalysisServices.Server object for TargetObject.

        If TargetObject is specified, do not specify TargetExpression.
    .PARAMETER OutputXml
        Indicates that this cmdlet produces its report in XML format using the Service Modeling Language Interchange Format (SML-IF) schema.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        ${Policy},

        [System.Object]
        ${AdHocPolicyEvaluationMode},

        [Parameter(ParameterSetName = 'ConnectionProcessing', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        ${TargetServerName},

        [Parameter(ParameterSetName = 'ConnectionProcessing')]
        [string]
        ${TargetExpression},

        [Parameter(ParameterSetName = 'ObjectProcessing', Mandatory = $true)]
        [psobject[]]
        ${TargetObjects},

        [switch]
        ${OutputXml}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-ProcessASDatabase
{
    <#
    .SYNOPSIS
        Conducts the Process operation on a specified Database with a specific ProcessType or RefreshType depending on the underlying metadata type.
    .PARAMETER DatabaseName
        Specifies the name of the Tabular or Multidimensional database to be processed.
    .PARAMETER RefreshType
        Specifies the process type for a Tabular database.

        See Process Database, Table, or Partition (Analysis Services) (/sql/analysis-services/tabular-models/process-database-table-or-partition-analysis-services)for descriptions and guidance.
    .PARAMETER ProcessType
        Specifies the process type for a Multidimensional database or a Tabular database at compatibility levels 1050-1103.

        See Processing Options and Settings (Analysis Services) (/sql/analysis-services/multidimensional-models/processing-options-and-settings-analysis-services)for descriptions and guidance.
    .PARAMETER Database
        Specifies the Tabular or Multidimensional database to be processed.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance.

        If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetTabularName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 0)]
        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true)]
        [System.Object]
        ${RefreshType},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [System.Object]
        ${ProcessType},

        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-ProcessCube
{
    <#
    .SYNOPSIS
        Conducts the Process operation on a specified Cube of a specific database with a specific ProcessType value.
    .PARAMETER DatabaseCube
        Microsoft.AnalysisServices.Cube object that has to be processed.
    .PARAMETER Name
        Name of the Cube that has to be processed.
    .PARAMETER Database
        Database name to which the Cube belongs to.
    .PARAMETER ProcessType
        Analysis Services ProcessType value.
    .PARAMETER RefreshType
        The type of refresh.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance.

        If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${DatabaseCube},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 1)]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [System.Object]
        ${ProcessType},

        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true, Position = 2)]
        [System.Object]
        ${RefreshType},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-ProcessDimension
{
    <#
    .SYNOPSIS
        Conducts the Process operation on a specified Cube of a specific database with a specific ProcessType value.
    .PARAMETER DatabaseDimension
        The Microsoft.AnalysisServices.Dimension object that has to be processed.
    .PARAMETER Name
        Name of the Dimension that has to be processed.
    .PARAMETER Database
        The database name to which the Dimension belongs to.
    .PARAMETER ProcessType
        Analysis Services ProcessType value.
    .PARAMETER RefreshType
        The type of refresh.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance.

        If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${DatabaseDimension},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 1)]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [System.Object]
        ${ProcessType},

        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true, Position = 2)]
        [System.Object]
        ${RefreshType},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-ProcessPartition
{
    <#
    .SYNOPSIS
        Conducts the Process operation on a specific Partition of a specific database having a specific Cube name and a MeasureGroup name with a specific ProcessType value.
    .PARAMETER PartitionName
        The name of the partition.
    .PARAMETER DatabasePartition
        Microsoft.AnalysisServices.Partition or Microsoft.AnalysisService.Tabular.Partition object that has to be processed. (Multidimensional and tabular metadata respectively)
    .PARAMETER CubeName
        Cube name to which the MeasureGroup belongs to. (Multidimensional metadata only)
    .PARAMETER MeasureGroupName
        MeasureGroup name to which the Partition belongs to.(Multidimensional metadata only)
    .PARAMETER TableName
        Specifies the name of the table.
    .PARAMETER Name
        Name of the Partition that has to be processed. (Multidimensional metadata only)
    .PARAMETER Database
        Database name to which the cube belongs to. (Multidimensional and tabular metadata)
    .PARAMETER ProcessType
        Specifies the process type (Multidimensional metadata only)
    .PARAMETER RefreshType
        The type of refresh.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance.

        If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 0)]
        [string]
        ${PartitionName},

        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${DatabasePartition},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 3)]
        [string]
        ${CubeName},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 4)]
        [string]
        ${MeasureGroupName},

        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 1)]
        [string]
        ${TableName},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 1)]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [System.Object]
        ${ProcessType},

        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true, Position = 2)]
        [System.Object]
        ${RefreshType},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-ProcessTable
{
    <#
    .SYNOPSIS
        Conducts the Process operation on a specified Table with a specific RefreshType.
    .PARAMETER TableName
        Name of the table to with the partition belongs that has to be processed.
    .PARAMETER DatabaseName
        Database name to which the cube belongs to.
    .PARAMETER RefreshType
        Microsoft.AnalysisServices.Tabular.RefreshType to process the partition with.
    .PARAMETER Table
        Microsoft.AnalysisServices.Tabular.Table object that is to be processed.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance.

        If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetTabularName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 1)]
        [string]
        ${TableName},

        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 0)]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ParameterSetTabularName', Mandatory = $true, Position = 2)]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true)]
        [System.Object]
        ${RefreshType},

        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Table},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-SqlAssessment
{
    <#
    .SYNOPSIS
        Runs SQL Assessment best practice checks for a chosen SQL Server object and returns their results.
    .PARAMETER Check
        One or more checks, check IDs, or tags.

        For every check object, Invoke-SqlAssessment runs that check if it supports the input object.

        For every check ID, Invoke-SqlAssessment runs the corresponding check if it supports the input object.

        For tags, Invoke-SqlAssessment runs checks with any of those tags.
    .PARAMETER InputObject
        Specifies a SQL Server object or the path to such an object.  The cmdlet runs assessment for this object.  When this parameter is omitted, current location is used as input object.  If current location is not a supported SQL Server object, the cmdlet signals an error.
    .PARAMETER Configuration
        Specifies paths to files containing custom configuration.  Customization files will be applied to default configuration in specified order.  The scope is limited to this cmdlet invocation only.
    .PARAMETER MinSeverity
        Specifies minimum severity level for checks to be found.  For example, checks of Low, Medium or Information levels will not be returned when -MinSeverity High.
    .PARAMETER FlattenOutput
        Indicates that this cmdlet produces simple objects of type Microsoft.SqlServer.Management.Assessment.Cmdlets.AssessmentNoteFlat instead of Microsoft.SqlServer.Management.Assessment.Cmdlets.AssessmentNote .

        Regular AssessmentNote returned from Invoke-SqlAssessment contains references to other useful complex  objects like Check (see example 12). With the Check property, you can get the check's description or  reuse the check (see example 13). But some cmdlets do not support complex properties. For example,  Write-SqlTableData will raise an error while trying to write AssessmentNote to a database.  To avoid this you can use -FlattenOutput parameter to replace the Check property with two simple  strings: CheckId and CheckName (see example 14).
    #>

    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Assessment.Cmdlets.AssessmentNote])]
    [OutputType([Microsoft.SqlServer.Management.Assessment.Cmdlets.AssessmentNoteFlat])]
    param (
        [System.Object[]]
        ${Check},

        [Parameter(Position = 10, ValueFromPipeline = $true)]
        [Alias('Target')]
        [psobject]
        ${InputObject},

        [psobject]
        ${Configuration},

        [Alias('Severity')]
        [System.Object]
        ${MinSeverity},

        [switch]
        ${FlattenOutput}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-Sqlcmd
{
    <#
    .SYNOPSIS
        Runs a script containing statements supported by the SQL Server SQLCMD utility.
    .PARAMETER ServerInstance
        Specifies a character string or SQL Server Management Objects (SMO) object that specifies the name of an instance of the Database Engine. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER Database
        Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.

        If the Database parameter is not specified, the database that is used depends on whether the current path specifies both the SQLSERVER:\SQL folder and a database name. If the path specifies both the SQL folder and a database name, this cmdlet connects to the database that is specified in the path. If the path is not based on the SQL folder, or the path does not contain a database name, this cmdlet connects to the default database for the current login ID. If you specify the IgnoreProviderContext parameter switch, this cmdlet does not consider any database specified in the current path, and connects to the database defined as the default for the current login ID.
    .PARAMETER Encrypt
        The kind of encryption to use when connecting to SQL Server.

        This value maps to the `Encrypt` property `SqlConnectionEncryptOption` on the SqlConnection object Microsoft.Data.SqlClient driver.

        When not specified, the default value is `Mandatory`.

        > This parameter is new in v22 of the module. For more details, see `Strict Connection Encyption` under Related Links (#Related-Links).
    .PARAMETER EncryptConnection
        Indicates that this cmdlet uses Secure Sockets Layer (SSL/TLS) encryption for the connection to the instance of the Database Engine specified in the ServerInstance parameter.

        > Starting in v22 of the module, this parameter is deprecated. Connections are encrypted by default. Please, consider using the new -Encrypt parameter instead.  For more details, see `Strict Connection Encyption` under Related Links (#Related-Links).
    .PARAMETER Username
        Specifies the login ID for making a SQL Server Authentication connection to an instance of the Database Engine.

        The password must be specified through the Password parameter.

        If Username and Password are not specified, this cmdlet attempts a Windows Authentication connection using the Windows account running the Windows PowerShell session. When possible, use Windows Authentication.
    .PARAMETER AccessToken
        A valid access token to be used to authenticate to SQL Server, in alternative to user/password or Windows Authentication.

        This can be used, for example, to connect to `SQL Azure DB` and `SQL Azure Managed Instance`  using a `Service Principal` or a `Managed Identity` (see references at the bottom of this page)

        Do not specify UserName , Password , or Credential when using this parameter.
    .PARAMETER Password
        Specifies the password for the SQL Server Authentication login ID that was specified in the Username parameter. Passwords are case-sensitive. When possible, use Windows Authentication. Do not use a blank password, when possible use a strong password.

        If you specify the Password parameter followed by your password, the password is visible to anyone who can see your monitor.

        If you code Password followed by your password in a .ps1 script, anyone reading the script file will see your password.

        Assign the appropriate NTFS permissions to the file to prevent other users from being able to read the file.
    .PARAMETER Credential
        The PSCredential object whose Username and Password fields will be used to connect to the SQL instance.
    .PARAMETER Query
        Specifies one or more queries that this cmdlet runs. The queries can be Transact-SQL or XQuery statements, or sqlcmd commands. Multiple queries separated by a semicolon can be specified. Do not specify the sqlcmd GO separator. Escape any double quotation marks included in the string. Consider using bracketed identifiers such as [MyTable] instead of quoted identifiers such as "MyTable".
    .PARAMETER QueryTimeout
        Specifies the number of seconds before the queries time out. If a timeout value is not specified, the queries do not time out. The timeout must be an integer value between 1 and 65535.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds when this cmdlet times out if it cannot successfully connect to an instance of the Database Engine. The timeout value must be an integer value between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER ErrorLevel
        Specifies that this cmdlet display only error messages whose severity level is equal to or higher than the value specified. All error messages are displayed if this parameter is not specified or set to 0. Database Engine error severities range from 1 to 24.
    .PARAMETER SeverityLevel
        Specifies the lower limit for the error message severity level this cmdlet returns to the ERRORLEVEL Windows PowerShell variable.

        This cmdlet returns the highest severity level from the error messages generated by the queries it runs, provided  that severity is equal to or higher than specified in the SeverityLevel parameter.

        If SeverityLevel is not specified or set to 0, this cmdlet returns 0 to ERRORLEVEL.

        The severity levels of Database Engine error messages range from 1 to 24.

        This cmdlet does not report severities for informational messages that have a severity of 10
    .PARAMETER MaxCharLength
        Specifies the maximum number of characters returned for columns with character or Unicode data types, such as char, nchar, varchar, and nvarchar. The default value is 4,000 characters.
    .PARAMETER MaxBinaryLength
        Specifies the maximum number of bytes returned for columns with binary string data types, such as binary and varbinary. The default value is 1,024 bytes.
    .PARAMETER AbortOnError
        Indicates that this cmdlet stops the SQL Server command and returns an error level to the Windows PowerShell ERRORLEVEL variable if this cmdlet encounters an error.

        The error level returned is 1 if the error has a severity higher than 10, and the error level is 0 if the error has a severity of 10 or less.

        If the ErrorLevel parameter is also specified, this cmdlet returns 1 only if the error message severity is also equal to or higher than the value specified for ErrorLevel.
    .PARAMETER DedicatedAdministratorConnection
        Indicates that this cmdlet uses a Dedicated Administrator Connection (DAC) to connect to an instance of the Database Engine.

        DAC is used by system administrators for actions such as troubleshooting instances that will not accept new standard connections.

        The instance must be configured to support DAC.

        If DAC is not enabled, this cmdlet reports an error and will not run.
    .PARAMETER DisableVariables
        Indicates that this cmdlet ignores sqlcmd scripting variables. This is useful when a script contains many INSERT statements that may contain strings that have the same format as variables, such as $(variable_name).
    .PARAMETER DisableCommands
        Indicates that this cmdlet turns off some sqlcmd features that might compromise security when run in batch files.

        It prevents Windows PowerShell variables from being passed in to the Invoke-Sqlcmd script.

        The startup script specified in the SQLCMDINI scripting variable is not run.
    .PARAMETER HostName
        Specifies a workstation name. The workstation name is reported by the sp_who system stored procedure and in the hostname column of the sys.processes catalog view. If this parameter is not specified, the default is the name of the computer on which Invoke-Sqlcmd is run. This parameter can be used to identify different Invoke-Sqlcmd sessions.
    .PARAMETER ApplicationName
        The name of the application associated with the connection.
    .PARAMETER ApplicationIntent
        The application workload type when connecting to a database in an SQL Server Availability Group.

        Allowed values are: ReadOnly and ReadWrite.
    .PARAMETER MultiSubnetFailover
        If your application is connecting to an AlwaysOn Availability Group (AG) on different subnets, passing this parameter provides faster detection of and connection to the (currently) active server.

        Note: passing -MultiSubnetFailover isn't required with .NET Framework 4.6.1 or later versions.
    .PARAMETER FailoverPartner
        The name or address of the partner server to connect to if the primary server is down.
    .PARAMETER HostNameInCertificate
        The host name to be used in validating the SQL Server TLS/SSL certificate.

        > This parameter is new in v22 of the module. For more details, see `Strict Connection Encyption` under Related Links (#Related-Links).
    .PARAMETER TrustServerCertificate
        Indicates whether the channel will be encrypted while bypassing walking the certificate chain to validate trust.

        > This parameter is new in v22 of the module. For more details, see `Strict Connection Encyption` under Related Links (#Related-Links).
    .PARAMETER NewPassword
        Specifies a new password for a SQL Server Authentication login ID. This cmdlet changes the password and then exits. You must also specify the Username and Password parameters, with Password that specifies the current password for the login.
    .PARAMETER Variable
        Specifies, as a string array, a sqlcmd scripting variable for use in the sqlcmd script, and sets a value for the variable.

        Use a Windows PowerShell array to specify multiple variables and their values.
    .PARAMETER InputFile
        Specifies a file to be used as the query input to this cmdlet. The file can contain Transact-SQL statements, XQuery statements, and sqlcmd commands and scripting variables. Specify the full path to the file. Spaces are not allowed in the file path or file name. The file is expected to be encoded using UTF-8.

        You should only run scripts from trusted sources. Ensure all input scripts are secured with the appropriate NTFS permissions.
    .PARAMETER OutputSqlErrors
        Indicates that this cmdlet displays error messages in the Invoke-Sqlcmd output.
    .PARAMETER IncludeSqlUserErrors
        Indicates that this cmdlet returns SQL user script errors that are otherwise ignored by default. If this parameter is specified, this cmdlet matches the default behavior of the sqlcmd utility.
    .PARAMETER SuppressProviderContextWarning
        Indicates that this cmdlet suppresses the warning that this cmdlet has used in the database context from the current SQLSERVER:\SQL path setting to establish the database context for the cmdlet.
    .PARAMETER IgnoreProviderContext
        Indicates that this cmdlet ignores the database context that was established by the current SQLSERVER:\SQL path. If the Database parameter is not specified, this cmdlet uses the default database for the current login ID or Windows account.
    .PARAMETER OutputAs
        Specifies the type of the results this cmdlet gets.

        If you do not specify a value for this parameter, the cmdlet sets the value to DataRows.
    .PARAMETER ConnectionString
        Specifies a connection string to connect to the server.
    .PARAMETER KeyVaultAccessToken
        Specifies an access token for key vaults in Azure Key Vault. Use this parameter if any column to  be queried is protected with Always Encrypted using a column master key stored in a key vault in Azure Key Vault.  Alternatively, you can authenticate to Azure with Add-SqlAzureAuthenticationContext before calling this cmdlet.
    .PARAMETER ManagedHsmAccessToken
        Specifies an access token for managed HSMs in Azure Key Vault. Use this parameter if any column to be queried  is protected with Always Encrypted using a column master key stored in a managed HSM in Azure Key Vault. Alternatively,  you can authenticate to Azure with Add-SqlAzureAuthenticationContext before calling this cmdlet.
    .PARAMETER StatisticsVariable
        Specify the name of a PowerShell variable that will be assigned the SQL Server run-time statistics when the cmdlet is executed.

        Common use for this parameter is to capture the `ExecutionTime` (the cumulative amount of time (in milliseconds) that the provider has spent processing the cmdlet), or `IduRows` (the total number of rows affected by INSERT, DELETE, and UPDATE statements).

        For more details, see Provider Statistics for SQL Server (/dotnet/framework/data/adonet/sql/provider-statistics-for-sql-server).
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByConnectionParameters')]
    param (
        [Parameter(ParameterSetName = 'ByConnectionParameters', ValueFromPipeline = $true)]
        [psobject]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [string]
        ${Encrypt},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [switch]
        ${EncryptConnection},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Username},

        [ValidateNotNullOrEmpty()]
        [string]
        ${AccessToken},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Password},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Query},

        [ValidateRange(0, 65535)]
        [int]
        ${QueryTimeout},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [int]
        ${ConnectionTimeout},

        [ValidateRange(-1, 255)]
        [int]
        ${ErrorLevel},

        [ValidateRange(-1, 25)]
        [int]
        ${SeverityLevel},

        [ValidateRange(1, 2147483647)]
        [int]
        ${MaxCharLength},

        [ValidateRange(1, 2147483647)]
        [int]
        ${MaxBinaryLength},

        [switch]
        ${AbortOnError},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [switch]
        ${DedicatedAdministratorConnection},

        [switch]
        ${DisableVariables},

        [switch]
        ${DisableCommands},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [Alias('WorkstationID')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${HostName},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationName},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${ApplicationIntent},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [switch]
        ${MultiSubnetFailover},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${FailoverPartner},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNull()]
        [string]
        ${HostNameInCertificate},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [switch]
        ${TrustServerCertificate},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [string]
        ${NewPassword},

        [string[]]
        ${Variable},

        [ValidateNotNullOrEmpty()]
        [string]
        ${InputFile},

        [bool]
        ${OutputSqlErrors},

        [switch]
        ${IncludeSqlUserErrors},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [switch]
        ${SuppressProviderContextWarning},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [switch]
        ${IgnoreProviderContext},

        [Alias('As')]
        [System.Object]
        ${OutputAs},

        [Parameter(ParameterSetName = 'ByConnectionString', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByConnectionString')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyVaultAccessToken},

        [Parameter(ParameterSetName = 'ByConnectionString')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ManagedHsmAccessToken},

        [string]
        ${StatisticsVariable}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-SqlColumnMasterKeyRotation
{
    <#
    .SYNOPSIS
        Initiates the rotation of a column master key.
    .PARAMETER SourceColumnMasterKeyName
        Specifies the name of the source column master key.
    .PARAMETER TargetColumnMasterKeyName
        Specifies the name of the target column master key.
    .PARAMETER KeyVaultAccessToken
        Specifies an access token for key vaults in Azure Key Vault. Use this parameter if the current  and/or the target column master key is stored in a key vault in Azure Key Vault.
    .PARAMETER ManagedHsmAccessToken
        Specifies an access token for managed HSMs in Azure Key Vault. Use this parameter if the current  and/or the target column master key is stored in a managed HSM in Azure Key Vault.
    .PARAMETER InputObject
        Specifies the SQL database object, for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database, for which this cmdlet runs the operation.

        If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet runs a Transact-SQL script that performs the task.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${SourceColumnMasterKeyName},

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TargetColumnMasterKeyName},

        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyVaultAccessToken},

        [ValidateNotNullOrEmpty()]
        [string]
        ${ManagedHsmAccessToken},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Invoke-SqlVulnerabilityAssessmentScan
{
    <#
    .SYNOPSIS
        Invokes a new Vulnerability Assessment scan.
    .PARAMETER ConnectionString
        Specifies a connection string to connect to the database. If this parameter is present, other connection parameters will be ignored
    .PARAMETER ServerInstance
        Specifies a character string or SQL Server Management Objects (SMO) object that specifies the name of an instance of the Database Engine. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER DatabaseName
        Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.

        If the Database parameter is not specified, the database that is used depends on whether the current path specifies both the SQLSERVER:\SQL folder and a database name. If the path specifies both the SQL folder and a database name, this cmdlet connects to the database that is specified in the path.
    .PARAMETER Credential
        Specifies a credential used to connect to the database.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server to execute the scan.
    .PARAMETER InputObject
        Specifies the input object for the scan operation.
    .PARAMETER ScanId
        The Vulnerability Assessment scan id
    .PARAMETER Baseline
        A Vulnerability Assessment security check baseline set
    .PARAMETER OmitMetadata
        Whether to omit the security checks metadata (e.g. title, description, etc.) Please notice that Export-VulnerabilityAssessmentScan requires the security checks metadata to execute correctly.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByContext')]
    param (
        [Parameter(ParameterSetName = 'ByConnectionString', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByDBObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [ValidateNotNullOrEmpty()]
        [string]
        ${ScanId},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Baseline},

        [switch]
        ${OmitMetadata}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Join-SqlAvailabilityGroup
{
    <#
    .SYNOPSIS
        Joins the local secondary replica to an availability group.
    .PARAMETER Name
        Specifies the name of the availability group to which this cmdlet joins a secondary replica.
    .PARAMETER Path
        Specifies the path of the instance of SQL Server that hosts the secondary replica that this cmdlet joins to the availability group. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER InputObject
        Specifies the server that hosts the instance of SQL Server that hosts the secondary replica that this cmdlet joins to the availability group.
    .PARAMETER ClusterType
        The type of cluster backing the AG. Possible values are:

        - Wsfc.     The AG will be integrated in Windows Server Failover Cluster. This is how AGs in SQL Server 2016 and below are             created. This is the default. - None.     The AG will be cluster-independent.

        - External. The AG will be managed by a cluster manager that is not a Windows Server Failover Cluster, like Pacemaker on Linux.

        This is supported in SQL Server 2017 and above. When targeting SQL Server on Linux, you must specify this value             or an error will occour.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.Object]
        ${InputObject},

        [System.Object]
        ${ClusterType},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Merge-Partition
{
    <#
    .SYNOPSIS
        This cmdlet merges the data of one or more source partitions into a target partition and deletes the source partitions.
    .PARAMETER Name
        Name of the target partition to where the source partitions data will be merged.
    .PARAMETER SourcePartitions
        Source partition names from which data is merged to target partition.
    .PARAMETER Database
        Name of the Analysis Server database where the partitions exist.
    .PARAMETER Cube
        Name of the cube under which the partitions exist.
    .PARAMETER MeasureGroup
        Name of the Measure Group under which the partitions exist.
    .PARAMETER TargetPartition
        Specifies the target partition to which the source partitions will be merged.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance. If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${SourcePartitions},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Cube},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${MeasureGroup},

        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.Object]
        ${TargetPartition},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-RestoreFolder
{
    <#
    .SYNOPSIS
        Restores an original folder to a new folder.
    .PARAMETER OriginalFolder
        Gets the original folder location.
    .PARAMETER NewFolder
        Sets the location of a new folder.
    .PARAMETER AsTemplate
        Specifies whether the object should be created in memory and returned.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance. If no credentials are specified default Windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [string]
        ${OriginalFolder},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [string]
        ${NewFolder},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [switch]
        ${AsTemplate},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-RestoreLocation
{
    <#
    .SYNOPSIS
        Used to add a restore location to the server.
    .PARAMETER File
        Specifies the name of the backup file that you are restoring.
    .PARAMETER DataSourceId
        @{Text=}
    .PARAMETER ConnectionString
        Specifies the connection string of a remote Analysis Services instance.
    .PARAMETER DataSourceType
        Specifies whether the data source is remote or local, based on the location of the partition.
    .PARAMETER Folders
        Specifies partition folders on the local or remote instance.
    .PARAMETER AsTemplate
        Specifies whether the object should be created in memory and returned.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        This parameter is used to pass in a username and password when using an HTTP connection to an Analysis Service instance, for an instance that you have configured for HTTP access. For more information, see Configure HTTP Access to Analysis Services on Internet Information Services (IIS) 8.0 (/sql/analysis-services/instances/configure-http-access-to-analysis-services-on-iis-8-0)for HTTP connections.

        If this parameter is specified, the username and password will be used to connect to the specified Analysis Server instance. If no credentials are specified, default windows account of the user who is running the tool will be used.

        To use this parameter, first create a PSCredential object using Get-Credential to specify the username and password (for example,

        $Cred = Get-Credential "adventure-works\bobh"

        . You can then pipe this object to the  �Credential parameter (

        -Credential $Cred

        ).
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetName')]
        [string]
        ${File},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [string]
        ${DataSourceId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [System.Object]
        ${DataSourceType},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [System.Object[]]
        ${Folders},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [switch]
        ${AsTemplate},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlAvailabilityGroup
{
    <#
    .SYNOPSIS
        Creates an availability group.
    .PARAMETER AvailabilityReplica
        Specifies an array of availability replicas that this cmdlet includes in the availability group. To obtain an AvailabilityReplica , use the New-SqlAvailabilityReplica cmdlet. Specify the AsTemplate parameter.
    .PARAMETER Database
        Specifies an array of local, read/write user databases. These databases must use the full recovery model and must not use AUTO_CLOSE. These databases cannot belong to another availability group and cannot be configured for database mirroring. You must specify a value for this parameter.
    .PARAMETER AutomatedBackupPreference
        Specifies the automated backup preference for the availability group.

        The acceptable values for this parameter are:

        - Primary.       Specifies that the backups always occur on the primary replica. This option supports the use of features                  not available when backup runs on a secondary replica, such as differential backups. - SecondaryOnly. Specifies that backups are never performed on primary replicas. If the primary replica is the only                  replica online, the backup does not occur. - Secondary.     Specifies that backups occur on secondary replicas, unless the primary replica is the only replica                  online. Then the backup occurs on the primary replica. - None.          Specifies that the primary or secondary status is not taken into account when deciding which replica                  performs backups. Instead, backup priority and online status determine which replica performs backups.
    .PARAMETER FailureConditionLevel
        Specifies the automatic failover behavior of the availability group. The acceptable values for this parameter are:

        - OnServerDown.                    Failover or restart if the SQL Server service stops.

        - OnServerUnresponsive.            Failover or restart if any condition of lower value is satisfied, plus when the SQL Server

        service is connected to the cluster and the HealthCheckTimeout threshold is exceeded, or if                                    the availability replica currently in primary role is in a failed state.  - OnCriticalServerError.           Failover or restart if any condition of lower value is satisfied, plus when an internal                                     critical Server error occurs, which include out of memory condition, serious write-access                                    violation, or too much dumping.  - OnModerateServerError.           Failover or restart if any condition of lower value is satisfied, plus if a moderate Server                                     error occurs, which includes persistent out of memory condition.  - OnAnyQualifiedFailureConditions. Failover or restart if any condition of lower value is satisfied, plus if a qualifying failure                                    condition occurs, which includes engine worker thread exhaustion and unsolvable deadlock detected.
    .PARAMETER HealthCheckTimeout
        Specifies the length of time, in milliseconds, after which Always On availability groups declare an unresponsive server to be unhealthy.
    .PARAMETER BasicAvailabilityGroup
        Specifies whether to create an `advanced` (default) or a `basic` availability group.
    .PARAMETER ContainedAvailabilityGroup
        Used to create a contained availability group. This option is used to create an availability group with its own `master` and `msdb` databases, which are kept in sync across the set of replicas in the availability group. This parameter may be used with its companion -ReuseSystemDatabases .

        > This parameter is allowed only when the target SQL Server supports Contained Availability Groups (SQL 2022 and above). Trying to use is against versions of SQL that do not support Contained Availability Groups would cause the cmdlet to throw an error.

        > This parameter is only available in version 22+ of the module.
    .PARAMETER ReuseSystemDatabases
        This parameter causes the contained `master` and `msdb` databases from a prior version of the AG to be used in the creation of this new availability group.

        > Trying to use this parameter without specifying -ContainedAvailabilityGroup is  not allowed would cause the cmdlet to throw an error.

        > This parameter is only available in version 22+ of the module.
    .PARAMETER DatabaseHealthTrigger
        Specifies whether to trigger an automatic failover of the availability group  if any user database replica within an availability group encounters a database failure condition.
    .PARAMETER DtcSupportEnabled
        Specifies whether databases within an availability group register with MSDTC  at the instance-level (default) or at the per-database level.
    .PARAMETER ClusterType
        The type of cluster backing the AG. Possible values are:

        - Wsfc.     The AG will be integrated in Windows Server Failover Cluster. This is how AGs in SQL Server 2016 and below are             created. This is the default. - None.     The AG will be cluster-independent.

        - External. The AG will be managed by a cluster manager that is not a Windows Server Failover Cluster, like Pacemaker on Linux.

        This is supported in SQL Server 2017 and above. When targeting SQL Server on Linux, you must specify this value             or an error will occour.

        Note: An exception will be thrown if the -ClusterType parameter is used when the target server is SQL Server 2016 and below.
    .PARAMETER RequiredSynchronizedSecondariesToCommit
        The number of synchronous commit secondaries that must be available to be able to commit on the primary.

        If a `SYNCHRONOUS_COMMIT` secondary is disconnected from the primary for some time, the primary demotes it to `ASYNCHRONOUS_COMMIT` to avoid blocking commits. If the primary then becomes unavailable and the user wishes to fail over to one of these secondaries, they may incur data loss. By setting RequiredSynchronizedSecondariesToCommit to some number, the user can prevent the data loss since the primary will start blocking commits if too many secondaries are demoted to `ASYNCHRONOUS_COMMIT`.

        The default value of this setting is 0, which means the primary will never block commits. This is identical to the behavior before SQL Server 2017.
    .PARAMETER Name
        Specifies the name of the availability group that this cmdlet creates.
    .PARAMETER InputObject
        Specifies the instance of SQL Server that hosts the primary replica of the availability group that this cmdlet creates.
    .PARAMETER Path
        Specifies the path of the instance of SQL Server that hosts the initial primary replica of the availability group that this cmdlet creates. If you do not specify this parameter, this cmdlet uses current working location. If you specify a value, the path must currently exist.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${AvailabilityReplica},

        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Database},

        [System.Object]
        ${AutomatedBackupPreference},

        [System.Object]
        ${FailureConditionLevel},

        [int]
        ${HealthCheckTimeout},

        [switch]
        ${BasicAvailabilityGroup},

        [switch]
        ${ContainedAvailabilityGroup},

        [switch]
        ${ReuseSystemDatabases},

        [switch]
        ${DatabaseHealthTrigger},

        [switch]
        ${DtcSupportEnabled},

        [System.Object]
        ${ClusterType},

        [int]
        ${RequiredSynchronizedSecondariesToCommit},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlAvailabilityGroupListener
{
    <#
    .SYNOPSIS
        Creates an availability group listener and attaches it to an availability group.
    .PARAMETER DhcpSubnet
        Specifies an IPv4 address and subnet mask of a network. The listener determines the address on this network by using DHCP. Specify the address in for following format: 192.168.0.1/255.255.255.0.

        If you specify this parameter, do not specify the StaticIp parameter.
    .PARAMETER StaticIp
        Specifies an array of addresses. Each address entry is either an IPv4 address and subnet mask or an IPv6 address. The listener listens on the addresses that this parameter specifies.

        If you specify this parameter, do not specify the DhcpSubnet parameter.
    .PARAMETER Port
        Specifies the port on which the listener listens for connections. The default port is TCP port 1433.
    .PARAMETER Name
        Specifies a name for the listener.
    .PARAMETER InputObject
        Specifies the availability group, as an AvailabilityGroup object, to which this cmdlet attaches the listener.
    .PARAMETER Path
        Specifies the path of the availability group to which this cmdlet attaches a listener. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        ${DhcpSubnet},

        [ValidateNotNullOrEmpty()]
        [string[]]
        ${StaticIp},

        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [int]
        ${Port},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlAvailabilityReplica
{
    <#
    .SYNOPSIS
        Creates an availability replica.
    .PARAMETER AvailabilityMode
        Specifies the replica availability mode.

        You can specify a value of `$Null.`
    .PARAMETER FailoverMode
        Specifies the failover mode.

        You can specify a value of `$Null`
    .PARAMETER EndpointUrl
        Specifies the URL of the database mirroring endpoint. This URL is a TCP address in the following form:

        TCP://system-address:port
    .PARAMETER SessionTimeout
        Specifies the amount of time, in seconds, to wait for a response between the primary replica and this replica before the connection fails.
    .PARAMETER ConnectionModeInPrimaryRole
        Specifies how the availability replica handles connections when in the primary role.

        The acceptable values for this parameter are:

        - AllowReadWriteConnections. Allows read/write connections

        - AllowAllConnections.       Allows all connections
    .PARAMETER ConnectionModeInSecondaryRole
        Specifies how the availability replica handles connections when in the secondary role. The acceptable values for this parameter are:

        - AllowNoConnections.             Disallows connections

        - AllowReadIntentConnectionsOnly. Allows only read-intent connections

        - AllowAllConnections.            Allows all connections
    .PARAMETER BackupPriority
        Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup.
    .PARAMETER ReadOnlyRoutingList
        Specifies an ordered list of replica server names that represent the probe sequence for connection  director to use when redirecting read-only connections through this availability replica. This parameter applies if the availability replica is the current primary replica of the availability group.
    .PARAMETER ReadonlyRoutingConnectionUrl
        Specifies the fully-qualified domain name (FQDN) and port to use when routing to the replica for read only connections, as in the following example: TCP://DBSERVER8.manufacturing.Contoso.com:7024
    .PARAMETER SeedingMode
        Specifies how the secondary replica will be initially seeded.
        Allowed values: - Automatic. Enables direct seeding.              This method will seed the secondary replica over the network.              This method does not require you to backup and restore a copy of the primary database on the replica. - Manual.    Specifies manual seeding.              This method requires you to create a backup of the database on the primary replica and manually              restore that backup on the secondary replica.
    .PARAMETER LoadBalancedReadOnlyRoutingList
        Specifies the load-balanced read-only routing list.

        The routing list is a list of load-balanced sets, which in turn are lists of replicas.

        For example, passing a value like

        @('Server1','Server2'),@('Server3'),@('Server4')

        means what we are passing 3 load-balanced sets: 1 with 2 replicas (Server1 and Server2) and 2 with just one (Server3 and Server4, respectively).

        At runtime, SQL Server will look sequentially at all the load-balanced sets until finds one such that at least on replica in it is available and use it for load-balancing.

        So, in the example above, if both Server1 and Server2 are not available, but Server3 is, SQL Server will pick Server3.
        > This cmdlet only sets the read-only routing list and does not check on the availablility of the specified replicas.

    .PARAMETER AsTemplate
        Indicates that this cmdlet creates a temporary AvailabilityReplica object in memory. Specify this parameter to create an availability group before you create an availability replica. Create an availability group by using the New-SqlAvailabilityGroup cmdlet. Specify the temporary availability replica as the value of the AvailabilityReplica parameter.

        If you specify AsTemplate , this cmdlet ignores values for the InputObject and Path parameters.

        If you specify this parameter, you must also specify a SQL Server version for the Version parameter, or your current session must have an active connection to an instance.
    .PARAMETER Version
        Specifies a SQL Server version. If you specify the AsTemplate parameter, you must specify a version. The template object is created in design mode on a server that includes this version. You can specify an integer or a string, as in the following examples (SQL Server 2017):

        - 14

        - '14.0.0'
    .PARAMETER Name
        Specifies a name for the availability replica in the following format: Computer\Instance
    .PARAMETER InputObject
        Specifies the availability group, as an AvailabilityGroup object, to which the replica belongs.
    .PARAMETER Path
        Specifies the path of the availability group to which the replica belongs. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        ${AvailabilityMode},

        [Parameter(Mandatory = $true)]
        [System.Object]
        ${FailoverMode},

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${EndpointUrl},

        [int]
        ${SessionTimeout},

        [System.Object]
        ${ConnectionModeInPrimaryRole},

        [System.Object]
        ${ConnectionModeInSecondaryRole},

        [ValidateRange(0, 100)]
        [int]
        ${BackupPriority},

        [string[]]
        ${ReadOnlyRoutingList},

        [string]
        ${ReadonlyRoutingConnectionUrl},

        [System.Object]
        ${SeedingMode},

        [string[][]]
        ${LoadBalancedReadOnlyRoutingList},

        [Parameter(ParameterSetName = 'AsTemplate')]
        [switch]
        ${AsTemplate},

        [Parameter(ParameterSetName = 'AsTemplate')]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Version},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlAzureKeyVaultColumnMasterKeySettings
{
    <#
    .SYNOPSIS
        Creates a SqlColumnMasterKeySettings object describing an asymmetric key stored in Azure Key Vault.
    .PARAMETER KeyUrl
        Specifies the link, as a URL, of the key in Azure Key Vault or a managed HSM.
    .PARAMETER Signature
        Specifies a hexadecimal string that is a digital signature of column master key properties. A client driver can verify the signature to ensure  the column master key properties have not been tampered with.

        This parameter is allowed only if AllowEnclaveComputations is specified. If AllowEnclaveComputations is specified, but Signature is not, the cmdlet automatically computes the signature and populates the Signature property of the new SqlColumnMasterKeySettings object.
    .PARAMETER KeyVaultAccessToken
        Specifies an access token for key vaults in Azure Key Vault. Use this parameter if the specified column master key is stored in a key vault in Azure Key Vault and the cmdlet is expected to sign key metadata.
    .PARAMETER ManagedHsmAccessToken
        Specifies an access token for managed HSMs in Azure Key Vault. Use this parameter if the specified column master key is stored in a managed HSM in Azure Key Vault and the cmdlet is expected to sign key metadata.
    .PARAMETER AllowEnclaveComputations
        Specifies whether the column master key allows enclave computations. If the parameter is specified, server-side secure enclaves will be allowed to perform computations on data protected with the column master key. Not valid for SQL Server 2017 and older versions.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyUrl},

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Signature},

        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyVaultAccessToken},

        [ValidateNotNullOrEmpty()]
        [string]
        ${ManagedHsmAccessToken},

        [Parameter(Position = 1)]
        [switch]
        ${AllowEnclaveComputations}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlBackupEncryptionOption
{
    <#
    .SYNOPSIS
        Creates the encryption options for the Backup-SqlDatabase cmdlet or the Set-SqlSmartAdmin cmdlet.
    .PARAMETER NoEncryption
        Indicates that this cmdlet disables encryption. This parameter cannot be used with any other parameters.
    .PARAMETER Algorithm
        Specifies the encryption algorithm.
    .PARAMETER EncryptorType
        Specifies the encryptor type.
    .PARAMETER EncryptorName
        Specifies the name of the server certificate or server asymmetric key.
    #>

    [CmdletBinding()]
    param (
        [switch]
        ${NoEncryption},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Algorithm},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${EncryptorType},

        [ValidateNotNullOrEmpty()]
        [string]
        ${EncryptorName}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlCertificateStoreColumnMasterKeySettings
{
    <#
    .SYNOPSIS
        Creates a SqlColumnMasterKeySettings object referencing the specified certificate.
    .PARAMETER CertificateStoreLocation
        Specifies the certificate store location, containing the certificate. The acceptable values for this parameter are:

        - CurrentUser

        - LocalMachine
    .PARAMETER Thumbprint
        Specifies the thumbprint of the certificate.
    .PARAMETER Signature
        Specifies a hexadecimal string that is a digital signature of column master key properties. A client driver can verify the signature to ensure the column master key properties have not been tampered with. This parameter is allowed only if AllowEnclaveComputations is specified. If AllowEnclaveComputations is specified, but Signature is not, the cmdlet automatically computes the signature and populates the Signature property of the new SqlColumnMasterKeySettings object.
    .PARAMETER AllowEnclaveComputations
        Specifies whether the column master key allows enclave computations. If the parameter is specified, server-side secure enclaves will be allowed to perform computations on data protected with the column master key. Not valid for SQL Server 2017 and older versions.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateStoreLocation},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Thumbprint},

        [Parameter(Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Signature},

        [Parameter(Position = 2)]
        [switch]
        ${AllowEnclaveComputations}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlCngColumnMasterKeySettings
{
    <#
    .SYNOPSIS
        Creates a SqlColumnMasterKeySettings object describing an asymmetric key stored in a key store supporting the CNG API.
    .PARAMETER CngProviderName
        Specifies the name of the CNG provider for the key store.
    .PARAMETER KeyName
        Specifies the name of the key in the key store.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CngProviderName},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyName}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlColumnEncryptionKey
{
    <#
    .SYNOPSIS
        Crates a column encryption key object in the database.
    .PARAMETER ColumnMasterKeyName
        Specifies the name of the column master key that was used to produce the specified encrypted value of the column encryption key, or the name the column master key that is used to produce the new encrypted value.
    .PARAMETER EncryptedValue
        Specifies a hexadecimal string that is an encrypted column encryption key value.
    .PARAMETER KeyVaultAccessToken
        Specifies an access token for key vaults in Azure Key Vault. Use this parameter if the column master key you want to use to encrypt the new column encryption key is stored in a key vault in Azure Key Vault.
    .PARAMETER ManagedHsmAccessToken
        Specifies an access token for managed HSMs in Azure Key Vault. Use this parameter if the column master key you want to use to encrypt the new column encryption key is stored in a managed HSM in Azure Key Vault.
    .PARAMETER Name
        Specifies the name of the column encryption key object to be created.
    .PARAMETER InputObject
        Specifies the SQL database object, for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database, for which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet runs a Transact-SQL script that performs the operation.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ColumnMasterKeyName},

        [ValidateNotNullOrEmpty()]
        [string]
        ${EncryptedValue},

        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyVaultAccessToken},

        [ValidateNotNullOrEmpty()]
        [string]
        ${ManagedHsmAccessToken},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlColumnEncryptionKeyEncryptedValue
{
    <#
    .SYNOPSIS
        Creates the encrypted value of a column encryption key.
    .PARAMETER TargetColumnMasterKeySettings
        Specifies the SqlColumnMasterKeySettings object that this cmdlet uses to determine where the column master key, to be used to encrypt the new encrypted value, is stored.
    .PARAMETER ColumnMasterKeySettings
        Specifies the SqlColumnMasterKeySettings object that this cmdlet uses to find where the column master key is stored.
    .PARAMETER EncryptedValue
        Specifies the existing encrypted value.

        If you specify a value for this parameter, the cmdlet will first decrypt this value using the column master key referenced by the ColumnMasterKeySettings parameter and then re-encrypt it using the column master key referenced by the TargetColumnMasterKeySettings parameter.
    .PARAMETER KeyVaultAccessToken
        Specifies an access token for key vaults in Azure Key Vault. Use this parameter if the column master key for encrypting or decrypting a symmetric column encryption key is stored in a key vault in Azure Key Vault.
    .PARAMETER ManagedHsmAccessToken
        Specifies an access token for managed HSMs in Azure Key Vault. Use this parameter if the column master key for encrypting or decrypting a symmetric column encryption key is stored in a managed HSM in Azure Key Vault.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${TargetColumnMasterKeySettings},

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${ColumnMasterKeySettings},

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${EncryptedValue},

        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyVaultAccessToken},

        [ValidateNotNullOrEmpty()]
        [string]
        ${ManagedHsmAccessToken}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlColumnEncryptionSettings
{
    <#
    .SYNOPSIS
        Creates a SqlColumnEncryptionSettings object that encapsulates information about a single column's encryption, including CEK and encryption type.
    .PARAMETER ColumnName
        Specifies the name of the database column that uses the following format: [<schemaName>.]<tableName>.<columnName>.
    .PARAMETER EncryptionType
        Specifies the type of encryption. The acceptable values for this parameter are:

        - Deterministic, for deterministic encryption

        - Randomized, for randomized encryption

        - Plaintext, indicating that the column is not encrypted.
    .PARAMETER EncryptionKey
        Specifies the name of the column encryption key object. This argument is not allowed if the EncryptionType parameter value is set to Plaintext.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ColumnName},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${EncryptionType},

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${EncryptionKey}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlColumnMasterKey
{
    <#
    .SYNOPSIS
        Creates a column master key object in the database.
    .PARAMETER ColumnMasterKeySettings
        Specifies the SqlColumnMasterKeySettings object that specifies the location of the actual column master key.

        The SqlColumnMasterKeySettings object has two properties: KeyStoreProviderName and KeyPath . KeyStoreProviderName specifies the name of a column master key store provider, which an Always Encrypted-enabled client driver must use to access the key store containing the column master key. KeyPath specifies the location of the column master key within the key store. The KeyPath format is specific to the key store.
    .PARAMETER Name
        Specifies the name of the column master key object that this cmdlet creates.
    .PARAMETER InputObject
        Specifies the SQL database object, for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database, for which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${ColumnMasterKeySettings},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlColumnMasterKeySettings
{
    <#
    .SYNOPSIS
        Creates a SqlColumnMasterKeySettings object describing a master key stored in an arbitrarily specified key store provider and path.
    .PARAMETER KeyStoreProviderName
        Specifies the provider name of the key store used to protect the physical master key.
    .PARAMETER KeyPath
        Specifies the path within the key store of the physical master key.
    .PARAMETER Signature
        Specifies a hexadecimal string that is a digital signature of column master key properties. A client driver can verify the signature to ensure the column master key properties have not been tampered with. This parameter is allowed only if AllowEnclaveComputations is specified. If AllowEnclaveComputations is specified, but Signature is not, the cmdlet automatically computes the signature and populates the Signature property of the new SqlColumnMasterKeySettings object.
    .PARAMETER KeyVaultAccessToken
        Specifies an access token for key vaults in Azure Key Vault. Use this parameter if the specified column master key is stored in a key vault in Azure Key Vault and the cmdlet is expected to sign key metadata.
    .PARAMETER ManagedHsmAccessToken
        Specifies an access token for managed HSMs in Azure Key Vault. Use this parameter if the specified column master key is stored in a managed HSM in Azure Key Vault and the cmdlet is expected to sign key metadata.
    .PARAMETER AllowEnclaveComputations
        Specifies whether the column master key allows enclave computations. If the parameter is specified, server-side secure enclaves will  be allowed to perform computations on data protected with the column master key. Not valid for SQL Server 2017 and older versions.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyStoreProviderName},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyPath},

        [Parameter(Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Signature},

        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyVaultAccessToken},

        [ValidateNotNullOrEmpty()]
        [string]
        ${ManagedHsmAccessToken},

        [Parameter(Position = 2)]
        [switch]
        ${AllowEnclaveComputations}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlCredential
{
    <#
    .SYNOPSIS
        Creates a SQL Server credential object.
    .PARAMETER Identity
        Specifies the name of user or account. For Windows Azure storage service authentication, this is the name of the Windows Azure storage account.
    .PARAMETER Secret
        Specifies the password for the user or account. For Windows Azure storage service authentication, this is the storage account access key value.
    .PARAMETER ProviderName
        Specifies the cryptographic provider name for the Enterprise Key Management Provider (EKM).
    .PARAMETER Name
        Specifies the name of the credential.
    .PARAMETER InputObject
        Specifies the Server object where the credential should be created.
    .PARAMETER Path
        Specifies the path of the instance of SQL Server for which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Identity},

        [ValidateNotNullOrEmpty()]
        [securestring]
        ${Secret},

        [string]
        ${ProviderName},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlCspColumnMasterKeySettings
{
    <#
    .SYNOPSIS
        Creates a SqlColumnMasterKeySettings object describing an asymmetric key stored in a key store with a CSP supporting CAPI.
    .PARAMETER CspProviderName
        Specifies the name of the CSP provider for the key store.
    .PARAMETER KeyName
        Specifies the name of the key in the key store.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CspProviderName},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyName}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlHADREndpoint
{
    <#
    .SYNOPSIS
        Creates a database mirroring endpoint on a SQL Server instance.
    .PARAMETER Port
        Specifies the TCP port on which the endpoint will listen for connections. The default is `5022`.
    .PARAMETER Owner
        Specifies the login of the owner of the endpoint. By default, this is the current login.
    .PARAMETER Certificate
        Specifies the name of the certificate that the endpoint will use to authenticate connections. The far endpoint must have a certificate with the public key matching the private key of the certificate.
    .PARAMETER IpAddress
        Specifies the IP address of the endpoint. The default is ALL, which indicates that the listener accepts a connection on any valid IP address.
    .PARAMETER AuthenticationOrder
        Specifies the order and type of authentication that is used by the endpoint.

        If the specified option calls for a certificate, the Certificate parameter must be set.
    .PARAMETER Encryption
        Specifies the encryption option for the endpoint.

        The default value is `Required`.
    .PARAMETER EncryptionAlgorithm
        Specifies the form of encryption used by the endpoint.

        By default the endpoint will use Aes encryption.

        NOTE: The RC4 algorithm is only supported for backward compatibility. New material can only be encrypted using RC4 or RC4_128 when the database is in compatibility level 90 or 100, but this is not recommended. For increased security, use a newer algorithm such as one of the `AES` algorithms instead.
    .PARAMETER Name
        Specifies the endpoint name.
    .PARAMETER InputObject
        Specifies the server object of the SQL Server instance where the endpoint is created.
    .PARAMETER Path
        Specifies the path to the SQL Server instance of the endpoint. If not specified, the current working location is used.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [ValidateNotNullOrEmpty()]
        [int]
        ${Port},

        [ValidateNotNullOrEmpty()]
        [string]
        ${Owner},

        [ValidateNotNullOrEmpty()]
        [string]
        ${Certificate},

        [ValidateNotNullOrEmpty()]
        [ipaddress]
        ${IpAddress},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${AuthenticationOrder},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Encryption},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${EncryptionAlgorithm},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlVulnerabilityAssessmentBaseline
{
    <#
    .SYNOPSIS
        Creates a new instance of Microsoft.SQL.VulnerabilityAssessment.SecurityCheckBaseline.
    .PARAMETER SecurityCheckId
        The security check id which the baseline applies to.
    .PARAMETER ExpectedResult
        The baseline expected result for the security check query. This expected result overrides the security check original expected results.
    .PARAMETER Severity
        The new severity for the security check. This severity overrides the security check original severity.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${SecurityCheckId},

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [string[][]]
        ${ExpectedResult},

        [ValidateNotNullOrEmpty()]
        [System.Nullable[System.Object]]
        ${Severity}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function New-SqlVulnerabilityAssessmentBaselineSet
{
    <#
    .SYNOPSIS
        Creates a new instance of Microsoft.SQL.VulnerabilityAssessment.SecurityCheckBaselineSet.
    .PARAMETER Baselines
        A list of security check baselines. The baseline set will be initialized with this list.
    #>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${Baselines}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Read-SqlTableData
{
    <#
    .SYNOPSIS
        Reads data from a table of a SQL database.
    .PARAMETER TableName
        Specifies the name of the table from which this cmdlet reads.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the TableName parameter anyway.
    .PARAMETER TopN
        Specifies the number of rows of data that this cmdlet returns. If you do not specify this parameter, the cmdlet returns all the rows.
    .PARAMETER ColumnName
        Specifies an array of names of columns that this cmdlet returns.
    .PARAMETER ColumnOrder
        Specifies an array of names of columns by which this cmdlet sorts the columns that it returns.
    .PARAMETER ColumnOrderType
        Specifies an array of order types for columns that this cmdlet returns. The acceptable values for this parameter are:

        - ASC. Ascending.

        - DESC. Descending.

        The values that you specify for this parameter match the columns that you specify in the ColumnOrder parameter. This cmdlet ignores any extra values.

    .PARAMETER OutputAs
        Specifies the type of output.
    .PARAMETER DatabaseName
        Specifies the name of the database that contains the table.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the DatabaseName parameter anyway.
    .PARAMETER SchemaName
        Specifies the name of the schema for the table.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the SchemaName parameter anyway.
    .PARAMETER IgnoreProviderContext
        Indicates that this cmdlet does not use the current context to override the values of the ServerInstance , DatabaseName , SchemaName , and TableName parameters. If you do not specify this parameter, the cmdlet ignores the values of these parameters, if possible, in favor of the context in which you run the cmdlet.
    .PARAMETER SuppressProviderContextWarning
        Indicates that this cmdlet suppresses the warning message that states that the cmdlet uses the provider context.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server. For the default instance, specify the computer name. For named instances, use the format `ComputerName\InstanceName`.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the ServerInstance parameter anyway.
    .PARAMETER Credential
        Specifies a PSCredential object for the connection to SQL Server. To obtain a credential object, use the Get-Credential cmdlet. For more information, type Get-Help Get-Credential.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Path
        Specifies the path to the table that this cmdlet reads.
    .PARAMETER InputObject
        Specifies an array of SQL Server Management Objects (SMO) objects that represent the table that this cmdlet reads.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(ParameterSetName = 'ByName')]
        [Alias('Name')]
        [string]
        ${TableName},

        [Alias('First')]
        [long]
        ${TopN},

        [Alias('ColumnToReturn')]
        [string[]]
        ${ColumnName},

        [Alias('OrderBy')]
        [string[]]
        ${ColumnOrder},

        [System.Object[]]
        ${ColumnOrderType},

        [Alias('As')]
        [System.Object]
        ${OutputAs},

        [Parameter(ParameterSetName = 'ByName')]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByName')]
        [string]
        ${SchemaName},

        [Parameter(ParameterSetName = 'ByName')]
        [switch]
        ${IgnoreProviderContext},

        [Parameter(ParameterSetName = 'ByName')]
        [switch]
        ${SuppressProviderContextWarning},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Read-SqlViewData
{
    <#
    .SYNOPSIS
        Reads data from a view of a SQL database.
    .PARAMETER ViewName
        Specifies the name of the view from which this cmdlet reads.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the ViewName parameter anyway.
    .PARAMETER TopN
        Specifies the number of rows of data that this cmdlet returns. If you do not specify this parameter, the cmdlet returns all the rows.
    .PARAMETER ColumnName
        Specifies an array of names of columns that this cmdlet returns.
    .PARAMETER ColumnOrder
        Specifies an array of names of columns by which this cmdlet sorts the columns that it returns.
    .PARAMETER ColumnOrderType
        Specifies an array of order types for columns that this cmdlet returns. The acceptable values for this parameter are:

        - ASC.  Ascending.

        - DESC. Descending.

        The values that you specify for this parameter match the columns that you specify in the ColumnOrder parameter. This cmdlet ignores any extra values.

    .PARAMETER OutputAs
        Specifies the type of output.
    .PARAMETER DatabaseName
        Specifies the name of the database that contains the view.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the DatabaseName parameter anyway.
    .PARAMETER SchemaName
        Specifies the name of the schema for the view.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the SchemaName parameter anyway.
    .PARAMETER IgnoreProviderContext
        Indicates that this cmdlet does not use the current context to override the values of the ServerInstance , DatabaseName , SchemaName , and ViewName parameters. If you do not specify this parameter, the cmdlet ignores the values of these parameters, if possible, in favor of the context in which you run the cmdlet.
    .PARAMETER SuppressProviderContextWarning
        Indicates that this cmdlet suppresses the warning message that states that the cmdlet uses the provider context.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server. For the default instance, specify the computer name. For named instances, use the format `ComputerName\InstanceName`.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the ServerInstance parameter anyway.
    .PARAMETER Credential
        Specifies a PSCredential object for the connection to SQL Server. To obtain a credential object, use the Get-Credential cmdlet. For more information, type Get-Help Get-Credential.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Path
        Specifies the path of the view that this cmdlet reads.
    .PARAMETER InputObject
        Specifies an array of SQL Server Management Objects (SMO) objects that represent the view that this cmdlet reads.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(ParameterSetName = 'ByName')]
        [Alias('Name')]
        [string]
        ${ViewName},

        [Alias('First')]
        [long]
        ${TopN},

        [Alias('ColumnToReturn')]
        [string[]]
        ${ColumnName},

        [Alias('OrderBy')]
        [string[]]
        ${ColumnOrder},

        [System.Object[]]
        ${ColumnOrderType},

        [Alias('As')]
        [System.Object]
        ${OutputAs},

        [Parameter(ParameterSetName = 'ByName')]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByName')]
        [string]
        ${SchemaName},

        [Parameter(ParameterSetName = 'ByName')]
        [switch]
        ${IgnoreProviderContext},

        [Parameter(ParameterSetName = 'ByName')]
        [switch]
        ${SuppressProviderContextWarning},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Read-SqlXEvent
{
    <#
    .SYNOPSIS
        Reads SQL Server XEvents from XEL file or live SQL XEvent session.
    .PARAMETER FileName
        File name of a XEvent file to read.
    .PARAMETER ConnectionString
        SQL Server connection string.
    .PARAMETER SessionName
        The SQL Server XEvent session name as defined by the CREATE EVENT SESSION Transact-SQL.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByFile')]
    [OutputType([Microsoft.SqlServer.XEvent.XELite.IXEvent])]
    param (
        [Parameter(ParameterSetName = 'ByFile', Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]
        ${FileName},

        [Parameter(ParameterSetName = 'ByLiveData', Mandatory = $true)]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByLiveData', Mandatory = $true)]
        [string]
        ${SessionName}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-RoleMember
{
    <#
    .SYNOPSIS
        Removes a member from the specific Role of a specific database.
    .PARAMETER MemberName
        Name of the member who should be removed.
    .PARAMETER Database
        Database name to which the Role belongs to.
    .PARAMETER RoleName
        Role name from which the member should be removed.
    .PARAMETER DatabaseRole
        Microsoft.AnalysisServices.Role object from which the member should be removed. (Multidimensional metadata only)
    .PARAMETER ModelRole
        The pipeline role object.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance. If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true)]
        [string]
        ${MemberName},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 2)]
        [string]
        ${RoleName},

        [Parameter(ParameterSetName = 'ParameterSetInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${DatabaseRole},

        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${ModelRole},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlAvailabilityDatabase
{
    <#
    .SYNOPSIS
        Removes an availability database from its availability group.
    .PARAMETER Path
        Specifies the path of an availability database that cmdlet removes.
    .PARAMETER InputObject
        Specifies availability database, as an AvailabilityDatabase object, that this cmdlet removes.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlAvailabilityGroup
{
    <#
    .SYNOPSIS
        Removes an availability group.
    .PARAMETER Path
        Specifies the path of the availability group that this cmdlet removes.
    .PARAMETER InputObject
        Specifies availability group that this cmdlet removes.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlAvailabilityReplica
{
    <#
    .SYNOPSIS
        Removes a secondary availability replica.
    .PARAMETER Path
        Specifies the path to the availability replica. This parameter is required.
    .PARAMETER InputObject
        Specifies the AvailabilityReplica object for the replica to remove.
    .PARAMETER Script
        Indicates that this command returns a Transact-SQL script that performs the task.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlColumnEncryptionKey
{
    <#
    .SYNOPSIS
        Removes the column encryption key object from the database.
    .PARAMETER Name
        Specifies the name of the column encryption key object that this cmdlet removes.
    .PARAMETER InputObject
        Specifies the SQL database object, for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database, for which this cmdlet runs the operation. If you do not specify a value for this parameter, this cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlColumnEncryptionKeyValue
{
    <#
    .SYNOPSIS
        Removes an encrypted value from an existing column encryption key object in the database.
    .PARAMETER ColumnMasterKeyName
        Specifies the name of the column master key that was used to produce the encrypted value that this cmdlet removes.
    .PARAMETER Name
        Specifies the name of the column encryption key object that this cmdlet removes.
    .PARAMETER InputObject
        Specifies the SQL database object for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database for which this cmdlet runs the operation. If you do not specify a value for this parameter, this cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ColumnMasterKeyName},

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlColumnMasterKey
{
    <#
    .SYNOPSIS
        Removes the column master key object from the database.
    .PARAMETER Name
        Specifies the name of the column master key object that this cmdlet removes.
    .PARAMETER InputObject
        Specifies the SQL database object, for which this cmdlet performs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database, for which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlCredential
{
    <#
    .SYNOPSIS
        Removes the SQL credential object.
    .PARAMETER Path
        Specifies the path of the credential, as an array, on which this cmdlet performs this operation. For instance, `SQLSERVER:\SQL\Computer\Instance\Credentials\Credential`.
    .PARAMETER InputObject
        Specifies an input credential object, as an array. You can use the Get-SqlCredential to get the object.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlLogin
{
    <#
    .SYNOPSIS
        Removes Login objects from an instance of SQL Server.
    .PARAMETER LoginName
        Specifies an array of names of Login objects that this cmdlet removes. > Note: The case sensitivity is the same as that of the instance of SQL Server.
    .PARAMETER RemoveAssociatedUsers
        Indicates that this cmdlet removes the users that are associated with the Login object.
    .PARAMETER Force
        Forces the command to run without asking for user confirmation.
    .PARAMETER InputObject
        Specifies an SQL Server Management Objects (SMO) object that represents the Login object that this cmdlet removes.
    .PARAMETER Path
        Specifies the path of the SQL Server on which this cmdlet runs the operation. The default value is the current working directory.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server. For the default instance, specify the computer name. For named instances, use the format `ComputerName\InstanceName`.
    .PARAMETER Credential
        Specifies a PSCredential object for the connection to SQL Server. To obtain a credential object, use the Get-Credential cmdlet. For more information, type Get-Help Get-Credential.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Alias('Name')]
        [string[]]
        ${LoginName},

        [switch]
        ${RemoveAssociatedUsers},

        [switch]
        ${Force},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Remove-SqlSensitivityClassification
{
    <#
    .SYNOPSIS
        Remove the sensitivity label and/or information type of columns in the database.
    .PARAMETER ColumnName
        Name(s) of columns for which information type and sensitivity label is fetched.
    .PARAMETER ConnectionString
        Specifies a connection string to connect to the database. If this parameter is present, other connection parameters will be ignored
    .PARAMETER ServerInstance
        Specifieseither the name of the server instance (a string) or SQL Server Management Objects (SMO) object that specifies the name of an instance of the Database Engine. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER DatabaseName
        Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.

        If the DatabaseName parameter is not specified, the database that is used depends on whether the current path specifies both the SQLSERVER:\SQL folder and a database name. If the path specifies both the SQL folder and a database name, this cmdlet connects to the database that is specified in the path.
    .PARAMETER Credential
        Specifies a credential used to connect to the database.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies a SQL Server Management Object (SMO) that represent the database that this cmdlet uses.
    .PARAMETER SuppressProviderContextWarning
        Indicates that this cmdlet suppresses the warning that this cmdlet has used in the database context from the current SQLSERVER:\SQL path setting to establish the database context for the cmdlet.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByContext')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Column')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ColumnName},

        [Parameter(ParameterSetName = 'ByConnectionString', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByDBObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByContext')]
        [switch]
        ${SuppressProviderContextWarning}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Restore-ASDatabase
{
    <#
    .SYNOPSIS
        Restores a specified Analysis Service database from a backup file.
    .PARAMETER RestoreFile
        Restores a specified Analysis Service database from a backup file.
    .PARAMETER Name
        Analysis Services Database Name that has to be restored.
    .PARAMETER AllowOverwrite
        Indicates whether the destination files can be overwritten during restore.
    .PARAMETER Security
        Represents security settings for the restore operation.
    .PARAMETER Password
        The password to use to decrypt the restoration file.
    .PARAMETER StorageLocation
        The database storage location.
    .PARAMETER Locations
        Remote location of the partitions to be restored.
    .PARAMETER Server
        Optionally specifies the server instance to connect to if not currently in the SQLAS Provider directory.
    .PARAMETER Credential
        If this parameter is specified, the user name and password passed will be used to connect to specified Analysis Server instance. If no credentials are specified default windows account of the user who is running the tool will be used.
    .PARAMETER ServicePrincipal
        Specifies that this connection is using service principal.
    .PARAMETER ApplicationId
        The application Id for the service principal.
    .PARAMETER TenantId
        The tenant Id for the service principal.
    .PARAMETER CertificateThumbprint
        The certificate thumbprint for the service principal.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ParameterSetName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${RestoreFile},

        [Parameter(ParameterSetName = 'ParameterSetName', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [switch]
        ${AllowOverwrite},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [System.Object]
        ${Security},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [securestring]
        ${Password},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [string]
        ${StorageLocation},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [System.Object[]]
        ${Locations},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [string]
        ${Server},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [pscredential]
        ${Credential},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [switch]
        ${ServicePrincipal},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApplicationId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TenantId},

        [Parameter(ParameterSetName = 'ParameterSetName')]
        [Parameter(ParameterSetName = 'ParameterSetInputObject')]
        [Parameter(ParameterSetName = 'ParameterSetTabularName')]
        [Parameter(ParameterSetName = 'ParameterSetTabularInputObject')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Restore-SqlDatabase
{
    <#
    .SYNOPSIS
        Restores a database from a backup or transaction log records.
    .PARAMETER ClearSuspectPageTable
        Indicates that the suspect page table is deleted after the restore operation.
    .PARAMETER KeepReplication
        Indicates that the replication configuration is preserved. If not set, the replication configuration is ignored by the restore operation.
    .PARAMETER Partial
        Indicates that the restore operation is a partial restore.
    .PARAMETER ReplaceDatabase
        Indicates that a new image of the database is created. This overwrites any existing database with the same name. If not set, the restore operation will fail when a database with that name already exists on the server.
    .PARAMETER RestrictedUser
        Indicates that access to the restored database is restricted to the db_owner fixed database role, and the dbcreator and sysadmin fixed server roles.
    .PARAMETER Offset
        Specifies the page addresses to be restored. This is only used when RestoreAction is set to OnlinePage.
    .PARAMETER RelocateFile
        Specifies a list of Smo.Relocate file objects. Each object consists of a logical backup file name and a physical file system location. The restore moves the restored database into the specified physical location on the target server.
    .PARAMETER AutoRelocateFile
        When this switch is specified, the cmdlet will take care of automatically relocating all the the logical files in the backup, unless such logical file is specified with the RelocateFile . The server DefaultFile and DefaultLog are used to relocate the files.
    .PARAMETER FileNumber
        Specifies the index number that is used to identify the targeted backup set on the backup medium.
    .PARAMETER RestoreAction
        Specifies the type of restore operation that is performed. Valid values are:

        - Database.    The database is restored.

        - Files.       One or more data files are restored. The DatabaseFile or DatabaseFileGroup parameter must be specified.

        - OnlinePage.  A data page is restored online so that the database remains available to users.

        - OnlineFiles. Data files are restored online so that the database remains available to users. The DatabaseFile or DatabaseFileGroup parameter must be specified.

        - Log.         The translaction log is restored.
    .PARAMETER StandbyFile
        Specifies the name of an undo file that is used as part of the imaging strategy for a SQL Server instance.
    .PARAMETER StopAtMarkAfterDate
        Specifies the date to be used with the mark name specified by the StopAtMarkName parameter to determine the stopping point of the recovery operation.
    .PARAMETER StopAtMarkName
        Specifies the marked transaction at which to stop the recovery operation. This is used with StopAtMarkAfterDate to determine the stopping point of the recovery operation. The recoverd data includes the transaction that contains the mark. If the StopAtMarkAfterDate value is not set, recovery stops at the first mark with the specified name.
    .PARAMETER StopBeforeMarkAfterDate
        Specifies the date to be used with StopBeforeMarkName to determine the stopping point of the recovery operation.
    .PARAMETER StopBeforeMarkName
        Specifies the marked transaction before which to stop the recovery operation. This is used with StopBeforeMarkAfterDate to determine the stopping point of the recovery operation.
    .PARAMETER ToPointInTime
        Specifies the endpoint for database log restoration. This only applies when RestoreAction is set to Log.
    .PARAMETER Database
        Specifies the name of the database to restore. This cannot be used with the DatabaseObject parameter. When this parameter is used, the Path , InputObject , or ServerInstance parameters must also be specified.
    .PARAMETER DatabaseObject
        Specifies a database object for the restore operation.
    .PARAMETER Path
        Specifies the path of the SQL Server instance on which to execute the restore operation. This parameter is optional. If not specified, the current working location is used.
    .PARAMETER InputObject
        Specifies the server object of the SQL Server instance where the restore occurs.
    .PARAMETER ServerInstance
        Specifies the name of a SQL Server instance. This server instance becomes the target of the restore operation.
    .PARAMETER Credential
        Specifies a PSCredential object that contains the credentials for a SQL Server login that has permission to perform this operation.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a timeout failure. The timeout value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not timeout.
    .PARAMETER BackupFile
        Specifies the location or locations where the backup files are stored. This parameter is optional. If not specified, the default backup location of the server is searched for the name `<database name>.trn` for log restores, or `<database name>.bak` for all other types of restores. This parameter cannot be used with the BackupDevice parameter. If you are backing up to the Windows Azure Blob Storage service (URL), either this parameter or the BackupDevice parameter must be specified.
    .PARAMETER SqlCredential
        Specifies an SQL Server credential object that stores authentication information. If you are backing up to Blob storage service, you must specify this parameter. The authentication information stored includes the Storage account name and the associated access key values. Do not specify this parameter for disk or tape.
    .PARAMETER BackupDevice
        Specifies the devices where the backups are be stored. This parameter cannot be used with the BackupFile parameter. Use this parameter if you are backing up to a tape device.
    .PARAMETER PassThru
        Indicates that this cmdlet outputs the Smo.Backup object used to perform the restore operation.
    .PARAMETER Checksum
        Indicates that a checksum value is calculated during the restore operation.
    .PARAMETER ContinueAfterError
        Indicates that the operation continues when a checksum error occurs. If not set, the operation will fail after a checksum error.
    .PARAMETER NoRewind
        Indicates that a tape drive is left open at the ending position when the restore is completed. If not set, the tape is rewound after the operation is completed. This does not apply to disk restores.
    .PARAMETER Restart
        Indicates that this cmdlet resumes a partially completed restore operation. If not set, the cmdlet restarts an interrupted restore operation at the beginning of the backup set.
    .PARAMETER UnloadTapeAfter
        Indicates that the tape device is rewound and unloaded when the operation is completed. If not set, no attempt is made to rewind and unload the tape medium. This does not apply to disk backups.
    .PARAMETER NoRecovery
        Indicates that the database is restored into the restoring state. A roll back operation does not occur and additional backups can be restored.
    .PARAMETER DatabaseFile
        Specifies the database files targeted by the restore operation. This is only used when the RestoreAction parameter is set to Files. When the RestoreAction parameter is set to Files, either the DatabaseFileGroups or DatabaseFiles parameter must also be specified.
    .PARAMETER DatabaseFileGroup
        Specifies the database file groups targeted by the restore operation. This is only used when the RestoreAction parameter is set to File. When the RestoreAction parameter is set to Files, either the DatabaseFileGroups or DatabaseFiles parameter must also be specified.
    .PARAMETER BlockSize
        Specifies the physical block size, in bytes, for the backup. The supported sizes are 512, 1024, 2048, 4096, 8192, 16384, 32768, and 65536 (64 KB) bytes. The default is 65536 for tape devices and 512 for all other devices.
    .PARAMETER BufferCount
        Specifies the total number of I/O buffers to be used for the backup operation. You can specify any positive integer. If there is insufficient virtual address space in the Sqlservr.exe process for the buffers, you will receive an out of memory error.
    .PARAMETER MaxTransferSize
        Specifies the maximum number of bytes to be transferred between the backup media and the SQL Server instance. The possible values are multiples of 65536 bytes (64 KB), up to 4194304 bytes (4 MB).
    .PARAMETER MediaName
        Specifies the name that identifies a media set.
    .PARAMETER Script
        Indicates that this cmdlet outputs a Transact-SQL script that performs the restore operation.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]
        ${ClearSuspectPageTable},

        [switch]
        ${KeepReplication},

        [switch]
        ${Partial},

        [switch]
        ${ReplaceDatabase},

        [switch]
        ${RestrictedUser},

        [long[]]
        ${Offset},

        [System.Object[]]
        ${RelocateFile},

        [switch]
        ${AutoRelocateFile},

        [int]
        ${FileNumber},

        [System.Object]
        ${RestoreAction},

        [string]
        ${StandbyFile},

        [string]
        ${StopAtMarkAfterDate},

        [string]
        ${StopAtMarkName},

        [string]
        ${StopBeforeMarkAfterDate},

        [string]
        ${StopBeforeMarkName},

        [string]
        ${ToPointInTime},

        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Database},

        [Parameter(ParameterSetName = 'ByDBObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${DatabaseObject},

        [Parameter(ParameterSetName = 'ByPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${BackupFile},

        [ValidateNotNullOrEmpty()]
        [psobject]
        ${SqlCredential},

        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${BackupDevice},

        [switch]
        ${PassThru},

        [switch]
        ${Checksum},

        [switch]
        ${ContinueAfterError},

        [switch]
        ${NoRewind},

        [switch]
        ${Restart},

        [switch]
        ${UnloadTapeAfter},

        [switch]
        ${NoRecovery},

        [ValidateNotNullOrEmpty()]
        [string[]]
        ${DatabaseFile},

        [ValidateNotNullOrEmpty()]
        [string[]]
        ${DatabaseFileGroup},

        [int]
        ${BlockSize},

        [int]
        ${BufferCount},

        [int]
        ${MaxTransferSize},

        [string]
        ${MediaName},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Resume-SqlAvailabilityDatabase
{
    <#
    .SYNOPSIS
        Resumes data movement on an availability database.
    .PARAMETER Path
        Specifies the path of an availability database that cmdlet resumes. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER InputObject
        Specifies availability database, as an AvailabilityDatabase object, that this cmdlet resumes.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Revoke-SqlAvailabilityGroupCreateAnyDatabase
{
    <#
    .SYNOPSIS
        Revokes the `CREATE ANY DATABASE` permission on an Always On Availability Group.
    .PARAMETER Path
        Specifies the path to the Availability Group on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies the target Availability Group object.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlAvailabilityGroup
{
    <#
    .SYNOPSIS
        Sets settings on an availability group.
    .PARAMETER AutomatedBackupPreference
        Specifies the automated backup preference for the availability group. The acceptable values for this parameter are:

        - Primary.       Specifies that the backups always occur on the primary replica. This option supports the use of features                   not available when backup runs on a secondary replica, such as differential backups. - SecondaryOnly. Specifies that backups are never performed on primary replicas. If the primary replica is the only replica                  online, the backup does not occur. - Secondary.     Specifies that backups occur on secondary replicas, unless the primary replica is the only replica online.                  Then the backup occurs on the primary replica. - None.          Specifies that the primary or secondary status is not taken into account when deciding which replica                  performs backups. Instead, backup priority and online status determine which replica performs backups.
    .PARAMETER FailureConditionLevel
        Specifies the automatic failover behavior of the availability group. The acceptable values for this parameter are:

        - OnServerDown.                    Failover or restart if the SQL Server service stops.

        - OnServerUnresponsive.            Failover or restart if any condition of lower value is satisfied, plus when the SQL Server

        service is connected to the cluster and the HealthCheckTimeout threshold is exceeded, or                                    if the availability replica currently in primary role is in a failed state.  - OnCriticalServerError.           Failover or restart if any condition of lower value is satisfied, plus when an internal                                    critical server error occurs, which include out of memory condition, serious write-access                                    violation, or too much dumping.  - OnModerateServerError.           Failover or restart if any condition of lower value is satisfied, plus if a moderate Server                                    error occurs, wich includes persistent out of memory condition.  - OnAnyQualifiedFailureConditions. Failover or restart if any condition of lower value is satisfied, plus if a qualifying                                     failure condition occurs, which includes engine worker thread exhaustion and unsolvable                                    deadlock detected.
    .PARAMETER HealthCheckTimeout
        Specifies the length of time, in milliseconds, after which Always On Availability Groups declares an unresponsive server to be unhealthy.
    .PARAMETER DatabaseHealthTrigger
        Specifies whether to trigger an automatic failover of the availability group  if any user database replica within an availability group encounters a database failure condition.
    .PARAMETER RequiredSynchronizedSecondariesToCommit
        The number of synchronous commit secondaries that must be available to be able to commit on the primary.

        If a `SYNCHRONOUS_COMMIT` secondary is disconnected from the primary for some time, the primary demotes it to `ASYNCHRONOUS_COMMIT` to avoid blocking commits. If the primary then becomes unavailable and the user wishes to fail over to one of these secondaries, they may incur data loss. By setting RequiredSynchronizedSecondariesToCommit to some number, the user can prevent the data loss since the primary will start blocking commits if too many secondaries are demoted to `ASYNCHRONOUS_COMMIT`.

        The default value of this setting is 0, which means the primary will never block commits. This is identical to the behavior before SQL Server 2017.
    .PARAMETER InputObject
        Specifies the availability group, as an AvailabilityGroup object, that this cmdlet modifies.
    .PARAMETER Path
        Specifies the path of the availability database that cmdlet modifies. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [System.Object]
        ${AutomatedBackupPreference},

        [System.Object]
        ${FailureConditionLevel},

        [int]
        ${HealthCheckTimeout},

        [bool]
        ${DatabaseHealthTrigger},

        [int]
        ${RequiredSynchronizedSecondariesToCommit},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlAvailabilityGroupListener
{
    <#
    .SYNOPSIS
        Sets the port setting on an availability group listener.
    .PARAMETER Port
        Specifies the port on which the listener listens for connections. The default port is TCP port 1433.
    .PARAMETER InputObject
        Specifies the listener, as an AvailabilityGroupListener object, that this cmdlet modifies.
    .PARAMETER Path
        Specifies the path of the availability group listener that this cmdlet modifies. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [int]
        ${Port},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlAvailabilityReplica
{
    <#
    .SYNOPSIS
        Sets the settings on an availability replica.
    .PARAMETER AvailabilityMode
        Specifies the replica availability mode.

        You can specify a value of `$Null`.
    .PARAMETER FailoverMode
        Specifies the failover mode.

        You can specify a value of `$Null`.
    .PARAMETER EndpointUrl
        Specifies the URL of the database mirroring endpoint. This URL is a TCP address in the following form: `TCP://system-address:port`
    .PARAMETER SessionTimeout
        Specifies the amount of time, in seconds, to wait for a response between the primary replica and this replica before the connection fails.
    .PARAMETER ConnectionModeInPrimaryRole
        Specifies how the availability replica handles connections when in the primary role. The acceptable values for this parameter are:

        - AllowReadWriteConnections. Allows read/write connections.

        - AllowAllConnections.       Allows all connections.
    .PARAMETER ConnectionModeInSecondaryRole
        Specifies how the availability replica handles connections when in the secondary role. The acceptable values for this parameter are:

        - AllowNoConnections.             Disallows connections.

        - AllowReadIntentConnectionsOnly. Allows only read-intent connections.

        - AllowAllConnections.            Allows all connections.
    .PARAMETER SeedingMode
        Specifies how the secondary replica will be initially seeded.
        Allowed values: - Automatic. Enables direct seeding.              This method will seed the secondary replica over the network.              This method does not require you to backup and restore a copy of the primary database on the replica. - Manual.    Specifies manual seeding.              This method requires you to create a backup of the database on the primary replica and manually              restore that backup on the secondary replica.
    .PARAMETER BackupPriority
        Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup.

        A value of zero (0) indicates that the replica is not a candidate.
    .PARAMETER ReadOnlyRoutingList
        Specifies an ordered list of replica server names that represent the probe sequence for connection director to use when redirecting read-only connections through this availability replica. This parameter applies if the availability replica is the current primary replica of the availability group.
    .PARAMETER ReadonlyRoutingConnectionUrl
        Specifies the fully-qualified domain name (FQDN) and port to use when routing to the replica for read-only connections, as in the following example: `TCP://DBSERVER8.manufacturing.Contoso.com:7024`
    .PARAMETER LoadBalancedReadOnlyRoutingList
        Specifies the load-balanced read-only routing list.

        The routing list is a list of load-balanced sets, which in turn are lists of replicas.

        For example, passing a value like

        @('Server1','Server2'),@('Server3'),@('Server4')

        means what we are passing 3 load-balanced sets: 1 with 2 replicas (Server1 and Server2) and 2 with just one (Server3 and Server4, respectively).

        At runtime, SQL Server will look sequentially at all the load-balanced sets until finds one such that at least on replica in it is available and use it for load-balancing.

        So, in the example above, if both Server1 and Server2 are not available, but Server3 is, SQL Server will pick Server3.
        > This cmdlet only sets the read-only routing list and does not check on the availablility of the specified replicas.

    .PARAMETER InputObject
        Specifies the availability group, as an AvailabilityGroup object, to which the replica belongs.
    .PARAMETER Path
        Specifies the path of the availability group to which the replica belongs. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [System.Object]
        ${AvailabilityMode},

        [System.Object]
        ${FailoverMode},

        [ValidateNotNullOrEmpty()]
        [string]
        ${EndpointUrl},

        [int]
        ${SessionTimeout},

        [System.Object]
        ${ConnectionModeInPrimaryRole},

        [System.Object]
        ${ConnectionModeInSecondaryRole},

        [System.Object]
        ${SeedingMode},

        [ValidateRange(0, 100)]
        [int]
        ${BackupPriority},

        [string[]]
        ${ReadOnlyRoutingList},

        [string]
        ${ReadonlyRoutingConnectionUrl},

        [string[][]]
        ${LoadBalancedReadOnlyRoutingList},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlAvailabilityReplicaRoleToSecondary
{
    <#
    .SYNOPSIS
        Sets the Availability Group replica role to secondary.
    .PARAMETER Path
        Specifies the path of the Availability Group to which the replica belongs. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER InputObject
        Specifies the availability group, as an AvailabilityGroup object, that this cmdlet modifies.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlColumnEncryption
{
    <#
    .SYNOPSIS
        Encrypts, decrypts, or re-encrypts specified columns in the database.
    .PARAMETER ColumnEncryptionSettings
        Specifies an array of SqlColumnEncryptionSettings objects, each of which specifies the target encryption configuration for one column in the database.
    .PARAMETER UseOnlineApproach
        If set, the cmdlet will use the online approach, to ensure the database is available to other applications for both reads and writes for most of the duration of the operation.

        Otherwise, the cmdlet will lock the impacted tables, making them unavailable for updates for the entire operation. The tables will be available for reads.
    .PARAMETER KeepCheckForeignKeyConstraints
        If set, check semantics (CHECK or NOCHECK) of foreign key constraints are preserved.

        Otherwise, if not set, and if UseOnlineApproach is not set, foreign key constraints are always recreated with the NOCHECK option to minimize the impact on applications.

        KeepCheckForeignKeyConstraints is valid only when UseOnlineApproach is set.

        > With the offline approach, the semantics of foreign key constraints is always preserved.
    .PARAMETER MaxDowntimeInSeconds
        Specifies the maximum time (in seconds), during which the source table will not be available for reads and writes. Valid only if UseOnlineApproach is set.
    .PARAMETER KeyVaultAccessToken
        Specifies an access token for key vaults in Azure Key Vault. Use this parameter if any of the column master  keys protecting the columns to be encrypted, decrypted, or re-encrypted, are stored in key vaults in Azure Key Vault.
    .PARAMETER ManagedHsmAccessToken
        Specifies an access token for managed HSMs in Azure Key Vault. Use this parameter if any of the column master  keys protecting the columns to be encrypted, decrypted, or re-encrypted, are stored in managed HSMs in Azure Key Vault.
    .PARAMETER LockTimeoutInSeconds
        Specifies the maximum time (in seconds) the cmdlet will wait for database locks  that are needed to begin the last catch-up iteration. A value of -1 (default)  indicates no timeout period (that is, wait forever). A value of 0 means to not  wait at all. When a wait for a lock exceeds the time-out value, an error is returned. Valid only if UseOnlineApproach is set.
    .PARAMETER MaxIterationDurationInDays
        Specifies the maximum time (in days) of seeding or a single catch-up iteration. If seeding or any catch-up iteration takes more than the specified value, the cmdlet aborts the operation and re-creates the  original state of the database. Valid only if UseOnlineApproach is set.
    .PARAMETER MaxDivergingIterations
        Specifies the maximum number of consecutive catch-up iterations, where the number of processed rows increases. When this limit is reached, the cmdlet assumes that it will not be able to catch up with the changes made in the source table, and it aborts the operation and re-creates the original state of the database. Valid only if UseOnlineApproach is set. Must be less than the value of MaxIterations .
    .PARAMETER MaxIterations
        Specifies the maximum number of iterations in the catch-up phase. When this limit is reached, the cmdlet aborts the operation and recreates the original state of the database. Valid only if UseOnlineApproach is set.
    .PARAMETER EnclaveAttestationProtocol
        Specifies the an enclave's attestation protocol for Always Encrypted with secure enclaves. This parameter is required for the cmdlet to perform cryptographic operations in-place - inside a server-side secure enclave - to void the expense of downloading and uploading the data. Note that in-place encryption has other pre-requisites: your database must have an enclave configured and you need to use enclave-enabled cryptographic keys.
    .PARAMETER EnclaveAttestationURL
        Specifies an enclave attestation URL for in-place encryption when using Always Encrypted with secure enclaves. Required if EnclaveAttestationProtocol is set to `AAS` or `HGS`.
    .PARAMETER LogFileDirectory
        If set, the cmdlet will create a log file in the specified directory.
    .PARAMETER InputObject
        Specifies the SQL database object, for which this cmdlet runs the operation.
    .PARAMETER Path
        Specifies the path of the SQL database, for which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${ColumnEncryptionSettings},

        [switch]
        ${UseOnlineApproach},

        [switch]
        ${KeepCheckForeignKeyConstraints},

        [ValidateRange(1, 2147483647)]
        [int]
        ${MaxDowntimeInSeconds},

        [ValidateNotNullOrEmpty()]
        [string]
        ${KeyVaultAccessToken},

        [ValidateNotNullOrEmpty()]
        [string]
        ${ManagedHsmAccessToken},

        [ValidateRange(-1, 2147483647)]
        [int]
        ${LockTimeoutInSeconds},

        [ValidateRange(1, 2147483647)]
        [int]
        ${MaxIterationDurationInDays},

        [ValidateRange(1, 2147483647)]
        [int]
        ${MaxDivergingIterations},

        [ValidateRange(1, 2147483647)]
        [int]
        ${MaxIterations},

        [Alias('AttestationProtocol')]
        [System.Object]
        ${EnclaveAttestationProtocol},

        [string]
        ${EnclaveAttestationURL},

        [string]
        ${LogFileDirectory},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlCredential
{
    <#
    .SYNOPSIS
        Sets the properties for the SQL Credential object.
    .PARAMETER Identity
        Specifies the user or account name for the resource SQL Server needs to authenticate to. For Windows Azure storage service, this is the name of the Windows Azure storage account.
    .PARAMETER Secret
        Specifies the password for the user or account. For Windows Azure storage service, this is the access key value for the Windows Azure storage account.
    .PARAMETER InputObject
        Specifies an input Credential object. To get this object, use the Get-SqlCredential cmdlet.
    .PARAMETER Path
        Specifies the path to the credential on which this cmdlet performs this operation. For instance, `SQLSERVER:\SQL\Computer\Instance\Credentials\Credential`.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Identity},

        [Parameter(Position = 3)]
        [ValidateNotNullOrEmpty()]
        [securestring]
        ${Secret},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlErrorLog
{
    <#
    .SYNOPSIS
        Sets or resets the maximum number of error log files before they are recycled.
    .PARAMETER ServerInstance
        Specifies, as a string array, the name of an instance of SQL Server. For default instances, only specify the computer name: MyComputer. For named instances, use the format `MyComputer\MyInstanceName`.
    .PARAMETER Credential
        Specifies a PSCredential object used to specify the credentials for a SQL Server login that has permission to perform this operation.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer value between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER MaxLogCount
        Specifies the maximum number of error log files. If the value is not specified, the cmdlet resets the value to the default.

        The allowed range of values are between 6 and 99.
    .PARAMETER ErrorLogSizeKb
        Specifies the size limit of the SQL instance error log file in kilo bytes.

        Valid range is 0 to Int32.MaxValue.

        If the user does not specify this parameter then the ErrorLogSizeKb remains unchanged. The default value for the SQL instance is 0.
    .PARAMETER InputObject
        Specifies the server object of the target instance.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the working location.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [ValidateRange(6, 99)]
        [uint16]
        ${MaxLogCount},

        [ValidateRange(0, 2147483647)]
        [int]
        ${ErrorLogSizeKb},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlHADREndpoint
{
    <#
    .SYNOPSIS
        Sets the properties of a database mirroring endpoint.
    .PARAMETER Owner
        Specifies the owner of the endpoint.
    .PARAMETER Certificate
        Specifies the name of the certificate the endpoint will use to authenticate connections. The far endpoint must have a certificate with the public key matching the private key of the specified certificate.
    .PARAMETER IpAddress
        Specifies the IP address on which the endpoint will listen.
    .PARAMETER AuthenticationOrder
        Specifies the order and type of authentication that is used by the endpoint. If the specified option calls for a certificate, the Certificate parameter must be set unless a certificate is already associated with the endpoint.
    .PARAMETER Encryption
        Specifies the endpoint encryption setting.
    .PARAMETER EncryptionAlgorithm
        Specifies the form of encryption used by the endpoint.

        NOTE: The RC4 algorithm is only supported for backward compatibility. New material can only be encrypted using `RC4` or `RC4_128` when the database is in compatibility level `90` or `100`, but this is not recommended. For improved security, use a newer algorithm such as one of the `AES` algorithms instead.
    .PARAMETER Port
        Specifies the TCP port number used by the endpoint to listen for connections.
    .PARAMETER State
        Specifies the state of the endpoint.
    .PARAMETER InputObject
        Specifies the endpoint that to modify. This must be a database mirroring endpoint.
    .PARAMETER Path
        Specifies the path to the database mirroring endpoint. If not specified, the current working location is used.
    .PARAMETER Script
        Indicates that this cmdlet outputs a Transact-SQL script that performs the task.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        ${Owner},

        [ValidateNotNullOrEmpty()]
        [string]
        ${Certificate},

        [ValidateNotNullOrEmpty()]
        [ipaddress]
        ${IpAddress},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${AuthenticationOrder},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${Encryption},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${EncryptionAlgorithm},

        [ValidateNotNullOrEmpty()]
        [int]
        ${Port},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${State},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlSensitivityClassification
{
    <#
    .SYNOPSIS
        Set the information type and/or sensitivity label and information type of columns in the database.
    .PARAMETER ColumnName
        Name(s) of columns for which information type and sensitivity label is set.
    .PARAMETER ConnectionString
        Specifies a connection string to connect to the database. If this parameter is present, other connection parameters will be ignored
    .PARAMETER ServerInstance
        Specifies either the name of the server instance (a string) or SQL Server Management Objects (SMO) object that specifies the name of an instance of the Database Engine. For default instances, only specify the computer name: MyComputer. For named instances, use the format ComputerName\InstanceName.
    .PARAMETER DatabaseName
        Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.

        If the DatabaseName parameter is not specified, the database that is used depends on whether the current path specifies both the SQLSERVER:\SQL folder and a database name. If the path specifies both the SQL folder and a database name, this cmdlet connects to the database that is specified in the path.
    .PARAMETER Credential
        Specifies a credential used to connect to the database.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server on which this cmdlet runs the operation. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies a SQL Server Management Object (SMO) that represent the database that this cmdlet uses.
    .PARAMETER SuppressProviderContextWarning
        Indicates that this cmdlet suppresses the warning that this cmdlet has used in the database context from the current SQLSERVER:\SQL path setting to establish the database context for the cmdlet.
    .PARAMETER SensitivityRank
        An identifier based on a predefinied set of values which define sensitivity rank. May be used by other services like Advanced Threat Protection to detect anomalies based on their rank
    .PARAMETER InformationType
        A name that describes the information type that is stored in the column(s). You must provide a value for SensitivityLabel, InformationType, or both. Possible values are limited and cannot be extended.
    .PARAMETER SensitivityLabel
        A name that describes the sensitivity of the data that is stored in the column(s). You must provide a value for SensitivityLabel, InformationType, or both. Possible values are limited and cannot be extended.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByContext')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Column')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ColumnName},

        [Parameter(ParameterSetName = 'ByConnectionString', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${ConnectionString},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByConnectionParameters', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByConnectionParameters')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [Parameter(ParameterSetName = 'ByDBObject', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByContext')]
        [switch]
        ${SuppressProviderContextWarning},

        [Parameter(ValueFromPipelineByPropertyName = $true, HelpMessage = 'An identifier based on a predefinied set of values which define sensitivity rank. May be used by other services like Advanced Threat Protection to detect anomalies based on their rank')]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${SensitivityRank}
    )

    dynamicparam
    {
        $parameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # InformationType
        $attributes = New-Object System.Collections.Generic.List[Attribute]

        $attribute = New-Object System.Management.Automation.ParameterAttribute
        $attribute.ValueFromPipelineByPropertyName = $True
        $attributes.Add($attribute)

        $attribute = New-Object System.Management.Automation.ValidateSetAttribute('Networking', 'Contact Info', 'Credentials', 'Credit Card', 'Banking', 'Financial', 'Other', 'Name', 'National ID', 'SSN', 'Health', 'Date Of Birth')
        $attributes.Add($attribute)

        $parameter = New-Object System.Management.Automation.RuntimeDefinedParameter('InformationType', [System.String], $attributes)
        $parameters.Add('InformationType', $parameter)

        # SensitivityLabel
        $attributes = New-Object System.Collections.Generic.List[Attribute]

        $attribute = New-Object System.Management.Automation.ParameterAttribute
        $attribute.ValueFromPipelineByPropertyName = $True
        $attributes.Add($attribute)

        $attribute = New-Object System.Management.Automation.ValidateSetAttribute('Public', 'General', 'Confidential', 'Confidential - GDPR', 'Highly Confidential', 'Highly Confidential - GDPR')
        $attributes.Add($attribute)

        $parameter = New-Object System.Management.Automation.RuntimeDefinedParameter('SensitivityLabel', [System.String], $attributes)
        $parameters.Add('SensitivityLabel', $parameter)

        return $parameters
    }

    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Set-SqlSmartAdmin
{
    <#
    .SYNOPSIS
        Configures or modifies backup retention and storage settings.
    .PARAMETER SqlCredential
        Specifies the SqlCredential object that is used to authenticate to the Windows Azure storage account.
    .PARAMETER MasterSwitch
        Indicates that this cmdlet pauses or restarts all services under Smart Admin including SQL Server Managed Backup to Windows Azure.
    .PARAMETER BackupEnabled
        Indicates that this cmdlet enables SQL Server Managed Backup to Windows Azure.
    .PARAMETER BackupRetentionPeriodInDays
        Specifies the number of days the backup files should be retained. This determines the timeframe of the recoverability for the databases. For instance, if you set the value for 30 days, you can recover a database to a point in time in the last 30 days.
    .PARAMETER EncryptionOption
        Specifies the encryption options.
    .PARAMETER DatabaseName
        Specifies the name of the database that this cmdlet modifies.
    .PARAMETER InputObject
        Specifies the Smo Smart Admin object. You can use the Get-SqlSmartAdmin cmdlet to get this object.
    .PARAMETER Path
        Specifies the path to the instance of SQL Server. If you do not specify a value for this parameter, the cmdlet uses the current working directory. This is useful when you create scripts to manage multiple instances.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [ValidateNotNullOrEmpty()]
        [psobject]
        ${SqlCredential},

        [bool]
        ${MasterSwitch},

        [bool]
        ${BackupEnabled},

        [int]
        ${BackupRetentionPeriodInDays},

        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${EncryptionOption},

        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Path},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Suspend-SqlAvailabilityDatabase
{
    <#
    .SYNOPSIS
        Suspends data movement on an availability database.
    .PARAMETER Path
        Specifies the path of an availability database that cmdlet suspends. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER InputObject
        Specifies availability database, as an AvailabilityDatabase object, that this cmdlet suspends.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Switch-SqlAvailabilityGroup
{
    <#
    .SYNOPSIS
        Starts a failover of an availability group to a secondary replica.
    .PARAMETER AllowDataLoss
        Indicates that this cmdlet starts a forced failover to the target secondary replica. Data loss is possible. Unless you specify the Force or Script parameter, the cmdlet prompts you for confirmation.
    .PARAMETER Force
        Forces the command to run without asking for user confirmation. This cmdlet prompts you for confirmation only if you specify the AllowDataLoss parameter.
    .PARAMETER Path
        Specifies the path of the availability group that this cmdlet fails over. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER InputObject
        Specifies availability group that this cmdlet fails over.
    .PARAMETER Script
        Indicates that this cmdlet returns a Transact-SQL script that performs the task that this cmdlet performs.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]
        ${AllowDataLoss},

        [switch]
        ${Force},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject},

        [switch]
        ${Script}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Test-SqlAvailabilityGroup
{
    <#
    .SYNOPSIS
        Evaluates the health of an availability group.
    .PARAMETER ShowPolicyDetails
        Indicates that this cmdlet displays the result of each policy evaluation that it performs. The cmdlet returns one object per policy evaluation. Each policy object includes the results of evaluation. This information includes whether the policy passed or not, the policy name, and policy category.
    .PARAMETER AllowUserPolicies
        Indicates that this cmdlet tests user policies found in the policy categories of Always On Availability Groups.
    .PARAMETER NoRefresh
        Indicates that will not refresh the objects specified by the Path or InputObject parameter.
    .PARAMETER Path
        Specifies the path of the availability group that this cmdlet evaluates. If you do not specify this parameter, this cmdlet uses current working location.
    .PARAMETER InputObject
        Specifies an array of availability group, as AvailabilityGroup objects. This cmdlet evaluates the health of the availability groups that this parameter specifies.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]
        ${ShowPolicyDetails},

        [switch]
        ${AllowUserPolicies},

        [switch]
        ${NoRefresh},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Test-SqlAvailabilityReplica
{
    <#
    .SYNOPSIS
        Evaluates the health of availability replicas.
    .PARAMETER ShowPolicyDetails
        Indicates that the result of each policy evaluation performed by this cmdlet is shown. The cmdlet outputs one object per policy evaluation. This object contains fields that describe the results of the evaluation.
    .PARAMETER AllowUserPolicies
        Indicates that this cmdlet runs user policies found in the Always On policy categories.
    .PARAMETER NoRefresh
        Indicates that this cmdlet will not manually refresh the objects specified by the Path or InputObject parameters.
    .PARAMETER Path
        Specifies the path to one or more availability replicas. This parameter is optional. If not specified, the current working location is used.
    .PARAMETER InputObject
        Specifies an array of availability replicas to evaluate.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]
        ${ShowPolicyDetails},

        [switch]
        ${AllowUserPolicies},

        [switch]
        ${NoRefresh},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Test-SqlDatabaseReplicaState
{
    <#
    .SYNOPSIS
        Evaluates the health of an availability database.
    .PARAMETER ShowPolicyDetails
        Indicates that this cmdlet shows the result of each policy evaluation performed. The cmdlet outputs one object per policy evaluation and the results of evaluation are available in the fields of the object.
    .PARAMETER AllowUserPolicies
        Indicates that this cmdlet runs user policies found in the Always On policy categories.
    .PARAMETER NoRefresh
        Indicates that this cmdlet will not manually refresh the objects specified by the Path or InputObject parameters.
    .PARAMETER Path
        Specifies the path to one or more database replica cluster states of the availability database. This is an optional parameter. If not specified, the value of the current working location is used.
    .PARAMETER InputObject
        Specifies an array of availability database state objects. This cmdlet computes the health of these availability databases.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]
        ${ShowPolicyDetails},

        [switch]
        ${AllowUserPolicies},

        [switch]
        ${NoRefresh},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Test-SqlSmartAdmin
{
    <#
    .SYNOPSIS
        Tests the health of Smart Admin by evaluating SQL Server policy based management (PBM) policies.
    .PARAMETER ShowPolicyDetails
        Indicates that this cmdlet shows the result of the policy. The cmdlet outputs one object per policy assessment. The output includes the results of the assessment: such as, the name of the policy, category, and health.
    .PARAMETER AllowUserPolicies
        Indicates that this cmdlet runs user policies found in the Smart Admin warning and error policy categories.
    .PARAMETER NoRefresh
        Indicates that this cmdlet will not manually refresh the object specified by the Path or InputObject parameters.
    .PARAMETER Path
        Specifies the path of the SQL Server instance,  as a string array. If you do not specify a value for this parameter, the cmdlet uses the current working location.
    .PARAMETER InputObject
        Specifies an array of SmartAdmin objects. To get this object, use the Get-SqlSmartAdmin cmdlet.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]
        ${ShowPolicyDetails},

        [switch]
        ${AllowUserPolicies},

        [switch]
        ${NoRefresh},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}

function Write-SqlTableData
{
    <#
    .SYNOPSIS
        Writes data to a table of a SQL database.
    .PARAMETER DatabaseName
        Specifies the name of the database that contains the table.

        The cmdlet supports quoting the value. You do not have to quote or escape special characters.
    .PARAMETER SchemaName
        Specifies the name of the schema for the table.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the SchemaName parameter anyway.

        The cmdlet supports quoting the value. You do not have to quote or escape special characters.
    .PARAMETER TableName
        Specifies the name of the table from which this cmdlet reads.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the TableName parameter anyway.

        The cmdlet supports quoting the value. You do not have to quote or escape special characters.
    .PARAMETER IgnoreProviderContext
        Indicates that this cmdlet does not use the current context to override the values of the ServerInstance , DatabaseName , SchemaName , and TableName parameters. If you do not specify this parameter, the cmdlet ignores the values of these parameters, if possible, in favor of the context in which you run the cmdlet.
    .PARAMETER SuppressProviderContextWarning
        Indicates that this cmdlet suppresses the warning message that states that the cmdlet uses the provider context.
    .PARAMETER Force
        Indicates that this cmdlet creates missing SQL Server objects. These include the database, schema, and table. You must have appropriate credentials to create these objects.

        If you do not specify this parameter for missing objects, the cmdlet returns an error.
    .PARAMETER InputData
        Specifies the data to write to the database.

        Typical input data is a System.Data.DataTable , but you can specify System.Data.DataSet or System.Data.DateRow * objects.
    .PARAMETER Passthru
        Indicates that this cmdlet returns an SMO.Table object. This object represents the table that includes the added data. You can operate on the table after the write operation.
    .PARAMETER Timeout
        Specifies a time-out value, in seconds, for the write operation. If you do not specify a value, the cmdlet uses a default value (typically, 30s). In order to avoid a timeout, pass 0. The timeout must be an integer value between 0 and 65535.
    .PARAMETER ServerInstance
        Specifies the name of an instance of SQL Server. For the default instance, specify the computer name. For named instances, use the format `ComputerName\InstanceName`.

        If you run this cmdlet in the context of a database or a child item of a database, the cmdlet ignores this parameter value. Specify the IgnoreProviderContext parameter for the cmdlet to use the value of the ServerInstance parameter anyway.
    .PARAMETER Credential
        Specifies a PSCredential object for the connection to SQL Server. To obtain a credential object, use the Get-Credential cmdlet. For more information, type Get-Help Get-Credential.
    .PARAMETER ConnectionTimeout
        Specifies the number of seconds to wait for a server connection before a time-out failure. The time-out value must be an integer between 0 and 65534. If 0 is specified, connection attempts do not time out.
    .PARAMETER Path
        Specifies the full path in the context of the SQL Provider of the table where this cmdlet writes data.
    .PARAMETER InputObject
        Specifies an array of SQL Server Management Objects (SMO) objects that represent the table to which this cmdlet writes.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param (
        [Parameter(ParameterSetName = 'ByName')]
        [string]
        ${DatabaseName},

        [Parameter(ParameterSetName = 'ByName')]
        [string]
        ${SchemaName},

        [Parameter(ParameterSetName = 'ByName')]
        [string]
        ${TableName},

        [Parameter(ParameterSetName = 'ByName')]
        [switch]
        ${IgnoreProviderContext},

        [Parameter(ParameterSetName = 'ByName')]
        [switch]
        ${SuppressProviderContextWarning},

        [switch]
        ${Force},

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]
        ${InputData},

        [switch]
        ${Passthru},

        [ValidateRange(0, 65535)]
        [int]
        ${Timeout},

        [Parameter(ParameterSetName = 'ByName', Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ServerInstance},

        [Parameter(ParameterSetName = 'ByName')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName = 'ByName')]
        [int]
        ${ConnectionTimeout},

        [Parameter(ParameterSetName = 'ByPath', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        ${InputObject}
    )
    end
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                'StubNotImplemented',
                'StubCalledError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $MyInvocation.MyCommand
            )
        )
    }
}
