<#
    .SYNOPSIS
        Initializes SQL Server Reporting Services.

    .DESCRIPTION
        Initializes SQL Server Reporting Services or Power BI Report Server
        by calling the `InitializeReportServer` method on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        This command initializes the report server with the current
        configuration settings. The report server must have a database
        connection configured before initialization.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after
        initialization.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Initialize-SqlDscRS

        Initializes the Reporting Services instance 'SSRS'.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Initialize-SqlDscRS -Force

        Initializes the Reporting Services instance without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Initialize-SqlDscRS -PassThru

        Initializes the Reporting Services instance and returns the
        configuration CIM instance.

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
        The report server database must be configured before calling this
        command. Use `Set-SqlDscRSDatabaseConnection` to configure the
        database connection first.

        The Reporting Services service may need to be restarted after
        initialization.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-initializereportserver
#>
function Initialize-SqlDscRS
{
    # cSpell: ignore PBIRS
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
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

        Write-Verbose -Message ($script:localizedData.Initialize_SqlDscRS_Initializing -f $instanceName)

        $descriptionMessage = $script:localizedData.Initialize_SqlDscRS_ShouldProcessDescription -f $instanceName
        $confirmationMessage = $script:localizedData.Initialize_SqlDscRS_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.Initialize_SqlDscRS_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'InitializeReportServer'
                Arguments   = @{
                    InstallationId = $Configuration.InstallationID
                }
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $script:localizedData.Initialize_SqlDscRS_FailedToInitialize -f $instanceName, $_.Exception.Message

                $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'ISRS0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
