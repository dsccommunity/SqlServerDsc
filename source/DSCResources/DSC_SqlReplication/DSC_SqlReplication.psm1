$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the SQL Replication distributor or publisher.

    .PARAMETER InstanceName
        SQL Server instance name where replication distribution will be configured.

    .PARAMETER Ensure
        'Present' will configure replication, 'Absent' will disable replication.
        Default value is 'Present'.

    .PARAMETER DistributorMode
        'Local' - Instance will be configured as it's own distributor.
        'Remote' - Instance will be configure with remote distributor
        (remote distributor needs to be already configured for distribution).

    .PARAMETER AdminLinkCredentials
        AdminLink password to be used when setting up publisher distributor
        relationship.

    .PARAMETER DistributionDBName
        Distribution database name. If DistributionMode='Local' this will be created,
        if 'Remote' needs to match distribution database on remote distributor.
        Default value is 'distributor'.

    .PARAMETER RemoteDistributor
        SQL Server network name that will be used as distributor for local instance.
        Required if DistributionMode='Remote'.

    .PARAMETER WorkingDirectory
        Publisher working directory.

    .PARAMETER UseTrustedConnection
        Publisher security mode. Default value is $true.

    .PARAMETER UninstallWithForce
        Force flag for uninstall procedure. Default values is $true.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateSet('Local', 'Remote')]
        [System.String]
        $DistributorMode,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [Parameter()]
        [System.String]
        $DistributionDBName = 'distribution',

        [Parameter()]
        [System.String]
        $RemoteDistributor,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [Parameter()]
        [System.Boolean]
        $UseTrustedConnection = $true,

        [Parameter()]
        [System.Boolean]
        $UninstallWithForce = $true
    )

    Write-Verbose -Message (
        $script:localizedData.GetCurrentState -f $InstanceName
    )

    Import-SqlDscPreferredModule

    $sqlMajorVersion = Get-SqlInstanceMajorVersion -InstanceName $InstanceName
    $localSqlName = Get-SqlLocalServerName -InstanceName $InstanceName

    $localServerConnection = New-ServerConnection -SqlMajorVersion $sqlMajorVersion -SqlServerName $localSqlName
    $localReplicationServer = New-ReplicationServer -SqlMajorVersion $sqlMajorVersion -ServerConnection $localServerConnection

    $currentEnsure = 'Present'

    if ($localReplicationServer.IsDistributor -eq $true)
    {
        $currentDistributorMode = 'Local'
    }
    elseif ($localReplicationServer.IsPublisher -eq $true)
    {
        $currentDistributorMode = 'Remote'
    }
    else
    {
        $currentEnsure = 'Absent'
    }

    if ($currentEnsure -eq 'Present')
    {
        Write-Verbose -Message (
            $script:localizedData.DistributorMode -f $DistributorMode, $InstanceName
        )

        $currentDistributionDBName = $localReplicationServer.DistributionDatabase
        $currentRemoteDistributor = $localReplicationServer.DistributionServer
        $currentWorkingDirectory = $localReplicationServer.WorkingDirectory
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.NoDistributorMode -f $InstanceName
        )
    }

    $returnValue = @{
        InstanceName       = $InstanceName
        Ensure             = $currentEnsure
        DistributorMode    = $currentDistributorMode
        DistributionDBName = $currentDistributionDBName
        RemoteDistributor  = $currentRemoteDistributor
        WorkingDirectory   = $currentWorkingDirectory
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Set the desired state of the SQL Replication distributor or publisher.

    .PARAMETER InstanceName
        SQL Server instance name where replication distribution will be configured.

    .PARAMETER Ensure
        'Present' will configure replication, 'Absent' will disable replication.
        Default value is 'Present'.

    .PARAMETER DistributorMode
        'Local' - Instance will be configured as it's own distributor.
        'Remote' - Instance will be configure with remote distributor
        (remote distributor needs to be already configured for distribution).

    .PARAMETER AdminLinkCredentials
        AdminLink password to be used when setting up publisher distributor
        relationship.

    .PARAMETER DistributionDBName
        Distribution database name. If DistributionMode='Local' this will be created,
        if 'Remote' needs to match distribution database on remote distributor.
        Default value is 'distributor'.

    .PARAMETER RemoteDistributor
        SQL Server network name that will be used as distributor for local instance.
        Required if DistributionMode='Remote'.

    .PARAMETER WorkingDirectory
        Publisher working directory.

    .PARAMETER UseTrustedConnection
        Publisher security mode. Default value is $true.

    .PARAMETER UninstallWithForce
        Force flag for uninstall procedure. Default values is $true.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateSet('Local', 'Remote')]
        [System.String]
        $DistributorMode,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [Parameter()]
        [System.String]
        $DistributionDBName = 'distribution',

        [Parameter()]
        [System.String]
        $RemoteDistributor,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [Parameter()]
        [System.Boolean]
        $UseTrustedConnection = $true,

        [Parameter()]
        [System.Boolean]
        $UninstallWithForce = $true
    )

    Import-SqlDscPreferredModule

    if (($DistributorMode -eq 'Remote') -and (-not $RemoteDistributor))
    {
        $errorMessage = $script:localizedData.NoRemoteDistributor
        New-InvalidArgumentException -ArgumentName 'RemoteDistributor' -Message $errorMessage
    }

    $sqlMajorVersion = Get-SqlInstanceMajorVersion -InstanceName $InstanceName
    $localSqlName = Get-SqlLocalServerName -InstanceName $InstanceName

    $localServerConnection = New-ServerConnection -SqlMajorVersion $sqlMajorVersion -SqlServerName $localSqlName
    $localReplicationServer = New-ReplicationServer -SqlMajorVersion $sqlMajorVersion -ServerConnection $localServerConnection

    if ($Ensure -eq 'Present')
    {
        if ($DistributorMode -eq 'Local' -and $localReplicationServer.IsDistributor -eq $false)
        {
            Write-Verbose -Message (
                $script:localizedData.ConfigureLocalDistributor
            )

            $distributionDB = New-DistributionDatabase `
                -SqlMajorVersion $sqlMajorVersion `
                -DistributionDBName $DistributionDBName `
                -ServerConnection $localServerConnection

            Install-LocalDistributor `
                -ReplicationServer $localReplicationServer `
                -AdminLinkCredentials $AdminLinkCredentials `
                -DistributionDB $distributionDB

            Register-DistributorPublisher `
                -SqlMajorVersion $sqlMajorVersion `
                -PublisherName $localSqlName `
                -ServerConnection $localServerConnection `
                -DistributionDBName $DistributionDBName `
                -WorkingDirectory $WorkingDirectory `
                -UseTrustedConnection $UseTrustedConnection
        }

        if ($DistributorMode -eq 'Remote' -and $localReplicationServer.IsPublisher -eq $false)
        {
            Write-Verbose -Message (
                $script:localizedData.ConfigureRemoteDistributor
            )

            $remoteConnection = New-ServerConnection -SqlMajorVersion $sqlMajorVersion -SqlServerName $RemoteDistributor

            Register-DistributorPublisher `
                -SqlMajorVersion $sqlMajorVersion `
                -PublisherName $localSqlName `
                -ServerConnection $remoteConnection `
                -DistributionDBName $DistributionDBName `
                -WorkingDirectory $WorkingDirectory `
                -UseTrustedConnection $UseTrustedConnection

            Install-RemoteDistributor `
                -ReplicationServer $localReplicationServer `
                -RemoteDistributor $RemoteDistributor `
                -AdminLinkCredentials $AdminLinkCredentials
        }
    }
    else #'Absent'
    {
        if ($localReplicationServer.IsDistributor -eq $true -or $localReplicationServer.IsPublisher -eq $true)
        {
            Write-Verbose -Message (
                $script:localizedData.RemoveDistributor
            )

            Uninstall-Distributor -ReplicationServer $localReplicationServer -UninstallWithForce $UninstallWithForce
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.NoDistributorMode -f $InstanceName
            )
        }
    }
}

<#
    .SYNOPSIS
        Determines the current state of the SQL Replication distributor or publisher.

    .PARAMETER InstanceName
        SQL Server instance name where replication distribution will be configured.

    .PARAMETER Ensure
        'Present' will configure replication, 'Absent' will disable replication.
        Default value is 'Present'.

    .PARAMETER DistributorMode
        'Local' - Instance will be configured as it's own distributor.
        'Remote' - Instance will be configure with remote distributor
        (remote distributor needs to be already configured for distribution).

    .PARAMETER AdminLinkCredentials
        AdminLink password to be used when setting up publisher distributor
        relationship.

    .PARAMETER DistributionDBName
        Distribution database name. If DistributionMode='Local' this will be created,
        if 'Remote' needs to match distribution database on remote distributor.
        Default value is 'distributor'.

    .PARAMETER RemoteDistributor
        SQL Server network name that will be used as distributor for local instance.
        Required if DistributionMode='Remote'.

    .PARAMETER WorkingDirectory
        Publisher working directory.

    .PARAMETER UseTrustedConnection
        Publisher security mode. Default value is $true.

    .PARAMETER UninstallWithForce
        Force flag for uninstall procedure. Default values is $true.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='It is imported in Get-TargetResource, also this resource explicitly loads assemblies from the GAC. This is being tracked in issue https://github.com/dsccommunity/SqlServerDsc/issues/1352')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateSet('Local', 'Remote')]
        [System.String]
        $DistributorMode,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [Parameter()]
        [System.String]
        $DistributionDBName = 'distribution',

        [Parameter()]
        [System.String]
        $RemoteDistributor,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [Parameter()]
        [System.Boolean]
        $UseTrustedConnection = $true,

        [Parameter()]
        [System.Boolean]
        $UninstallWithForce = $true
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration
    )

    $result = $false
    $state = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq 'Absent' -and $state.Ensure -eq 'Absent')
    {
        $result = $true
    }
    elseif ($Ensure -eq 'Present' -and $state.Ensure -eq 'Present' -and $state.DistributorMode -eq $DistributorMode)
    {
        $result = $true
    }

    return $result
}

<#
    .SYNOPSIS
        Initiates and returns a new server connection.

    .PARAMETER SqlMajorVersion
        Specifies the major version of the Sql Server instance.

    .PARAMETER SqlServerName
        SQL Server instance name to connect to.
#>
function New-ServerConnection
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlMajorVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlServerName
    )

    if ($SqlMajorVersion -eq 16)
    {
        <#
            For SQL Server 2022 the object must be created with New-Object and
            also requires the module SqlServer v22 (minimum v22.0.49-preview).
        #>
        $serverConnection = New-Object -TypeName 'Microsoft.SqlServer.Management.Common.ServerConnection' -ArgumentList $SqlServerName
    }
    else
    {
        <#
            SQL Server 2016, 2017, and 2019 must use the assembly in the GAC. If the
            method for SQL Server 2022 is used it throws the error:

            Cannot find an overload for "ReplicationServer" and the argument count: "1".
                + CategoryInfo          : InvalidOperation: (:) [], CimException
                + FullyQualifiedErrorId : ConstructorInvokedThrowException,Microsoft.PowerShell.Commands.NewObjectCommand
                + PSComputerName        : localhost
        #>
        $connInfo = Get-ConnectionInfoAssembly -SqlMajorVersion $SqlMajorVersion
        $serverConnection = New-Object -TypeName $connInfo.GetType('Microsoft.SqlServer.Management.Common.ServerConnection') -ArgumentList $SqlServerName
    }

    return $serverConnection
}

<#
    .SYNOPSIS
        Initiates and returns a new server connection.

    .PARAMETER SqlMajorVersion
        Specifies the major version of the Sql Server instance.

    .PARAMETER ServerConnection
        SQL Server instance to connect to.
#>
function New-ReplicationServer
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlMajorVersion,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $ServerConnection
    )

    $rmo = Get-RmoAssembly -SqlMajorVersion $SqlMajorVersion
    $localReplicationServer = New-Object $rmo.GetType('Microsoft.SqlServer.Replication.ReplicationServer') $ServerConnection

    return $localReplicationServer;
}

<#
    .SYNOPSIS
        Initiates and returns a new distribution database object.

    .PARAMETER SqlMajorVersion
        Specifies the major version of the Sql Server instance.

    .PARAMETER DistributionDBName
        Specifies the distribution database name.

    .PARAMETER ServerConnection
        SQL Server instance to connect to.
#>
function New-DistributionDatabase
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlMajorVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DistributionDBName,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $ServerConnection
    )

    $rmo = Get-RmoAssembly -SqlMajorVersion $SqlMajorVersion

    Write-Verbose -Message (
        $script:localizedData.CreateDistributionDatabase -f $DistributionDBName
    )

    $distributionDB = New-Object $rmo.GetType('Microsoft.SqlServer.Replication.DistributionDatabase') $DistributionDBName, $ServerConnection

    return $distributionDB
}

<#
    .SYNOPSIS
        Initiates and returns a new distribution publisher object.

    .PARAMETER SqlMajorVersion
        Specifies the major version of the Sql Server instance.

    .PARAMETER PublisherName
        Specifies the name of the publisher.

    .PARAMETER ServerConnection
        SQL Server instance to connect to.
#>
function New-DistributionPublisher
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlMajorVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PublisherName,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $ServerConnection
    )

    $rmo = Get-RmoAssembly -SqlMajorVersion $SqlMajorVersion

    try
    {
        $distributorPublisher = New-object $rmo.GetType('Microsoft.SqlServer.Replication.DistributionPublisher') $PublisherName, $ServerConnection
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedInFunction -f 'New-DistributionPublisher'

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    return $distributorPublisher
}

<#
    .SYNOPSIS
        Installs a remote distributor.

    .PARAMETER ReplicationServer
        Specifies the replication server object from the cmdlet New-ReplicationServer.

    .PARAMETER RemoteDistributor
        Specifies the name of the remote distributor.

    .PARAMETER AdminLinkCredentials
        AdminLink password to be used when setting up publisher distributor
        relationship.
#>
function Install-RemoteDistributor
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ReplicationServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RemoteDistributor,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials
    )

    Write-Verbose -Message (
        $script:localizedData.InstallRemoteDistributor -f $RemoteDistributor
    )

    try
    {
        $ReplicationServer.InstallDistributor($RemoteDistributor, $AdminLinkCredentials.Password)
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedInFunction -f 'Install-RemoteDistributor'

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Installs a local distributor.

    .PARAMETER ReplicationServer
        Specifies the replication server object from the cmdlet New-ReplicationServer.

    .PARAMETER DistributionDB
        Specifies the name of the distributor database.

    .PARAMETER AdminLinkCredentials
        AdminLink password to be used when setting up publisher distributor
        relationship.
#>
function Install-LocalDistributor
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ReplicationServer,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $DistributionDB
    )

    Write-Verbose -Message (
        $script:localizedData.InstallLocalDistributor
    )

    try
    {
        $ReplicationServer.InstallDistributor($AdminLinkCredentials.Password, $DistributionDB)
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedInFunction -f 'Install-LocalDistributor'

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Uninstalls a distributor.

    .PARAMETER ReplicationServer
        Specifies the replication server object from the cmdlet New-ReplicationServer.

    .PARAMETER UninstallWithForce
        Force flag for uninstall procedure. Default values is $true.
#>
function Uninstall-Distributor
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ReplicationServer,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $UninstallWithForce
    )

    Write-Verbose -Message (
        $script:localizedData.UninstallDistributor
    )

    try
    {
        $ReplicationServer.UninstallDistributor($UninstallWithForce)
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedInFunction -f 'Uninstall-Distributor'

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Registers a distribution publisher.

    .PARAMETER SqlMajorVersion
        Specifies the major version of the Sql Server instance.

    .PARAMETER PublisherName
        Specifies the name of the publisher.

    .PARAMETER ServerConnection
        SQL Server instance to connect to.

    .PARAMETER DistributionDBName
        Specifies the distribution database name.

    .PARAMETER WorkingDirectory
        Publisher working directory.

    .PARAMETER UseTrustedConnection
        Publisher security mode. Default value is $true.
#>
function Register-DistributorPublisher
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlMajorVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PublisherName,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $ServerConnection,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DistributionDBName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $UseTrustedConnection
    )

    Write-Verbose -Message (
        $script:localizedData.CreateDistributorPublisher -f $PublisherName, $ServerConnection.ServerInstance
    )

    $distributorPublisher = New-DistributionPublisher `
        -SqlMajorVersion $SqlMajorVersion `
        -PublisherName $PublisherName `
        -ServerConnection $ServerConnection

    $distributorPublisher.DistributionDatabase = $DistributionDBName
    $distributorPublisher.WorkingDirectory = $WorkingDirectory
    $distributorPublisher.PublisherSecurity.WindowsAuthentication = $UseTrustedConnection

    try
    {
        $distributorPublisher.Create()
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedInFunction -f 'Register-DistributorPublisher'

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Returns a reference to the ConnectionInfo assembly.

    .DESCRIPTION
        Returns a reference to the ConnectionInfo assembly.

    .PARAMETER SqlMajorVersion
        Specifies the major version of the SQL Server instance, e.g. '14'.

    .OUTPUTS
        [System.Reflection.Assembly]

        Returns a reference to the ConnectionInfo assembly.

    .EXAMPLE
        Get-ConnectionInfoAssembly -SqlMajorVersion '14'

    .NOTES
        This should normally work using Import-Module and New-Object instead of
        using the method [System.Reflection.Assembly]::Load(). But due to a
        missing assembly in the module SqlServer ('Microsoft.SqlServer.Rmo') we
        cannot use this:

        Import-Module SqlServer
        $connectionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Common.ServerConnection' -ArgumentList @('testclu01a\SQL2014')
        # Missing assembly 'Microsoft.SqlServer.Rmo' in module SqlServer prevents this call from working.
        $replication = New-Object -TypeName 'Microsoft.SqlServer.Replication.ReplicationServer' -ArgumentList @($connectionInfo)
#>
function Get-ConnectionInfoAssembly
{
    [CmdletBinding()]
    [OutputType([System.Reflection.Assembly])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlMajorVersion
    )

    $connectionInfo = Import-Assembly -Name "Microsoft.SqlServer.ConnectionInfo, Version=$SqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

    return $connectionInfo
}

<#
    .SYNOPSIS
        Returns a reference to the RMO assembly.

    .DESCRIPTION
        Returns a reference to the RMO assembly.

    .PARAMETER SqlMajorVersion
        Specifies the major version of the SQL Server instance, e.g. '14'.

    .OUTPUTS
        [System.Reflection.Assembly]

        Returns a reference to the RMO assembly.

    .EXAMPLE
        Get-RmoAssembly -SqlMajorVersion '14'

    .NOTES
        This should normally work using Import-Module and New-Object instead of
        using the method [System.Reflection.Assembly]::Load(). But due to a
        missing assembly in the module SqlServer ('Microsoft.SqlServer.Rmo') we
        cannot use this:

        Import-Module SqlServer
        $connectionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Common.ServerConnection' -ArgumentList @('testclu01a\SQL2014')
        # Missing assembly 'Microsoft.SqlServer.Rmo' in module SqlServer prevents this call from working.
        # Tracked in issue https://github.com/microsoft/sqlmanagementobjects/issues/59.
        $replication = New-Object -TypeName 'Microsoft.SqlServer.Replication.ReplicationServer' -ArgumentList @($connectionInfo)
#>
function Get-RmoAssembly
{
    [CmdletBinding()]
    [OutputType([System.Reflection.Assembly])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlMajorVersion
    )

    $rmo = Import-Assembly -Name "Microsoft.SqlServer.Rmo, Version=$SqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

    return $rmo
}

<#
    .SYNOPSIS
        Returns the service name to connect to.

    .PARAMETER InstanceName
        Specifies the instance name.
#>
function Get-SqlLocalServerName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        return Get-ComputerName
    }
    else
    {
        return "$(Get-ComputerName)\$InstanceName"
    }
}
