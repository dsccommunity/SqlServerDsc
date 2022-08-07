<#
    .SYNOPSIS
        The `SqlAudit` DSC resource is used to create, modify, or remove
        server audits.

    .DESCRIPTION
        The `SqlAudit` DSC resource is used to create, modify, or remove
        server audits.

        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must be running SQL Server Database Engine 2012 or later.
        * Target machine must have access to the SQLPS PowerShell module or the SqlServer
          PowerShell module.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlAudit).

        ### `PSDscRunAsCredential` not supported

        The built-in property `PSDscRunAsCredential` does not work with class-based
        resources that using advanced type like the parameter `Permission` does.
        Use the parameter `Credential` instead of `PSDscRunAsCredential`.

        ### Using `Credential` property.

        SQL Authentication and Group Managed Service Accounts is not supported as
        impersonation credentials. Currently only Windows Integrated Security is
        supported to use as credentials.

        For Windows Authentication the username must either be provided with the User
        Principal Name (UPN), e.g. 'username@domain.local' or if using non-domain
        (for example a local Windows Server account) account the username must be
        provided without the NetBIOS name, e.g. 'username'. The format 'DOMAIN\username'
        will not work.

        See more information in [Credential Overview](https://github.com/dsccommunity/SqlServerDsc/wiki/CredentialOverview).

    .PARAMETER InstanceName
        The name of the _SQL Server_ instance to be configured. Default value is
        `'MSSQLSERVER'`.

    .PARAMETER Name
        The name of the audit.

    .PARAMETER ServerName
        The host name of the _SQL Server_ to be configured. Default value is the
        current computer name.

    .PARAMETER LogType
        Specifies the to which log an audit logs to. Mutually exclusive to parameter
        **Path**. This can be set to `SecurityLog` or `ApplicationLog`.

    .PARAMETER Path
        Specifies the destination path for a file audit. Mutually exclusive to parameter
        **LogType**.

    .PARAMETER Filter
        Specifies the filter that should be used on the audit.

    .PARAMETER MaximumFiles
        Specifies the number of files on disk. Mutually exclusive to parameter
        **MaximumRolloverFiles**.

    .PARAMETER MaximumFileSize
        Specifies the maximum file size in units by parameter **MaximumFileSizeUnit**.
        If this is specified the parameter **MaximumFileSizeUnit** must also be
        specified.

    .PARAMETER MaximumFileSizeUnit
        Specifies the unit that is used for the file size. this can be KB, MB or GB.
        If this is specified the parameter **MaximumFileSize** must also be
        specified.

    .PARAMETER MaximumRolloverFiles
        Specifies the amount of files on disk before SQL Server starts reusing
        the files. Mutually exclusive to parameter **MaximumFiles**.

    .PARAMETER OnFailure
        Specifies what should happen when writing events to the store fails.
        This can be `Continue`, `FailOperation`, or `Shutdown`.

    .PARAMETER QueueDelay
        Specifies the maximum delay before a event is written to the store.
        When set to low this could impact server performance.
        When set to high events could be missing when a server crashes.

    .PARAMETER ReserveDiskSpace
        Specifies if the needed file space should be reserved. only needed
        when writing to a file log.

    .PARAMETER Enabled
        Specifies if the audit should be enabled. Defaults to `$false`.

    .PARAMETER Ensure
        Specifies if the server audit should be present or absent. If set to `Present`
        the audit will be added if it does not exist, or updated if the audit exist.
        If `Absent` then the audit will be removed from the server. Defaults to
        `Present`.

    .PARAMETER Force
        Specifies if it is allowed to re-create the server audit if a current audit
        exist with the same name but of a different audit type. Defaults to `$false`
        not allowing server audits to be re-created.

    .PARAMETER Credential
        Specifies the credential to use to connect to the _SQL Server_ instance.

        If parameter **Credential'* is not provided then the resource instance is
        run using the credential that runs the configuration.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlAudit -Method Get -Property @{
            ServerName           = 'localhost'
            InstanceName         = 'SQL2017'
            Credential           = (Get-Credential -UserName 'myuser@company.local' -Message 'Password:')
            Name                 = 'Log1'
        }

        This example shows how to call the resource using Invoke-DscResource.
#>

# TODO: verify RunAsCredential = 'NotSupported' - remove in comment-based help
[DscResource()]
class SqlAudit : ResourceBase
{
    <#
        Property for holding the server connection object.
        This should be an object of type [Microsoft.SqlServer.Management.Smo.Server]
        but using that type fails the build process currently.
        See issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/121.
    #>
    hidden [System.Object] $sqlServerObject = $null

    [DscProperty(Key)]
    [System.String]
    $InstanceName

    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [System.String]
    $ServerName = (Get-ComputerName)

    [DscProperty()]
    [ValidateSet('SecurityLog', 'ApplicationLog')]
    [System.String]
    $LogType

    # TODO: Must assert the path at run time
    [DscProperty()]
    [System.String]
    $Path

    [DscProperty()]
    [System.String]
    $AuditFilter

    [DscProperty()]
    [System.UInt32]
    $MaximumFiles

    [DscProperty()]
    [ValidateRange(2, 2147483647)]
    [System.UInt32]
    $MaximumFileSize

    [DscProperty()]
    [ValidateSet('Megabyte', 'Gigabyte', 'Terabyte')]
    [System.String]
    $MaximumFileSizeUnit

    [DscProperty()]
    [System.UInt32]
    $MaximumRolloverFiles

    [DscProperty()]
    [ValidateSet('Continue', 'FailOperation', 'Shutdown')]
    [System.String]
    $OnFailure

    [DscProperty()]
    [ValidateRange(1000, 2147483647)]
    [System.UInt32]
    $QueueDelay

    [DscProperty()]
    [ValidatePattern('^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [System.String]
    $AuditGuid

    [DscProperty()]
    [System.Boolean]
    $ReserveDiskSpace

    [DscProperty()]
    [System.Boolean]
    $Enabled

    [DscProperty()]
    [ValidateSet('Present', 'Absent')]
    [System.String]
    $Ensure = 'Present'

    [DscProperty()]
    [System.Boolean]
    $Force

    [DscProperty()]
    [PSCredential]
    $Credential

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    SqlAudit() : base ()
    {
        # These properties will not be enforced.
        $this.notEnforcedProperties = @(
            'ServerName'
            'InstanceName'
            'Name'
            'Credential'
        )
    }

    [SqlAudit] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [System.Boolean] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        return ([ResourceBase] $this).Test()
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    <#
        TODO: This method can be moved to a parent class "SqlServerDscResource" that
              instead inherits ResourceBase. Then this method does not need to be
              duplicated. Make sure to create a localized strings file for the new
              class.
              The property 'sqlServerObject' should also be moved (but still be hidden).
    #>
    <#
        Returns and reuses the server connection object. If the server connection
        object does not exist a connection to the SQL Server instance will occur.

        This should return an object of type [Microsoft.SqlServer.Management.Smo.Server]
        but using that type fails the build process currently.
        See issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/121.
    #>
    hidden [System.Object] GetServerObject()
    {
        if (-not $this.sqlServerObject)
        {
            $connectSqlDscDatabaseEngineParameters = @{
                ServerName   = $this.ServerName
                InstanceName = $this.InstanceName
            }

            if ($this.Credential)
            {
                $connectSqlDscDatabaseEngineParameters.Credential = $this.Credential
            }

            $this.sqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters
        }

        return $this.sqlServerObject
    }

    <#
        Base method Get() call this method to get the current state as a hashtable.
        The parameter properties will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $currentStateCredential = $null

        if ($this.Credential)
        {
            <#
                This does not work, even if username is set, the method Get() will
                return an empty PSCredential-object. Kept it here so it at least
                return a Credential object.
            #>
            $currentStateCredential = [PSCredential]::new(
                $this.Credential.UserName,
                [SecureString]::new()
            )
        }

        $currentState = @{
            Credential = $currentStateCredential
        }

        Write-Verbose -Message (
            $this.localizedData.EvaluateServerPermissionForPrincipal -f @(
                $properties.Name,
                $properties.InstanceName
            )
        )

        $serverObject = $this.GetServerObject()

        $auditObject = $serverObject |
            Get-SqlDscAudit -Name $this.Name -ErrorAction 'SilentlyContinue'

        # If permissions was returned, build the current permission array of [ServerPermission].
        if ($auditObject)
        {
        }

        return $currentState
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced are not in desired state. It is not called if all properties
        are in desired state. The variable $properties contain the properties
        that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        $serverObject = $this.GetServerObject()

        # if (-not $isLogin)
        # {
        #     $missingPrincipalMessage = $this.localizedData.NameIsMissing -f @(
        #         $this.Name,
        #         $this.InstanceName
        #     )

        #     New-InvalidOperationException -Message $missingPrincipalMessage
        # }

    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # PermissionToInclude and PermissionToExclude should be mutually exclusive from Permission
        $assertBoundParameterParameters = @{
            BoundParameterList     = $properties
            MutuallyExclusiveList1 = @(
                'MaximumFiles'
            )
            MutuallyExclusiveList2 = @(
                'MaximumRolloverFiles'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        # Get all assigned permission properties.
        $assignedSizeProperty = $properties.Keys.Where({
                $_ -in @(
                    'MaximumFileSize',
                    'MaximumFileSizeUnit'
                )
            })

        # TODO: Above count should be either 0 or 2, if 1 throw an error.
        # if ([System.String]::IsNullOrEmpty($assignedPermissionProperty))
        # {
        #     $errorMessage = $this.localizedData.MustAssignOnePermissionProperty

        #     New-InvalidArgumentException -ArgumentName 'Permission, PermissionToInclude, PermissionToExclude' -Message $errorMessage
        # }

        # TODO: Test path
        # if (-not (Test-Path -Path $_))
        # {
        #     throw ($script:localizedData.Audit_PathParameterValueInvalid -f $_)
        # }
    }
}
