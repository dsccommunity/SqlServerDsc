<#
    .SYNOPSIS
        The `SqlAudit` DSC resource is used to create, modify, or remove
        server audits.

    .DESCRIPTION
        The `SqlAudit` DSC resource is used to create, modify, or remove
        server audits.

        The built-in parameter **PSDscRunAsCredential** can be used to run the resource
        as another user. The resource will then authenticate to the SQL Server
        instance as that user. It also possible to instead use impersonation by the
        parameter **Credential**.

        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must be running SQL Server Database Engine 2012 or later.
        * Target machine must have access to the SQLPS PowerShell module or the SqlServer
          PowerShell module.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlAudit).

        ### Property **Reasons** does not work with **PSDscRunAsCredential**

        When using the built-in parameter **PSDscRunAsCredential** the read-only
        property **Reasons** will return empty values for the properties **Code**
        and **Phrase. The built-in property **PSDscRunAsCredential** does not work
        together with class-based resources that using advanced type like the parameter
        **Reasons** have.

        ### Using **Credential** property

        SQL Authentication and Group Managed Service Accounts is not supported as
        impersonation credentials. Currently only Windows Integrated Security is
        supported to use as credentials.

        For Windows Authentication the username must either be provided with the User
        Principal Name (UPN), e.g. `username@domain.local` or if using non-domain
        (for example a local Windows Server account) account the username must be
        provided without the NetBIOS name, e.g. `username`. Using the NetBIOS name, e.g
        using the format `DOMAIN\username` will not work.

        See more information in [Credential Overview](https://github.com/dsccommunity/SqlServerDsc/wiki/CredentialOverview).

    .PARAMETER Name
        The name of the audit.

    .PARAMETER LogType
        Specifies the to which log an audit logs to. Mutually exclusive to parameter
        **Path**.

    .PARAMETER Path
        Specifies the destination path for a file audit. Mutually exclusive to parameter
        **LogType**.

    .PARAMETER Filter
        Specifies the filter that should be used on the audit.

    .PARAMETER MaximumFiles
        Specifies the number of files on disk. Mutually exclusive to parameter
        **MaximumRolloverFiles**. Mutually exclusive to parameter **LogType**.

    .PARAMETER MaximumFileSize
        Specifies the maximum file size in units by parameter **MaximumFileSizeUnit**.
        If this is specified the parameter **MaximumFileSizeUnit** must also be
        specified. Mutually exclusive to parameter **LogType**. Minimum allowed value
        is 2 (MB). It also allowed to set the value to 0 which mean unlimited file
        size.

    .PARAMETER MaximumFileSizeUnit
        Specifies the unit that is used for the file size.
        If this is specified the parameter **MaximumFileSize** must also be
        specified. Mutually exclusive to parameter **LogType**.

    .PARAMETER MaximumRolloverFiles
        Specifies the amount of files on disk before SQL Server starts reusing
        the files. Mutually exclusive to parameter **MaximumFiles** and **LogType**.

    .PARAMETER OnFailure
        Specifies what should happen when writing events to the store fails.
        This can be `Continue`, `FailOperation`, or `Shutdown`.

    .PARAMETER QueueDelay
        Specifies the maximum delay before a event is written to the store.
        When set to low this could impact server performance.
        When set to high events could be missing when a server crashes.

    .PARAMETER ReserveDiskSpace
        Specifies if the needed file space should be reserved. only needed
        when writing to a file log. Mutually exclusive to parameter **LogType**.

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

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlAudit -Method Get -Property @{
            ServerName           = 'localhost'
            InstanceName         = 'SQL2017'
            Credential           = (Get-Credential -UserName 'myuser@company.local' -Message 'Password:')
            Name                 = 'Log1'
        }

        This example shows how to call the resource using Invoke-DscResource.
#>
[DscResource(RunAsCredential = 'Optional')]
class SqlAudit : SqlResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [ValidateSet('SecurityLog', 'ApplicationLog')]
    [System.String]
    $LogType

    # The Path is evaluated if exist in AssertProperties().
    [DscProperty()]
    [System.String]
    $Path

    [DscProperty()]
    [System.String]
    $AuditFilter

    [DscProperty()]
    [Nullable[System.UInt32]]
    $MaximumFiles

    [DscProperty()]
    # There is an extra evaluation in AssertProperties() for this range.
    [ValidateRange(0, 2147483647)]
    [Nullable[System.UInt32]]
    $MaximumFileSize

    [DscProperty()]
    [ValidateSet('Megabyte', 'Gigabyte', 'Terabyte')]
    [System.String]
    $MaximumFileSizeUnit

    [DscProperty()]
    [ValidateRange(0, 2147483647)]
    [Nullable[System.UInt32]]
    $MaximumRolloverFiles

    [DscProperty()]
    [ValidateSet('Continue', 'FailOperation', 'Shutdown')]
    [System.String]
    $OnFailure

    [DscProperty()]
    # There is an extra evaluation in AssertProperties() for this range.
    [ValidateRange(0, 2147483647)]
    [Nullable[System.UInt32]]
    $QueueDelay

    [DscProperty()]
    [ValidatePattern('^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [System.String]
    $AuditGuid

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ReserveDiskSpace

    [DscProperty()]
    [Nullable[System.Boolean]]
    $Enabled

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [Nullable[System.Boolean]]
    $Force

    SqlAudit () : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'ServerName'
            'InstanceName'
            'Name'
            'Credential'
            'Force'
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
        Base method Get() call this method to get the current state as a hashtable.
        The parameter properties will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message (
            $this.localizedData.EvaluateServerAudit -f @(
                $properties.Name,
                $properties.InstanceName
            )
        )

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

        <#
            Only set key property Name if the audit exist. Base class will set it
            and handle Ensure.
        #>
        $currentState = @{
            Credential   = $currentStateCredential
            InstanceName = $properties.InstanceName
            ServerName   = $this.ServerName
            Force        = $this.Force
        }

        $serverObject = $this.GetServerObject()

        $auditObjectArray = $serverObject |
            Get-SqlDscAudit -Name $properties.Name -ErrorAction 'SilentlyContinue'

        # Pick the only object in the array.
        $auditObject = $auditObjectArray | Select-Object -First 1

        if ($auditObject)
        {
            $currentState.Name = $properties.Name

            if ($auditObject.DestinationType -in @('ApplicationLog', 'SecurityLog'))
            {
                $currentState.LogType = $auditObject.DestinationType.ToString()
            }

            if ($auditObject.FilePath)
            {
                # Remove trailing slash or backslash.
                $currentState.Path = $auditObject.FilePath -replace '[\\|/]*$'
            }

            $currentState.AuditFilter = $auditObject.Filter
            $currentState.MaximumFiles = [System.UInt32] $auditObject.MaximumFiles
            $currentState.MaximumFileSize = [System.UInt32] $auditObject.MaximumFileSize

            # The value of MaximumFileSizeUnit can be zero, so have to check against $null
            if ($null -ne $auditObject.MaximumFileSizeUnit)
            {
                $convertedMaximumFileSizeUnit = (
                    @{
                        0 = 'Megabyte'
                        1 = 'Gigabyte'
                        2 = 'Terabyte'
                    }
                ).($auditObject.MaximumFileSizeUnit.value__)

                $currentState.MaximumFileSizeUnit = $convertedMaximumFileSizeUnit
            }

            $currentState.MaximumRolloverFiles = [System.UInt32] $auditObject.MaximumRolloverFiles
            $currentState.OnFailure = $auditObject.OnFailure
            $currentState.QueueDelay = [System.UInt32] $auditObject.QueueDelay
            $currentState.AuditGuid = $auditObject.Guid
            $currentState.ReserveDiskSpace = $auditObject.ReserveDiskSpace
            $currentState.Enabled = $auditObject.Enabled
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
        $auditObject = $null

        if ($properties.Keys -contains 'Ensure')
        {
            # Evaluate the desired state for property Ensure.
            switch ($properties.Ensure)
            {
                'Present'
                {
                    # Create the audit since it was missing. Always created disabled.
                    $auditObject = $this.CreateAudit()
                }

                'Absent'
                {
                    # Remove the audit since it was present
                    $serverObject | Remove-SqlDscAudit -Name $this.Name -Force
                }
            }
        }
        else
        {
            <#
                Update any properties not in desired state if the audit should be present.
                At this point it is assumed the audit exist since Ensure property was
                in desired state.

                If the desired state happens to be Absent then ignore any properties not
                in desired state (user have in that case wrongly added properties to an
                "absent configuration").
            #>
            if ($this.Ensure -eq [Ensure]::Present)
            {
                $auditObjectArray = $serverObject |
                    Get-SqlDscAudit -Name $this.Name -ErrorAction 'Stop'

                # Pick the only object in the array.
                $auditObject = $auditObjectArray | Select-Object -First 1

                if ($auditObject)
                {
                    $auditIsWrongType = (
                        # If $auditObject.DestinationType is not null.
                        $null -ne $auditObject.DestinationType -and (
                            # Path is not in desired state but the audit is not of type File.
                            $properties.ContainsKey('Path') -and $auditObject.DestinationType -ne 'File'
                        ) -or (
                            # LogType is not in desired state but the audit is of type File.
                            $properties.ContainsKey('LogType') -and $auditObject.DestinationType -eq 'File'
                        )
                    )

                    # Does the audit need to be re-created?
                    if ($auditIsWrongType)
                    {
                        if ($this.Force -eq $true)
                        {
                            $auditObject | Remove-SqlDscAudit -Force

                            $auditObject = $this.CreateAudit()
                        }
                        else
                        {
                            New-InvalidOperationException -Message $this.localizedData.AuditIsWrongType
                        }
                    }
                    else
                    {
                        <#
                            Should evaluate DestinationType so that is does not try to set a
                            File audit property when audit type is of a Log-type.
                        #>
                        if ($null -ne $auditObject.DestinationType -and $auditObject.DestinationType -ne 'File')
                        {
                            # Look for file audit properties not in desired state
                            $fileAuditProperty = $properties.Keys.Where({
                                $_ -in @(
                                    'Path'
                                    'MaximumFiles'
                                    'MaximumFileSize'
                                    'MaximumFileSizeUnit'
                                    'MaximumRolloverFiles'
                                    'ReserveDiskSpace'
                                )
                            })

                            # If a property was found, throw an exception.
                            if ($fileAuditProperty.Count -gt 0)
                            {
                                New-InvalidOperationException -Message ($this.localizedData.AuditOfWrongTypeForUseWithProperty -f $auditObject.DestinationType)
                            }
                        }

                        # Get all optional properties that has an assigned value.
                        $assignedOptionalDscProperties = $this | Get-DscProperty -HasValue -Attribute 'Optional' -ExcludeName @(
                            # Remove optional properties that is not an audit property.
                            'ServerName'
                            'Ensure'
                            'Force'
                            'Credential'

                            # Remove this audit property since it must be handled later.
                            'Enabled'
                        )

                        <#
                            Only call Set when there is a property to Set. The property
                            Enabled was ignored, so it could be the only one that was
                            not in desired state (Enabled is handled later).
                        #>
                        if ($assignedOptionalDscProperties.Count -gt 0)
                        {
                            <#
                                This calls Set-SqlDscAudit to set all the desired value
                                even if they were in desired state. Then the no logic is
                                needed to make sure we call using the correct parameter
                                set that Set-SqlDscAudit requires.
                            #>
                            $auditObject | Set-SqlDscAudit @assignedOptionalDscProperties -Force
                        }
                    }
                }
            }
        }

        <#
            If there is an audit object either from a newly created or fetched from
            current state, and if the desired state is Present, evaluate if the
            audit should be enable or disable.
        #>
        if ($auditObject -and $this.Ensure -eq [Ensure]::Present -and $properties.Keys -contains 'Enabled')
        {
            switch ($properties.Enabled)
            {
                $true
                {
                    $serverObject | Enable-SqlDscAudit -Name $this.Name -Force
                }

                $false
                {
                    $serverObject | Disable-SqlDscAudit -Name $this.Name -Force
                }
            }
        }
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # The properties MaximumFiles and MaximumRolloverFiles are mutually exclusive.
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

        # LogType is mutually exclusive from any of the File audit properties.
        $assertBoundParameterParameters = @{
            BoundParameterList     = $properties
            MutuallyExclusiveList1 = @(
                'LogType'
            )
            MutuallyExclusiveList2 = @(
                'Path'
                'MaximumFiles'
                'MaximumFileSize'
                'MaximumFileSizeUnit'
                'MaximumRolloverFiles'
                'ReserveDiskSpace'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        # Get all assigned *FileSize properties.
        $assignedSizeProperty = $properties.Keys.Where({
                $_ -in @(
                    'MaximumFileSize',
                    'MaximumFileSizeUnit'
                )
            })

        <#
            Neither or both of the properties MaximumFileSize and MaximumFileSizeUnit
            must be assigned.
        #>
        if ($assignedSizeProperty.Count -eq 1)
        {
            $errorMessage = $this.localizedData.BothFileSizePropertiesMustBeSet

            New-InvalidArgumentException -ArgumentName 'MaximumFileSize, MaximumFileSizeUnit' -Message $errorMessage
        }

        <#
            Since we cannot use [ValidateScript()], and it is no possible to exclude
            a value in the [ValidateRange()], evaluate so 1 is not assigned.
        #>
        if ($properties.Keys -contains 'MaximumFileSize' -and $properties.MaximumFileSize -eq 1)
        {
            $errorMessage = $this.localizedData.MaximumFileSizeValueInvalid

            New-InvalidArgumentException -ArgumentName 'MaximumFileSize' -Message $errorMessage
        }

        <#
            Since we cannot use [ValidateScript()], and it is no possible to exclude
            a value in the [ValidateRange()], evaluate so 1-999 is not assigned.
        #>
        if ($properties.Keys -contains 'QueueDelay' -and $properties.QueueDelay -in 1..999)
        {
            $errorMessage = $this.localizedData.QueueDelayValueInvalid

            New-InvalidArgumentException -ArgumentName 'QueueDelay' -Message $errorMessage
        }

        # ReserveDiskSpace can only be used with MaximumFiles.
        if ($properties.Keys -contains 'ReserveDiskSpace' -and $properties.Keys -notcontains 'MaximumFiles')
        {
            $errorMessage = $this.localizedData.BothFileSizePropertiesMustBeSet

            New-InvalidArgumentException -ArgumentName 'ReserveDiskSpace' -Message $errorMessage
        }

        # Test so that the path exist.
        if ($properties.Keys -contains 'Path' -and -not (Test-Path -Path $properties.Path))
        {
            $errorMessage = $this.localizedData.PathInvalid -f $properties.Path

            New-InvalidArgumentException -ArgumentName 'Path' -Message $errorMessage
        }
    }

    <#
        Create and returns the desired audit object. Always created disabled.

        This should return an object of type [Microsoft.SqlServer.Management.Smo.Audit]
        but using that type fails the build process currently.
        See issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/121.
    #>
    hidden [System.Object] CreateAudit()
    {
        # Get all properties that has an assigned value.
        $assignedDscProperties = $this | Get-DscProperty -HasValue -Attribute @(
            'Key'
            'Optional'
        ) -ExcludeName @(
            # Remove properties that is not an audit property.
            'InstanceName'
            'ServerName'
            'Ensure'
            'Force'
            'Credential'

            # Remove this audit property since it must be handled later.
            'Enabled'
        )

        if ($assignedDscProperties.Keys -notcontains 'LogType' -and $assignedDscProperties.Keys -notcontains 'Path')
        {
            New-InvalidOperationException -Message $this.localizedData.CannotCreateNewAudit
        }

        $serverObject = $this.GetServerObject()

        $auditObject = $serverObject | New-SqlDscAudit @assignedDscProperties -Force -PassThru

        return $auditObject
    }
}
