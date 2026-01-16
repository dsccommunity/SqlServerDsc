<#
    .SYNOPSIS
        Sets the service account for SQL Server Reporting Services.

    .DESCRIPTION
        Sets the Windows service account for SQL Server Reporting Services or
        Power BI Report Server by calling the `SetWindowsServiceIdentity`
        method on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command changes the Windows service account that the Reporting
        Services service runs under. Sets file permissions on files and folders
        in the report server installation directory. The account requires
        LogonAsService rights in Windows, the specified account will be granted
        this right.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Credential
        Specifies the credentials for the new service account. The username
        should be in the format 'DOMAIN\Username' for domain accounts or
        'Username' for local accounts.

    .PARAMETER UseBuiltInAccount
        Indicates that the account specified is a built-in Windows account
        such as 'NT AUTHORITY\NetworkService' or 'NT AUTHORITY\LocalSystem'.
        When this switch is used, only the username portion of the Credential
        is used and the password is ignored.

    .PARAMETER RestartService
        If specified, restarts the Reporting Services service after changing
        the service account. The service must be restarted for the change to
        take effect.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after setting
        the service account.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .PARAMETER SuppressUrlReservationWarning
        If specified, suppresses the warning message about URL reservations
        needing to be updated when the service account changes.

    .EXAMPLE
        $credential = Get-Credential
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSServiceAccount -Credential $credential -RestartService

        Sets the service account for Reporting Services and restarts the service.

    .EXAMPLE
        $credential = New-Object System.Management.Automation.PSCredential('NT AUTHORITY\NetworkService', (New-Object System.Security.SecureString))
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSServiceAccount -Credential $credential -UseBuiltInAccount -Force

        Sets the service account to NetworkService without confirmation.

    .EXAMPLE
        $credential = Get-Credential
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSServiceAccount -Credential $credential -PassThru

        Sets the service account and returns the configuration CIM instance.

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
        The Reporting Services service must be restarted for the change to take
        effect. Use the -RestartService parameter or manually restart the service.

        URL reservations are created for the current service account.
        Changing the service account requires updating all URL
        reservations.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setwindowsserviceidentity
#>
function Set-SqlDscRSServiceAccount
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UseBuiltInAccount,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RestartService,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SuppressUrlReservationWarning
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $instanceName = $Configuration.InstanceName
        $serviceName = $Configuration.ServiceName

        $userName = $Credential.UserName

        Write-Verbose -Message ($script:localizedData.Set_SqlDscRSServiceAccount_Setting -f $userName, $instanceName)

        $descriptionMessage = $script:localizedData.Set_SqlDscRSServiceAccount_ShouldProcessDescription -f $userName, $instanceName
        $confirmationMessage = $script:localizedData.Set_SqlDscRSServiceAccount_ShouldProcessConfirmation -f $userName
        $captionMessage = $script:localizedData.Set_SqlDscRSServiceAccount_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $passwordPlainText = ''

            if (-not $UseBuiltInAccount.IsPresent)
            {
                $passwordBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)

                try
                {
                    $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($passwordBstr)
                }
                finally
                {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordBstr)
                }
            }

            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'SetWindowsServiceIdentity'
                Arguments   = @{
                    UseBuiltInAccount = $UseBuiltInAccount.IsPresent
                    Account           = $userName
                    Password          = $passwordPlainText
                }
            }

            $currentServiceAccount = $Configuration.WindowsServiceIdentityActual

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

                if (-not $SuppressUrlReservationWarning.IsPresent -and $currentServiceAccount -ne $userName)
                {
                    Write-Warning -Message ($script:localizedData.Set_SqlDscRSServiceAccount_UrlReservationWarning -f $currentServiceAccount, $userName)
                }

                if ($RestartService.IsPresent)
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscRSServiceAccount_RestartingService -f $serviceName)

                    Restart-SqlDscRSService -ServiceName $serviceName -Force
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.Set_SqlDscRSServiceAccount_FailedToSet -f $instanceName

                $exception = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'SSRSSA0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
