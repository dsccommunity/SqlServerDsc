<#
    .SYNOPSIS
        Disables snapshot isolation for a database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command disables snapshot isolation for a database in a SQL Server Database Engine
        instance. Disabling snapshot isolation removes row-versioning and snapshot isolation
        settings for the database.

        The command uses the SetSnapshotIsolation() method on the SMO Database object to disable
        row-versioning and snapshot isolation settings.

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
        Specifies that snapshot isolation should be disabled without any confirmation.

    .PARAMETER PassThru
        Specifies that the database object should be returned after modification.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $serverObject -Name 'MyDatabase'

        Disables snapshot isolation for the database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Disable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $databaseObject -Force

        Disables snapshot isolation for the database using a database object without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $serverObject -Name 'MyDatabase' -PassThru

        Disables snapshot isolation and returns the updated database object.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Database

        The database object to modify (from Get-SqlDscDatabase).

    .OUTPUTS
        None.

        By default, no output is returned.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Database

        When PassThru is specified, the updated database object is returned.
#>
function Disable-SqlDscDatabaseSnapshotIsolation
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

        $descriptionMessage = $script:localizedData.DatabaseSnapshotIsolation_Disable_ShouldProcessVerboseDescription -f $sqlDatabaseObject.Name, $sqlDatabaseObject.Parent.InstanceName
        $confirmationMessage = $script:localizedData.DatabaseSnapshotIsolation_Disable_ShouldProcessVerboseWarning -f $sqlDatabaseObject.Name
        $captionMessage = $script:localizedData.DatabaseSnapshotIsolation_Disable_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            # Check if snapshot isolation is already disabled (idempotence)
            if ($sqlDatabaseObject.SnapshotIsolationState -eq 'Disabled')
            {
                Write-Debug -Message ($script:localizedData.DatabaseSnapshotIsolation_AlreadyDisabled -f $sqlDatabaseObject.Name)
            }
            else
            {
                Write-Debug -Message ($script:localizedData.DatabaseSnapshotIsolation_Disabling -f $sqlDatabaseObject.Name)

                try
                {
                    $sqlDatabaseObject.SetSnapshotIsolation($false)
                }
                catch
                {
                    $errorMessage = $script:localizedData.DatabaseSnapshotIsolation_DisableFailed -f $sqlDatabaseObject.Name

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'DSDSI0001', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $sqlDatabaseObject
                        )
                    )
                }

                Write-Debug -Message ($script:localizedData.DatabaseSnapshotIsolation_Disabled -f $sqlDatabaseObject.Name)
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
