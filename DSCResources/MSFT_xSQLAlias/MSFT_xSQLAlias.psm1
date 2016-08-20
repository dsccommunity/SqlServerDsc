#
# xSQLAlias: DSC resource to configure Client Aliases part of xSQLServer
#

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName
    )

    Write-Verbose -Message 'Get-TargetResource'
    
    $returnValue = @{
        Name = [System.String]
        Protocol = [System.String]
        ServerName = [System.String]
        TCPPort = [System.Int32]
        PipeName = [System.String]
        Ensure = [System.String]
    }

    if ($null -ne (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -ErrorAction SilentlyContinue))
    {
        $itemValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -ErrorAction SilentlyContinue
        
        $returnValue.Name = $Name
        $itemConfig = $itemValue."$Name" -split ','
        if ($itemConfig[0] -eq 'DBMSSOCN')
        {
            $returnValue.Protocol = 'TCP'
            $returnValue.ServerName = $itemConfig[1]
            $returnValue.TCPPort = $itemConfig[2]
        }
        else
        {
            $returnValue.Protocol = 'NP'
            $returnValue.PipeName = $itemConfig[1]
        }

    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [ValidateSet("TCP","NP")]
        [System.String]
        $Protocol,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [System.Int32]
        $TCPPort,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Write-Verbose -Message 'Set-TargetResource'

    $itemValue = [System.String]
    
    if ($Protocol -eq 'NP')
    {
        $itemValue = "DBNMPNTW,\\$ServerName\PIPE\sql\query"
    }

    if ($Protocol -eq 'TCP')
    {
        $itemValue = "DBMSSOCN,$ServerName,$TCPPort"
    }

    # Logic based on ensure value Present
    if ($Ensure -eq 'Present')
    {
        Write-Debug -Message 'Check if value requires changing'

        $currentValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $currentValue -and $itemValue -ne $currentValue)
        {
            if ($PSCmdlet.ShouldProcess($Name,"Changing the client alias (64-bit)"))
            {
                Write-Debug -Message 'Set-ItemProperty'
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -Value $itemValue
            }
        }
        elseif ($null -eq $currentValue)
        {
            if ($PSCmdlet.ShouldProcess($Name,"Create client alias (64-bit)"))
            {
                if (!(Test-Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'))
                {
                    Write-Debug -Message 'New-Item'
                    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' | Out-Null
                }

                Write-Debug -Message 'New-ItemProperty'
                New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -Value $itemValue | Out-Null
            }
        }

        Write-Debug -Message 'Check OSArchitecture'
        # If this is a 64 bit machine also update Wow6432Node
        if ((Get-Wmiobject -Class win32_OperatingSystem).OSArchitecture -eq '64-bit')
        {
            Write-Debug -Message 'Is 64Bit'
            Write-Debug -Message 'Check if value requires changing'
            $currentValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $currentValue -and $itemValue -ne $currentValue)
            {
                if ($PSCmdlet.ShouldProcess($Name,"Changing the client alias (32-bit)"))
                {
                    Write-Debug -Message 'Set-ItemProperty'
                    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -Value $itemValue
                }
            }
            elseif ($null -eq $currentValue)
            {
                if ($PSCmdlet.ShouldProcess($Name,"Create client alias (32-bit)"))
                {
                    if (!(Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'))
                    {
                        Write-Debug -Message 'New-Item'
                        New-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' | Out-Null
                    }

                    Write-Debug -Message 'New-ItemProperty'
                    New-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -Value $itemValue
                }
            }
        }
    }

    # Logic based on ensure value Absent
    if ($Ensure -eq 'Absent')
    {
        # If the base path doesn't exist then we don't need to do anything
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo')
        {
            
            if ($PSCmdlet.ShouldProcess($Name,"Remove the client alias (64-bit)"))
            {
                Write-Debug -Message 'Remove-ItemProperty'
                Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name
            }
            
            Write-Debug -Message 'Check OSArchitecture'

            # If this is a 64 bit machine also update Wow6432Node
            if ((Get-Wmiobject -Class win32_OperatingSystem).OSArchitecture -eq '64-bit' -and (Test-Path -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'))
            {
                if ($PSCmdlet.ShouldProcess($Name,"Remove the client alias (34-bit)"))
                {
                    Write-Debug -Message 'Remove-ItemProperty Wow6432Node'
                    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name
                }
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [ValidateSet("TCP","NP")]
        [System.String]
        $Protocol,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [System.Int32]
        $TCPPort,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Write-Debug -Message 'Test-TargetResource'

    $result = [System.Boolean] $true

    if (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo')
    {
        Write-Debug -Message 'Alias registry container exists'
        if ($null -ne (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -ErrorAction SilentlyContinue))
        {
            Write-Debug -Message 'Existing alias found'
            if ($Ensure -eq 'Present')
            {
                $itemValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -ErrorAction SilentlyContinue
                
                $itemConfig = $itemValue."$Name" -split ','

                if ($Protocol -eq 'NP')
                {
                    Write-Debug -Message 'Named Pipes'

                    if ($itemConfig[0] -ne 'DBNMPNTW')
                    {
                        $result = $false
                    }

                    if ($itemConfig[1] -ne "\\$ServerName\PIPE\sql\query")
                    {
                        $result = $false
                    }
                }

                if ($Protocol -eq 'TCP')
                {
                    Write-Debug -Message 'TCP'
                    if ($itemConfig[0] -ne 'DBMSSOCN')
                    {
                        $result = $false
                    }

                    if ($itemConfig[1] -ne $ServerName)
                    {
                        $result = $false
                    }

                    if ($itemConfig[2] -ne $TCPPort)
                    {
                        $result = $false
                    }
                }

                # If this is a 64 bit machine also check Wow6432Node
                if ((Get-Wmiobject -Class win32_OperatingSystem).OSArchitecture -eq '64-bit')
                {
                    Write-Debug -Message 'Wow6432Node'
                    if ($null -ne (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name -ErrorAction SilentlyContinue))
                    {
                        Write-Debug -Message 'Existing alias found'
                        $itemValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' -Name $Name  -ErrorAction SilentlyContinue

                        $itemConfig = $itemValue."$Name" -split ','

                        if ($Protocol -eq 'NP')
                        {
                            Write-Debug -Message 'Named Pipes'

                            if ($itemConfig[0] -ne 'DBNMPNTW')
                            {
                                $result = $false
                            }

                            if ($itemConfig[1] -ne "\\$ServerName\PIPE\sql\query")
                            {
                                $result = $false
                            }
                        }

                        if ($Protocol -eq 'TCP')
                        {
                            Write-Debug -Message 'TCP'

                            if ($itemConfig[0] -ne 'DBMSSOCN')
                            {
                                $result = $false
                            }

                            if ($itemConfig[1] -ne $ServerName)
                            {
                                $result = $false
                            }
                            
                            if ($itemConfig[2] -ne $TCPPort)
                            {
                                $result = $false
                            }
                        }
                    }
                    else
                    {
                        # Wow6432Node
                        $result = $false
                    }
                }
            }
            else
            {
                # Existing alias not found
                $result = $false
            }
        }
        else
        {
            # Registry container doesn't exist
            if ($Ensure -eq 'Present')
            {
                $result = $false
            }
            else
            {
                $result = $true
            }
        }
    }
    else
    {
        # Alias not present
        if ($Ensure -eq 'Present')
        {
            $result = $false
        }
        else
        {
            $result = $true
        }
    }

    Write-Debug -Message "Test-TargetResource Result: $result"
    
    return $result
}


Export-ModuleMember -Function *-TargetResource
