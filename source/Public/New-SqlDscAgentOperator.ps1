<#
    .SYNOPSIS
        Creates a new SQL Agent Operator.

    .DESCRIPTION
        This command creates a new SQL Agent Operator on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to create.

    .PARAMETER EmailAddress
        Specifies the email address for the SQL Agent Operator.

    .PARAMETER CategoryName
        Specifies the category name for the SQL Agent Operator.

    .PARAMETER NetSendAddress
        Specifies the net send address for the SQL Agent Operator.

    .PARAMETER PagerAddress
        Specifies the pager address for the SQL Agent Operator.

    .PARAMETER PagerDays
        Specifies the days when pager notifications are active for the SQL Agent Operator.

    .PARAMETER SaturdayPagerEndTime
        Specifies the Saturday pager end time for the SQL Agent Operator.

    .PARAMETER SaturdayPagerStartTime
        Specifies the Saturday pager start time for the SQL Agent Operator.

    .PARAMETER SundayPagerEndTime
        Specifies the Sunday pager end time for the SQL Agent Operator.

    .PARAMETER SundayPagerStartTime
        Specifies the Sunday pager start time for the SQL Agent Operator.

    .PARAMETER WeekdayPagerEndTime
        Specifies the weekday pager end time for the SQL Agent Operator.

    .PARAMETER WeekdayPagerStartTime
        Specifies the weekday pager start time for the SQL Agent Operator.

    .PARAMETER PassThru
        If specified, the created operator object will be returned.

    .PARAMETER Force
        Specifies that the operator should be created without any confirmation.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Agent.Operator]` if passing parameter **PassThru**,
         otherwise none.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        New-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator'

        Creates a new SQL Agent Operator named 'MyOperator'.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscAgentOperator -Name 'MyOperator' -EmailAddress 'admin@contoso.com'

        Creates a new SQL Agent Operator named 'MyOperator' with an email address using pipeline input.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $operatorObject = $serverObject | New-SqlDscAgentOperator -Name 'MyOperator' -PassThru

        Creates a new SQL Agent Operator and returns the created object.
#>
function New-SqlDscAgentOperator
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Operator])]
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
        [System.String]
        $EmailAddress,

        [Parameter()]
        [System.String]
        $CategoryName,

        [Parameter()]
        [System.String]
        $NetSendAddress,

        [Parameter()]
        [System.String]
        $PagerAddress,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.Agent.WeekDays]
        $PagerDays,

        [Parameter()]
        [System.TimeSpan]
        $SaturdayPagerEndTime,

        [Parameter()]
        [System.TimeSpan]
        $SaturdayPagerStartTime,

        [Parameter()]
        [System.TimeSpan]
        $SundayPagerEndTime,

        [Parameter()]
        [System.TimeSpan]
        $SundayPagerStartTime,

        [Parameter()]
        [System.TimeSpan]
        $WeekdayPagerEndTime,

        [Parameter()]
        [System.TimeSpan]
        $WeekdayPagerStartTime,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        # Dynamically get settable properties by filtering out common parameters and control parameters
        $settableProperties = Get-CommandParameter -Command $MyInvocation.MyCommand -Exclude @('ServerObject', 'Name', 'PassThru', 'Force')

        Assert-BoundParameter -BoundParameterList $PSBoundParameters -AtLeastOneList $settableProperties
    }

    # cSpell: ignore NSAO
    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        # Check if operator already exists
        if (Test-SqlDscAgentOperator -ServerObject $ServerObject -Name $Name)
        {
            $errorMessage = $script:localizedData.New_SqlDscAgentOperator_OperatorAlreadyExists -f $Name

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'NSAO0002', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $Name
                )
            )
        }

        $verboseDescriptionMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                # Create the new operator SMO object
                $newOperatorObject = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::new($ServerObject.JobServer, $Name)

                if ($PSBoundParameters.ContainsKey('EmailAddress'))
                {
                    $newOperatorObject.EmailAddress = $EmailAddress
                }

                if ($PSBoundParameters.ContainsKey('CategoryName'))
                {
                    $newOperatorObject.CategoryName = $CategoryName
                }

                if ($PSBoundParameters.ContainsKey('NetSendAddress'))
                {
                    $newOperatorObject.NetSendAddress = $NetSendAddress
                }

                if ($PSBoundParameters.ContainsKey('PagerAddress'))
                {
                    $newOperatorObject.PagerAddress = $PagerAddress
                }

                if ($PSBoundParameters.ContainsKey('PagerDays'))
                {
                    $newOperatorObject.PagerDays = $PagerDays
                }

                if ($PSBoundParameters.ContainsKey('SaturdayPagerEndTime'))
                {
                    $newOperatorObject.SaturdayPagerEndTime = $SaturdayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('SaturdayPagerStartTime'))
                {
                    $newOperatorObject.SaturdayPagerStartTime = $SaturdayPagerStartTime
                }

                if ($PSBoundParameters.ContainsKey('SundayPagerEndTime'))
                {
                    $newOperatorObject.SundayPagerEndTime = $SundayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('SundayPagerStartTime'))
                {
                    $newOperatorObject.SundayPagerStartTime = $SundayPagerStartTime
                }

                if ($PSBoundParameters.ContainsKey('WeekdayPagerEndTime'))
                {
                    $newOperatorObject.WeekdayPagerEndTime = $WeekdayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('WeekdayPagerStartTime'))
                {
                    $newOperatorObject.WeekdayPagerStartTime = $WeekdayPagerStartTime
                }

                $newOperatorObject.Create()

                if ($PassThru.IsPresent)
                {
                    return $newOperatorObject
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.New_SqlDscAgentOperator_CreateFailed -f $Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'NSAO0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Name
                    )
                )
            }
        }
    }
}
