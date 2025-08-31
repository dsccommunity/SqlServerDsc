<#
    .SYNOPSIS
        Creates a new database in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command creates a new database in a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to be created.

    .PARAMETER Collation
        The name of the SQL collation to use for the new database.
        Default value is server collation.

    .PARAMETER CompatibilityLevel
        The version of the SQL compatibility level to use for the new database.
        Default value is server version.

    .PARAMETER RecoveryModel
        The recovery model to be used for the new database.
        Default value is Full.

    .PARAMETER OwnerName
        Specifies the name of the login that should be the owner of the database.

    .PARAMETER Force
        Specifies that the database should be created without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        creating the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscDatabase -Name 'MyDatabase'

        Creates a new database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscDatabase -Name 'MyDatabase' -Collation 'SQL_Latin1_General_Pref_CP850_CI_AS' -RecoveryModel 'Simple' -Force

        Creates a new database named **MyDatabase** with the specified collation and recovery model
        without prompting for confirmation.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Database]`
#>
function New-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
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

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
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
        if ($Refresh.IsPresent)
        {
            # Refresh the server object's databases collection
            $ServerObject.Databases.Refresh()
        }

        Write-Verbose -Message ($script:localizedData.Database_Create -f $Name, $ServerObject.InstanceName)

        # Check if the database already exists
        if ($ServerObject.Databases[$Name])
        {
            $errorMessage = $script:localizedData.Database_AlreadyExists -f $Name, $ServerObject.InstanceName
            New-InvalidOperationException -Message $errorMessage
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
                New-InvalidArgumentException -ArgumentName 'CompatibilityLevel' -Message $errorMessage
            }
        }

        # Validate collation if specified
        if ($PSBoundParameters.ContainsKey('Collation'))
        {
            if ($Collation -notin $ServerObject.EnumCollations().Name)
            {
                $errorMessage = $script:localizedData.Database_InvalidCollation -f $Collation, $ServerObject.InstanceName
                New-InvalidArgumentException -ArgumentName 'Collation' -Message $errorMessage
            }
        }

        $verboseDescriptionMessage = $script:localizedData.Database_Create_ShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.Database_Create_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.Database_Create_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                $sqlDatabaseObjectToCreate = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList $ServerObject, $Name

                if ($PSBoundParameters.ContainsKey('RecoveryModel'))
                {
                    $sqlDatabaseObjectToCreate.RecoveryModel = $RecoveryModel
                }

                if ($PSBoundParameters.ContainsKey('Collation'))
                {
                    $sqlDatabaseObjectToCreate.Collation = $Collation
                }

                if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
                {
                    $sqlDatabaseObjectToCreate.CompatibilityLevel = $CompatibilityLevel
                }

                Write-Verbose -Message ($script:localizedData.Database_Creating -f $Name)

                $sqlDatabaseObjectToCreate.Create()

                <#
                    This must be run after the object is created because
                    the owner property is read-only and the method cannot
                    be call until the object has been created.
                #>
                if ($PSBoundParameters.ContainsKey('OwnerName'))
                {
                    $sqlDatabaseObjectToCreate.SetOwner($OwnerName)
                }

                Write-Verbose -Message ($script:localizedData.Database_Created -f $Name)

                return $sqlDatabaseObjectToCreate
            }
            catch
            {
                $errorMessage = $script:localizedData.Database_CreateFailed -f $Name, $ServerObject.InstanceName
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}
