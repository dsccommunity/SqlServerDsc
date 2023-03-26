$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets the SQL Agent Failsafe Operator.

    .PARAMETER Name
        The name of the SQL Agent Failsafe Operator.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default is the current
        computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.
#>
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

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName
    )

    $returnValue = @{
        Name               = $null
        Ensure             = 'Absent'
        ServerName         = $ServerName
        InstanceName       = $InstanceName
        NotificationMethod = $null
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.GetSqlAgentFailsafe
        )

        $sqlAlertSystemObject = $sqlServerObject.JobServer.AlertSystem | Where-Object -FilterScript { $_.FailSafeOperator -eq $Name }

        if ($sqlAlertSystemObject)
        {
            Write-Verbose -Message (
                $script:localizedData.SqlFailsafePresent `
                    -f $Name
            )

            $returnValue['Ensure'] = 'Present'
            $returnValue['Name'] = $sqlAlertSystemObject.FailSafeOperator
            $returnValue['NotificationMethod'] = $sqlAlertSystemObject.NotificationMethod
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.SqlFailsafeAbsent `
                    -f $Name
            )
        }
    }
    else
    {
        $errorMessage = $script:localizedData.ConnectServerFailed -f $ServerName, $InstanceName
        New-InvalidOperationException -Message $errorMessage
    }

    return $returnValue
}

<#
    .SYNOPSIS
        This function sets the SQL Agent Failsafe Operator.

    .PARAMETER Ensure
        Specifies if the SQL Agent Failsafe Operator should be present or absent. Default is Present

    .PARAMETER Name
        The name of the SQL Agent Failsafe Operator.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default is the current
        computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER NotificationMethod
        The method of notification for the Failsafe Operator.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('None', 'NotifyEmail', 'Pager', 'NetSend', 'NotifyAll')]
        [System.String]
        $NotificationMethod
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    if ($sqlServerObject)
    {
        switch ($Ensure)
        {
            'Present'
            {
                try
                {
                    $sqlAlertSystemObject = $sqlServerObject.JobServer.AlertSystem

                    Write-Verbose -Message (
                        $script:localizedData.UpdateFailsafeOperator `
                            -f $Name
                    )

                    $sqlAlertSystemObject.FailSafeOperator = $Name
                    if ($PSBoundParameters.ContainsKey('NotificationMethod'))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.UpdateNotificationMethod `
                                -f $NotificationMethod, $Name
                        )

                        $sqlAlertSystemObject.NotificationMethod = $NotificationMethod
                    }

                    $sqlAlertSystemObject.Alter()
                }
                catch
                {
                    $errorMessage = $script:localizedData.UpdateFailsafeOperatorError -f $Name, $ServerName, $InstanceName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }

            'Absent'
            {
                try
                {
                    $sqlAlertSystemObject = $sqlServerObject.JobServer.AlertSystem

                    Write-Verbose -Message (
                        $script:localizedData.RemoveFailsafeOperator
                    )

                    $sqlAlertSystemObject.FailSafeOperator = $null
                    $sqlAlertSystemObject.NotificationMethod = 'None'
                    $sqlAlertSystemObject.Alter()
                }
                catch
                {
                    $errorMessage = $script:localizedData.UpdateFailsafeOperatorError -f $Name, $ServerName, $InstanceName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
        }
    }
    else
    {
        $errorMessage = $script:localizedData.ConnectServerFailed -f $ServerName, $InstanceName
        New-InvalidOperationException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        This function tests the SQL Agent Failsafe Operator.

    .PARAMETER Ensure
        Specifies if the SQL Agent Failsafe Operator should be present or absent. Default is Present

    .PARAMETER Name
        The name of the SQL Agent Failsafe Operator.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default is the current
        computer name

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER NotificationMethod
        The method of notification for the Failsafe Operator.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql is called when Get-TargetResource is called')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [ValidateSet('None', 'NotifyEmail', 'Pager', 'NetSend', 'NotifyAll')]
        [System.String]
        $NotificationMethod
    )

    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Name         = $Name
    }

    $returnValue = $false

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration
    )

    if ($Ensure -eq 'Present')
    {
        $returnValue = Test-DscParameterState `
            -CurrentValues $getTargetResourceResult `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @(
                'FailsafeOperator'
                'NotificationMethod'
            ) `
            -TurnOffTypeChecking
    }
    else
    {
        if ($Ensure -eq $getTargetResourceResult.Ensure)
        {
            $returnValue = $true
        }
    }

    return $returnValue
}
