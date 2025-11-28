<#
    .SYNOPSIS
        Sets the default full-text catalog for a database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command sets the default full-text catalog for a database in a SQL Server
        Database Engine instance. The catalog name must be a valid full-text catalog
        that exists in the database. The command uses the SetDefaultFullTextCatalog()
        method on the SMO Database object to set the default catalog.

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

        This parameter is only used when setting the default full-text catalog using
        **ServerObject** and **Name** parameters.

    .PARAMETER CatalogName
        Specifies the name of the full-text catalog to set as the default for the database.

    .PARAMETER Force
        Specifies that the default full-text catalog should be modified without any confirmation.

    .PARAMETER PassThru
        Specifies that the database object should be returned after modification.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $serverObject -Name 'MyDatabase' -CatalogName 'MyCatalog'

        Sets the default full-text catalog of the database named **MyDatabase** to **MyCatalog**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Set-SqlDscDatabaseDefaultFullTextCatalog -DatabaseObject $databaseObject -CatalogName 'MyCatalog' -Force

        Sets the default full-text catalog using a database object without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $serverObject -Name 'MyDatabase' -CatalogName 'MyCatalog' -PassThru

        Sets the default full-text catalog and returns the updated database object.

    .EXAMPLE
        $databaseObject | Set-SqlDscDatabaseDefaultFullTextCatalog -CatalogName 'MyCatalog'

        Sets the default full-text catalog using pipeline input.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Database

        The database object to modify (from Get-SqlDscDatabase).

    .OUTPUTS
        None.

        When PassThru is specified the output is [Microsoft.SqlServer.Management.Smo.Database].
#>
function Set-SqlDscDatabaseDefaultFullTextCatalog
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $CatalogName,

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

        $verboseDescriptionMessage = $script:localizedData.DatabaseDefaultFullTextCatalog_Set_ShouldProcessVerboseDescription -f $sqlDatabaseObject.Name, $CatalogName, $sqlDatabaseObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.DatabaseDefaultFullTextCatalog_Set_ShouldProcessVerboseWarning -f $sqlDatabaseObject.Name, $CatalogName
        $captionMessage = $script:localizedData.DatabaseDefaultFullTextCatalog_Set_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Check if the default full-text catalog is already correct (idempotence)
            if ($sqlDatabaseObject.DefaultFullTextCatalog -eq $CatalogName)
            {
                Write-Debug -Message ($script:localizedData.DatabaseDefaultFullTextCatalog_AlreadyCorrect -f $sqlDatabaseObject.Name, $CatalogName)
            }
            else
            {
                Write-Debug -Message ($script:localizedData.DatabaseDefaultFullTextCatalog_Updating -f $sqlDatabaseObject.Name, $CatalogName)

                try
                {
                    $sqlDatabaseObject.SetDefaultFullTextCatalog($CatalogName)
                }
                catch
                {
                    $errorMessage = $script:localizedData.DatabaseDefaultFullTextCatalog_SetFailed -f $sqlDatabaseObject.Name, $CatalogName

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'SSDDF0004', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $sqlDatabaseObject
                        )
                    )
                }

                Write-Debug -Message ($script:localizedData.DatabaseDefaultFullTextCatalog_Updated -f $sqlDatabaseObject.Name, $CatalogName)
            }

            <#
                Refresh the database object to get the updated DefaultFullTextCatalog property if:
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
