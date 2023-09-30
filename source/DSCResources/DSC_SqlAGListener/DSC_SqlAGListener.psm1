$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the Availability Group listener.

    .PARAMETER InstanceName
        The SQL Server instance name of the primary replica. Default value is 'MSSQLSERVER'.

    .PARAMETER ServerName
        The host name or FQDN of the primary replica.

    .PARAMETER Name
        The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).

    .PARAMETER AvailabilityGroup
        The name of the availability group to which the availability group listener is or will be connected.
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [Parameter()]
        [System.Boolean]
        $ProcessOnlyOnActiveNode
    )

    Write-Verbose -Message (
        $script:localizedData.GetAvailabilityGroupListener -f $Name, $AvailabilityGroup, $InstanceName
    )

    try
    {
        $serverObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

        # Is this node actively hosting the SQL instance?
        $isActiveNode = Test-ActiveNode -ServerObject $serverObject

        $availabilityGroupListener = Get-SQLAlwaysOnAvailabilityGroupListener -Name $Name -AvailabilityGroup $AvailabilityGroup -ServerName $ServerName -InstanceName $InstanceName

        if ($null -ne $availabilityGroupListener)
        {
            Write-Verbose -Message (
                $script:localizedData.AvailabilityGroupListenerIsPresent -f $Name
            )

            $ensure = 'Present'
            $port = [uint16]( $availabilityGroupListener | Select-Object -ExpandProperty PortNumber )

            $presentIpAddress = $availabilityGroupListener.AvailabilityGroupListenerIPAddresses
            $dhcp = [bool]( $presentIpAddress | Select-Object -First 1 -ExpandProperty IsDHCP )

            $ipAddress = @()
            foreach ($currentIpAddress in $presentIpAddress)
            {
                if ($currentIpAddress.SubnetMask)
                {
                    $ipAddress += "$($currentIpAddress.IPAddress)/$($currentIpAddress.SubnetMask)"
                }
                else
                {
                    $ipAddress += "$($currentIpAddress.IPAddress)"
                }
            }
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.AvailabilityGroupListenerIsNotPresent -f $Name
            )

            $ensure = 'Absent'
            $port = 0
            $dhcp = $false
            $ipAddress = $null
        }
    }
    catch
    {
        $errorMessage = $script:localizedData.AvailabilityGroupListenerNotFound -f $Name, $AvailabilityGroup
        New-ObjectNotFoundException -Message $errorMessage -ErrorRecord $_
    }

    return @{
        InstanceName            = [System.String] $InstanceName
        ServerName              = [System.String] $ServerName
        Name                    = [System.String] $Name
        Ensure                  = [System.String] $ensure
        AvailabilityGroup       = [System.String] $AvailabilityGroup
        IpAddress               = [System.String[]] $ipAddress
        Port                    = [System.UInt16] $port
        DHCP                    = [System.Boolean] $dhcp
        ProcessOnlyOnActiveNode = [System.Boolean] $ProcessOnlyOnActiveNode
        IsActiveNode            = [System.Boolean] $isActiveNode
    }
}

<#
    .SYNOPSIS
        Creates the Availability Group listener.

    .PARAMETER InstanceName
        The SQL Server instance name of the primary replica. Default value is 'MSSQLSERVER'.

    .PARAMETER ServerName
        The host name or FQDN of the primary replica.

    .PARAMETER Name
        The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).

    .PARAMETER Ensure
        If the availability group listener should be present or absent.

    .PARAMETER AvailabilityGroup
        The name of the availability group to which the availability group listener is or will be connected.

    .PARAMETER IpAddress
        The IP address used for the availability group listener, in the format 192.168.10.45/255.255.252.0. If using DHCP, set to the first IP-address of the DHCP subnet, in the format 192.168.8.1/255.255.252.0. Must be valid in the cluster-allowed IP range.

    .PARAMETER Port
        The port used for the availability group listener.

    .PARAMETER DHCP
        If DHCP should be used for the availability group listener instead of static IP address.

    .PARAMETER ProcessOnlyOnActiveNode
        Specifies that the resource will only determine if a change is needed if the target node is the active host of the SQL Server instance.
        Not used in Set-TargetResource.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [Parameter()]
        [System.String[]]
        $IpAddress,

        [Parameter()]
        [System.UInt16]
        $Port,

        [Parameter()]
        [System.Boolean]
        $DHCP,

        [Parameter()]
        [System.Boolean]
        $ProcessOnlyOnActiveNode
    )

    $parameters = @{
        InstanceName      = [System.String] $InstanceName
        ServerName        = [System.String] $ServerName
        Name              = [System.String] $Name
        AvailabilityGroup = [System.String] $AvailabilityGroup
    }

    $availabilityGroupListenerState = Get-TargetResource @parameters

    if ($Ensure -ne '' -and $availabilityGroupListenerState.Ensure -ne $Ensure)
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message (
                $script:localizedData.CreateAvailabilityGroupListener -f $Name, $AvailabilityGroup, $InstanceName
            )

            $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

            $availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
            if ($availabilityGroupObject)
            {
                $newListenerParams = @{
                    Name        = $Name
                    InputObject = $availabilityGroupObject
                }

                if ($PSBoundParameters.ContainsKey('Port'))
                {
                    Write-Verbose -Message (
                        $script:localizedData.SetAvailabilityGroupListenerPort -f $Port
                    )

                    $newListenerParams += @{
                        Port = $Port
                    }
                }

                if ($PSBoundParameters.ContainsKey('DHCP') -and $DHCP -and $IpAddress.Count -gt 0)
                {
                    Write-Verbose -Message (
                        $script:localizedData.SetAvailabilityGroupListenerDhcp -f $IpAddress
                    )

                    $newListenerParams += @{
                        DhcpSubnet = [System.String] $IpAddress
                    }
                }
                elseif ($PSBoundParameters.ContainsKey('IpAddress') -and -not $DHCP -and $IpAddress.Count -gt 0)
                {
                    Write-Verbose -Message (
                        $script:localizedData.SetAvailabilityGroupListenerStaticIpAddress -f ($IpAddress -join ', ')
                    )

                    $newListenerParams += @{
                        StaticIp = $IpAddress
                    }
                }
                else
                {
                    Write-Verbose -Message $script:localizedData.SetAvailabilityGroupListenerDhcpDefaultSubnet
                }

                New-SqlAvailabilityGroupListener @newListenerParams -ErrorAction Stop | Out-Null
            }
            else
            {
                $errorMessage = $script:localizedData.AvailabilityGroupNotFound -f $AvailabilityGroup, $InstanceName
                New-ObjectNotFoundException -Message $errorMessage
            }
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.DropAvailabilityGroupListener -f $Name, $AvailabilityGroup, $InstanceName
            )

            $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

            $availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
            if ($availabilityGroupObject)
            {
                $availabilityGroupListenerObject = $availabilityGroupObject.AvailabilityGroupListeners[$Name]
                if ($availabilityGroupListenerObject)
                {
                    $availabilityGroupListenerObject.Drop()
                }
                else
                {
                    $errorMessage = $script:localizedData.AvailabilityGroupListenerNotFound -f $Name, $AvailabilityGroup
                    New-ObjectNotFoundException -Message $errorMessage
                }
            }
            else
            {
                $errorMessage = $script:localizedData.AvailabilityGroupNotFound -f $AvailabilityGroup, $InstanceName
                New-ObjectNotFoundException -Message $errorMessage
            }
        }
    }
    else
    {
        if ($availabilityGroupListenerState.Ensure -eq 'Present')
        {
            Write-Verbose -Message (
                $script:localizedData.AvailabilityGroupListenerIsPresent -f $Name
            )

            if (-not $DHCP -and $availabilityGroupListenerState.IpAddress.Count -lt $IpAddress.Count) # Only able to add a new IP-address, not change existing ones.
            {
                Write-Verbose -Message $script:localizedData.FoundNewIpAddress

                $ipAddressEqual = $false
            }
            else
            {
                # No new IP-address
                if (-not $PSBoundParameters.ContainsKey('IpAddress') -or -not ( Compare-Object -ReferenceObject $IpAddress -DifferenceObject $availabilityGroupListenerState.IpAddress))
                {
                    $ipAddressEqual = $true
                }
                else
                {
                    $errorMessage = $script:localizedData.AvailabilityGroupListenerIPChangeError -f ($IpAddress -join ', '), ($availabilityGroupListenerState.IpAddress -join ', ')
                    New-InvalidOperationException -Message $errorMessage
                }
            }

            if ($PSBoundParameters.ContainsKey('DHCP') -and $availabilityGroupListenerState.DHCP -ne $DHCP)
            {
                $errorMessage = $script:localizedData.AvailabilityGroupListenerDHCPChangeError -f $DHCP, $availabilityGroupListenerState.DHCP
                New-InvalidOperationException -Message $errorMessage
            }

            $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

            $availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
            if ($availabilityGroupObject)
            {
                $availabilityGroupListenerObject = $availabilityGroupObject.AvailabilityGroupListeners[$Name]
                if ($availabilityGroupListenerObject)
                {
                    if (($PSBoundParameters.ContainsKey('Port') -and $availabilityGroupListenerState.Port -ne $Port) -or -not $ipAddressEqual)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.AvailabilityGroupListenerNotInDesiredState -f $Name, $AvailabilityGroup, $InstanceName
                        )

                        if ($PSBoundParameters.ContainsKey('Port') -and $availabilityGroupListenerState.Port -ne $Port)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.ChangingAvailabilityGroupListenerPort -f $Port
                            )

                            $setListenerParams = @{
                                InputObject = $availabilityGroupListenerObject
                                Port        = $Port
                            }

                            Set-SqlAvailabilityGroupListener @setListenerParams -ErrorAction Stop | Out-Null
                        }

                        if (-not $ipAddressEqual)
                        {
                            $newIpAddress = @()

                            foreach ($currentIpAddress in $IpAddress)
                            {
                                if (-not ( $availabilityGroupListenerState.IpAddress -contains $currentIpAddress))
                                {
                                    Write-Verbose -Message (
                                        $script:localizedData.AddingAvailabilityGroupListenerIpAddress -f $currentIpAddress
                                    )

                                    $newIpAddress += $currentIpAddress
                                }
                            }

                            $setListenerParams = @{
                                InputObject = $availabilityGroupListenerObject
                                StaticIp    = $newIpAddress
                            }

                            Add-SqlAvailabilityGroupListenerStaticIp @setListenerParams -ErrorAction Stop | Out-Null
                        }
                    }
                    else
                    {
                        Write-Verbose -Message (
                            $script:localizedData.AvailabilityGroupListenerInDesiredState -f $Name, $AvailabilityGroup, $InstanceName
                        )
                    }
                }
                else
                {
                    $errorMessage = $script:localizedData.AvailabilityGroupListenerNotFound -f $Name, $AvailabilityGroup
                    New-ObjectNotFoundException -Message $errorMessage
                }
            }
            else
            {
                $errorMessage = $script:localizedData.AvailabilityGroupNotFound -f $AvailabilityGroup, $InstanceName
                New-ObjectNotFoundException -Message $errorMessage
            }
        }
    }
}

<#
    .SYNOPSIS
        Tests if the the Availability Group listener is in desired state.

    .PARAMETER InstanceName
        The SQL Server instance name of the primary replica. Default value is 'MSSQLSERVER'.

    .PARAMETER ServerName
        The host name or FQDN of the primary replica.

    .PARAMETER Name
        The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).

    .PARAMETER Ensure
        If the availability group listener should be present or absent.

    .PARAMETER AvailabilityGroup
        The name of the availability group to which the availability group listener is or will be connected.

    .PARAMETER IpAddress
        The IP address used for the availability group listener, in the format 192.168.10.45/255.255.252.0. If using DHCP, set to the first IP-address of the DHCP subnet, in the format 192.168.8.1/255.255.252.0. Must be valid in the cluster-allowed IP range.

    .PARAMETER Port
        The port used for the availability group listener.

    .PARAMETER DHCP
        If DHCP should be used for the availability group listener instead of static IP address.

    .PARAMETER ProcessOnlyOnActiveNode
        Specifies that the resource will only determine if a change is needed if the target node is the active host of the SQL Server instance.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification = 'The command Connect-Sql is called when Get-TargetResource is called')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [Parameter()]
        [System.String[]]
        $IpAddress,

        [Parameter()]
        [System.UInt16]
        $Port,

        [Parameter()]
        [System.Boolean]
        $DHCP,

        [Parameter()]
        [System.Boolean]
        $ProcessOnlyOnActiveNode
    )

    $parameters = @{
        InstanceName      = [System.String] $InstanceName
        ServerName        = [System.String] $ServerName
        Name              = [System.String] $Name
        AvailabilityGroup = [System.String] $AvailabilityGroup
    }

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration -f $Name, $AvailabilityGroup, $InstanceName
    )

    $availabilityGroupListenerState = Get-TargetResource @parameters

    [System.Boolean] $result = $false

    <#
        If this is supposed to process only the active node, and this is not the
        active node, don't bother evaluating the test.
    #>
    if ($ProcessOnlyOnActiveNode -and -not $availabilityGroupListenerState.IsActiveNode)
    {
        # Use localization if the resource has been converted
        Write-Verbose -Message ('The node ''{0}'' is not actively hosting the instance ''{1}''. Exiting the test.' -f (Get-ComputerName), $InstanceName)

        $result = $true

        return $result
    }

    if ($availabilityGroupListenerState.Ensure -eq $Ensure)
    {
        $result = $true

        if ($Ensure -eq 'Present')
        {
            if ($PSBoundParameters.ContainsKey('Port') -and $availabilityGroupListenerState.Port -ne $Port)
            {
                $result = $false
            }

            if ($PSBoundParameters.ContainsKey('DHCP') -and $availabilityGroupListenerState.DHCP -ne $DHCP)
            {
                $result = $false
            }

            if ($PSBoundParameters.ContainsKey('IpAddress') -and $availabilityGroupListenerState.DHCP -eq $true)
            {
                $result = $false
            }

            # Compare-Object will return a value if the comparison is not equal.
            if ($PSBoundParameters.ContainsKey('IpAddress') -and (Compare-Object -ReferenceObject $IpAddress -DifferenceObject $availabilityGroupListenerState.IpAddress))
            {
                $result = $false
            }
        }
    }

    if ($result)
    {
        Write-Verbose -Message (
            $script:localizedData.AvailabilityGroupListenerInDesiredState -f $Name, $AvailabilityGroup, $InstanceName
        )
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.AvailabilityGroupListenerNotInDesiredState -f $Name, $AvailabilityGroup, $InstanceName
        )
    }

    return $result
}

<#
    .SYNOPSIS
        Returns the listener with the specified name for the specified availability group.

    .PARAMETER InstanceName
        The SQL Server instance name of the primary replica. Default value is 'MSSQLSERVER'.

    .PARAMETER ServerName
        The host name or FQDN of the primary replica.

    .PARAMETER Name
        The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).

    .PARAMETER AvailabilityGroup
        The name of the availability group to which the availability group listener is or will be connected.
#>
function Get-SQLAlwaysOnAvailabilityGroupListener
{
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName
    )

    Write-Debug -Message (
        $script:localizedData.DebugConnectingAvailabilityGroup -f $Name, [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    $availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
    if ($availabilityGroupObject)
    {
        $availabilityGroupListener = $availabilityGroupObject.AvailabilityGroupListeners[$Name]
    }
    else
    {
        $errorMessage = $script:localizedData.AvailabilityGroupNotFound -f $AvailabilityGroup, $InstanceName
        New-ObjectNotFoundException -Message $errorMessage
    }

    return $availabilityGroupListener
}
