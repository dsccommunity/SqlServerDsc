$ErrorActionPreference = "Stop"

$script:currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -ErrorAction Stop

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName = "DEFAULT",

        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1,15)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup
    )

    try {
        $listner = Get-SQLAlwaysOnAvailabilityGroupListner -Name $Name -AvailabilityGroup $AvailabilityGroup -NodeName $NodeName -InstanceName $InstanceName
        
        if( $null -ne $listner ) {
            New-VerboseMessage -Message "Listner $Name already exist"

            $ensure = "Present"
            
            $port = [uint16]( $listner | Select-Object -ExpandProperty PortNumber )

            $presentIpAddress = $listner.AvailabilityGroupListenerIPAddresses

            $dhcp = [bool]( $presentIpAddress | Select-Object -first 1 IsDHCP )

            $ipAddress = @()
            foreach( $currentIpAddress in $presentIpAddress ) {
                $ipAddress += "$($currentIpAddress.IPAddress)/$($currentIpAddress.SubnetMask)"
            } 
        } else {
            New-VerboseMessage -Message "Listner $Name does not exist"

            $ensure = "Absent"
            $port = 0
            $dhcp = $false
            $ipAddress = $null
        }
    } catch {
        throw New-TerminatingError -ErrorType AvailabilityGroupListnerNotFound -FormatArgs @($Name) -ErrorCategory ObjectNotFound -InnerException $_.Exception
    }

    $returnValue = @{
        InstanceName = [System.String] $InstanceName
        NodeName = [System.String] $NodeName
        Name = [System.String] $Name
        Ensure = [System.String] $ensure
        AvailabilityGroup = [System.String] $AvailabilityGroup
        IpAddress = [System.String[]] $ipAddress
        Port = [System.UInt16] $port
        DHCP = [System.Boolean] $dhcp
    }

    return $returnValue
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName = "DEFAULT",

        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1,15)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [System.String[]]
        $IpAddress,

        [System.UInt16]
        $Port,

        [System.Boolean]
        $DHCP
    )
   
    $parameters = @{
        InstanceName = [System.String] $InstanceName
        NodeName = [System.String] $NodeName
        Name = [System.String] $Name
        AvailabilityGroup = [System.String] $AvailabilityGroup
    }
    
    $listnerState = Get-TargetResource @parameters 
    if( $null -ne $listnerState ) {
        if( $Ensure -ne "" -and $listnerState.Ensure -ne $Ensure ) {
            $InstanceName = Get-SQLPSInstanceName -InstanceName $InstanceName
            
            if( $Ensure -eq "Present") {
                if( ( $PSCmdlet.ShouldProcess( $Name, "Create listner on $AvailabilityGroup" ) ) ) {
                    $newListnerParams = @{
                        Name = $Name
                        Path = "SQLSERVER:\SQL\$NodeName\$InstanceName\AvailabilityGroups\$AvailabilityGroup"
                    }

                    if( $Port ) {
                        New-VerboseMessage -Message "Listner port set to $Port"
                        $newListnerParams += @{
                            Port = $Port
                        }
                    }

                    if( $DHCP -and $IpAddress.Count -gt 0 ) {
                        New-VerboseMessage -Message "Listner set to DHCP with subnet $IpAddress"
                        $newListnerParams += @{
                            DhcpSubnet = [string]$IpAddress
                        }
                    } elseif ( -not $DHCP -and $IpAddress.Count -gt 0 ) {
                        New-VerboseMessage -Message "Listner set to static IP-address(es); $($IpAddress -join ', ')"
                        $newListnerParams += @{
                            StaticIp = $IpAddress
                        }
                    } else {
                        New-VerboseMessage -Message "Listner using DHCP with server default subnet"
                    }
                                        
                    New-SqlAvailabilityGroupListener @newListnerParams -Verbose:$False | Out-Null   # Suppressing Verbose because it prints the entire T-SQL statement otherwise
                }
            } else {
                if( ( $PSCmdlet.ShouldProcess( $Name, "Remove listner from $AvailabilityGroup" ) ) ) {
                    Remove-Item "SQLSERVER:\SQL\$NodeName\$InstanceName\AvailabilityGroups\$AvailabilityGroup\AvailabilityGroupListeners\$Name"
                }
            }
        } else {
            if( $Ensure -ne "" ) { New-VerboseMessage -Message "State is already $Ensure" }
            
            if( $listnerState.Ensure -eq "Present") {
                if( -not $DHCP -and $listnerState.IpAddress.Count -lt $IpAddress.Count ) { # Only able to add a new IP-address, not change existing ones.
                    New-VerboseMessage -Message "Found at least one new IP-address."
                    $ipAddressEqual = $False
                } else {
                    # No new IP-address
                    if( $null -eq $IpAddress -or -not ( Compare-Object -ReferenceObject $IpAddress -DifferenceObject $listnerState.IpAddress ) ) { 
                       $ipAddressEqual = $True
                    } else {
                        throw New-TerminatingError -ErrorType AvailabilityGroupListnerIPChangeError -FormatArgs @($($IpAddress -join ', '),$($listnerState.IpAddress -join ', ')) -ErrorCategory InvalidOperation
                    }
                }
                
                if( $listnerState.Port -ne $Port -or -not $ipAddressEqual ) {
                    New-VerboseMessage -Message "Listner differ in configuration."

                    if( $listnerState.Port -ne $Port ) {
                        if( ( $PSCmdlet.ShouldProcess( $Name, "Changing port configuration" ) ) ) {
                            $InstanceName = Get-SQLPSInstanceName -InstanceName $InstanceName
                            
                            $setListnerParams = @{
                                Path = "SQLSERVER:\SQL\$NodeName\$InstanceName\AvailabilityGroups\$AvailabilityGroup\AvailabilityGroupListeners\$Name"
                                Port = $Port
                            }

                            Set-SqlAvailabilityGroupListener @setListnerParams -Verbose:$False | Out-Null # Suppressing Verbose because it prints the entire T-SQL statement otherwise
                        }
                    }

                    if( -not $ipAddressEqual ) {
                        if( ( $PSCmdlet.ShouldProcess( $Name, "Adding IP-address(es)" ) ) ) {
                            $InstanceName = Get-SQLPSInstanceName -InstanceName $InstanceName
                            
                            $newIpAddress = @()
                            
                            foreach( $currentIpAddress in $IpAddress ) {
                                if( -not $listnerState.IpAddress -contains $currentIpAddress ) {
                                    $newIpAddress += $currentIpAddress
                                }
                            }
                            
                            $setListnerParams = @{
                                Path = "SQLSERVER:\SQL\$NodeName\$InstanceName\AvailabilityGroups\$AvailabilityGroup\AvailabilityGroupListeners\$Name"
                                StaticIp = $newIpAddress
                            }

                            Add-SqlAvailabilityGroupListenerStaticIp @setListnerParams -Verbose:$False | Out-Null # Suppressing Verbose because it prints the entire T-SQL statement otherwise
                        }
                    }

                } else {
                    New-VerboseMessage -Message "Listner configuration is already correct."
                }
            } else {
                throw New-TerminatingError -ErrorType AvailabilityGroupListnerNotFound -ErrorCategory ObjectNotFound
            }
        }
    } else {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -ErrorCategory InvalidResult
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName = "DEFAULT",

        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1,15)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [System.String[]]
        $IpAddress,

        [System.UInt16]
        $Port,

        [System.Boolean]
        $DHCP
    )

    $parameters = @{
        InstanceName = [System.String] $InstanceName
        NodeName = [System.String] $NodeName
        Name = [System.String] $Name
        AvailabilityGroup = [System.String] $AvailabilityGroup
    }
    
    New-VerboseMessage -Message "Testing state of listner $Name"
    
    $listnerState = Get-TargetResource @parameters 
    if( $null -ne $listnerState ) {
        if( $null -eq $IpAddress -or ($null -ne $listnerState.IpAddress -and -not ( Compare-Object -ReferenceObject $IpAddress -DifferenceObject $listnerState.IpAddress ) ) ) { 
            $ipAddressEqual = $true
        } else {
            $ipAddressEqual = $false
        }
        
        [System.Boolean] $result = $false
        if( ( $Ensure -eq "" -or ( $Ensure -ne "" -and $listnerState.Ensure -eq $Ensure) ) -and ($Port -eq "" -or $listnerState.Port -eq $Port) -and $ipAddressEqual ) {
            $result = $true
        }
    } else {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -ErrorCategory InvalidResult
    }

    return $result
}

function Get-SQLAlwaysOnAvailabilityGroupListner
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
        $NodeName 
    )

    $instance = Get-SQLPSInstance -InstanceName $InstanceName -NodeName $NodeName
    $Path = "$($instance.PSPath)\AvailabilityGroups\$AvailabilityGroup\AvailabilityGroupListeners"

    Write-Debug "Connecting to $Path as $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    
    [string[]] $presentListner = Get-ChildItem $Path
    if( $presentListner.Count -ne 0 -and $presentListner.Contains("[$Name]") ) {
        Write-Debug "Connecting to availability group $Name as $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
        $listner = Get-Item "$Path\$Name"
    } else {
        $listner = $null
    }    

    return $listner
}

Export-ModuleMember -Function *-TargetResource
