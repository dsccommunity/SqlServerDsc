<#
    .SYNOPSIS
        Sets the database timeout settings for SQL Server Reporting Services.

    .DESCRIPTION
        Sets the database logon timeout and/or query timeout for SQL Server
        Reporting Services or Power BI Report Server by calling the
        `SetDatabaseLogonTimeout` and/or `SetDatabaseQueryTimeout` methods
        on the `MSReportServer_ConfigurationSetting` CIM instance.

        At least one of `LogonTimeout` or `QueryTimeout` must be specified.
        Both can be specified together to set both values in a single call.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER LogonTimeout
        Specifies the default timeout value, in seconds, for report server
        database connections. A value of 0 means no timeout.

    .PARAMETER QueryTimeout
        Specifies the default timeout value, in seconds, for report server
        database queries. A value of 0 means no timeout.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after setting
        the timeout values.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30

        Sets the database logon timeout to 30 seconds.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120

        Sets the database query timeout to 120 seconds.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -QueryTimeout 120

        Sets both the database logon timeout and query timeout.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Set-SqlDscRSDatabaseTimeout -Configuration $config -LogonTimeout 30 -QueryTimeout 120 -Force

        Sets both timeout values without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSDatabaseTimeout -LogonTimeout 0

        Sets the database logon timeout to 0 (no timeout).

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        None. By default, this command does not generate any output.

    .OUTPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        When PassThru is specified, returns the MSReportServer_ConfigurationSetting
        CIM instance.

    .NOTES
        The Reporting Services service may need to be restarted for the
        changes to take effect.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setdatabaselogontimeout

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setdatabasequerytimeout
#>
function Set-SqlDscRSDatabaseTimeout
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(DefaultParameterSetName = 'LogonTimeout', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(ParameterSetName = 'LogonTimeout', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'QueryTimeout', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'BothTimeouts', Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter(ParameterSetName = 'LogonTimeout', Mandatory = $true)]
        [Parameter(ParameterSetName = 'BothTimeouts', Mandatory = $true)]
        [ValidateRange(0, [System.Int32]::MaxValue)]
        [System.Int32]
        $LogonTimeout,

        [Parameter(ParameterSetName = 'QueryTimeout', Mandatory = $true)]
        [Parameter(ParameterSetName = 'BothTimeouts', Mandatory = $true)]
        [ValidateRange(0, [System.Int32]::MaxValue)]
        [System.Int32]
        $QueryTimeout,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $instanceName = $Configuration.InstanceName

        # Build ShouldProcess messages based on parameter set
        switch ($PSCmdlet.ParameterSetName)
        {
            'LogonTimeout'
            {
                $descriptionMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_ShouldProcessDescription_LogonTimeout -f $LogonTimeout, $instanceName
                $confirmationMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_ShouldProcessConfirmation_LogonTimeout -f $LogonTimeout
            }

            'QueryTimeout'
            {
                $descriptionMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_ShouldProcessDescription_QueryTimeout -f $QueryTimeout, $instanceName
                $confirmationMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_ShouldProcessConfirmation_QueryTimeout -f $QueryTimeout
            }

            'BothTimeouts'
            {
                $descriptionMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_ShouldProcessDescription_BothTimeouts -f $LogonTimeout, $QueryTimeout, $instanceName
                $confirmationMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_ShouldProcessConfirmation_BothTimeouts -f $LogonTimeout, $QueryTimeout
            }
        }

        $captionMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            # Set logon timeout if specified
            if ($PSBoundParameters.ContainsKey('LogonTimeout'))
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscRSDatabaseTimeout_SettingLogon -f $LogonTimeout, $instanceName)

                $invokeRsCimMethodParameters = @{
                    CimInstance = $Configuration
                    MethodName  = 'SetDatabaseLogonTimeout'
                    Arguments   = @{
                        LogonTimeout = $LogonTimeout
                    }
                }

                try
                {
                    $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
                }
                catch
                {
                    $errorMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_FailedToSetLogon -f $instanceName

                    $exception = New-Exception -Message $errorMessage -ErrorRecord $_

                    $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'SSRSDT0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }
            }

            # Set query timeout if specified
            if ($PSBoundParameters.ContainsKey('QueryTimeout'))
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscRSDatabaseTimeout_SettingQuery -f $QueryTimeout, $instanceName)

                $invokeRsCimMethodParameters = @{
                    CimInstance = $Configuration
                    MethodName  = 'SetDatabaseQueryTimeout'
                    Arguments   = @{
                        QueryTimeout = $QueryTimeout
                    }
                }

                try
                {
                    $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
                }
                catch
                {
                    $errorMessage = $script:localizedData.Set_SqlDscRSDatabaseTimeout_FailedToSetQuery -f $instanceName

                    $exception = New-Exception -Message $errorMessage -ErrorRecord $_

                    $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'SSRSDT0002' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
