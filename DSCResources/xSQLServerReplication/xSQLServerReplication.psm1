Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $IsDistributor,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $IsPublisher,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [System.String]
        $DistributionDBName,

        [System.String]
        $PublisherDistributor,

        [System.String]
        $PublisherWorkingDirectory,

        [System.Boolean]
        $PublisherTrustedConnection,

        [System.Boolean]
        $UninstallWithForce
    )

    if(Test-TargetResource $InstanceName $Ensure $IsDistributor $IsPublisher $AdminLinkCredentials $DistributionDBName $PublisherDistributor $PublisherWorkingDirectory $PublisherTrustedConnection $UninstallWithForce)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }
    
    $returnValue = @{
        InstanceName = $InstanceName
        Ensure = $Ensure
        IsDistributor = $IsDistributor
        IsPublisher = $IsPublisher
        AdminLinkCredentials = $AdminLinkCredentials
        DistributionDBName = $DistributionDBName
        PublisherDistributor = $PublisherDistributor
        PublisherWorkingDirectory = $PublisherWorkingDirectory
        PublisherTrustedConnection = $PublisherTrustedConnection
        UninstallWithForce = $UninstallWithForce
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
        [System.Boolean]
        $IsDistributor,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $IsPublisher,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [System.String]
        $DistributionDBName = 'distribution',

        [System.String]
        $PublisherDistributor,

        [System.String]
        $PublisherWorkingDirectory,

        [System.Boolean]
        $PublisherTrustedConnection,

        [System.Boolean]
        $UninstallWithForce
    )

    $sqlMajorVersion = Get-SqlServerMajorVersion $InstanceName

    try
    {
        $dom = [AppDomain]::CreateDomain("xSQLServerReplication_$sqlMajorVersion")
        $connInfo = $dom.Load("Microsoft.SqlServer.ConnectionInfo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
        $rmo = $dom.Load("Microsoft.SqlServer.Rmo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")

        if($InstanceName -eq "MSSQLSERVER")
        {
            $connectSQL = $env:COMPUTERNAME
        }
        else
        {
            $connectSQL = "$($env:COMPUTERNAME)\$InstanceName"
        }

        $serverConnection = New-Object $connInfo.GetType('Microsoft.SqlServer.Management.Common.ServerConnection') $connectSQL
        $replicationServer = New-Object $rmo.GetType('Microsoft.SqlServer.Replication.ReplicationServer') $serverConnection

        if($Ensure -eq 'Present')
        {
            Write-Verbose "Distribution will be configured ..."
            if($IsDistributor -eq $true -and $replicationServer.IsDistributor -eq $false)
            {
                Write-Verbose "Distributor role will be configured ..."
                $distributionDB = New-Object $rmo.GetType('Microsoft.SqlServer.Replication.DistributionDatabase') $DistributionDBName, $serverConnection
                $replicationServer.InstallDistributor($AdminLinkCredentials.Password, $distributionDB)
            }

            if($IsPublisher -eq $true -and $replicationServer.IsPublisher -eq $false)
            {
                Write-Verbose "Publisher role will be configured ..."
                if($PublisherDistributor)
                {
                    $distributorConnection = New-Object $connInfo.GetType('Microsoft.SqlServer.Management.Common.ServerConnection') $PublisherDistributor
                }
                else
                {
                    $distributorConnection = $serverConnection
                }

                $publisher = New-object $rmo.GetType('Microsoft.SqlServer.Replication.DistributionPublisher') $connectSQL, $distributorConnection
                $publisher.DistributionDatabase = $DistributionDBName
                $publisher.WorkingDirectory = $PublisherWorkingDirectory
                $publisher.PublisherSecurity.WindowsAuthentication = $PublisherTrustedConnection
                $publisher.Create()
            }
        }
        else #'Absent'
        {
            if($replicationServer.IsDistributor -eq $true -or $replicationServer.IsPublisher -eq $true)
            {
                Write-Verbose "Distribution will be removed ..."
                $replicationServer.UninstallDistributor($UninstallWithForce)
            }
            else
            {
                Write-Verbose "Distribution is not configured on this instance."
            }
        }
    }
    finally
    {
        [AppDomain]::Unload($dom)
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
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $IsDistributor,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $IsPublisher,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminLinkCredentials,

        [System.String]
        $DistributionDBName,

        [System.String]
        $PublisherDistributor,

        [System.String]
        $PublisherWorkingDirectory,

        [System.Boolean]
        $PublisherTrustedConnection,

        [System.Boolean]
        $UninstallWithForce
    )

    $sqlMajorVersion = Get-SqlServerMajorVersion $InstanceName
    $result = $false

    try
    {
        $dom = [AppDomain]::CreateDomain("xSQLServerReplication_$sqlMajorVersion")
        $connInfo = $dom.Load("Microsoft.SqlServer.ConnectionInfo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
        $rmo = $dom.Load("Microsoft.SqlServer.Rmo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")

        if($InstanceName -eq "MSSQLSERVER")
        {
            $connectSQL = $env:COMPUTERNAME
        }
        else
        {
            $connectSQL = "$($env:COMPUTERNAME)\$InstanceName"
        }

        $serverConnection = New-Object $connInfo.GetType('Microsoft.SqlServer.Management.Common.ServerConnection') $connectSQL
        $replicationServer = New-Object $rmo.GetType('Microsoft.SqlServer.Replication.ReplicationServer') $serverConnection

        if($Ensure = 'Present')
        {
            if($replicationServer.IsDistributor -eq $IsDistributor -and $replicationServer.IsPublisher -eq $IsPublisher)
            {
                $result = $true
            }

        }
        else #Absent
        {
            if($replicationServer.IsDistributor -eq $false -and $replicationServer.IsPublisher -eq $false)
            {
                $result = $true
            }
        }
    }
    finally
    {
        [AppDomain]::Unload($dom)
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
