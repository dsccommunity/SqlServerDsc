<#
    .SYNOPSIS
        Generates the T-SQL script to grant database permissions for Reporting Services.

    .DESCRIPTION
        Generates the T-SQL script to grant the necessary database permissions for
        a user account to access the report server database. This is done by calling
        the `GenerateDatabaseRightsScript` method on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        The generated script can be executed on a SQL Server Database Engine
        instance using `Invoke-SqlDscQuery` to grant the required permissions.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER DatabaseName
        Specifies the name of the report server database to grant permissions on.
        This should match the database name used when creating the database.

    .PARAMETER UserName
        Specifies the user account name to grant permissions to. This is typically
        the Reporting Services service account.

    .PARAMETER IsRemote
        If specified, indicates that the database is on a remote server.
        By default, assumes the database is local.

    .PARAMETER UseSqlAuthentication
        If specified, indicates the user is a SQL Server authentication user.
        By default, assumes Windows authentication.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'NT SERVICE\SQLServerReportingServices'

        Generates the T-SQL script to grant permissions on the 'ReportServer'
        database for the Reporting Services service account.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        $serviceAccount = $config.WindowsServiceIdentityActual
        $script = $config | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $serviceAccount
        Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $script -Force

        Gets the Reporting Services service account from the configuration object,
        generates the database rights script, and executes it on the RSDB SQL
        Server instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Request-SqlDscRSDatabaseRightsScript -Configuration $config -DatabaseName 'ReportServer' -UserName 'DOMAIN\SQLRSUser' -IsRemote

        Generates the rights script for a remote database scenario.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.String`

        Returns the T-SQL script as a string.

    .NOTES
        This command should be run after creating the report server database
        using the script from `Request-SqlDscRSDatabaseScript`. After granting
        permissions, use `Set-SqlDscRSDatabaseConnection` to configure the
        Reporting Services instance to use the database.

        To get the Reporting Services service account name, use the
        `WindowsServiceIdentityActual` property from the configuration object:
        `(Get-SqlDscRSConfiguration -InstanceName 'SSRS').WindowsServiceIdentityActual`

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-generatedatabaserightsscript
#>
function Request-SqlDscRSDatabaseRightsScript
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $UserName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IsRemote,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UseSqlAuthentication
    )

    process
    {
        $rsInstanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Request_SqlDscRSDatabaseRightsScript_Generating -f $DatabaseName, $UserName, $rsInstanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'GenerateDatabaseRightsScript'
            Arguments   = @{
                DatabaseName  = $DatabaseName
                UserName      = $UserName
                IsRemote      = $IsRemote.IsPresent
                IsWindowsUser = -not $UseSqlAuthentication.IsPresent
            }
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
        }
        catch
        {
            $errorMessage = $script:localizedData.Request_SqlDscRSDatabaseRightsScript_FailedToGenerate -f $rsInstanceName, $_.Exception.Message

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'RSRDBRS0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        return $result.Script
    }
}
