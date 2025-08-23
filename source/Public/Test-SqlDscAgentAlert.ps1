<#
    .SYNOPSIS
        Tests if a SQL Agent Alert exists and has the desired properties.

    .DESCRIPTION
        This command tests if a SQL Agent Alert exists on a SQL Server Database Engine
        instance and optionally validates its properties.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Alert to test.

    .PARAMETER Severity
        Specifies the expected severity level for the SQL Agent Alert. Valid range is 0 to 25.
        If specified, the command will return $true only if the alert exists and has this severity.

    .PARAMETER MessageId
        Specifies the expected message ID for the SQL Agent Alert. Valid range is 0 to 2147483647.
        If specified, the command will return $true only if the alert exists and has this message ID.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscAgentAlert -ServerObject $serverObject -Name 'MyAlert'

        Tests if the SQL Agent Alert named 'MyAlert' exists.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscAgentAlert -Name 'MyAlert' -Severity 16

        Tests if the SQL Agent Alert named 'MyAlert' exists and has severity level 16.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscAgentAlert -Name 'MyAlert' -MessageId 50001

        Tests if the SQL Agent Alert named 'MyAlert' exists and has message ID 50001.
#>
function Test-SqlDscAgentAlert
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateRange(0, 25)]
        [System.Int32]
        $Severity,

        [Parameter()]
        [ValidateRange(0, 2147483647)]
        [System.Int32]
        $MessageId
    )

    # cSpell: ignore TSAA
    process
    {
        # Validate that both Severity and MessageId are not specified
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -MutuallyExclusiveList1 @('Severity') -MutuallyExclusiveList2 @('MessageId')

        Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_TestingAlert -f $Name)

        $alertObject = Get-AgentAlertObject -ServerObject $ServerObject -Name $Name

        if ($null -eq $alertObject)
        {
            Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_AlertNotFound -f $Name)

            return $false
        }

        Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_AlertFound -f $Name)

        # If no specific properties are specified, just return true (alert exists)
        if (-not $PSBoundParameters.ContainsKey('Severity') -and -not $PSBoundParameters.ContainsKey('MessageId'))
        {
            Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_NoPropertyTest)

            return $true
        }

        # Test severity if specified
        if ($PSBoundParameters.ContainsKey('Severity'))
        {
            if ($alertObject.Severity -ne $Severity)
            {
                Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_SeverityMismatch -f $alertObject.Severity, $Severity)

                return $false
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_SeverityMatch -f $Severity)
            }
        }

        # Test message ID if specified
        if ($PSBoundParameters.ContainsKey('MessageId'))
        {
            if ($alertObject.MessageId -ne $MessageId)
            {
                Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_MessageIdMismatch -f $alertObject.MessageId, $MessageId)

                return $false
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_MessageIdMatch -f $MessageId)
            }
        }

        Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentAlert_AllTestsPassed -f $Name)

        return $true
    }
}
