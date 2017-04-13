Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

Import-SQLPSModule

enum Ensure
{
    Absent
    Exactly
    Present
}

[DscResource()]
class xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
{
    [DscProperty(Mandatory)]
    [string[]]
    $DatabaseName

    [DscProperty(Key)]
    [string]
    $SQLServer

    [DscProperty(Key)]
    [string]
    $SQLInstanceName

    [DscProperty(Key)]
    [string]
    $AvailabilityGroupName

    [DscProperty()]
    [string]
    $BackupPath

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [switch]
    $MatchDatabaseOwner = $true

    [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership] Get()
    {
        # Create an object that reflects the current configuration
        $currentConfiguration = New-Object xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
        $currentConfiguration.SQLServer = $this.SQLServer
        $currentConfiguration.SQLInstanceName = $this.SQLInstanceName
        
        # Connect to the instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the availabilty group object
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        if ( $availabilityGroup )
        {
            $currentConfiguration.AvailabilityGroupName = $this.AvailabilityGroupName
            
            # Get the databases in the availability group
            $currentConfiguration.DatabaseName = $availabilityGroup.AvailabilityDatabases | Select-Object -ExpandProperty Name
        }
        else
        {
            New-VerboseMessage -Message "The availabilty group '$($this.AvailabilityGroupName)' does not exist."

            $currentConfiguration.MatchDatabaseOwner = $false
        }

        return $currentConfiguration
    }

    [void] Set()
    {        
        # Connect to the defined instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the Availabilty Group if it exists
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        # Make sure we're communicating with the primary replica in order to make changes to the replica
        $primaryServerObject = $this.GetPrimaryReplicaServerObject($serverObject,$availabilityGroup)

        $databasesToAddToAvailabilityGroup = $this.GetDatabasesToAddToAvailabilityGroup($primaryServerObject,$availabilityGroup)
        $databasesToRemoveFromAvailabilityGroup = $this.GetDatabasesToRemoveFromAvailabilityGroup($primaryServerObject,$availabilityGroup)

        if ( $databasesToAddToAvailabilityGroup.Count -gt 0 )
        {
            # Ensure the appropriate permissions are in place on all the replicas
            if ( $this.MatchDatabaseOwner )
            {
                $impersonatePermissionsStatus = @{}

                foreach ( $availabilityGroupReplica in $availabilityGroup.AvailabilityReplicas )
                {
                    $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                    $impersonatePermissionsStatus.Add($availabilityGroupReplica.Name, $this.TestImpersonatePermissions($currentAvailabilityGroupReplicaServerObject))
                }

                if ( $impersonatePermissionsStatus.Values -contains $false )
                {
                    $newTerminatingErrorParams = @{
                        ErrorType = 'ImperstonatePermissionsMissing'
                        FormatArgs = @(
                            [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
                            ( ( $impersonatePermissionsStatus.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key ) -join ', ' )
                        )
                        ErrorCategory = 'SecurityError'
                    }
                    New-TerminatingError @newTerminatingErrorParams
                }
            }

            # Create a hash table to store the databases that failed to be added to the Availability Group
            $databasesToAddFailures = @{}
            
            foreach ( $databaseName in $databasesToAddToAvailabilityGroup )
            {
                $database = $primaryServerObject.Databases[$databaseName]

                # Verify the prerequisites prior to joining the database to the availability group
                # https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/prereqs-restrictions-recommendations-always-on-availability#a-nameprerequisitesfordbsa-availability-database-prerequisites-and-restrictions

                # Create a hash table to store prerequisite check failures
                $prerequisiteCheckFailures = @()

                $prerequisiteChecks = @{
                    RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full
                    ReadOnly = $false
                    UserAccess = [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Multiple
                    AutoClose = $false
                    AvailabilityGroupName = ''
                    IsMirroringEnabled = $false
                }
                
                foreach ( $prerequisiteCheck in $prerequisiteChecks.GetEnumerator() )
                {
                    if ( $database.($prerequisiteCheck.Key) -ne $prerequisiteCheck.Value )
                    {
                        $prerequisiteCheckFailures += "$($prerequisiteCheck.Key) is not $($prerequisiteCheck.Value)."
                    }
                }

                # Cannot be a system database
                if ( $database.ID -le 4 )
                {
                    $prerequisiteCheckFailures += 'The database cannot be a system database.'
                }

                # If FILESTREAM is enabled, ensure FILESTREAM is enabled on all replica instances
                if (
                    ( -not [string]::IsNullOrEmpty($database.DefaultFileStreamFileGroup) ) `
                    -or ( -not [string]::IsNullOrEmpty($database.FilestreamDirectoryName) ) `
                    -or ( $database.FilestreamNonTransactedAccess -ne [Microsoft.SqlServer.Management.Smo.FilestreamNonTransactedAccessType]::Off )
                )
                {
                    $availbilityReplicaFilestreamLevel = @{}
                    foreach ( $availabilityGroupReplica in $availabilityGroup.AvailabilityReplicas )
                    {
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                        $availbilityReplicaFilestreamLevel.Add($availabilityGroupReplica.Name, $currentAvailabilityGroupReplicaServerObject.FilestreamLevel)
                    }

                    if ( $availbilityReplicaFilestreamLevel.Values -contains [Microsoft.SqlServer.Management.Smo.FileStreamEffectiveLevel]::Off )
                    {
                        $prerequisiteCheckFailures += ( 'Filestream is disabled on the following instances: {0}' -f ( $availbilityReplicaFilestreamLevel.Keys -join ', ' ) )
                    }
                }

                # If the database is contained, ensure contained database authentication is enabled on all replica instances
                if ( $database.ContainmentType -ne [Microsoft.SqlServer.Management.Smo.ContainmentType]::None )
                {
                    $availbilityReplicaContainmentEnabled = @{}
                    foreach ( $availabilityGroupReplica in $availabilityGroup.AvailabilityReplicas )
                    {
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                        $availbilityReplicaContainmentEnabled.Add($availabilityGroupReplica.Name, $currentAvailabilityGroupReplicaServerObject.Configuration.ContainmentEnabled.ConfigValue)
                    }

                    if ( $availbilityReplicaContainmentEnabled.Values -contains 1 )
                    {
                        $prerequisiteCheckFailures += ( 'Contained Database Authentication is not enabled on the following instances: {0}' -f ( $availbilityReplicaContainmentEnabled.Keys -join ', ' ) )
                    }
                }

                # Ensure the data and log file paths exist on all replicas
                $databaseFileDirectories = @()
                $databaseFileDirectories += $database.FileGroups.Files.FileName | ForEach-Object { Split-Path -Path $_ -Parent } | Select-Object -Unique
                $databaseFileDirectories += $database.LogFiles.FileName | ForEach-Object { Split-Path -Path $_ -Parent } | Select-Object -Unique
                $databaseFileDirectories = $databaseFileDirectories | Select-Object -Unique

                $availabilityReplicaMissingDirectories = @{}
                foreach ( $availabilityGroupReplica in $availabilityGroup.AvailabilityReplicas )
                {
                    $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                    
                    $missingDirectories = @()
                    foreach ( $databaseFileDirectory in $databaseFileDirectories )
                    {
                        $fileExistsQuery = "EXEC master.dbo.xp_fileexist '$databaseFileDirectory'"
                        $fileExistsResult = Invoke-Query -SQLServer $currentAvailabilityGroupReplicaServerObject.NetName -SQLInstanceName $currentAvailabilityGroupReplicaServerObject.ServiceName -Database master -Query $fileExistsQuery -WithResults

                        if  ( $fileExistsResult.Tables.Rows.'File is a Directory' -ne 1 )
                        {
                            $missingDirectories += $databaseFileDirectory
                        }
                    }

                    if ( $missingDirectories.Count -gt 0 )
                    {
                        $availabilityReplicaMissingDirectories.Add($availabilityGroupReplica, ( $missingDirectories -join ', ' ))
                    }
                }

                # If the database is TDE'd, ensure the certificate or asymmetric key is installed on all replicas
                if ( $database.EncryptionEnabled )
                {
                    $databaseCertificateThumbprint = [System.BitConverter]::ToString($database.DatabaseEncryptionKey.Thumbprint)
                    $databaseCertificateName = $database.DatabaseEncryptionKey.EncryptorName

                    $availabilityReplicaMissingCertificates = @{}
                    foreach ( $availabilityGroupReplica in $availabilityGroup.AvailabilityReplicas )
                    {
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                        $installedCertificateThumbprints = $currentAvailabilityGroupReplicaServerObject.Databases['master'].Certificates | ForEach-Object { [System.BitConverter]::ToString($_.Thumbprint) }

                        if ( $installedCertificateThumbprints -notcontains $databaseCertificateThumbprint )
                        {
                            $availabilityReplicaMissingCertificates.Add($availabilityGroupReplica, $databaseCertificateName)
                        }
                    }
                }

                if ( $prerequisiteCheckFailures.Count -eq 0 )
                {
                    # If no full backup was ever taken, take one w/o copy only, otherwise do backups with copy-only

                    # Add database to each replica
                    Add-SqlAvailabilityDatabase
                }
                else
                {
                    $databasesToAddFailures.Add($databaseName, 'The following prerequisite checks failed:')
                }
            }
        }

        if ( $databasesToRemoveFromAvailabilityGroup.Count -gt 0 )
        {
            # Create a hash table to store the databases that failed to be added to the Availability Group
            $databasesToRemoveFailures = @{}
            
            foreach ( $databaseName in $databasesToRemoveFromAvailabilityGroup )
            {
                $availabilityDatabase = $primaryServerObject.AvailabilityGroups[$this.AvailabilityGroupName].AvailabilityDatabases[$databaseName]

                try
                {
                    Remove-SqlAvailabilityDatabase -InputObject $availabilityDatabase -ErrorAction Stop
                }
                catch
                {
                    $databasesToRemoveFailures.Add($databaseName, 'Failed to remove the database from the availability group.')
                }
            }
        }

        # Combine the failures into one error message and throw it here. Doing this will allow all the databases that can be processes to be processed and will still show that applying the configuration failed
        $databasesToAddFailures
        $databasesToRemoveFailures
    }

    [bool] Test()
    {
        $configurationInDesiredState = $true
        $currentConfiguration = $this.Get()

        # Connect to the defined instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the Availabilty Group if it exists
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        # Make sure we're communicating with the primary replica in order to make changes to the replica
        $primaryServerObject = $this.GetPrimaryReplicaServerObject($serverObject,$availabilityGroup)

        $matchingDatabaseNames = $this.GetMatchingDatabaseNames($primaryServerObject)
        $databasesNotFoundOnTheInstance = @()

        if ( ( @( [Ensure]::Present,[Ensure]::Exactly ) -contains $this.Ensure ) -and $matchingDatabaseNames.Count -eq 0 )
        {
            $configurationInDesiredState = $false
            New-VerboseMessage -Message ( 'No databases found that match the name(s): {0}' -f ($this.DatabaseName -join ', ') )
        }
        else
        {
            $databasesNotFoundOnTheInstance = $this.GetDatabaseNamesNotFoundOnTheInstance($matchingDatabaseNames)

            # If the databases specified are not present on the instance and the desired state is not Absent
            if ( ( $databasesNotFoundOnTheInstance.Count -gt 0 ) -and ( $this.Ensure -ne [Ensure]::Absent ) )
            {
                $configurationInDesiredState = $false
                New-VerboseMessage -Message ( "The following databases were not found in the instance: {0}" -f ( $databasesNotFoundOnTheInstance -join ', ' ) )
            }

            $databasesToAddToAvailabilityGroup = $this.GetDatabasesToAddToAvailabilityGroup($primaryServerObject,$availabilityGroup)

            if ( $databasesToAddToAvailabilityGroup.Count -gt 0 )
            {
                $configurationInDesiredState = $false
                New-VerboseMessage -Message ( "The following databases should be a member of the availability group '{0}': {1}" -f $this.AvailabilityGroupName,( $databasesToAddToAvailabilityGroup -join ', ' ) )
            }

            $databasesToRemoveFromAvailabilityGroup = $this.GetDatabasesToRemoveFromAvailabilityGroup($primaryServerObject,$availabilityGroup)

            if ( $databasesToRemoveFromAvailabilityGroup.Count -gt 0 )
            {
                $configurationInDesiredState = $false
                New-VerboseMessage -Message ( "The following databases should not be a member of the availability group '{0}': {1}" -f $this.AvailabilityGroupName,( $databasesToRemoveFromAvailabilityGroup -join ', ' ) )
            }
        }

        return $configurationInDesiredState
    }

    [string[]] GetDatabasesToAddToAvailabilityGroup (
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
        $AvailabilityGroup
    )
    {
        $matchingDatabaseNames = $this.GetMatchingDatabaseNames($ServerObject)
        $databasesInAvailabilityGroup = $AvailabilityGroup.AvailabilityDatabases | Select-Object -ExpandProperty Name

        $comparisonResult = Compare-Object -ReferenceObject $matchingDatabaseNames -DifferenceObject $databasesInAvailabilityGroup
        $databasesToAddToAvailabilityGroup = @()

        if ( @([Ensure]::Present,[Ensure]::Exactly) -contains $this.Ensure )
        {
            $databasesToAddToAvailabilityGroup = $comparisonResult | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
        }

        return $databasesToAddToAvailabilityGroup
    }

    [string[]] GetDatabasesToRemoveFromAvailabilityGroup (
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
        $AvailabilityGroup
    )
    {
        $matchingDatabaseNames = $this.GetMatchingDatabaseNames($ServerObject)
        $databasesInAvailabilityGroup = $AvailabilityGroup.AvailabilityDatabases | Select-Object -ExpandProperty Name

        $comparisonResult = Compare-Object -ReferenceObject $matchingDatabaseNames -DifferenceObject $databasesInAvailabilityGroup -IncludeEqual
        $databasesToRemoveFromAvailabilityGroup = @()

        if ( [Ensure]::Absent -eq $this.Ensure )
        {
            $databasesToRemoveFromAvailabilityGroup = $comparisonResult | Where-Object { '==' -eq $_.SideIndicator } | Select-Object -ExpandProperty InputObject
        }
        elseif ( [Ensure]::Exactly -eq $this.Ensure )
        {
            $databasesToRemoveFromAvailabilityGroup = $comparisonResult | Where-Object { '=>' -eq $_.SideIndicator } | Select-Object -ExpandProperty InputObject
        }
    
        return $databasesToRemoveFromAvailabilityGroup
    }
    
    [string[]] GetMatchingDatabaseNames (
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )
    {
        $matchingDatabaseNames = @()

        foreach ( $dbName in $this.DatabaseName )
        {
            $matchingDatabaseNames += $ServerObject.Databases | Where-Object { $_.Name -like $dbName } | Select-Object -ExpandProperty Name
        }      

        return $matchingDatabaseNames
    }

    [string[]] GetDatabaseNamesNotFoundOnTheInstance (
        [string[]]
        $MatchingDatabaseNames
    )
    {
        $databasesNotFoundOnTheInstance = @{}
        foreach ( $dbName in $this.DatabaseName )
        {
            # Assume the database name was not found
            $databaseNameNotFound = $true

            foreach ( $matchingDatabaseName in $matchingDatabaseNames )
            {
                if ( $matchingDatabaseName -like $dbName )
                {
                    # If we found the database name, it's not missing
                    $databaseNameNotFound = $false
                }
            }

            $databasesNotFoundOnTheInstance.Add($dbName,$databaseNameNotFound)
        }

        $result = $databasesNotFoundOnTheInstance.GetEnumerator() | Where-Object { $_.Value } | Select-Object -ExpandProperty Key

        return $result
    }

    [Microsoft.SqlServer.Management.Smo.Server] GetPrimaryReplicaServerObject (
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,
        
        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
        $AvailabilityGroup
    )
    {
        $primaryReplicaServerObject = $serverObject
        
        # Determine if we're connected to the primary replica
        if ( ( $AvailabilityGroup.PrimaryReplicaServerName -ne $serverObject.DomainInstanceName ) -and ( -not [string]::IsNullOrEmpty($AvailabilityGroup.PrimaryReplicaServerName) ) )
        {
            $primaryReplicaServerObject = Connect-SQL -SQLServer $AvailabilityGroup.PrimaryReplicaServerName
        }

        return $primaryReplicaServerObject
    }

    [bool] TestImpersonatePermissions (
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )
    {
        $testLoginEffectivePermissionsParams = @{
            SQLServer = $ServerObject.ComputerNamePhysicalNetBIOS
            SQLInstanceName = $ServerObject.ServiceName
            LoginName = $ServerObject.ConnectionContext.TrueLogin
            Permissions = @('IMPERSONATE ANY LOGIN')
        }
        
        $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

        if ( -not $impersonatePermissionsPresent )
        {
            New-VerboseMessage -Message ( 'The login "{0}" does not have impersonate permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName )
        }

        return $impersonatePermissionsPresent
    }
}
