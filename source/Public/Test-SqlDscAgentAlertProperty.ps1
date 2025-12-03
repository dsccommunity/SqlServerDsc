<#
    .SYNOPSIS
        Tests if a SQL Agent Alert has the specified properties.

    .DESCRIPTION
        This command tests if a SQL Agent Alert on a SQL Server Database Engine
        instance has the specified properties. At least one property parameter
        must be specified.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Alert to test.

    .PARAMETER AlertObject
        Specifies the SQL Agent Alert object to test.

    .PARAMETER Severity
        Specifies the expected severity level for the SQL Agent Alert. Valid range is 0 to 25.
        If specified, the command will return $true only if the alert exists and has this severity.

    .PARAMETER MessageId
        Specifies the expected message ID for the SQL Agent Alert. Valid range is 0 to 2147483647.
        If specified, the command will return $true only if the alert exists and has this message ID.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Alert

        SQL Agent Alert object.

    .OUTPUTS
        `System.Boolean`

        Returns the output object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscAgentAlertProperty -ServerObject $serverObject -Name 'MyAlert' -Severity 16

        Tests if the SQL Agent Alert named 'MyAlert' exists and has severity level 16.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscAgentAlertProperty -Name 'MyAlert' -MessageId 50001

        Tests if the SQL Agent Alert named 'MyAlert' exists and has message ID 50001.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $alertObject = $serverObject | Get-SqlDscAgentAlert -Name 'MyAlert'
        $alertObject | Test-SqlDscAgentAlertProperty -Severity 16

        Tests if the SQL Agent Alert has severity level 16 using alert object pipeline input.
#>
function Test-SqlDscAgentAlertProperty
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(DefaultParameterSetName = 'ByServerAndName')]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(ParameterSetName = 'ByServerAndName', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'ByServerAndName', Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'ByAlertObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Agent.Alert]
        $AlertObject,

        [Parameter()]
        [ValidateRange(0, 25)]
        [System.Int32]
        $Severity,

        [Parameter()]
        [ValidateRange(0, 2147483647)]
        [System.Int32]
        $MessageId
    )

    # cSpell: ignore TSAAP
    process
    {
        # Ensure at least one property parameter is specified
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -AtLeastOneList @('Severity', 'MessageId')

        # Validate that both Severity and MessageId are not specified
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -MutuallyExclusiveList1 @('Severity') -MutuallyExclusiveList2 @('MessageId')

        if ($PSCmdlet.ParameterSetName -eq 'ByAlertObject')
        {
            $alertObject = $AlertObject
        }
        else
        {
            $alertObject = Get-AgentAlertObject -ServerObject $ServerObject -Name $Name

            if ($null -eq $alertObject)
            {
                $errorMessage = $script:localizedData.Test_SqlDscAgentAlertProperty_AlertNotFound -f $Name

                Write-Error -Message $errorMessage -Category 'ObjectNotFound' -ErrorId 'TSDAAP0001' -TargetObject $Name

                return $false
            }
        }

        # Test severity if specified
        if ($PSBoundParameters.ContainsKey('Severity'))
        {
            if ($alertObject.Severity -ne $Severity)
            {
                return $false
            }
        }

        # Test message ID if specified
        if ($PSBoundParameters.ContainsKey('MessageId'))
        {
            if ($alertObject.MessageId -ne $MessageId)
            {
                return $false
            }
        }

        return $true
    }
}
