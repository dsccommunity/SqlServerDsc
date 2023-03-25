<#
    .SYNOPSIS
        Ensure the correct module stubs are loaded.

    .PARAMETER SQLVersion
        The major version of the SQL instance.

    .PARAMETER ModuleName
        The name of the module to load the stubs for. Default is 'SqlServer'.

    .OUTPUTS
        [System.String]

        The name of the module that was imported if the parameter PassThru was specified.
#>
function Import-SqlModuleStub
{
    [CmdletBinding(DefaultParameterSetName = 'Module')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [System.UInt32]
        $SQLVersion,

        [Parameter(ParameterSetName = 'Module')]
        [ValidateSet('SQLPS', 'SqlServer')]
        [System.String]
        $ModuleName = 'SqlServer',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    <#
        Translate the module names to their appropriate stub name.
        This must be the correct casing to work cross-platform.
    #>
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

    Get-Module -Name $otherStubModules -All | Remove-Module -Force

    # If the desired module is not loaded, load it now
    if ( -not ( Get-Module -Name $stubModuleName ) )
    {
        # Build the path to the module stub
        $moduleStubPath = Join-Path -Path ( Join-Path -Path ( Join-Path -Path ( Split-Path -Path $PSScriptRoot -Parent ) -ChildPath Unit ) -ChildPath Stubs ) -ChildPath "$($stubModuleName).psm1"

        Import-Module -Name $moduleStubPath -Force -Global -WarningAction 'SilentlyContinue'
    }

    if ($PassThru.IsPresent)
    {
        return $stubModuleName
    }
}

<#
    .SYNOPSIS
        Ensure the module stubs are unloaded.
#>
function Remove-SqlModuleStub
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('SQLPSStub', 'SqlServerStub')]
        [System.String[]]
        $Name = @(
            # Possible stub modules.
            'SQLPSStub'
            'SqlServerStub'
        )
    )

    Get-Module $Name -All | Remove-Module -Force
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

    $loopbackAdapterModuleName = 'LoopbackAdapter'

    # Ensure the loopback adapter module is downloaded
    if (-not (Get-Module -Name $loopbackAdapterModuleName -ListAvailable))
    {
        throw ('Missing module ''{0}''' -f $loopbackAdapterModuleName)
    }

    # Import the loopback adapter module
    Import-Module -Name $loopbackAdapterModuleName -Force

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
    param
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

<#
    .SYNOPSIS
        This command will create a new self-signed certificate to be used to
        secure Sql Server connection.

    .OUTPUTS
        Returns the created certificate. Writes the path to the public
        certificate in the machine environment variable $env:sqlPrivateCertificatePath,
        and the certificate thumbprint in the machine environment variable
        $env:SqlCertificateThumbprint.
#>
function New-SQLSelfSignedCertificate
{
    [CmdletBinding()]
    param ()

    $sqlPublicCertificatePath = Join-Path -Path $env:temp -ChildPath 'SqlPublicKey.cer'
    $sqlPrivateCertificatePath = Join-Path -Path $env:temp -ChildPath 'SqlPrivateKey.cer'
    $sqlPrivateKeyPassword = ConvertTo-SecureString -String "1234" -Force -AsPlainText

    $certificateSubject = $env:COMPUTERNAME

    <#
        There are build workers still on Windows Server 2012 R2 so let's
        use the alternate method of New-SelfSignedCertificate.
    #>
    Import-Module -Name 'PSPKI'

    $newSelfSignedCertificateExParameters = @{
        Subject            = "CN=$certificateSubject"
        EKU                = 'Server Authentication'
        KeyUsage           = 'KeyEncipherment, DataEncipherment'
        SAN                = "dns:$certificateSubject"
        FriendlyName       = 'Sql Encryption certificate'
        Path               = $sqlPrivateCertificatePath
        Password           = $sqlPrivateKeyPassword
        Exportable         = $true
        KeyLength          = 2048
        ProviderName       = 'Microsoft Enhanced Cryptographic Provider v1.0'
        AlgorithmName      = 'RSA'
        SignatureAlgorithm = 'SHA256'
    }

    $certificate = New-SelfSignedCertificateEx @newSelfSignedCertificateExParameters

    Write-Verbose -Message ('Created self-signed certificate ''{0}'' with thumbprint ''{1}''.' -f $certificate.Subject, $certificate.Thumbprint)

    # Update a machine and session environment variable with the path to the private certificate.
    [Environment]::SetEnvironmentVariable('SqlPrivateCertificatePath', $sqlPrivateCertificatePath, 'Machine')
    Write-Verbose -Message ('Machine environment variable SqlPrivateCertificatePath set to ''{0}''' -f [System.Environment]::GetEnvironmentVariable('SqlPrivateCertificatePath', 'Machine'))

    $env:SqlPrivateCertificatePath = $sqlPrivateCertificatePath
    Write-Verbose -Message ('Session environment variable $env:SqlPrivateCertificatePath set to ''{0}''' -f $env:SqlPrivateCertificatePath)

    # Update a machine and session environment variable with the thumbprint of the certificate.
    [Environment]::SetEnvironmentVariable('SqlCertificateThumbprint', $certificate.Thumbprint, 'Machine')
    Write-Verbose -Message ('Machine environment variable $env:SqlCertificateThumbprint set to ''{0}''' -f [System.Environment]::GetEnvironmentVariable('SqlCertificateThumbprint', 'Machine'))

    $env:SqlCertificateThumbprint = $certificate.Thumbprint
    Write-Verbose -Message ('Session environment variable $env:SqlCertificateThumbprint set to ''{0}''' -f $env:SqlCertificateThumbprint)

    return $certificate
}

<#
    .SYNOPSIS
        Returns $true if the environment variable CONFIGURATION is set to the value
        passed in the parameter Category.

    .PARAMETER Category
        One or more categories to check if they are set in $env:TEST_CONFIGURATION.
#>
function Test-ContinuousIntegrationTaskCategory
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Category
    )

    $result = $false

    if ($env:TEST_CONFIGURATION -in $Category)
    {
        $result = $true
    }

    return $result
}

<#
    .SYNOPSIS
        Used to test arguments passed to Start-SqlSetupProcess while inside and It-block.

        This function must be called inside a Mock, since it depends being run inside an It-block.

    .PARAMETER Argument
        A string containing all the arguments separated with space and each argument should start with '/'.
        Only the first string in the array is evaluated.

    .PARAMETER ExpectedArgument
        A hash table containing all the expected arguments.
#>
function Test-SetupArgument
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Argument,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ExpectedArgument
    )

    $argumentHashTable = @{}

    # Break the argument string into a hash table
    ($Argument -split ' ?/') | ForEach-Object -Process {
        <#
            This regex must support different types of values, and no values:
            /ENU /ACTION="Install" /FEATURES=SQLENGINE /SQLSYSADMINACCOUNTS="COMPANY\sqladmin" "COMPANY\SQLAdmins" /FailoverClusterDisks="Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs"
        #>
        if ($_ -imatch '(\w+)(=([^\/]+)"?)?')
        {
            $key = $Matches[1]
            if ($key -in @('FailoverClusterDisks', 'FailoverClusterIPAddresses'))
            {
                $value = ($Matches[3] -replace '" "', '; ') -replace '"', ''
            }
            elseif ($key -in @('SkipRules'))
            {
                # Do no transformation.
                $value = $Matches[3]
            }
            else
            {
                $value = ($Matches[3] -replace '" "', ' ') -replace '"', ''
            }

            $argumentHashTable.Add($key, $value)
        }
    }

    $actualValues = $argumentHashTable.Clone()

    # Limit the output in the console when everything is fine.
    if ($actualValues.Count -ne $ExpectedArgument.Count)
    {
        Write-Warning -Message 'Verified the setup argument count (expected vs actual)'
        Write-Warning -Message ('Expected: {0}' -f ($ExpectedArgument.Keys -join ','))
        Write-Warning -Message ('Actual: {0}' -f ($actualValues.Keys -join ','))
    }

    # Start by checking whether we have the same number of parameters
    $actualValues.Count | Should -Be $ExpectedArgument.Count `
        -Because ('the expected arguments was: {0}' -f ($ExpectedArgument.Keys -join ','))

    Write-Verbose -Message 'Verified actual setup argument values against expected setup argument values' -Verbose

    foreach ($argumentKey in $ExpectedArgument.Keys)
    {
        $argumentKeyName = $actualValues.GetEnumerator() |
            Where-Object -FilterScript {
                $_.Name -eq $argumentKey
            } | Select-Object -ExpandProperty 'Name'

        $argumentKeyName | Should -Be $argumentKey -Because 'the argument should have been included when setup.exe was called'

        $argumentValue = $actualValues.$argumentKey
        $argumentValue | Should -Be $ExpectedArgument.$argumentKey -Because 'the argument should have been set to the correct value when calling setup.exe'
    }
}

<#
    .SYNOPSIS
        Remove installed module.

    .PARAMETER Name
        Specifies an array of module names to remove. Defaults to 'SqlServer' and
        'SQLPS'.

    .NOTES
        Removes any existing versions of the SqlServer and SQLPS module.
        Importing module SqlServerDsc will import the module SqlServer or SQLPS.
        If SqlServer is imported it will render it locked and it is not possible
        to switch to another version. Also, regardless of SqlServer or SQLPS it
        could load the wrong assembly versions which will break SqlServerDsc if,
        for example, SqlServer is switch to another version.
#>
function Remove-PowerShellModuleFromCI
{
    param
    (
        [Parameter()]
        [System.String[]]
        $Name = @('SqlServer', 'SQLPS')
    )

    Write-Information -MessageData 'Checking if any path in $env:PSModulePath contain a module that are not suppose to be present.' -InformationAction 'Continue'

    $sqlServerModule = Get-Module -Name $Name -ListAvailable

    if ($sqlServerModule)
    {
        $existingModulesString = $sqlServerModule |
            Select-Object -Property @(
                'Name',
                'Version',
                @{
                    Name = 'Prerelease'
                    Expression = { $_.PrivateData.PSData.Prerelease }
                },
                'Path'
            ) |
            Out-String

        Write-Information -MessageData ('Existing modules: {0}' -f $existingModulesString) -InformationAction 'Continue'

        Write-Information -MessageData 'Removing the found modules.' -InformationAction 'Continue'

        # Remove versions, removes each file to detect if any file cannot be removed (e.g. locked assembly).
        $sqlServerModule |
            ForEach-Object -Process {
                Write-Information -MessageData ('Removing module version: {0}' -f $_.ModuleBase) -InformationAction 'Continue'

                $_.ModuleBase |
                    Remove-Item -Recurse -Force -ErrorAction 'Stop'
            }

        # Remove the module folder that is left by previous call.
        $sqlServerModule |
            ForEach-Object -Process {
                $parentFolder = Split-Path -Path $_.ModuleBase

                # Only remove if the path exist and does not end with '/Modules'.
                if ($parentFolder -notmatch 'modules$' -and (Test-Path -Path $parentFolder))
                {
                    Write-Information -MessageData ('Removing module folder: {0}' -f $parentFolder) -InformationAction 'Continue'

                    $parentFolder |
                        Remove-Item -Recurse -Force -ErrorAction 'Stop'
                }
            }
    }
    else
    {
        Write-Information -MessageData 'No existing SqlServer or SQLPS modules, nothing to remove.' -InformationAction 'Continue'
    }
}
