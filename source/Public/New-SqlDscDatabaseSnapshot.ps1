<#
    .SYNOPSIS
        Creates a new database snapshot in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command creates a new database snapshot in a SQL Server Database Engine
        instance using SMO. It provides an automated and DSC-friendly approach to
        snapshot management by leveraging the existing `New-SqlDscDatabase` command
        for the actual creation.

    .PARAMETER ServerObject
        Specifies the current server connection object. This parameter is used in the
        ServerObject parameter set.

    .PARAMETER Name
        Specifies the name of the database snapshot to be created.

    .PARAMETER DatabaseName
        Specifies the name of the source database from which to create a snapshot.
        This parameter is used in the ServerObject parameter set.

    .PARAMETER DatabaseObject
        Specifies the source database object to snapshot. This parameter can be
        provided via pipeline and is used in the DatabaseObject parameter set.

    .PARAMETER FileGroup
        Specifies an array of DatabaseFileGroupSpec objects that define the file groups
        and data files for the database snapshot. Each DatabaseFileGroupSpec contains the
        file group name and an array of DatabaseFileSpec objects for the sparse files.
        When not specified, SQL Server will create sparse files in the default data
        directory with automatically generated names.

    .PARAMETER Force
        Specifies that the snapshot should be created without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        creating the snapshot. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscDatabaseSnapshot -Name 'MyDatabase_Snapshot' -DatabaseName 'MyDatabase'

        Creates a new database snapshot named **MyDatabase_Snapshot** from the source
        database **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        $databaseObject | New-SqlDscDatabaseSnapshot -Name 'MyDatabase_Snapshot' -Force

        Creates a new database snapshot named **MyDatabase_Snapshot** from the database
        object **MyDatabase** without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscDatabaseSnapshot -Name 'MyDB_Snap' -DatabaseName 'MyDatabase' -Force

        Creates a new database snapshot named **MyDB_Snap** from the source database
        **MyDatabase** without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $sourceDb = $serverObject.Databases['MyDatabase']

        $dataFile = New-SqlDscDataFile -Name 'MyDatabase_Data' -FileName 'C:\Snapshots\MyDatabase_Data.ss' -AsSpec
        $fileGroup = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($dataFile) -AsSpec

        $serverObject | New-SqlDscDatabaseSnapshot -Name 'MyDB_Snap' -DatabaseName 'MyDatabase' -FileGroup @($fileGroup) -Force

        Creates a new database snapshot named **MyDB_Snap** from the source database
        **MyDatabase** with a specified sparse file location without prompting for confirmation.

    .INPUTS
        `[Microsoft.SqlServer.Management.Smo.Server]`

        `[Microsoft.SqlServer.Management.Smo.Database]`

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Database]`

    .NOTES
        This command is for snapshot creation only and does not support modification
        of existing snapshots.

        Database snapshots are only supported in certain SQL Server editions (Enterprise,
        Developer, and Evaluation editions). The command will validate edition support
        before attempting to create the snapshot.
#>
function New-SqlDscDatabaseSnapshot
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in New-SqlDscDatabase')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [DatabaseFileGroupSpec[]]
        $FileGroup,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'ServerObject')]
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
        # Determine the server object and source database name based on parameter set
        if ($PSCmdlet.ParameterSetName -eq 'DatabaseObject')
        {
            $ServerObject = $DatabaseObject.Parent
            $DatabaseName = $DatabaseObject.Name
        }

        Write-Verbose -Message ($script:localizedData.DatabaseSnapshot_Create -f $Name, $DatabaseName, $ServerObject.InstanceName)

        # Validate SQL Server edition supports snapshots
        $supportedEditions = @('Enterprise', 'Developer', 'EnterpriseCore', 'EnterpriseOrDeveloper')

        if ($ServerObject.EngineEdition -notin @('Enterprise', 'EnterpriseEvaluation'))
        {
            # Check edition name for older servers or evaluation
            $editionName = $ServerObject.Edition

            $isSupported = $false

            foreach ($supportedEdition in $supportedEditions)
            {
                if ($editionName -like "*$supportedEdition*")
                {
                    $isSupported = $true
                    break
                }
            }

            # Also check for Evaluation edition
            if ($editionName -like '*Evaluation*')
            {
                $isSupported = $true
            }

            if (-not $isSupported)
            {
                $errorMessage = $script:localizedData.DatabaseSnapshot_EditionNotSupported -f $ServerObject.InstanceName, $editionName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'NSDS0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $ServerObject
                    )
                )
            }
        }

        # Create the snapshot using New-SqlDscDatabase
        $newSqlDscDatabaseParameters = @{
            ServerObject = $ServerObject
            Name = $Name
            DatabaseSnapshotBaseName = $DatabaseName
            Force = $Force
            WhatIf = $WhatIfPreference
        }

        if ($PSBoundParameters.ContainsKey('FileGroup'))
        {
            $newSqlDscDatabaseParameters['FileGroup'] = $FileGroup
        }

        if ($PSCmdlet.ParameterSetName -eq 'ServerObject' -and $Refresh.IsPresent)
        {
            $newSqlDscDatabaseParameters['Refresh'] = $true
        }

        $snapshotDatabaseObject = New-SqlDscDatabase @newSqlDscDatabaseParameters

        return $snapshotDatabaseObject
    }
}
