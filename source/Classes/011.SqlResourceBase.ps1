<#
    .SYNOPSIS
        The SqlResource base have generic properties and methods for the class-based
        resources.

    .PARAMETER InstanceName
        The name of the _SQL Server_ instance to be configured. Default value is
        `'MSSQLSERVER'`.

    .PARAMETER ServerName
        The host name of the _SQL Server_ to be configured. Default value is the
        current computer name.

    .PARAMETER Credential
        Specifies the credential to use to connect to the _SQL Server_ instance.

        If parameter **Credential'* is not provided then the resource instance is
        run using the credential that runs the configuration.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
#>
class SqlResourceBase : ResourceBase
{
    # Cache for resolved enum types to avoid repeated assembly scanning.
    hidden static [System.Collections.Generic.Dictionary[System.String, System.Type]] $EnumTypeCache = [System.Collections.Generic.Dictionary[System.String, System.Type]]::new()

    <#
        Property for holding the server connection object.
        This should be an object of type [Microsoft.SqlServer.Management.Smo.Server]
        but using that type fails the build process currently.
        See issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/121.
    #>
    hidden [System.Object] $SqlServerObject

    [DscProperty(Key)]
    [System.String]
    $InstanceName

    [DscProperty()]
    [System.String]
    $ServerName = (Get-ComputerName)

    [DscProperty()]
    [PSCredential]
    $Credential

    [DscProperty(NotConfigurable)]
    [SqlReason[]]
    $Reasons

    # Passing the module's base directory to the base constructor.
    SqlResourceBase () : base ($PSScriptRoot)
    {
        $this.SqlServerObject = $null
    }

    <#
        Returns and reuses the server connection object. If the server connection
        object does not exist a connection to the SQL Server instance will occur.

        This should return an object of type [Microsoft.SqlServer.Management.Smo.Server]
        but using that type fails the build process currently.
        See issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/121.
    #>
    hidden [System.Object] GetServerObject()
    {
        if (-not $this.SqlServerObject)
        {
            $connectSqlDscDatabaseEngineParameters = @{
                ServerName   = $this.ServerName
                InstanceName = $this.InstanceName
                ErrorAction  = 'Stop'
            }

            if ($this.Credential)
            {
                $connectSqlDscDatabaseEngineParameters.Credential = $this.Credential
            }

            $this.SqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters
        }

        return $this.SqlServerObject
    }

    <#
        .SYNOPSIS
            Converts a string value to the corresponding SMO enum type at runtime.

        .DESCRIPTION
            This helper method is required because PowerShell parses class definitions
            at module load time. Direct SMO type literals (e.g., [SMOType]::Value)
            would fail because SMO assemblies may not be loaded yet.

            This method uses runtime type resolution to avoid parse-time errors.

        .PARAMETER TypeName
            The name of the SMO enum type (e.g., 'RecoveryModel'). If the type name
            does not contain a dot, the Namespace parameter is prepended.

        .PARAMETER Value
            The string value to convert to the enum type.

        .PARAMETER Namespace
            The namespace of the SMO enum type. Defaults to 'Microsoft.SqlServer.Management.Smo'.

        .OUTPUTS
            The SMO enum value.

        .NOTES
            This is required due to PowerShell's class parsing behavior. We cannot
            use SMO types directly in the class definition, because they may not be
            installed when the module is imported. The user also decides which SMO
            to use (SQLPS, SqlServer, dbatools).
    #>
    hidden [System.Object] ConvertToSmoEnumType([System.String] $TypeName, [System.String] $Value)
    {
        return $this.ConvertToSmoEnumType($TypeName, $Value, 'Microsoft.SqlServer.Management.Smo')
    }

    hidden [System.Object] ConvertToSmoEnumType([System.String] $TypeName, [System.String] $Value, [System.String] $Namespace)
    {
        # If the type name doesn't contain a dot, prepend the namespace
        $fullTypeName = if ($TypeName -notmatch '\.')
        {
            '{0}.{1}' -f $Namespace, $TypeName
        }
        else
        {
            $TypeName
        }

        # Check cache first to avoid repeated assembly scanning.
        if ([SqlResourceBase]::EnumTypeCache.ContainsKey($fullTypeName))
        {
            $enumType = [SqlResourceBase]::EnumTypeCache[$fullTypeName]
        }
        else
        {
            $enumType = [System.Type]::GetType($fullTypeName, $false, $true)

            if (-not $enumType)
            {
                # Try loading from loaded assemblies if direct resolution fails.
                $enumType = [System.AppDomain]::CurrentDomain.GetAssemblies().GetTypes() |
                    Where-Object -FilterScript { $_.FullName -eq $fullTypeName } |
                    Select-Object -First 1
            }

            if ($enumType)
            {
                [SqlResourceBase]::EnumTypeCache[$fullTypeName] = $enumType
            }
        }

        if (-not $enumType)
        {
            New-InvalidOperationException -Message (
                $this.localizedData.ConvertToSmoEnumType_FailedToFindType -f $fullTypeName
            )
        }

        return [System.Enum]::Parse($enumType, $Value, $true)
    }
}
