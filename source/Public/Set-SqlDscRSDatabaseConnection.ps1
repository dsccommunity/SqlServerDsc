<#
    .SYNOPSIS
        Sets the report server database connection for SQL Server Reporting Services.

    .DESCRIPTION
        Sets the report server database connection for SQL Server Reporting Services
        or Power BI Report Server by calling the `SetDatabaseConnection` method on
        the `MSReportServer_ConfigurationSetting` CIM instance.

        This command configures which database the report server should use for
        storing report definitions, metadata, and other report server data.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER ServerName
        Specifies the name of the server that hosts the report server database.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance that hosts the report
        server database. If not specified, the default instance is used.

    .PARAMETER DatabaseName
        Specifies the name of the report server database. Common names are
        'ReportServer' or 'ReportServer$InstanceName'.

    .PARAMETER Type
        Specifies the type of credentials to use for the database connection.
        Valid values are:
        - 'Windows': Windows authentication with specified credentials.
        - 'SqlServer': SQL Server authentication with specified credentials.
        - 'ServiceAccount': Windows Service integrated security using the
          report server service account.

        The default is 'ServiceAccount'.

    .PARAMETER Credential
        Specifies the credentials for connecting to the database when using
        'Windows' or 'SqlServer' credentials type. This parameter is required
        when Type is 'Windows' or 'SqlServer'.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after setting
        the database connection.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer'

        Sets the report server database connection to use the 'ReportServer'
        database on 'localhost' using the report server service account.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Set-SqlDscRSDatabaseConnection -Configuration $config -ServerName 'SqlServer01' -InstanceName 'MSSQLSERVER' -DatabaseName 'ReportServer' -Confirm:$false

        Sets the report server database connection without confirmation.

    .EXAMPLE
        $credential = Get-Credential
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSDatabaseConnection -ServerName 'SqlServer01' -DatabaseName 'ReportServer' -Type 'SqlServer' -Credential $credential

        Sets the report server database connection using SQL Server
        authentication with the specified credentials.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -PassThru

        Sets the database connection and returns the configuration CIM instance.

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

        When using Type 'ServiceAccount', the report server web service
        will use either the ASP.NET account or an application pool's account and
        the Windows service account to access the report server database.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setdatabaseconnection
#>
function Set-SqlDscRSDatabaseConnection
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [ValidateSet('Windows', 'SqlServer', 'ServiceAccount')]
        [System.String]
        $Type = 'ServiceAccount',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

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

        $rsInstanceName = $Configuration.InstanceName

        # Build the database server connection string
        if ($PSBoundParameters.ContainsKey('InstanceName'))
        {
            $databaseServerName = '{0}\{1}' -f $ServerName, $InstanceName
        }
        else
        {
            $databaseServerName = $ServerName
        }

        # Validate Credential parameter is provided when required
        if ($Type -in @('Windows', 'SqlServer') -and -not $PSBoundParameters.ContainsKey('Credential'))
        {
            $errorMessage = $script:localizedData.Set_SqlDscRSDatabaseConnection_CredentialRequired -f $Type

            $errorRecord = New-ErrorRecord -Exception (New-ArgumentException -Message $errorMessage -ArgumentName 'Credential' -PassThru) -ErrorId 'SSRSDC0002' -ErrorCategory 'InvalidArgument' -TargetObject $Type

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        <#
            Map Type to the numeric value expected by the CIM method:
            0 = Windows
            1 = SQL Server
            2 = Windows Service (Integrated Security)
        #>
        $typeNumeric = switch ($Type)
        {
            'Windows'
            {
                0
            }

            'SqlServer'
            {
                1
            }

            'ServiceAccount'
            {
                2
            }
        }

        $userName = ''
        $password = ''

        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $userName = $Credential.UserName
            $password = $Credential.GetNetworkCredential().Password
        }

        Write-Verbose -Message ($script:localizedData.Set_SqlDscRSDatabaseConnection_Setting -f $DatabaseName, $databaseServerName, $rsInstanceName)

        $descriptionMessage = $script:localizedData.Set_SqlDscRSDatabaseConnection_ShouldProcessDescription -f $DatabaseName, $databaseServerName, $rsInstanceName
        $confirmationMessage = $script:localizedData.Set_SqlDscRSDatabaseConnection_ShouldProcessConfirmation -f $DatabaseName, $databaseServerName
        $captionMessage = $script:localizedData.Set_SqlDscRSDatabaseConnection_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'SetDatabaseConnection'
                Arguments   = @{
                    Server          = $databaseServerName
                    DatabaseName    = $DatabaseName
                    Username        = $userName
                    Password        = $password
                    CredentialsType = $typeNumeric
                }
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
            catch
            {
                $errorMessage = $script:localizedData.Set_SqlDscRSDatabaseConnection_FailedToSet -f $rsInstanceName, $_.Exception.Message

                $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'SSRSDC0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
