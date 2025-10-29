<#
    .SYNOPSIS
        Sets the owner of a database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command sets the owner of a database in a SQL Server Database Engine instance.

        The owner must be a valid login on the SQL Server instance. The command uses
        the SetOwner() method on the SMO Database object to change the ownership.

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

        This parameter is only used when setting owner using **ServerObject** and
        **Name** parameters.

    .PARAMETER OwnerName
        Specifies the name of the login that should be the owner of the database.

    .PARAMETER DropExistingUser
        Specifies whether to drop any existing database users mapped to the specified
        login before changing the owner. This is required if a non-dbo user account
        already exists for the login being set as the new owner.

    .PARAMETER Force
        Specifies that the database owner should be modified without any confirmation.

    .PARAMETER PassThru
        Specifies that the database object should be returned after modification.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseOwner -ServerObject $serverObject -Name 'MyDatabase' -OwnerName 'sa'

        Sets the owner of the database named **MyDatabase** to **sa**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseOwner -ServerObject $serverObject -Name 'MyDatabase' -OwnerName 'sa' -DropExistingUser

        Sets the owner of the database named **MyDatabase** to **sa**, dropping any existing
        user account mapped to the **sa** login before changing the owner.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Set-SqlDscDatabaseOwner -DatabaseObject $databaseObject -OwnerName 'DOMAIN\SqlAdmin' -Force

        Sets the owner of the database using a database object without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseOwner -ServerObject $serverObject -Name 'MyDatabase' -OwnerName 'sa' -PassThru

        Sets the owner and returns the updated database object.

    .INPUTS
        `[Microsoft.SqlServer.Management.Smo.Database]`

        The database object to modify (from Get-SqlDscDatabase).

    .OUTPUTS
        None. But when **PassThru** is specified the output is `[Microsoft.SqlServer.Management.Smo.Database]`.
#>
function Set-SqlDscDatabaseOwner
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
        $OwnerName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $DropExistingUser,

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

        $verboseDescriptionMessage = $script:localizedData.DatabaseOwner_Set_ShouldProcessVerboseDescription -f $sqlDatabaseObject.Name, $OwnerName, $sqlDatabaseObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.DatabaseOwner_Set_ShouldProcessVerboseWarning -f $sqlDatabaseObject.Name, $OwnerName
        $captionMessage = $script:localizedData.DatabaseOwner_Set_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Check if the owner is already correct (idempotence)
            if ($sqlDatabaseObject.Owner -eq $OwnerName)
            {
                Write-Debug -Message ($script:localizedData.DatabaseOwner_OwnerAlreadyCorrect -f $sqlDatabaseObject.Name, $OwnerName)
            }
            else
            {
                Write-Debug -Message ($script:localizedData.DatabaseOwner_Updating -f $sqlDatabaseObject.Name, $OwnerName)

                try
                {
                    if ($DropExistingUser.IsPresent)
                    {
                        $sqlDatabaseObject.SetOwner($OwnerName, $true)
                    }
                    else
                    {
                        $sqlDatabaseObject.SetOwner($OwnerName)
                    }

                    $sqlDatabaseObject.Alter()
                }
                catch
                {
                    $errorMessage = $script:localizedData.DatabaseOwner_SetFailed -f $sqlDatabaseObject.Name, $OwnerName

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'SSDDO0001', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $sqlDatabaseObject
                        )
                    )
                }

                Write-Debug -Message ($script:localizedData.DatabaseOwner_Updated -f $sqlDatabaseObject.Name, $OwnerName)
            }

            <#
                Refresh the database object to get the updated owner property if:
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
