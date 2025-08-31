<#
    .SYNOPSIS
        Sets properties of a database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command sets properties of a database in a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseObject
        Specifies a database object to modify.

    .PARAMETER Name
        Specifies the name of the database to be modified.

    .PARAMETER Collation
        The name of the SQL collation to set for the database.

    .PARAMETER CompatibilityLevel
        The version of the SQL compatibility level to set for the database.

    .PARAMETER RecoveryModel
        The recovery model to be set for the database.

    .PARAMETER OwnerName
        Specifies the name of the login that should be the owner of the database.

    .PARAMETER Force
        Specifies that the database should be modified without any confirmation.

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
        $databaseObject | Set-SqlDscDatabase -RecoveryModel 'Simple'

        Sets the recovery model of the database named **MyDatabase** to **Simple**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Set-SqlDscDatabase -Name 'MyDatabase' -OwnerName 'sa' -Force

        Sets the owner of the database named **MyDatabase** to **sa** without prompting for confirmation.

    .OUTPUTS
        None. But when **PassThru** is specified the output is `[Microsoft.SqlServer.Management.Smo.Database]`.
#>
function Set-SqlDscDatabase
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
        $Collation,

        [Parameter()]
        [ValidateSet('Version80', 'Version90', 'Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150', 'Version160')]
        [System.String]
        $CompatibilityLevel,

        [Parameter()]
        [ValidateSet('Simple', 'Full', 'BulkLogged')]
        [System.String]
        $RecoveryModel,

        [Parameter()]
        [System.String]
        $OwnerName,

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

    begin
    {
         }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            if ($Refresh.IsPresent)
            {
                # Refresh the server object's databases collection
                $ServerObject.Databases.Refresh()
            }

            Write-Verbose -Message ($script:localizedData.Database_Set -f $Name, $ServerObject.InstanceName)

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
            Write-Verbose -Message ($script:localizedData.Database_Set -f $Name, $ServerObject.InstanceName)
        }

        # Validate compatibility level if specified
        if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
        {
            $supportedCompatibilityLevels = @{
                8  = @('Version80')
                9  = @('Version80', 'Version90')
                10 = @('Version80', 'Version90', 'Version100')
                11 = @('Version90', 'Version100', 'Version110')
                12 = @('Version100', 'Version110', 'Version120')
                13 = @('Version100', 'Version110', 'Version120', 'Version130')
                14 = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140')
                15 = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150')
                16 = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150', 'Version160')
            }

            if ($CompatibilityLevel -notin $supportedCompatibilityLevels.$($ServerObject.VersionMajor))
            {
                $errorMessage = $script:localizedData.Database_InvalidCompatibilityLevel -f $CompatibilityLevel, $ServerObject.InstanceName
                New-ObjectNotFoundException -Message $errorMessage
            }
        }

        # Validate collation if specified
        if ($PSBoundParameters.ContainsKey('Collation'))
        {
            if ($Collation -notin $ServerObject.EnumCollations().Name)
            {
                $errorMessage = $script:localizedData.Database_InvalidCollation -f $Collation, $ServerObject.InstanceName
                New-ObjectNotFoundException -Message $errorMessage
            }
        }

        $verboseDescriptionMessage = $script:localizedData.Database_Set_ShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.Database_Set_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.Database_Set_ShouldProcessCaption

        if ($Force.IsPresent -or $PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                $wasUpdate = $false

                if ($PSBoundParameters.ContainsKey('Collation'))
                {
                    Write-Verbose -Message ($script:localizedData.Database_UpdatingCollation -f $Collation)
                    $DatabaseObject.Collation = $Collation
                    $wasUpdate = $true
                }

                if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
                {
                    Write-Verbose -Message ($script:localizedData.Database_UpdatingCompatibilityLevel -f $CompatibilityLevel)
                    $DatabaseObject.CompatibilityLevel = $CompatibilityLevel
                    $wasUpdate = $true
                }

                if ($PSBoundParameters.ContainsKey('RecoveryModel'))
                {
                    Write-Verbose -Message ($script:localizedData.Database_UpdatingRecoveryModel -f $RecoveryModel)
                    $DatabaseObject.RecoveryModel = $RecoveryModel
                    $wasUpdate = $true
                }

                if ($PSBoundParameters.ContainsKey('OwnerName'))
                {
                    Write-Verbose -Message ($script:localizedData.Database_UpdatingOwner -f $OwnerName)
                    $DatabaseObject.SetOwner($OwnerName)
                    $wasUpdate = $true
                }

                if ($wasUpdate)
                {
                    Write-Verbose -Message ($script:localizedData.Database_Updating -f $Name)
                    $DatabaseObject.Alter()
                    Write-Verbose -Message ($script:localizedData.Database_Updated -f $Name)
                }

                if ($PassThru.IsPresent)
                {
                    return $DatabaseObject
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.Database_SetFailed -f $Name, $ServerObject.InstanceName
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}
