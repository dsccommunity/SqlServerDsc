<#
    .SYNOPSIS
        Gets the database upgrade script for SQL Server Reporting Services.

    .DESCRIPTION
        Gets the database upgrade script for SQL Server Reporting Services or
        Power BI Report Server by calling the `GenerateDatabaseUpgradeScript`
        method on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command generates a Transact-SQL script that can be used to
        upgrade the report server database schema to match the current
        Reporting Services version. This is useful during upgrade scenarios.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Request-SqlDscRSDatabaseUpgradeScript

        Gets the database upgrade script for the Reporting Services instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        $script = Request-SqlDscRSDatabaseUpgradeScript -Configuration $config
        Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'ReportServer' -Query $script

        Gets the upgrade script and executes it against the database.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.String`

        Returns the Transact-SQL script for upgrading the database.

    .NOTES
        Review the generated script before executing it against a production
        database. Always back up the database before performing upgrades.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-generatedatabaseupgradescript
#>
function Request-SqlDscRSDatabaseUpgradeScript
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration
    )

    process
    {
        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Request_SqlDscRSDatabaseUpgradeScript_Generating -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'GenerateDatabaseUpgradeScript'
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

            return $result.Script
        }
        catch
        {
            $errorMessage = $script:localizedData.Request_SqlDscRSDatabaseUpgradeScript_FailedToGenerate -f $instanceName, $_.Exception.Message

            $errorRecord = New-ErrorRecord -Message $errorMessage -ErrorId 'RSRSDBUS0001' -ErrorCategory ([System.Management.Automation.ErrorCategory]::InvalidOperation) -TargetObject $Configuration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}
