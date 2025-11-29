<#
    .SYNOPSIS
        Sets the default filegroup for a database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command sets the default filegroup or default FILESTREAM filegroup for a
        database in a SQL Server Database Engine instance.

        The filegroup must exist in the database. The command uses the SetDefaultFileGroup()
        or SetDefaultFileStreamFileGroup() methods on the SMO Database object to change
        the default filegroup.

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

        This parameter is only used when setting the default filegroup using **ServerObject**
        and **Name** parameters.

    .PARAMETER DefaultFileGroup
        Specifies the name of the filegroup that should be set as the default filegroup
        for the database. This is mutually exclusive with **DefaultFileStreamFileGroup**.

    .PARAMETER DefaultFileStreamFileGroup
        Specifies the name of the filegroup that should be set as the default FILESTREAM
        filegroup for the database. This is mutually exclusive with **DefaultFileGroup**.

    .PARAMETER Force
        Specifies that the default filegroup should be modified without any confirmation.

    .PARAMETER PassThru
        Specifies that the database object should be returned after modification.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseDefaultFileGroup -ServerObject $serverObject -Name 'MyDatabase' -DefaultFileGroup 'UserData'

        Sets the default filegroup of the database named **MyDatabase** to **UserData**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseDefaultFileGroup -ServerObject $serverObject -Name 'MyDatabase' -DefaultFileStreamFileGroup 'FileStreamData'

        Sets the default FILESTREAM filegroup of the database named **MyDatabase** to **FileStreamData**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $databaseObject -DefaultFileGroup 'UserData' -Force

        Sets the default filegroup of the database using a database object without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscDatabaseDefaultFileGroup -ServerObject $serverObject -Name 'MyDatabase' -DefaultFileGroup 'UserData' -PassThru

        Sets the default filegroup and returns the updated database object.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Database

        The database object to modify (from Get-SqlDscDatabase).

    .OUTPUTS
        None.

        When PassThru is specified the output is [Microsoft.SqlServer.Management.Smo.Database].
#>
function Set-SqlDscDatabaseDefaultFileGroup
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues.')]
    [OutputType()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(DefaultParameterSetName = 'ServerObjectSet', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectSetFileStream', Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ServerObjectSetFileStream', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'ServerObjectSet')]
        [Parameter(ParameterSetName = 'ServerObjectSetFileStream')]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter(ParameterSetName = 'DatabaseObjectSet', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'DatabaseObjectSetFileStream', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatabaseObjectSet', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultFileGroup,

        [Parameter(ParameterSetName = 'ServerObjectSetFileStream', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatabaseObjectSetFileStream', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultFileStreamFileGroup,

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
        switch -Wildcard ($PSCmdlet.ParameterSetName)
        {
            'ServerObjectSet*'
            {
                $previousErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'

                $sqlDatabaseObject = $ServerObject |
                    Get-SqlDscDatabase -Name $Name -Refresh:$Refresh -ErrorAction 'Stop'

                $ErrorActionPreference = $previousErrorActionPreference
            }

            'DatabaseObjectSet*'
            {
                $sqlDatabaseObject = $DatabaseObject
            }
        }

        # Determine which filegroup type to set
        if ($PSBoundParameters.ContainsKey('DefaultFileGroup'))
        {
            $fileGroupName = $DefaultFileGroup
            $currentFileGroup = $sqlDatabaseObject.DefaultFileGroup
            $verboseDescriptionMessage = $script:localizedData.DatabaseDefaultFileGroup_Set_ShouldProcessVerboseDescription_DefaultFileGroup -f $sqlDatabaseObject.Name, $fileGroupName, $sqlDatabaseObject.Parent.InstanceName
            $verboseWarningMessage = $script:localizedData.DatabaseDefaultFileGroup_Set_ShouldProcessVerboseWarning_DefaultFileGroup -f $sqlDatabaseObject.Name, $fileGroupName
        }
        else
        {
            $fileGroupName = $DefaultFileStreamFileGroup
            $currentFileGroup = $sqlDatabaseObject.DefaultFileStreamFileGroup
            $verboseDescriptionMessage = $script:localizedData.DatabaseDefaultFileGroup_Set_ShouldProcessVerboseDescription_DefaultFileStreamFileGroup -f $sqlDatabaseObject.Name, $fileGroupName, $sqlDatabaseObject.Parent.InstanceName
            $verboseWarningMessage = $script:localizedData.DatabaseDefaultFileGroup_Set_ShouldProcessVerboseWarning_DefaultFileStreamFileGroup -f $sqlDatabaseObject.Name, $fileGroupName
        }

        $captionMessage = $script:localizedData.DatabaseDefaultFileGroup_Set_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Check if the default filegroup is already correct (idempotence)
            if ($currentFileGroup -eq $fileGroupName)
            {
                if ($PSBoundParameters.ContainsKey('DefaultFileGroup'))
                {
                    Write-Debug -Message ($script:localizedData.DatabaseDefaultFileGroup_AlreadyCorrect_DefaultFileGroup -f $sqlDatabaseObject.Name, $fileGroupName)
                }
                else
                {
                    Write-Debug -Message ($script:localizedData.DatabaseDefaultFileGroup_AlreadyCorrect_DefaultFileStreamFileGroup -f $sqlDatabaseObject.Name, $fileGroupName)
                }
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('DefaultFileGroup'))
                {
                    Write-Debug -Message ($script:localizedData.DatabaseDefaultFileGroup_Updating_DefaultFileGroup -f $sqlDatabaseObject.Name, $fileGroupName)
                }
                else
                {
                    Write-Debug -Message ($script:localizedData.DatabaseDefaultFileGroup_Updating_DefaultFileStreamFileGroup -f $sqlDatabaseObject.Name, $fileGroupName)
                }

                try
                {
                    if ($PSBoundParameters.ContainsKey('DefaultFileGroup'))
                    {
                        $sqlDatabaseObject.SetDefaultFileGroup($fileGroupName)
                    }
                    else
                    {
                        $sqlDatabaseObject.SetDefaultFileStreamFileGroup($fileGroupName)
                    }
                }
                catch
                {
                    if ($PSBoundParameters.ContainsKey('DefaultFileGroup'))
                    {
                        $errorMessage = $script:localizedData.DatabaseDefaultFileGroup_SetFailed_DefaultFileGroup -f $sqlDatabaseObject.Name, $fileGroupName
                    }
                    else
                    {
                        $errorMessage = $script:localizedData.DatabaseDefaultFileGroup_SetFailed_DefaultFileStreamFileGroup -f $sqlDatabaseObject.Name, $fileGroupName
                    }

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'SSDDFG0004', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $sqlDatabaseObject
                        )
                    )
                }

                if ($PSBoundParameters.ContainsKey('DefaultFileGroup'))
                {
                    Write-Debug -Message ($script:localizedData.DatabaseDefaultFileGroup_Updated_DefaultFileGroup -f $sqlDatabaseObject.Name, $fileGroupName)
                }
                else
                {
                    Write-Debug -Message ($script:localizedData.DatabaseDefaultFileGroup_Updated_DefaultFileStreamFileGroup -f $sqlDatabaseObject.Name, $fileGroupName)
                }
            }

            <#
                Refresh the database object to get the updated default filegroup property if:
                - PassThru is specified (user wants the updated object back)
                - Using DatabaseObject parameter set (user's object reference should be updated)

                Refresh even if no change was made to ensure the object is up to date.
            #>
            if ($PassThru.IsPresent -or $PSCmdlet.ParameterSetName -match 'DatabaseObjectSet')
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
