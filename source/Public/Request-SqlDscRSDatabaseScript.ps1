<#
    .SYNOPSIS
        Generates the T-SQL script to create a report server database.

    .DESCRIPTION
        Generates the T-SQL script to create a report server database for SQL
        Server Reporting Services or Power BI Report Server by calling the
        `GenerateDatabaseCreationScript` method on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        The generated script can be executed on a SQL Server Database Engine
        instance using `Invoke-SqlDscQuery` to create the report server database.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER DatabaseName
        Specifies the name of the report server database to create. Common names
        are 'ReportServer' or 'ReportServer$InstanceName'.

    .PARAMETER Lcid
        Specifies the Language Code ID (LCID) to use for the database collation.
        If not specified, defaults to the operating system language.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer'

        Generates the T-SQL script to create the 'ReportServer' database for
        the 'SSRS' Reporting Services instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        $script = Request-SqlDscRSDatabaseScript -Configuration $config -DatabaseName 'ReportServer'
        Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $script -Force

        Generates the database creation script and executes it on the RSDB
        SQL Server instance to create the report server database.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.String`

        Returns the T-SQL script as a string.

    .NOTES
        After creating the database, use `Request-SqlDscRSDatabaseRightsScript`
        to generate the script that grants the necessary permissions, then use
        `Set-SqlDscRSDatabaseConnection` to configure the Reporting Services
        instance to use the new database.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-generatedatabasecreationscript
#>
function Request-SqlDscRSDatabaseScript
{
    # cSpell: ignore PBIRS Lcid
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

        [Parameter()]
        [System.Int32]
        $Lcid
    )

    process
    {
        $rsInstanceName = $Configuration.InstanceName

        if (-not $PSBoundParameters.ContainsKey('Lcid'))
        {
            $Lcid = (Get-OperatingSystem).OSLanguage
        }

        Write-Verbose -Message ($script:localizedData.Request_SqlDscRSDatabaseScript_Generating -f $DatabaseName, $rsInstanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'GenerateDatabaseCreationScript'
            Arguments   = @{
                DatabaseName     = $DatabaseName
                # IsSharePointMode must always be false. SharePoint integrated mode
                # is not supported since SQL Server 2012 (11.x) via WMI provider.
                IsSharePointMode = $false
                Lcid             = $Lcid
            }
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
        }
        catch
        {
            $errorMessage = $script:localizedData.Request_SqlDscRSDatabaseScript_FailedToGenerate -f $rsInstanceName, $_.Exception.Message

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'RSRDBS0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        return $result.Script
    }
}
