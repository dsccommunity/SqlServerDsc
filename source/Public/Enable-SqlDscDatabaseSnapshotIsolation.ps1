<#
    .SYNOPSIS
        Enables snapshot isolation for a database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command enables snapshot isolation for a database in a SQL Server Database Engine
        instance. Enabling snapshot isolation may require additional tempdb space and can affect
        transaction behavior.

        The command uses the SetSnapshotIsolation() method on the SMO Database object to enable
        row-versioning and snapshot isolation settings to optimize concurrency and consistency.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to modify.

    .PARAMETER DatabaseObject
        Specifies the database object to modify (from Get-SqlDscDatabase).

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        trying to get the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

        This parameter is only used when setting snapshot isolation using **ServerObject** and
        **Name** parameters.

    .PARAMETER Force
        Specifies that snapshot isolation should be enabled without any confirmation.

    .PARAMETER PassThru
        Specifies that the database object should be returned after modification.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Enable-SqlDscDatabaseSnapshotIsolation -ServerObject $serverObject -Name 'MyDatabase'

        Enables snapshot isolation for the database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Enable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $databaseObject -Force

        Enables snapshot isolation for the database using a database object without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Enable-SqlDscDatabaseSnapshotIsolation -ServerObject $serverObject -Name 'MyDatabase' -PassThru

        Enables snapshot isolation and returns the updated database object.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Database

        The database object to modify (from Get-SqlDscDatabase).

    .OUTPUTS
        None.

        When PassThru is specified the output is [Microsoft.SqlServer.Management.Smo.Database].
#>
function Enable-SqlDscDatabaseSnapshotIsolation
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues.')]
    [OutputType()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(DefaultParameterSetName = 'ServerObjectSet', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'ServerObjectSet')]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter(ParameterSetName = 'DatabaseObjectSet', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        # Get the database object based on the parameter set
        switch ($PSCmdlet.ParameterSetName)
        {
            'ServerObjectSet'
            {
                $previousErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'

                $sqlDatabaseObject = $ServerObject |
                    Get-SqlDscDatabase -Name $Name -Refresh:$Refresh -ErrorAction 'Stop'

                $ErrorActionPreference = $previousErrorActionPreference
            }

            'DatabaseObjectSet'
            {
                $sqlDatabaseObject = $DatabaseObject
            }
        }

        $verboseDescriptionMessage = $script:localizedData.DatabaseSnapshotIsolation_Enable_ShouldProcessVerboseDescription -f $sqlDatabaseObject.Name, $sqlDatabaseObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.DatabaseSnapshotIsolation_Enable_ShouldProcessVerboseWarning -f $sqlDatabaseObject.Name
        $captionMessage = $script:localizedData.DatabaseSnapshotIsolation_Enable_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Check if snapshot isolation is already enabled (idempotence)
            if ($sqlDatabaseObject.SnapshotIsolationState -eq 'Enabled')
            {
                Write-Debug -Message ($script:localizedData.DatabaseSnapshotIsolation_AlreadyEnabled -f $sqlDatabaseObject.Name)
            }
            else
            {
                Write-Debug -Message ($script:localizedData.DatabaseSnapshotIsolation_Enabling -f $sqlDatabaseObject.Name)

                try
                {
                    $sqlDatabaseObject.SetSnapshotIsolation($true)
                }
                catch
                {
                    $errorMessage = $script:localizedData.DatabaseSnapshotIsolation_EnableFailed -f $sqlDatabaseObject.Name

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'ESDSI0001', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $sqlDatabaseObject
                        )
                    )
                }

                Write-Debug -Message ($script:localizedData.DatabaseSnapshotIsolation_Enabled -f $sqlDatabaseObject.Name)
            }

            <#
                Refresh the database object to get the updated SnapshotIsolationState property if:
                - PassThru is specified (user wants the updated object back)
                - Using DatabaseObject parameter set (user's object reference should be updated)

                Refresh even if no change was made to ensure the object is up to date.
            #>
            if ($PassThru.IsPresent -or $PSCmdlet.ParameterSetName -eq 'DatabaseObjectSet')
            {
                $sqlDatabaseObject.Refresh()
            }

            if ($PassThru.IsPresent)
            {
                return $sqlDatabaseObject
            }
        }
    }
}
