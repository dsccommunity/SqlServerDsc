Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $EndpointName,

        [Parameter()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    $getTargetResourceReturnValues = @{
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
        Ensure = 'Absent'
        EndpointName = ''
        Port = ''
        IpAddress = ''
    }

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    if ($sqlServerObject)
    {
        Write-Verbose -Message ('Connected to {0}\{1}' -f $SQLServer, $SQLInstanceName)

        $endpointObject = $sqlServerObject.Endpoints[$EndpointName]
        if ($endpointObject.Name -eq $EndpointName)
        {
            if ($sqlServerObject.Endpoints[$EndPointName].EndpointType -ne 'DatabaseMirroring')
            {
                throw New-TerminatingError -ErrorType EndpointFoundButWrongType `
                                            -FormatArgs @($EndpointName) `
                                            -ErrorCategory InvalidOperation
            }

            $getTargetResourceReturnValues.Ensure = 'Present'
            $getTargetResourceReturnValues.EndpointName = $endpointObject.Name
            $getTargetResourceReturnValues.Port = $endpointObject.Protocol.Tcp.ListenerPort
            $getTargetResourceReturnValues.IpAddress = $endpointObject.Protocol.Tcp.ListenerIPAddress
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NotConnectedToInstance `
                                    -FormatArgs @($SQLServer,$SQLInstanceName) `
                                    -ErrorCategory InvalidOperation
    }

    return $getTargetResourceReturnValues
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $EndpointName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.UInt16]
        $Port = 5022,

        [Parameter()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter()]
        [System.String]
        $IpAddress = '0.0.0.0'
    )

    $getTargetResourceResult = Get-TargetResource -EndpointName $EndpointName -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    if ($sqlServerObject)
    {
        if ($Ensure -eq 'Present' -and $getTargetResourceResult.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ('Creating endpoint {0}.' -f $EndpointName)

            $endpointObject = New-Object -typename Microsoft.SqlServer.Management.Smo.Endpoint -ArgumentList $sqlServerObject, $EndpointName
            $endpointObject.EndpointType = [Microsoft.SqlServer.Management.Smo.EndpointType]::DatabaseMirroring
            $endpointObject.ProtocolType = [Microsoft.SqlServer.Management.Smo.ProtocolType]::Tcp
            $endpointObject.Protocol.Tcp.ListenerPort = $Port
            $endpointObject.Protocol.Tcp.ListenerIPAddress = $IpAddress
            $endpointObject.Payload.DatabaseMirroring.ServerMirroringRole = [Microsoft.SqlServer.Management.Smo.ServerMirroringRole]::All
            $endpointObject.Payload.DatabaseMirroring.EndpointEncryption = [Microsoft.SqlServer.Management.Smo.EndpointEncryption]::Required
            $endpointObject.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm = [Microsoft.SqlServer.Management.Smo.EndpointEncryptionAlgorithm]::Aes
            $endpointObject.Create()
            $endpointObject.Start()
        }
        elseif ($Ensure -eq 'Present' -and $getTargetResourceResult.Ensure -eq 'Present')
        {
            # The endpoint already exist, verifying supported endpoint properties so they are in desired state.
            $endpointObject = $sqlServerObject.Endpoints[$EndpointName]
            if ($endpointObject)
            {
                if ($endpointObject.Protocol.Tcp.ListenerIPAddress -ne $IpAddress)
                {
                    Write-Verbose -Message ('Updating endpoint {0} IP address to {1}.' -f $EndpointName, $IpAddress)
                    $endpointObject.Protocol.Tcp.ListenerIPAddress = $IpAddress
                }

                if ($endpointObject.Protocol.Tcp.ListenerPort -ne $Port)
                {
                    Write-Verbose -Message ('Updating endpoint {0} port to {1}.' -f $EndpointName, $Port)
                    $endpointObject.Protocol.Tcp.ListenerPort = $Port
                }

                $endpointObject.Alter()
            }
        }
        elseif ($Ensure -eq 'Absent' -and $getTargetResourceResult.Ensure -eq 'Present')
        {
            Write-Verbose -Message ('Dropping endpoint {0}.' -f $EndpointName)

            $endpointObject = $sqlServerObject.Endpoints[$EndpointName]
            if ($endpointObject)
            {
                $endpointObject.Drop()
            }
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NotConnectedToInstance `
                                    -FormatArgs @($SQLServer,$SQLInstanceName) `
                                    -ErrorCategory InvalidOperation
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
        $EndpointName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.UInt16]
        $Port = 5022,

        [Parameter()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter()]
        [System.String]
        $IpAddress = '0.0.0.0'
    )

    $getTargetResourceResult = Get-TargetResource -EndpointName $EndpointName -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    if( $getTargetResourceResult.Ensure -eq $Ensure )
    {
        $result = $true

        if ($getTargetResourceResult.Ensure -eq 'Present' `
            -and (
                $getTargetResourceResult.Port -ne $Port `
                -or $getTargetResourceResult.IpAddress -ne $IpAddress
                )
            )
        {
            $result = $false
        }
    }
    else
    {
        $result = $false
    }

    return $result
}

Export-ModuleMember -Function *-TargetResource
