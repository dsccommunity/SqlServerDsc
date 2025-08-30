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
        $PassThru
    )

    # cSpell: ignore NSAO
    process
    {
        # Check if operator already exists
        $existingOperator = Get-SqlDscAgentOperator -ServerObject $ServerObject -Name $Name

        if ($existingOperator)
        {
            $errorMessage = $script:localizedData.New_SqlDscAgentOperator_OperatorAlreadyExists -f $Name
            New-InvalidOperationException -Message $errorMessage
        }

        $verboseDescriptionMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_CreatingOperator -f $Name)

                # Create the new operator SMO object
                $newOperatorObject = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::new($ServerObject.JobServer, $Name)

                if ($PSBoundParameters.ContainsKey('EmailAddress'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingEmailAddress -f $EmailAddress, $Name)
                    $newOperatorObject.EmailAddress = $EmailAddress
                }

                if ($PSBoundParameters.ContainsKey('CategoryName'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingCategoryName -f $CategoryName, $Name)
                    $newOperatorObject.CategoryName = $CategoryName
                }

                if ($PSBoundParameters.ContainsKey('NetSendAddress'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingNetSendAddress -f $NetSendAddress, $Name)
                    $newOperatorObject.NetSendAddress = $NetSendAddress
                }

                if ($PSBoundParameters.ContainsKey('PagerAddress'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingPagerAddress -f $PagerAddress, $Name)
                    $newOperatorObject.PagerAddress = $PagerAddress
                }

                if ($PSBoundParameters.ContainsKey('PagerDays'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingPagerDays -f $PagerDays, $Name)
                    $newOperatorObject.PagerDays = $PagerDays
                }

                if ($PSBoundParameters.ContainsKey('SaturdayPagerEndTime'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingSaturdayPagerEndTime -f $SaturdayPagerEndTime, $Name)
                    $newOperatorObject.SaturdayPagerEndTime = $SaturdayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('SaturdayPagerStartTime'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingSaturdayPagerStartTime -f $SaturdayPagerStartTime, $Name)
                    $newOperatorObject.SaturdayPagerStartTime = $SaturdayPagerStartTime
                }

                if ($PSBoundParameters.ContainsKey('SundayPagerEndTime'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingSundayPagerEndTime -f $SundayPagerEndTime, $Name)
                    $newOperatorObject.SundayPagerEndTime = $SundayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('SundayPagerStartTime'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingSundayPagerStartTime -f $SundayPagerStartTime, $Name)
                    $newOperatorObject.SundayPagerStartTime = $SundayPagerStartTime
                }

                if ($PSBoundParameters.ContainsKey('WeekdayPagerEndTime'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingWeekdayPagerEndTime -f $WeekdayPagerEndTime, $Name)
                    $newOperatorObject.WeekdayPagerEndTime = $WeekdayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('WeekdayPagerStartTime'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingWeekdayPagerStartTime -f $WeekdayPagerStartTime, $Name)
                    $newOperatorObject.WeekdayPagerStartTime = $WeekdayPagerStartTime
                }

                $newOperatorObject.Create()

                Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_OperatorCreated -f $Name)

                if ($PassThru.IsPresent)
                {
                    return $newOperatorObject
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.New_SqlDscAgentOperator_CreateFailed -f $Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}
