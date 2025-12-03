<#
    .SYNOPSIS
        Brings a SQL Server database back online.

    .DESCRIPTION
        This command brings a SQL Server database back online, making it available
        to users again after maintenance or downtime. The command uses the SMO
        Database.SetOnline() method to resume the database.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to bring online.

    .PARAMETER DatabaseObject
        Specifies the database object to bring online (from Get-SqlDscDatabase).

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        trying to get the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

        This parameter is only used when resuming a database using **ServerObject** and
        **Name** parameters.

    .PARAMETER Force
        Specifies that the database should be brought online without any confirmation.

    .PARAMETER PassThru
        Specifies that the database object should be returned after the operation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Resume-SqlDscDatabase -ServerObject $serverObject -Name 'MyDatabase'

        Brings the database named **MyDatabase** back online.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Resume-SqlDscDatabase -DatabaseObject $databaseObject -Force

        Brings the database online using a database object without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Resume-SqlDscDatabase -ServerObject $serverObject -Name 'MyDatabase' -PassThru

        Brings the database online and returns the updated database object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscDatabase -Name 'MyDatabase' | Resume-SqlDscDatabase -Force

        Brings the database online using pipeline input without prompting for confirmation.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        The server object from Connect-SqlDscDatabaseEngine.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Database`

        The database object to bring online (from Get-SqlDscDatabase).

    .OUTPUTS
        None.

        By default, no output is returned.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Database`

        When PassThru is specified, the updated database object is returned.
#>
function Resume-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues.')]
    [OutputType()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(DefaultParameterSetName = 'ServerObjectSet', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true, ValueFromPipeline = $true)]
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

        $descriptionMessage = $script:localizedData.Database_Resume_ShouldProcessVerboseDescription -f $sqlDatabaseObject.Name, $sqlDatabaseObject.Parent.InstanceName
        $confirmationMessage = $script:localizedData.Database_Resume_ShouldProcessVerboseWarning -f $sqlDatabaseObject.Name
        $captionMessage = $script:localizedData.Database_Resume_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            <#
                Refresh the database object to get the current status if using DatabaseObject
                and if Refresh was specified. If ServerObject and Name parameters are used, the
                database object is already fresh as Refresh was passed to Get-SqlDscDatabase.
            #>
            if ($PSCmdlet.ParameterSetName -eq 'DatabaseObjectSet' -and $Refresh.IsPresent)
            {
                $sqlDatabaseObject.Refresh()
            }

            # Check if database has a status other than offline (idempotence)
            if (-not $sqlDatabaseObject.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline))
            {
                Write-Debug -Message ($script:localizedData.Database_AlreadyOnline -f $sqlDatabaseObject.Name, ($sqlDatabaseObject.Status -join ', '))
            }
            else
            {
                Write-Debug -Message ($script:localizedData.Database_BringingOnline -f $sqlDatabaseObject.Name)

                try
                {
                    $sqlDatabaseObject.SetOnline()
                }
                catch
                {
                    $errorMessage = $script:localizedData.Database_ResumeFailed -f $sqlDatabaseObject.Name

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'RSDD0001', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $sqlDatabaseObject
                        )
                    )
                }

                Write-Debug -Message ($script:localizedData.Database_BroughtOnline -f $sqlDatabaseObject.Name)
            }

            if ($PassThru.IsPresent)
            {
                # Refresh the database object to get the updated Status property
                $sqlDatabaseObject.Refresh()

                $sqlDatabaseObject
            }
        }
    }
}
