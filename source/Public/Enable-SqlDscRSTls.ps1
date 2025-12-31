<#
    .SYNOPSIS
        Enables TLS for SQL Server Reporting Services.

    .DESCRIPTION
        Enables TLS (Transport Layer Security) for SQL Server Reporting Services
        or Power BI Report Server by setting the secure connection level to 1.

        This command calls the `SetSecureConnectionLevel` method on the
        `MSReportServer_ConfigurationSetting` CIM instance with a level value
        of 1, which requires TLS for all connections to the Reporting Services
        web service and portal.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after enabling TLS.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Enable-SqlDscRSTls

        Enables TLS for the SSRS instance by piping the configuration from
        `Get-SqlDscRSConfiguration`.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Enable-SqlDscRSTls -Configuration $config

        Enables TLS for the SSRS instance by passing the configuration as a
        parameter.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Enable-SqlDscRSTls -PassThru

        Enables TLS for the SSRS instance and returns the configuration CIM
        instance.

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
        The Reporting Services service may need to be restarted for the change
        to take effect.

        Since SQL Server 2008 R2, the secure connection level is treated as an
        on/off toggle where any value greater than or equal to 1 enables TLS.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setsecureconnectionlevel
#>
function Enable-SqlDscRSTls
{
    # cSpell: ignore PBIRS
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

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

        Write-Verbose -Message ($script:localizedData.Enable_SqlDscRSTls_EnablingTls -f $instanceName)

        $descriptionMessage = $script:localizedData.Enable_SqlDscRSTls_ShouldProcessDescription -f $instanceName
        $confirmationMessage = $script:localizedData.Enable_SqlDscRSTls_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.Enable_SqlDscRSTls_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'SetSecureConnectionLevel'
                Arguments   = @{
                    Level = 1
                }
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
            catch
            {
                $errorMessage = $script:localizedData.Enable_SqlDscRSTls_FailedToEnableTls -f $instanceName, $_.Exception.Message

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'ESRSTLS0001',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Configuration
                    )
                )
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
