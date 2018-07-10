<#
    .SYNOPSIS
        Ensure the correct module stubs are loaded.

    .PARAMETER SQLVersion
        The major version of the SQL instance.

    .PARAMETER ModuleName
        The name of the module to load the stubs for. Default is 'SqlServer'.
#>
function Import-SQLModuleStub
{
    [CmdletBinding(DefaultParameterSetName = 'Module')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [System.UInt32]
        $SQLVersion,

        [Parameter(ParameterSetName = 'Module')]
        [ValidateSet('SQLPS', 'SqlServer')]
        [System.String]
        $ModuleName = 'SqlServer'
    )

    # Translate the module names to their appropriate stub name
    $modulesAndStubs = @{
        SQLPS     = 'SQLPSStub'
        SqlServer = 'SqlServerStub'
    }

    # Determine which module to ensure is loaded based on the parameters passed
    if ( $PsCmdlet.ParameterSetName -eq 'Version' )
    {
        if ( $SQLVersion -le 12 )
        {
            $ModuleName = 'SQLPS'
        }
        elseif ( $SQLVersion -ge 13 )
        {
            $ModuleName = 'SqlServer'
        }
    }

    # Get the stub name
    $stubModuleName = $modulesAndStubs.$ModuleName

    # Ensure none of the other stub modules are loaded
    [System.Array] $otherStubModules = $modulesAndStubs.Values | Where-Object -FilterScript {
        $_ -ne $stubModuleName
    }

    if ( Get-Module -Name $otherStubModules )
    {
        Remove-Module -Name $otherStubModules
    }

    # If the desired module is not loaded, load it now
    if ( -not ( Get-Module -Name $stubModuleName ) )
    {
        # Build the path to the module stub
        $moduleStubPath = Join-Path -Path ( Join-Path -Path ( Join-Path -Path ( Split-Path -Path $PSScriptRoot -Parent ) -ChildPath Unit ) -ChildPath Stubs ) -ChildPath "$($stubModuleName).psm1"

        Import-Module -Name $moduleStubPath -Force -Global
    }
}

<#
    .SYNOPSIS
        Installs the PowerShell module 'LoopbackAdapter' from PowerShell Gallery
        and creates a new network loopback adapter.

    .PARAMETER AdapterName
        The name of the loopback adapter to create.
#>
function New-IntegrationLoopbackAdapter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AdapterName
    )

    # Ensure the loopback adapter module is downloaded
    $LoopbackAdapterModuleName = 'LoopbackAdapter'
    $LoopbackAdapterModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$LoopbackAdapterModuleName"

    # This is a helper function from DscResource.Tests\TestHelper.psm1.
    Install-ModuleFromPowerShellGallery `
        -ModuleName $LoopbackAdapterModuleName `
        -DestinationPath $LoopbackAdapterModulePath

    $LoopbackAdapterModule = Join-Path `
        -Path $LoopbackAdapterModulePath `
        -ChildPath "$($LoopbackAdapterModuleName).psm1"

    # Import the loopback adapter module
    Import-Module -Name $LoopbackAdapterModule -Force

    $loopbackAdapterParameters = @{
        Name = $AdapterName
    }

    try
    {
        # Does the loopback adapter already exist?
        $null = Get-LoopbackAdapter @loopbackAdapterParameters
    }
    catch
    {
        # The loopback Adapter does not exist so create it
        $loopbackAdapterParameters['Force'] = $true
        $loopbackAdapterParameters['ErrorAction'] = 'Stop'

        $null = New-LoopbackAdapter @loopbackAdapterParameters
    } # try
} # function New-IntegrationLoopbackAdapter

<#
    .SYNOPSIS
        Removes a new network loopback adapter.

    .PARAMETER AdapterName
        The name of the loopback adapter to remove.
#>
function Remove-IntegrationLoopbackAdapter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $AdapterName
    )

    $loopbackAdapterParameters = @{
        Name = $AdapterName
    }

    try
    {
        # Does the loopback adapter exist?
        $null = Get-LoopbackAdapter @loopbackAdapterParameters
    }
    catch
    {
        # Loopback Adapter does not exist - do nothing
        return
    }

    if ($env:APPVEYOR)
    {
        # Running in AppVeyor so force silent uninstall of LoopbackAdapter
        $forceUninstall = $true
    }
    else
    {
        $forceUninstall = $false
    }

    $loopbackAdapterParameters['Force'] = $forceUninstall

    # Remove Loopback Adapter
    Remove-LoopbackAdapter @loopbackAdapterParameters
} # function Remove-IntegrationLoopbackAdapter

<#
    .SYNOPSIS
        Returns the IP network address from an IPv4 address and prefix length.

    .PARAMETER IpAddress
        The IP address to look up.

    .PARAMETER PrefixLength
        The prefix length of the network.
#>
function Get-NetIPAddressNetwork
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $PrefixLength
    )

    $cidrNotation = $PrefixLength

    # Create array to hold our output mask.
    $subnetMaskOctet = @()

    # For loop to run through each octet.
    for ($octetNumber = 0; $octetNumber -lt 4; $octetNumber++)
    {
        # If there are 8 or more bits left.
        if ($cidrNotation -gt 7)
        {
            # Add 255 to mask array, and subtract 8 bits.
            $subnetMaskOctet += [byte] 255
            $cidrNotation -= 8
        }
        else
        {
            <#
                Bits are less than 8, calculate octet bits and
                zero out the $cidrNotation variable.
            #>
            $subnetMaskOctet += [byte] 255 -shl (8 - $cidrNotation)
            $cidrNotation = 0
        }
    }

    # Convert the calculated octets to the subnet representation.
    $subnetMask = [IPAddress] ($subnetMaskOctet -join '.')

    $networkAddress = ([IPAddress]($IPAddress.Address -band $subnetMask.Address)).IPAddressToString

    $networkObject = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $networkObject -MemberType NoteProperty -Name 'IPAddress' -Value $IPAddress
    Add-Member -InputObject $networkObject -MemberType NoteProperty -Name 'PrefixLength' -Value $PrefixLength
    Add-Member -InputObject $networkObject -MemberType NoteProperty -Name 'SubnetMask' -Value $subnetMask
    Add-Member -InputObject $networkObject -MemberType NoteProperty -Name 'NetworkAddress' -Value $networkAddress

    return $networkObject
}
