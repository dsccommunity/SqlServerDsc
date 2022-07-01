#Region '.\prefix.ps1' 0
$script:dscResourceCommonModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules/DscResource.Common'
Import-Module -Name $script:dscResourceCommonModulePath

# TODO: The goal would be to remove this, when no classes and public or private functions need it.
$script:sqlServerDscCommonModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules/SqlServerDsc.Common'
Import-Module -Name $script:sqlServerDscCommonModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
#EndRegion '.\prefix.ps1' 9
#Region '.\Enum\1.Ensure.ps1' 0
<#
    .SYNOPSIS
        The possible states for the DSC resource parameter Ensure.
#>

enum Ensure
{
    Present
    Absent
}
#EndRegion '.\Enum\1.Ensure.ps1' 11

#Region '.\Classes\002.DatabasePermission.ps1' 0
<#
    .SYNOPSIS
        The possible database permission states.

    .PARAMETER State
        The state of the permission.

    .PARAMETER Permission
        The permissions to be granted or denied for the user in the database.

    .NOTES
        The DSC properties specifies attributes Key and Required, those attributes
        are not honored during compilation in the current implementation of
        PowerShell DSC. They are kept here so when they do get honored it will help
        detect missing properties during compilation. The Key property is evaluate
        during runtime so that no two states are enforcing the same permission.
#>
class DatabasePermission
{
    [DscProperty(Key)]
    [ValidateSet('Grant', 'GrantWithGrant', 'Deny')]
    [System.String]
    $State

    # TODO: Can we use a validate set for the permissions?
    [DscProperty(Mandatory)]
    [System.String[]]
    $Permission
}
#EndRegion '.\Classes\002.DatabasePermission.ps1' 30
#Region '.\Classes\002.Reason.ps1' 0
class Reason
{
    [DscProperty()]
    [System.String]
    $Code

    [DscProperty()]
    [System.String]
    $Phrase
}
#EndRegion '.\Classes\002.Reason.ps1' 11
#Region '.\Classes\003.SimpleResource.ps1' 0
<#
    .SYNOPSIS
        Resource for testing.
#>

[DscResource()]
class SimpleResource
{
    [DscProperty(Key)]
    [System.String]
    $InstanceName

    [DscProperty(Key)]
    [System.String]
    $DatabaseName

    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [System.String]
    $ServerName = (Get-ComputerName)

    [DscProperty(Mandatory)]
    [DatabasePermission[]]
    $Permission

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [SimpleResource] Get()
    {
        $dscResourceObject = [SimpleResource] @{
            InstanceName = 'SQL2017'
            DatabaseName = 'MyDB'
            Name = 'MyPrincipal'
            ServerName = 'MyHost'
            Ensure = 'Present'
            Permission = [DatabasePermission[]] @(
                    [DatabasePermission] @{
                        State = 'Grant'
                        Permission = @('CONNECT')
                    }
                    [DatabasePermission] @{
                        State = 'Deny'
                        Permission = @('SELECT')
                    }
                )
            Reasons = [Reason[]] @(
                [Reason] @{
                    Code = '{0}:{0}:Ensure' -f $this.GetType()
                    Phrase = 'The property Ensure should be Present, but was Absent'
                }
            )
        }

        return $dscResourceObject
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set()
    {
    }
}
#EndRegion '.\Classes\003.SimpleResource.ps1' 69
#Region '.\Classes\001.ResourceBase.ps1' 0
<#
    .SYNOPSIS
        A class with methods that are equal for all class-based resources.

    .DESCRIPTION
        A class with methods that are equal for all class-based resources.

    .NOTES
        This class should not contain any DSC properties.
#>

class ResourceBase
{
    # Hidden property for holding localization strings
    hidden [System.Collections.Hashtable] $localizedData = @{}

    # Default constructor
    ResourceBase()
    {
        # TODO: When this fails the LCM returns 'Failed to create an object of PowerShell class SqlDatabasePermission' instead of the actual error that occurred.
        $this.localizedData = Get-LocalizedDataRecursive -ClassName ($this | Get-ClassName -Recurse)
    }

    [ResourceBase] Get()
    {
        $this.Assert()

        # Get all key properties.
        $keyProperty = $this | Get-KeyProperty

        # TODO: TA BORT -VERBOSE
        Write-Verbose -Verbose -Message ($this.localizedData.GetCurrentState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

        <#
            TODO: Should call back to the derived class for proper handling of adding
                  additional parameters to the variable $keyProperty that needs to be
                  passed to GetCurrentState().
        #>
        #$specialKeyProperty = @()

        $getCurrentStateResult = $this.GetCurrentState($keyProperty)

        Write-Verbose -Verbose -Message ($getCurrentStateResult | Out-String)

        $dscResourceObject = [System.Activator]::CreateInstance($this.GetType())


           $dscResourceObject.InstanceName = 'SQL2017'
           $dscResourceObject.DatabaseName = 'MyDB'
           $dscResourceObject.Name = 'MyPrincipal'
           $dscResourceObject.ServerName = 'MyHost'
           $dscResourceObject.Ensure = 'Present'
           $dscResourceObject.Permission = [DatabasePermission[]] @(
                    [DatabasePermission] @{
                        State = 'Grant'
                        Permission = @('CONNECT')
                    }
                    [DatabasePermission] @{
                        State = 'Deny'
                        Permission = @('SELECT')
                    }
                )
           $dscResourceObject.Reasons = [Reason[]] @(
                [Reason] @{
                    Code = '{0}:{0}:Ensure' -f $this.GetType()
                    Phrase = 'The property Ensure should be Present, but was Absent'
                }
            )


        return $dscResourceObject

        $dscResourceObject = [System.Activator]::CreateInstance($this.GetType())

        foreach ($propertyName in $this.PSObject.Properties.Name)
        {
            Write-Verbose -Verbose -Message '----------------------------'
            Write-Verbose -Verbose -Message $propertyName

            if ($propertyName -in @($getCurrentStateResult.Keys))
            {
                Write-verbose -Verbose -Message ($getCurrentStateResult.$propertyName.GetType().FullName | Out-String)
                Write-verbose -Verbose -Message ($getCurrentStateResult.$propertyName.GetType().IsArray | Out-String)
                Write-verbose -Verbose -Message ($getCurrentStateResult.$propertyName.GetType().Module.ScopeName | Out-String)
                #Write-verbose -Verbose -Message ($getCurrentStateResult.$propertyName.GetType() | fl * | Out-String)

                if ($propertyName -eq 'Permission')
                {
                    Write-verbose -Verbose -Message 'HARDCODE PERMISSION'

                    $dscResourceObject.Permission = [DatabasePermission[]] @(
                        [DatabasePermission] @{
                            State = 'Grant'
                            Permission = @('CONNECT')
                        }
                        [DatabasePermission] @{
                            State = 'Deny'
                            Permission = @('SELECT')
                        }
                    )
                }
                else
                {
                    $dscResourceObject.$propertyName = $getCurrentStateResult.$propertyName -as $getCurrentStateResult.$propertyName.GetType().FullName
                }
            }
        }

        # Return properties.
        return $dscResourceObject
    }

    [void] Set()
    {
        # Get all key properties.
        $keyProperty = $this | Get-KeyProperty

        Write-Verbose -Verbose -Message ($this.localizedData.SetDesiredState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

        $this.Assert()

        # Call the Compare method to get enforced properties that are not in desired state.
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $propertiesToModify = $this.GetDesiredStateForSplatting($propertiesNotInDesiredState)

            $propertiesToModify.Keys | ForEach-Object -Process {
                Write-Verbose -Verbose -Message ($this.localizedData.SetProperty -f $_, $propertiesToModify.$_)
            }

            <#
                Call the Modify() method with the properties that should be enforced
                and was not in desired state.
            #>
            $this.Modify($propertiesToModify)
        }
        else
        {
            Write-Verbose -Verbose -Message $this.localizedData.NoPropertiesToSet
        }
    }

    [System.Boolean] Test()
    {
        # Get all key properties.
        $keyProperty = $this | Get-KeyProperty

        Write-Verbose -Verbose -Message ($this.localizedData.TestDesiredState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

        $this.Assert()

        $isInDesiredState = $true

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $isInDesiredState = $false
        }

        if ($isInDesiredState)
        {
            Write-Verbose -Verbose -Message $this.localizedData.InDesiredState
        }
        else
        {
            Write-Verbose -Verbose -Message $this.localizedData.NotInDesiredState
        }

        return $isInDesiredState
    }

    <#
        Returns a hashtable containing all properties that should be enforced and
        are not in desired state.

        This method should normally not be overridden.
    #>
    hidden [System.Collections.Hashtable[]] Compare()
    {
        $currentState = $this.Get() | ConvertFrom-DscResourceInstance
        $desiredState = $this | Get-DesiredStateProperty

        $CompareDscParameterState = @{
            CurrentValues     = $currentState
            DesiredValues     = $desiredState
            Properties        = $desiredState.Keys
            ExcludeProperties = @('DnsServer')
            IncludeValue      = $true
        }

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        return (Compare-DscParameterState @CompareDscParameterState)
    }

    # Returns a hashtable containing all properties that should be enforced.
    hidden [System.Collections.Hashtable] GetDesiredStateForSplatting([System.Collections.Hashtable[]] $Properties)
    {
        $desiredState = @{}

        $Properties | ForEach-Object -Process {
            $desiredState[$_.Property] = $_.ExpectedValue
        }

        return $desiredState
    }

    # This method should normally not be overridden.
    hidden [void] Assert()
    {
        $desiredState = $this | Get-DesiredStateProperty

        $this.AssertProperties($desiredState)
    }

    <#
        This method can be overridden if resource specific property asserts are
        needed. The parameter properties will contain the properties that was
        passed a value.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidEmptyNamedBlocks', '')]
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
    }

    <#
        This method must be overridden by a resource. The parameter properties will
        contain the properties that should be enforced and that are not in desired
        state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        throw $this.localizedData.ModifyMethodNotImplemented
    }

    <#
        This method must be overridden by a resource. The parameter properties will
        contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        throw $this.localizedData.GetCurrentStateMethodNotImplemented
    }
}
#EndRegion '.\Classes\001.ResourceBase.ps1' 200

#Region '.\Classes\003.SqlDatabasePermission.ps1' 0
<#
    .SYNOPSIS
        The `SqlDatabasePermission` DSC resource is used to grant, deny or revoke
        permissions for a user in a database

    .DESCRIPTION
        The `SqlDatabasePermission` DSC resource is used to grant, deny or revoke
        permissions for a user in a database. For more information about permissions,
        please read the article [Permissions (Database Engine)](https://docs.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine).

        >**Note:** When revoking permission with PermissionState 'GrantWithGrant', both the
        >grantee and _all the other users the grantee has granted the same permission to_,
        >will also get their permission revoked.

        Valid permission names can be found in the article [DatabasePermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.databasepermissionset#properties).

        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must be running SQL Server Database Engine 2012 or later.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabasePermission).

    .PARAMETER InstanceName
        The name of the SQL Server instance to be configured. Default value is
        'MSSQLSERVER'.

    .PARAMETER DatabaseName
        The name of the database.

    .PARAMETER Name
        The name of the user that should be granted or denied the permission.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER Permission
        An array of database permissions to enforce.

        This is an array of CIM instances of class `DatabasePermission` from the
        namespace `root/Microsoft/Windows/DesiredStateConfiguration`.

    .PARAMETER Ensure
        If the permission should be granted ('Present') or revoked ('Absent').

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
#>

[DscResource()]
class SqlDatabasePermission : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $InstanceName

    [DscProperty(Key)]
    [System.String]
    $DatabaseName

    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [System.String]
    $ServerName = (Get-ComputerName)

    [DscProperty(Mandatory)]
    [DatabasePermission[]]
    $Permission

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [SqlDatabasePermission] Get()
    {
            $dscResourceObject = [SimpleResource] @{
            InstanceName = 'SQL2017'
            DatabaseName = 'MyDB'
            Name = 'MyPrincipal'
            ServerName = 'MyHost'
            Ensure = 'Present'
            Permission = [DatabasePermission[]] @(
                    [DatabasePermission] @{
                        State = 'Grant'
                        Permission = @('CONNECT')
                    }
                    [DatabasePermission] @{
                        State = 'Deny'
                        Permission = @('SELECT')
                    }
                )
            Reasons = [Reason[]] @(
                [Reason] @{
                    Code = '{0}:{0}:Ensure' -f $this.GetType()
                    Phrase = 'The property Ensure should be Present, but was Absent'
                }
            )
        }

        return $dscResourceObject

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
        $currentState = @{
            Ensure       = 'Absent'
            ServerName   = $this.ServerName
            InstanceName = $properties.InstanceName
            DatabaseName = $properties.DatabaseName
            Permission   = [DatabasePermission[]] @()
            Name         = $properties.Name
        }

        $sqlServerObject = Connect-SqlDscDatabaseEngine -ServerName $this.ServerName -InstanceName $properties.InstanceName

        # TA BORT -VERBOSE!
        Write-Verbose -Verbose -Message (
            $this.localizedData.EvaluateDatabasePermissionForPrincipal -f @(
                $properties.Name,
                $properties.DatabaseName,
                $properties.InstanceName
            )
        )

        $databasePermissionInfo = $sqlServerObject |
            Get-SqlDscDatabasePermission -DatabaseName $this.DatabaseName -Name $this.Name -IgnoreMissingPrincipal

        if ($databasePermissionInfo)
        {
            $permissionState = $databasePermissionInfo | ForEach-Object -Process {
                # Convert from the type PermissionState to String.
                [System.String] $_.PermissionState
            } | Select-Object -Unique

            foreach ($currentPermissionState in $permissionState)
            {
                $filteredDatabasePermission = $databasePermissionInfo |
                    Where-Object -FilterScript {
                        $_.PermissionState -eq $currentPermissionState
                    }

                $databasePermission = [DatabasePermission] @{
                    State = $currentPermissionState
                }

                # Initialize variable permission
                [System.String[]] $statePermissionResult = @()

                foreach ($currentPermission in $filteredDatabasePermission)
                {
                    $permissionProperty = (
                        $currentPermission.PermissionType |
                            Get-Member -MemberType Property
                    ).Name

                    foreach ($currentPermissionProperty in $permissionProperty)
                    {
                        if ($currentPermission.PermissionType."$currentPermissionProperty")
                        {
                            $statePermissionResult += $currentPermissionProperty
                        }
                    }
                }

                <#
                    Sort and remove any duplicate permissions, also make sure
                    it is an array even if only one item.
                #>
                $databasePermission.Permission = @(
                    $statePermissionResult |
                        Sort-Object -Unique
                )

                [DatabasePermission[]] $currentState.Permission += $databasePermission
            }
        }

        return $currentState
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced and that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message ($properties | Out-String) -Verbose

        #Set-DnsServerDsSetting @properties
    }

    <#
        Base method Assert() call this method with the properties that was passed
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # @(
        #     'DirectoryPartitionAutoEnlistInterval',
        #     'TombstoneInterval'
        # ) | ForEach-Object -Process {
        #     $valueToConvert = $this.$_

        #     # Only evaluate properties that have a value.
        #     if ($null -ne $valueToConvert)
        #     {
        #         Assert-TimeSpan -PropertyName $_ -Value $valueToConvert -Minimum '0.00:00:00'
        #     }
        # }
    }
}
#EndRegion '.\Classes\003.SqlDatabasePermission.ps1' 215
#Region '.\Private\Get-ClassName.ps1' 0
<#
    .SYNOPSIS
        Get the class name of the passed object, and optional an array with
        all inherited classes.

    .PARAMETER InputObject
       The object to be evaluated.

    .OUTPUTS
        Returns a string array with at least one item.
#>
function Get-ClassName
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Recurse
    )

    # Create a list of the inherited class names
    $class = @($InputObject.GetType().FullName)

    if ($Recurse.IsPresent)
    {
        $parentClass = $InputObject.GetType().BaseType

        while ($parentClass -ne [System.Object])
        {
            $class += $parentClass.FullName

            $parentClass = $parentClass.BaseType
        }
    }

    return ,$class
}
#EndRegion '.\Private\Get-ClassName.ps1' 44
#Region '.\Private\Get-DesiredStateProperty.ps1' 0

<#
    .SYNOPSIS
        Returns the properties that should be enforced for the desired state.

    .DESCRIPTION
        Returns the properties that should be enforced for the desired state.
        This function converts a PSObject into a hashtable containing the properties
        that should be enforced.

    .PARAMETER InputObject
        The object that contain the properties with the desired state.

    .OUTPUTS
        Hashtable
#>
function Get-DesiredStateProperty
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject
    )

    $desiredStateProperty = $InputObject | ConvertFrom-DscResourceInstance

    <#
        Remove properties that have $null as the value, and remove read
        properties so that there is no chance to compare those.
    #>
    @($desiredStateProperty.Keys) | ForEach-Object -Process {
        $isReadProperty = $InputObject.GetType().GetMember($_).CustomAttributes.Where( { $_.NamedArguments.MemberName -eq 'NotConfigurable' }).NamedArguments.TypedValue.Value -eq $true

        if ($isReadProperty -or $null -eq $desiredStateProperty[$_])
        {
            $desiredStateProperty.Remove($_)
        }
    }

    return $desiredStateProperty
}
#EndRegion '.\Private\Get-DesiredStateProperty.ps1' 45
#Region '.\Private\Get-KeyProperty.ps1' 0

<#
    .SYNOPSIS
        Returns the DSC resource key property and its value.

    .DESCRIPTION
        Returns the DSC resource key property and its value.

    .PARAMETER InputObject
        The object that contain the key property.

    .OUTPUTS
        Hashtable
#>
function Get-KeyProperty
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject
    )

    # Get all key properties.
    $keyProperty = $InputObject |
        Get-Member -MemberType 'Property' |
        Select-Object -ExpandProperty 'Name' |
        Where-Object -FilterScript {
            $InputObject.GetType().GetMember($_).CustomAttributes.Where( { $_.NamedArguments.MemberName -eq 'Key' }).NamedArguments.TypedValue.Value -eq $true
        }

    # Return a hashtable containing each key property and its value.
    $getKeyPropertyResult = @{}

    $keyProperty | ForEach-Object -Process {
        $getKeyPropertyResult.$_ = $InputObject.$_
    }

    return $getKeyPropertyResult
}
#EndRegion '.\Private\Get-KeyProperty.ps1' 43
#Region '.\Private\Get-LocalizedDataRecursive.ps1' 0
<#
    .SYNOPSIS
        Get the localization strings data from one or more localization string files.
        This can be used in classes to be able to inherit localization strings
        from one or more parent (base) classes.

        The order of class names passed to parameter `ClassName` determines the order
        of importing localization string files. First entry's localization string file
        will be imported first, then next entry's localization string file, and so on.
        If the second (or any consecutive) entry's localization string file contain a
        localization string key that existed in a previous imported localization string
        file that localization string key will be ignored. Making it possible for a
        child class to override localization strings from one or more parent (base)
        classes.

    .PARAMETER ClassName
        An array of class names, normally provided by `Get-ClassName -Recurse`.

    .OUTPUTS
        Returns a string array with at least one item.
#>
function Get-LocalizedDataRecursive
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String[]]
        $ClassName
    )

    begin
    {
        $localizedData = @{}
    }

    process
    {
        foreach ($name in $ClassName)
        {
            if ($name -match '\.psd1')
            {
                # Assume we got full file name.
                $localizationFileName = $name
            }
            else
            {
                # Assume we only got class name.
                $localizationFileName = '{0}.strings.psd1' -f $name
            }

            Write-Debug -Message ('Importing localization data from {0}' -f $localizationFileName)

            # Get localized data for the class
            $classLocalizationStrings = Get-LocalizedData -DefaultUICulture 'en-US' -FileName $localizationFileName -ErrorAction 'Stop'

            # Append only previously unspecified keys in the localization data
            foreach ($key in $classLocalizationStrings.Keys)
            {
                if (-not $localizedData.ContainsKey($key))
                {
                    $localizedData[$key] = $classLocalizationStrings[$key]
                }
            }
        }
    }

    end
    {
        Write-Debug -Message ('Localization data: {0}' -f ($localizedData | ConvertTo-JSON))

        return $localizedData
    }
}
#EndRegion '.\Private\Get-LocalizedDataRecursive.ps1' 76
#Region '.\Public\Connect-SqlDscDatabaseEngine.ps1' 0
<#
    .SYNOPSIS
        Connect to a SQL Server Database Engine and return the server object.

    .PARAMETER ServerName
        String containing the host name of the SQL Server to connect to.
        Default value is the current computer name.

    .PARAMETER InstanceName
        String containing the SQL Server Database Engine instance to connect to.
        Default value is 'MSSQLSERVER'.

    .PARAMETER Credential
        The credentials to use to impersonate a user when connecting to the
        SQL Server Database Engine instance. If this parameter is left out, then
        the current user will be used to connect to the SQL Server Database Engine
        instance using Windows Integrated authentication.

    .PARAMETER LoginType
        Specifies which type of logon credential should be used. The valid types
        are 'WindowsUser' or 'SqlLogin'. Default value is 'WindowsUser'
        If set to 'WindowsUser' then the it will impersonate using the Windows
        login specified in the parameter Credential.
        If set to 'WindowsUser' then the it will impersonate using the native SQL
        login specified in the parameter Credential.

    .PARAMETER StatementTimeout
        Set the query StatementTimeout in seconds. Default 600 seconds (10 minutes).

    .EXAMPLE
        Connect-SqlDscDatabaseEngine

        Connects to the default instance on the local server.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'

        Connects to the instance 'MyInstance' on the local server.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine -ServerName 'sql.company.local' -InstanceName 'MyInstance'

        Connects to the instance 'MyInstance' on the server 'sql.company.local'.
#>
function Connect-SqlDscDatabaseEngine
{
    [CmdletBinding(DefaultParameterSetName = 'SqlServer')]
    param
    (
        [Parameter(ParameterSetName = 'SqlServer')]
        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateNotNull()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(ParameterSetName = 'SqlServer')]
        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateNotNull()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter(ParameterSetName = 'SqlServerWithCredential', Mandatory = $true)]
        [ValidateNotNull()]
        [Alias('SetupCredential', 'DatabaseCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateSet('WindowsUser', 'SqlLogin')]
        [System.String]
        $LoginType = 'WindowsUser',

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600
    )

    # Call the private function.
    return (Connect-Sql @PSBoundParameters)
}
#EndRegion '.\Public\Connect-SqlDscDatabaseEngine.ps1' 82
#Region '.\Public\Get-SqlDscDatabasePermission.ps1' 0
<#
    .SYNOPSIS
        Returns the current permissions for the database principal.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specifies the database name.

    .PARAMETER Name
        Specifies the name of the database principal for which the permissions are
        returned.

    .PARAMETER IgnoreMissingPrincipal
        Specifies that the command ignores if the database principal do not exist
        which also include if database is not present.
        If not passed the command throws an error if the database or database
        principal is missing.

    .OUTPUTS
        [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]]

    .NOTES
        This command excludes fixed roles like db_datareader, and will always return
        $null for such roles.
#>
function Get-SqlDscDatabasePermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Because Script Analyzer does not understand type even if cast when using comma in return statement')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IgnoreMissingPrincipal
    )

    # Initialize variable permission
    $getSqlDscDatabasePermissionResult = $null

    $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]

    if ($sqlDatabaseObject)
    {
        $testSqlDscIsDatabasePrincipalParameters = @{
            ServerObject      = $ServerObject
            DatabaseName      = $DatabaseName
            Name              = $Name
            ExcludeFixedRoles = $true
        }

        $isDatabasePrincipal = Test-SqlDscIsDatabasePrincipal @testSqlDscIsDatabasePrincipalParameters

        if ($isDatabasePrincipal)
        {
            $getSqlDscDatabasePermissionResult = $sqlDatabaseObject.EnumDatabasePermissions($Name)
        }
        else
        {
            $missingPrincipalMessage = $script:localizedData.DatabasePermissionMissingPrincipal -f $Name, $DatabaseName

            if ($IgnoreMissingPrincipal.IsPresent)
            {
                Write-Verbose -Message $missingPrincipalMessage
            }
            else
            {
                throw $missingPrincipalMessage
            }
        }
    }
    else
    {
        $missingPrincipalMessage = $script:localizedData.DatabasePermissionMissingDatabase -f $DatabaseName

        if ($IgnoreMissingPrincipal.IsPresent)
        {
            Write-Verbose -Message $missingPrincipalMessage
        }
        else
        {
            throw $missingPrincipalMessage
        }
    }

    return , $getSqlDscDatabasePermissionResult
}
#EndRegion '.\Public\Get-SqlDscDatabasePermission.ps1' 103
#Region '.\Public\Test-SqlDscIsDatabasePrincipal.ps1' 0
<#
    .SYNOPSIS
        Returns whether the database principal exist.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specifies the SQL database name.

    .PARAMETER Name
        Specifies the name of the database principal.
#>
function Test-SqlDscIsDatabasePrincipal
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeUsers,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeRoles,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeFixedRoles,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeApplicationRoles
    )

    $principalExist = $false

    $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]

    if (-not $ExcludeUsers.IsPresent -and $sqlDatabaseObject.Users[$Name])
    {
        $principalExist = $true
    }

    if (-not $ExcludeRoles.IsPresent)
    {
        $userDefinedRole = if ($ExcludeFixedRoles.IsPresent)
        {
            # Skip fixed roles like db_datareader.
            $sqlDatabaseObject.Roles | Where-Object -FilterScript {
                -not $_.IsFixedRole -and $_.Name -eq $Name
            }
        }
        else
        {
            $sqlDatabaseObject.Roles[$Name]
        }

        if ($userDefinedRole)
        {
            $principalExist = $true
        }
    }

    if (-not $ExcludeApplicationRoles.IsPresent -and $sqlDatabaseObject.ApplicationRoles[$Name])
    {
        $principalExist = $true
    }

    return $principalExist
}
#EndRegion '.\Public\Test-SqlDscIsDatabasePrincipal.ps1' 85
