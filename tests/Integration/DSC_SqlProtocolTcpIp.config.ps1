#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $availableNic = Get-NetIPAddress -AddressFamily 'IPv4'

    $availableNicString = $availableNic |
        Format-Table -Property @('IPAddress', 'InterfaceAlias', 'AddressFamily') |
        Out-String

    Write-Verbose -Message ("Available IPv4 NICs on build worker:`n{0}" -f $availableNicString) -Verbose

    $currentIp4Address = $availableNic |
        Where-Object -Property 'InterfaceAlias' -Like 'Ethernet*' |
        Select-Object -First 1 -ExpandProperty 'IPAddress'

    # Pass to Out-String to handle $null value.
    Write-Verbose -Message ('Tests will be using IP address: {0}' -f ($currentIp4Address | Out-String)) -Verbose

    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'

                UserName        = "$env:COMPUTERNAME\SqlInstall"
                Password        = 'P@ssw0rd1'

                IpAddress       = $currentIp4Address

                InstanceName    = 'DSCSQLTEST'

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Disables listen on all IP addresses and then configures IP address group
        'IP1' with the first IP address assigned to the node (first IP address
        which has DHCP as the prefix origin).
#>
Configuration DSC_SqlProtocolTcpIp_ListenOnSpecificIpAddress_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlProtocol 'DisableListenAllIPAddresses'
        {
            InstanceName           = $Node.InstanceName
            ProtocolName           = 'TcpIp'
            Enabled                = $true
            ListenOnAllIpAddresses = $false
            SuppressRestart        = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlProtocolTcpIP 'Integration_Test'
        {
            InstanceName           = $Node.InstanceName
            IpAddressGroup         = 'IP1'
            Enabled                 = $true
            IpAddress              = $Node.IpAddress
            SuppressRestart        = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
