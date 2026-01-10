<#
    .SYNOPSIS
        Creates a new SQL Agent Alert.

    .DESCRIPTION
        This command creates a new SQL Agent Alert on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Alert to create.

    .PARAMETER Severity
        Specifies the severity level for the SQL Agent Alert. Valid range is 0 to 25.
        Cannot be used together with MessageId.

    .PARAMETER MessageId
        Specifies the message ID for the SQL Agent Alert. Valid range is 0 to 2147483647.
        Cannot be used together with Severity.

    .PARAMETER PassThru
        If specified, the created alert object will be returned.

    .PARAMETER Force
        Forces the action without prompting for confirmation.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        SQL Server Database Engine instance object.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Agent.Alert`

        Returns the created alert object when using the **PassThru** parameter.

    .OUTPUTS
        None.

        No output when the **PassThru** parameter is not specified.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        New-SqlDscAgentAlert -ServerObject $serverObject -Name 'MyAlert' -Severity 16

        Creates a new SQL Agent Alert named 'MyAlert' with severity level 16.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscAgentAlert -Name 'MyAlert' -MessageId 50001

        Creates a new SQL Agent Alert named 'MyAlert' for message ID 50001 using pipeline input.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $alertObject = $serverObject | New-SqlDscAgentAlert -Name 'MyAlert' -Severity 16 -PassThru

        Creates a new SQL Agent Alert and returns the created object.

    .NOTES
        Either -Severity or -MessageId must be specified (mutually exclusive).
#>
function New-SqlDscAgentAlert
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Alert])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateRange(0, 25)]
        [System.Int32]
        $Severity,

        [Parameter()]
        [ValidateRange(0, 2147483647)]
        [System.Int32]
        $MessageId,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    # cSpell: ignore NSAA
    process
    {
        # Validate that both Severity and MessageId are not specified
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -MutuallyExclusiveList1 @('Severity') -MutuallyExclusiveList2 @('MessageId')

        # Check if alert already exists
        $alertExists = Test-SqlDscIsAgentAlert -ServerObject $ServerObject -Name $Name

        if ($alertExists)
        {
            $errorMessage = $script:localizedData.New_SqlDscAgentAlert_AlertAlreadyExists -f $Name

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'NSAA0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $Name
                )
            )
        }

        $verboseDescriptionMessage = $script:localizedData.New_SqlDscAgentAlert_CreateShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.New_SqlDscAgentAlert_CreateShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.New_SqlDscAgentAlert_CreateShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.New_SqlDscAgentAlert_CreatingAlert -f $Name)

                # Create the new alert SMO object
                $newAlertObject = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::new($ServerObject.JobServer, $Name)

                if ($PSBoundParameters.ContainsKey('Severity'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentAlert_SettingSeverity -f $Severity, $Name)
                    $newAlertObject.Severity = $Severity
                }

                if ($PSBoundParameters.ContainsKey('MessageId'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentAlert_SettingMessageId -f $MessageId, $Name)
                    $newAlertObject.MessageId = $MessageId
                }

                $newAlertObject.Create()

                Write-Verbose -Message ($script:localizedData.New_SqlDscAgentAlert_AlertCreated -f $Name)

                if ($PassThru.IsPresent)
                {
                    return $newAlertObject
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.New_SqlDscAgentAlert_CreateFailed -f $Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'NSAA0002', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Name
                    )
                )
            }
        }
    }
}
