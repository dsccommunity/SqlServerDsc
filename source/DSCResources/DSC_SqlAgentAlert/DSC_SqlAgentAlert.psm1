$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets the SQL Agent Alert.

    .PARAMETER Name
        The name of the SQL Agent Alert.

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
        Name         = $null
        Ensure       = 'Absent'
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Severity     = $null
        MessageId    = $null
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.GetSqlAlerts
        )
        # Check agent exists
        $sqlAgentObject = $sqlServerObject.JobServer.Alerts | Where-Object -FilterScript { $_.Name -eq $Name }
        if ($sqlAgentObject)
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAlertPresent `
                    -f $Name
            )
            $returnValue['Ensure'] = 'Present'
            $returnValue['Name'] = $sqlAgentObject.Name
            $returnValue['Severity'] = $sqlAgentObject.Severity
            $returnValue['MessageId'] = $sqlAgentObject.MessageId
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAlertAbsent `
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
        This function sets the SQL Agent Alert.

    .PARAMETER Ensure
        Specifies if the SQL Agent Alert should be present or absent. Default is Present

    .PARAMETER Name
        The name of the SQL Agent Alert.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default is the current
        computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER Severity
        The severity of the SQL Agent Alert.

    .PARAMETER MessageId
        The messageid of the SQL Agent Alert.
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
        [System.String]
        $Severity,

        [Parameter()]
        [System.String]
        $MessageId
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    if ($sqlServerObject)
    {
        switch ($Ensure)
        {
            'Present'
            {
                $sqlAlertObject = $sqlServerObject.JobServer.Alerts | Where-Object -FilterScript { $_.Name -eq $Name }
                if ($sqlAlertObject)
                {
                    if ($PSBoundParameters.ContainsKey('Severity') -and $PSBoundParameters.ContainsKey('MessageId'))
                    {
                        $errorMessage = $script:localizedData.MultipleParameterError -f $Name
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }

                    if ($PSBoundParameters.ContainsKey('Severity'))
                    {
                        try
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdateSeverity `
                                    -f $Severity, $Name
                            )
                            $sqlAlertObject.MessageId = 0
                            $sqlAlertObject.Severity = $Severity
                            $sqlAlertObject.Alter()
                        }
                        catch
                        {
                            $errorMessage = $script:localizedData.UpdateAlertSeverityError -f $ServerName, $InstanceName, $Name, $Severity
                            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                        }
                    }

                    if ($PSBoundParameters.ContainsKey('MessageId'))
                    {
                        try
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdateMessageId `
                                    -f $MessageId, $Name
                            )
                            $sqlAlertObject.Severity = 0
                            $sqlAlertObject.MessageId = $MessageId
                            $sqlAlertObject.Alter()
                        }
                        catch
                        {
                            $errorMessage = $script:localizedData.UpdateAlertMessageIdError -f $ServerName, $InstanceName, $Name, $MessageId
                            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                        }
                    }
                }
                else
                {
                    try
                    {
                        $sqlAlertObjectToCreate = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.Alert -ArgumentList $sqlServerObject.JobServer, $Name

                        if ($sqlAlertObjectToCreate)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.AddSqlAgentAlert `
                                    -f $Name
                            )
                            if ($PSBoundParameters.ContainsKey('Severity'))
                            {
                                Write-Verbose -Message (
                                    $script:localizedData.UpdateSeverity `
                                        -f $Severity, $Name
                                )
                                $sqlAlertObjectToCreate.Severity = $Severity
                            }
                            if ($PSBoundParameters.ContainsKey('MessageId'))
                            {
                                Write-Verbose -Message (
                                    $script:localizedData.UpdateMessageId `
                                        -f $MessageId, $Name
                                )
                                $sqlAlertObjectToCreate.MessageId = $MessageId
                            }
                            $sqlAlertObjectToCreate.Create()
                        }
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.CreateAlertSetError -f $Name, $ServerName, $InstanceName
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }

            'Absent'
            {
                try
                {
                    $sqlAlertObjectToDrop = $sqlServerObject.JobServer.Alerts | Where-Object -FilterScript { $_.Name -eq $Name }
                    if ($sqlAlertObjectToDrop)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DeleteSqlAgentAlert `
                                -f $Name
                        )
                        $sqlAlertObjectToDrop.Drop()
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.DropAlertSetError -f $Name, $ServerName, $InstanceName
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
        This function tests the SQL Agent Alert.

    .PARAMETER Ensure
        Specifies if the SQL Agent Alert should be present or absent. Default is Present

    .PARAMETER Name
        The name of the SQL Agent Alert.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default is the current
        computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER Severity
        The severity of the SQL Agent Alert.

    .PARAMETER MessageId
        The messageid of the SQL Agent Alert.
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
        [System.String]
        $Severity,

        [Parameter()]
        [System.String]
        $MessageId
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
                'Name'
                'Severity'
                'MessageId'
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
