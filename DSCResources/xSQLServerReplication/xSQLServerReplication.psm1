$dom = [AppDomain]::CreateDomain('xSQLServerReplication')

Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [parameter(Mandatory = $true)]
        [ValidateSet('Local', 'Remote')]
        [System.String]
        $DistributorMode,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory
    )

    $WorkingDirectory = ''
    $Ensure = 'Absent'

    $sqlMajorVersion = Get-SqlServerMajorVersion $InstanceName
    $connInfo = $dom.Load("Microsoft.SqlServer.ConnectionInfo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
    Write-Verbose "Loaded assembly: $($connInfo.FullName)"
    $rmo = $dom.Load("Microsoft.SqlServer.Rmo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
    Write-Verbose "Loaded assembly: $($rmo.FullName)"

    if($InstanceName -eq "MSSQLSERVER")
    {
        $localSqlName = $env:COMPUTERNAME
    }
    else
    {
        $localSqlName = "$($env:COMPUTERNAME)\$InstanceName"
    }

    $localConnection = New-Object $connInfo.GetType('Microsoft.SqlServer.Management.Common.ServerConnection') $localSqlName
    $localReplicationServer = New-Object $rmo.GetType('Microsoft.SqlServer.Replication.ReplicationServer') $localConnection

    if($localReplicationServer.IsDistributor -eq $true)
    {
        $Ensure = 'Present'
        $DistributorMode = 'Local'
    }
    elseif($localReplicationServer.IsPublisher -eq $true)
    {
        $Ensure = 'Present'
        $DistributorMode = 'Remote'
    }

    if($Ensure -eq 'Preset')
    {
        $DistributionDBName = $localReplicationServer.DistributionDatabase
        $RemoteDistributor = $localReplicationServer.DistributionServer
        $WorkingDirectory = $localReplicationServer.WorkingDirectory
    }
               
    $returnValue = @{
        InstanceName = $InstanceName
        Ensure = $Ensure
        DistributorMode = $DistributorMode
        DistributionDBName = $DistributionDBName
        RemoteDistributor = $RemoteDistributor
        WorkingDirectory = $WorkingDirectory
    }
    
    return $returnValue
}

Function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [ValidateSet('Local', 'Remote')]
        [System.String]
        $DistributorMode,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [System.String]
        $DistributionDBName = 'distribution',

        [System.String]
        $RemoteDistributor,

        [parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [System.Boolean]
        $UseTrustedConnection = $true,

        [System.Boolean]
        $UninstallWithForce = $true
    )

    if($DistributorMode -eq 'Remote' -and !$RemoteDistributor)
    {
        throw "RemoteDistributor parameter cannot be empty when DistributorMode = 'Remote'!"
    }

    $sqlMajorVersion = Get-SqlServerMajorVersion $InstanceName

    $connInfo = $dom.Load("Microsoft.SqlServer.ConnectionInfo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
    Write-Verbose "Loaded assembly: $($connInfo.FullName)"
    $rmo = $dom.Load("Microsoft.SqlServer.Rmo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
    Write-Verbose "Loaded assembly: $($rmo.FullName)"

    if($InstanceName -eq "MSSQLSERVER")
    {
        $localSqlName = $env:COMPUTERNAME
    }
    else
    {
        $localSqlName = "$($env:COMPUTERNAME)\$InstanceName"
    }

    $localConnection = New-Object $connInfo.GetType('Microsoft.SqlServer.Management.Common.ServerConnection') $localSqlName
    $localReplicationServer = New-Object $rmo.GetType('Microsoft.SqlServer.Replication.ReplicationServer') $localConnection

    if($Ensure -eq 'Present')
    {
        if($DistributorMode -eq 'Local' -and $localReplicationServer.IsDistributor -eq $false)
        {
            Write-Verbose "Local distribution will be configured ..."
            $distributionDB = New-Object $rmo.GetType('Microsoft.SqlServer.Replication.DistributionDatabase') $DistributionDBName, $localConnection
            $localReplicationServer.InstallDistributor($AdminLinkCredentials.Password, $distributionDB)

            $distributorPublisher = New-object $rmo.GetType('Microsoft.SqlServer.Replication.DistributionPublisher') $localSqlName, $localConnection
            $distributorPublisher.DistributionDatabase = $DistributionDBName
            $distributorPublisher.WorkingDirectory = $WorkingDirectory
            $distributorPublisher.PublisherSecurity.WindowsAuthentication = $UseTrustedConnection
            $distributorPublisher.Create()
        }
            
        if($DistributorMode -eq 'Remote' -and $localReplicationServer.IsPublisher -eq $false)
        {
            Write-Verbose "Remote distribution will be configured ..."

            $remoteConnection = New-Object $connInfo.GetType('Microsoft.SqlServer.Management.Common.ServerConnection') $RemoteDistributor

            $distributorPublisher = New-object $rmo.GetType('Microsoft.SqlServer.Replication.DistributionPublisher') $localSqlName, $remoteConnection
            $distributorPublisher.DistributionDatabase = $DistributionDBName
            $distributorPublisher.WorkingDirectory = $WorkingDirectory
            $distributorPublisher.PublisherSecurity.WindowsAuthentication = $UseTrustedConnection
            $distributorPublisher.Create()

            $localReplicationServer.InstallDistributor($RemoteDistributor, $AdminLinkCredentials.Password)
        }
    }
    else #'Absent'
    {
        if($localReplicationServer.IsDistributor -eq $true -or $localReplicationServer.IsPublisher -eq $true)
        {
            Write-Verbose "Distribution will be removed ..."
            $localReplicationServer.UninstallDistributor($UninstallWithForce)
        }
        else
        {
            Write-Verbose "Distribution is not configured on this instance."
        }
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [ValidateSet('Local', 'Remote')]
        [System.String]
        $DistributorMode,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [System.String]
        $DistributionDBName = 'distribution',

        [System.String]
        $RemoteDistributor,

        [parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [System.Boolean]
        $UseTrustedConnection = $true,

        [System.Boolean]
        $UninstallWithForce = $true
    )

    $result = $false
    $state = Get-TargetResource -InstanceName $InstanceName -DistributorMode $DistributorMode -AdminLinkCredentials $AdminLinkCredentials -WorkingDirectory $WorkingDirectory

    if($Ensure -eq 'Absent' -and $state.Ensure -eq 'Absent')
    {
        $result = $true
    }
    elseif($Ensure -eq 'Present' -and $state.Ensure -eq 'Present' -and $state.DistributorMode -eq $DistributorMode)
    {
        $result = $true
    }
          
    return $result
}

Function Get-SqlServerMajorVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $instanceId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").$InstanceName
    $sqlVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup").Version
    $sqlMajorVersion = $sqlVersion.Split(".")[0]
    if (!$sqlMajorVersion)
    {
        throw "Unable to detect version for sql server instance: $InstanceName!"
    }
    return $sqlMajorVersion
}

Export-ModuleMember -Function *-TargetResource
