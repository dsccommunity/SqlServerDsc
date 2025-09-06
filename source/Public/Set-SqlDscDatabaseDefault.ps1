<#
    .SYNOPSIS
        Sets default objects of a database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command sets default objects of a database in a SQL Server Database Engine instance.
        It can set the default filegroup, default FILESTREAM filegroup, and default Full-Text catalog
        using SMO methods.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseObject
        Specifies a database object to modify.

    .PARAMETER Name
        Specifies the name of the database to be modified.

    .PARAMETER DefaultFileGroup
        Sets the default filegroup for the database. The filegroup must exist in the database.

    .PARAMETER DefaultFileStreamFileGroup
        Sets the default FILESTREAM filegroup for the database. The filegroup must exist in the database.

    .PARAMETER DefaultFullTextCatalog
        Sets the default Full-Text catalog for the database. The catalog must exist in the database.

    .PARAMETER Force
        Specifies that the database defaults should be modified without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        modifying the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough, or pass in **DatabaseObject**.

    .PARAMETER PassThru
        Specifies that the database object should be returned after modification.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        $databaseObject | Set-SqlDscDatabaseDefault -DefaultFileGroup 'MyFileGroup'

        Sets the default filegroup of the database named **MyDatabase** to **MyFileGroup**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Set-SqlDscDatabaseDefault -Name 'MyDatabase' -DefaultFullTextCatalog 'MyCatalog' -Force

        Sets the default Full-Text catalog of the database named **MyDatabase** to **MyCatalog** without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        $databaseObject | Set-SqlDscDatabaseDefault -DefaultFileGroup 'DataFileGroup' -DefaultFileStreamFileGroup 'FileStreamFileGroup' -DefaultFullTextCatalog 'FTCatalog'

        Sets multiple default objects for the database named **MyDatabase**.

    .OUTPUTS
        None. But when **PassThru** is specified the output is `[Microsoft.SqlServer.Management.Smo.Database]`.
#>
function Set-SqlDscDatabaseDefault
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'DatabaseObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultFileGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultFileStreamFileGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultFullTextCatalog,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'ServerObject')]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            if ($Refresh.IsPresent)
            {
                # Refresh the server object's databases collection
                $ServerObject.Databases.Refresh()
            }

            Write-Verbose -Message ($script:localizedData.DatabaseDefault_Set -f $Name, $ServerObject.InstanceName)

            # Get the database object
            $DatabaseObject = $ServerObject.Databases[$Name]

            if (-not $DatabaseObject)
            {
                $errorMessage = $script:localizedData.Database_NotFound -f $Name
                New-InvalidOperationException -Message $errorMessage
            }
        }
        else
        {
            $Name = $DatabaseObject.Name
            $ServerObject = $DatabaseObject.Parent
            Write-Verbose -Message ($script:localizedData.DatabaseDefault_Set -f $Name, $ServerObject.InstanceName)
        }

        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        try
        {
            $wasUpdate = $false

            if ($PSBoundParameters.ContainsKey('DefaultFileGroup'))
            {
                $descriptionMessage = $script:localizedData.DatabaseDefault_SetFileGroup_ShouldProcessVerboseDescription -f $Name, $DefaultFileGroup, $ServerObject.InstanceName
                $confirmationMessage = $script:localizedData.DatabaseDefault_SetFileGroup_ShouldProcessVerboseWarning -f $Name, $DefaultFileGroup
                $captionMessage = $script:localizedData.DatabaseDefault_SetFileGroup_ShouldProcessCaption

                if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
                {
                    Write-Verbose -Message ($script:localizedData.DatabaseDefault_UpdatingDefaultFileGroup -f $DefaultFileGroup)
                    $DatabaseObject.SetDefaultFileGroup($DefaultFileGroup)
                    $wasUpdate = $true
                }
            }

            if ($PSBoundParameters.ContainsKey('DefaultFileStreamFileGroup'))
            {
                $descriptionMessage = $script:localizedData.DatabaseDefault_SetFileStreamFileGroup_ShouldProcessVerboseDescription -f $Name, $DefaultFileStreamFileGroup, $ServerObject.InstanceName
                $confirmationMessage = $script:localizedData.DatabaseDefault_SetFileStreamFileGroup_ShouldProcessVerboseWarning -f $Name, $DefaultFileStreamFileGroup
                $captionMessage = $script:localizedData.DatabaseDefault_SetFileStreamFileGroup_ShouldProcessCaption

                if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
                {
                    Write-Verbose -Message ($script:localizedData.DatabaseDefault_UpdatingDefaultFileStreamFileGroup -f $DefaultFileStreamFileGroup)
                    $DatabaseObject.SetDefaultFileStreamFileGroup($DefaultFileStreamFileGroup)
                    $wasUpdate = $true
                }
            }

            if ($PSBoundParameters.ContainsKey('DefaultFullTextCatalog'))
            {
                $descriptionMessage = $script:localizedData.DatabaseDefault_SetFullTextCatalog_ShouldProcessVerboseDescription -f $Name, $DefaultFullTextCatalog, $ServerObject.InstanceName
                $confirmationMessage = $script:localizedData.DatabaseDefault_SetFullTextCatalog_ShouldProcessVerboseWarning -f $Name, $DefaultFullTextCatalog
                $captionMessage = $script:localizedData.DatabaseDefault_SetFullTextCatalog_ShouldProcessCaption

                if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
                {
                    Write-Verbose -Message ($script:localizedData.DatabaseDefault_UpdatingDefaultFullTextCatalog -f $DefaultFullTextCatalog)
                    $DatabaseObject.SetDefaultFullTextCatalog($DefaultFullTextCatalog)
                    $wasUpdate = $true
                }
            }

            if ($wasUpdate)
            {
                Write-Verbose -Message ($script:localizedData.DatabaseDefault_Updated -f $Name)
            }

            if ($PassThru.IsPresent)
            {
                return $DatabaseObject
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.DatabaseDefault_SetFailed -f $Name, $ServerObject.InstanceName

            $exception = [System.InvalidOperationException]::new($errorMessage, $_.Exception)

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'SSDDD0001', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Name
                )
            )
        }
    }
}
