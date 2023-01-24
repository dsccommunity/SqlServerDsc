$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the cluster role/group that is waiting to be created,
        along with the time and number of times to wait.

    .PARAMETER ServerName
        Hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        Name of the SQL instance to be configured.

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the
        Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group.
        Default value is 20 seconds. When the cluster role/group has been found the
        resource will check if the AG group exist. When the availability group has
        been found the resource will also wait this amount of time before returning.

    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error.
        Default values is 30 times.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 20,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    Write-Verbose -Message (
        $script:localizedData.GetCurrentState -f $Name
    )

    $clusterGroupFound = $false

    # No ClusterName specified, so defaults to cluster on this node.
    $clusterGroup = Get-ClusterGroup -Name $Name -ErrorAction SilentlyContinue

    if ($null -ne $clusterGroup)
    {
        Write-Verbose -Message (
            $script:localizedData.FoundClusterGroup -f $Name
        )

        # Connect to the instance
        $serverObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

        if ($serverObject)
        {
            # Determine if HADR is enabled on the instance. If not, AG group can not exist.
            if ($serverObject.IsHadrEnabled )
            {
                $availabilityGroup = $serverObject.AvailabilityGroups[$Name]

                if ( $availabilityGroup )
                {
                    $clusterGroupFound = $true
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.AGNotFound -f $name, $InstanceName, $RetryIntervalSec
                    )
                }
            }
            else
            {
                Write-Verbose -Message (
                    $script:localizedData.HadrNotEnabled -f $InstanceName
                )
            }
        }
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.MissingClusterGroup -f $Name
        )
    }

    return @{
        ServerName       = $ServerName
        InstanceName     = $InstanceName
        Name             = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
        GroupExist       = $clusterGroupFound
    }
}

<#
    .SYNOPSIS
        Waits for a cluster role/group to be created

    .PARAMETER ServerName
        Hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        Name of the SQL instance to be configured.

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the
        Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group.
        Default value is 20 seconds. When the cluster role/group has been found the
        resource will check if the AG group exist. When the availability group has
        been found the resource will also wait this amount of time before returning.


    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error.
        Default values is 30 times.
#>
function Set-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql is called when Get-TargetResource is called')]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 20,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    Write-Verbose -Message (
        $script:localizedData.WaitingClusterGroup -f $Name, $RetryCount, ($RetryIntervalSec * $RetryCount)
    )

    $getTargetResourceParameters = @{
        ServerName       = $ServerName
        InstanceName     = $InstanceName
        Name             = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
    }

    for ($forLoopCount = 0; $forLoopCount -lt $RetryCount; $forLoopCount++)
    {
        $clusterGroupFound = (Get-TargetResource @getTargetResourceParameters).GroupExist
        if ($clusterGroupFound)
        {
            Write-Verbose -Message (
                '{0} {1}' -f `
                    ($script:localizedData.FoundClusterGroup -f $Name, $RetryCount, ($RetryIntervalSec * $RetryCount)),
                    ($script:localizedData.SleepMessage -f $RetryIntervalSec)
            )

            Start-Sleep -Seconds $RetryIntervalSec
            break
        }

        Write-Verbose -Message (
            '{0} {1}' -f `
                ($script:localizedData.MissingClusterGroup -f $Name, $RetryCount, ($RetryIntervalSec * $RetryCount)),
                ($script:localizedData.RetryMessage -f $RetryIntervalSec)
        )

        Start-Sleep -Seconds $RetryIntervalSec
    }

    if (-not $clusterGroupFound)
    {
        $errorMessage = $script:localizedData.FailedMessage -f $Name
        New-InvalidOperationException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Tests if the cluster role/group has been created.

    .PARAMETER ServerName
        Hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        Name of the SQL instance to be configured.

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the
        Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group.
        Default value is 20 seconds. When the cluster role/group has been found the
        resource will check if the AG group exist. When the availability group has
        been found the resource will also wait this amount of time before returning.


    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error.
        Default values is 30 times.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql is called when Get-TargetResource is called')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 20,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration -f $Name
    )

    $getTargetResourceParameters = @{
        ServerName       = $ServerName
        InstanceName     = $InstanceName
        Name             = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
    }

    $clusterGroupFound = (Get-TargetResource @getTargetResourceParameters).GroupExist
    if ($clusterGroupFound)
    {
        Write-Verbose -Message (
            $script:localizedData.FoundClusterGroup -f $Name
        )
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.MissingClusterGroup -f $Name
        )
    }

    return $clusterGroupFound
}
