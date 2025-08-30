<#
    .SYNOPSIS
        Automated unit test for DSC_SqlAGDatabase DSC resource.

#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlAGDatabase'

    $env:SqlServerDscCI = $true

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    # Load the default SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

    # Mock Windows identity function at module level for cross-platform testing
    Mock -CommandName Get-CurrentWindowsIdentityName -MockWith { return 'NT AUTHORITY\SYSTEM' } -ModuleName $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlAGDatabase\Get-TargetResource' {
            BeforeAll {
                #region Parameter Mocks

                # The databases defined in the resource
                $mockDatabaseNameParameter = @(
                    'DB*'
                    'AnotherDB'
                    '3rd*OfDatabase'
                    '4th*OfDatabase'
                )

                $mockDatabaseNameParameterWithNonExistingDatabases = @(
                    'NotFound*'
                    'Unknown1'
                )

                $mockBackupPath = 'X:\Backup'

                $mockProcessOnlyOnActiveNode = $false

                #endregion Parameter Mocks

                #region mock names

                $mockServerObjectDomainInstanceName = 'Server1'
                $mockPrimaryServerObjectDomainInstanceName = 'Server2'
                $mockAvailabilityGroupObjectName = 'AvailabilityGroup1'
                $mockAvailabilityGroupWithoutDatabasesObjectName = 'AvailabilityGroupWithoutDatabases'
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName = 'AvailabilityGroup2'
                $mockTrueLogin = 'Login1'
                $mockDatabaseOwner = 'DatabaseOwner1'
                $mockReplicaSeedingMode = 'Manual'
                #endregion mock names

                #region Availability Replica Mocks

                $mockAvailabilityReplicaObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
                foreach ( $mockAvailabilityReplicaName in @('Server1','Server2') )
                {
                    $newAvailabilityReplicaObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                    $newAvailabilityReplicaObject.Name = $mockAvailabilityReplicaName
                    $newAvailabilityReplicaObject.SeedingMode = 'Manual'

                    if ( $mockServerObjectDomainInstanceName -eq $mockAvailabilityReplicaName )
                    {
                        $newAvailabilityReplicaObject.Role = 'Primary'
                    }

                    $mockAvailabilityReplicaObjects.Add($newAvailabilityReplicaObject)
                }

                #endregion Availability Replica Mocks

                #region Availability Group Mocks

                $mockAvailabilityDatabaseNames = @(
                    'DB2'
                    '3rdTypeOfDatabase'
                    'UndefinedDatabase'
                )

                $mockAvailabilityDatabaseAbsentResults = @(
                    'DB2'
                    '3rdTypeOfDatabase'
                )

                $mockAvailabilityDatabaseExactlyAddResults = @(
                    'DB1'
                )

                $mockAvailabilityDatabaseExactlyRemoveResults = @(
                    'UndefinedDatabase'
                )

                $mockAvailabilityDatabasePresentResults = @(
                    'DB1'
                )

                $mockAvailabilityDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
                foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                {
                    $newAvailabilityDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
                    $newAvailabilityDatabaseObject.Name = $mockAvailabilityDatabaseName
                    $mockAvailabilityDatabaseObjects.Add($newAvailabilityDatabaseObject)
                }

                $mockBadAvailabilityGroupObject = New-Object -TypeName Object

                $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupObject.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
                $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupObjectName
                $mockAvailabilityGroupObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
                $mockAvailabilityGroupObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                $mockAvailabilityGroupWithoutDatabasesObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupWithoutDatabasesObject.Name = $mockAvailabilityGroupWithoutDatabasesObjectName
                $mockAvailabilityGroupWithoutDatabasesObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
                $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.PrimaryReplicaServerName = $mockPrimaryServerObjectDomainInstanceName
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                #endregion Availability Group Mocks

                #region Certificate Mocks

                [byte[]]$mockThumbprint1 = @(
                    83
                    121
                    115
                    116
                    101
                    109
                    46
                    84
                    101
                    120
                    116
                    46
                    85
                    84
                    70
                    56
                    69
                    110
                    99
                    111
                    100
                    105
                    110
                    103
                )

                [byte[]]$mockThumbprint2 = @(
                    83
                    121
                    115
                    23
                    101
                    109
                    46
                    84
                    101
                    120
                    116
                    85
                    85
                    84
                    70
                    56
                    69
                    23
                    99
                    111
                    100
                    105
                    110
                    103
                )

                $mockCertificateObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
                $mockCertificateObject1.Thumbprint = $mockThumbprint1

                $mockCertificateObject2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
                $mockCertificateObject2.Thumbprint = $mockThumbprint2

                $mockDatabaseEncryptionKeyObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseEncryptionKey
                $mockDatabaseEncryptionKeyObject.EncryptorName = 'TDE Cert'
                $mockDatabaseEncryptionKeyObject.Thumbprint = $mockThumbprint1

                #endregion Certificate Mocks

                #region Database File Mocks

                $mockDataFilePath = 'E:\SqlData'
                $mockLogFilePath = 'F:\SqlLog'
                $mockDataFilePathIncorrect = 'G:\SqlData'
                $mockLogFilePathIncorrect = 'H:\SqlData'

                #endregion Database File Mocks

                #region Database Mocks

                # The databases found on the instance
                $mockPresentDatabaseNames = @(
                    'DB1'
                    'DB2'
                    '3rdTypeOfDatabase'
                    'UndefinedDatabase'
                )

                $mockMasterDatabaseName = 'master'
                $mockMasterDatabaseObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                $mockMasterDatabaseObject1.Name = $mockMasterDatabaseName
                    $mockMasterDatabaseObject1.ServerInstance = $mockServerObjectDomainInstanceName
                $mockMasterDatabaseObject1.ID = 1
                $mockMasterDatabaseObject1.Certificates = @($mockCertificateObject1)
                $mockMasterDatabaseObject1.FileGroups = @{
                    Name = 'PRIMARY'
                    Files = @{
                        FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockMasterDatabaseName).mdf" ) )
                    }
                }
                $mockMasterDatabaseObject1.LogFiles = @{
                    FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockMasterDatabaseName).ldf" ) )
                }

                $mockDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
                {
                    $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                    $newDatabaseObject.Name = $mockPresentDatabaseName
                        $newDatabaseObject.ServerInstance = $mockServerObjectDomainInstanceName
                    $newDatabaseObject.FileGroups = @{
                        Name = 'PRIMARY'
                        Files = @{
                            FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockPresentDatabaseName).mdf" ) )
                        }
                    }
                    $newDatabaseObject.LogFiles = @{
                        FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockPresentDatabaseName).ldf" ) )
                    }
                    $newDatabaseObject.Owner = $mockDatabaseOwner

                    # Add the database object to the database collection
                    $mockDatabaseObjects.Add($newDatabaseObject)
                }
                $mockDatabaseObjects.Add($mockMasterDatabaseObject1)

                $mockDatabaseObjectsWithIncorrectFileNames = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
                {
                    $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                    $newDatabaseObject.Name = $mockPresentDatabaseName
                        $newDatabaseObject.ServerInstance = $mockServerObjectDomainInstanceName
                    $newDatabaseObject.FileGroups = @{
                        Name = 'PRIMARY'
                        Files = @{
                            FileName = ( [IO.Path]::Combine( $mockDataFilePathIncorrect, "$($mockPresentDatabaseName).mdf" ) )
                        }
                    }
                    $newDatabaseObject.LogFiles = @{
                        FileName = ( [IO.Path]::Combine( $mockLogFilePathIncorrect, "$($mockPresentDatabaseName).ldf" ) )
                    }
                    $newDatabaseObject.Owner = $mockDatabaseOwner

                    # Add the database object to the database collection
                    $mockDatabaseObjectsWithIncorrectFileNames.Add($newDatabaseObject)
                }

                #endregion Database Mocks

                #region Server mocks
                $mockBadServerObject = New-Object -TypeName Object

                $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServerObject.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
                $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
                $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
                $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
                $mockServerObject.ComputerNamePhysicalNetBIOS = $mockServerObjectDomainInstanceName
                $mockServerObject.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
                $mockServerObject.ConnectionContext.TrueLogin = $mockTrueLogin
                $mockServerObject.Databases = $mockDatabaseObjects
                $mockServerObject.DomainInstanceName = $mockServerObjectDomainInstanceName
                    $mockServerObject.ServerInstance = $mockServerObjectDomainInstanceName
                $mockServerObject.NetName = $mockServerObjectDomainInstanceName
                $mockServerObject.ServiceName = 'MSSQLSERVER'
                $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Primary'
                $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Primary'
                $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Secondary'

                $mockServer2Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServer2Object.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
                $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
                $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
                $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
                $mockServer2Object.ComputerNamePhysicalNetBIOS = $mockPrimaryServerObjectDomainInstanceName
                $mockServer2Object.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
                $mockServer2Object.ConnectionContext.TrueLogin = $mockTrueLogin
                $mockServer2Object.Databases = $mockDatabaseObjects
                $mockServer2Object.DomainInstanceName = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.ServerInstance = $mockPrimaryServerObjectDomainInstanceName
                $mockServer2Object.NetName = $mockPrimaryServerObjectDomainInstanceName
                $mockServer2Object.ServiceName = 'MSSQLSERVER'
                $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Secondary'
                $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Secondary'
                $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Primary'

                #endregion Server mocks

                #region Invoke Query Mock

                $mockResultInvokeQueryFileExist = {
                    return @{
                        Tables = @{
                            Rows = @{
                                'File is a Directory' = 1
                            }
                        }
                    }
                }

                $mockResultInvokeQueryFileNotExist = {
                    return @{
                        Tables = @{
                            Rows = @{
                                'File is a Directory' = 0
                            }
                        }
                    }
                }

                $mockInvokeQueryParameterRestoreDatabase = {
                    $Query -like 'RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY'
                }

                $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs = {
                    $Query -like 'EXECUTE AS LOGIN = *
RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY*
REVERT'
                }

                #endregion Invoke Query Mock


                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable
                Mock -CommandName Import-SqlDscPreferredModule -Verifiable
            }

            BeforeEach {
                $getTargetResourceParameters = @{
                    DatabaseName = $mockDatabaseNameParameter
                    ServerName = 'Server1'
                    InstanceName = 'MSSQLSERVER'
                    AvailabilityGroupName = 'AvailabilityGroup1'
                    BackupPath = $($mockBackupPath)
                }
            }

            Context 'When the Get-TargetResource function is called' {
                It 'Should not return an availability group name or availability databases when the availability group does not exist' {
                    $getTargetResourceParameters.AvailabilityGroupName = 'NonExistentAvailabilityGroup'

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                    $result.AvailabilityGroupName | Should -BeNullOrEmpty
                    $result.DatabaseName | Should -BeNullOrEmpty

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 0 -Scope It
                }

                It 'Should not return any databases if there are no databases in the availability group' {
                    $getTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupWithoutDatabasesObject.Name

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                    $result.AvailabilityGroupName | Should -Be $mockAvailabilityGroupWithoutDatabasesObject.Name
                    $result.DatabaseName | Should -BeNullOrEmpty

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 0 -Scope It
                }

                It 'Should return databases when there are databases in the availability group' {
                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                    $result.AvailabilityGroupName | Should -Be $mockAvailabilityGroupObject.Name

                    foreach ( $resultDatabaseName in $result.DatabaseName )
                    {
                        $mockAvailabilityDatabaseNames -contains $resultDatabaseName | Should -Be $true
                    }

                    foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                    {
                        $result.DatabaseName -contains $mockAvailabilityDatabaseName | Should -Be $true
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'SqlAGDatabase\Set-TargetResource' -Tag 'Set Manual' {
            Context 'Tests that was moved into its own context block to prevent intermittent fails (see issue #1532) - workaround until proper refactor with seeding on manual' {
                BeforeAll {
                    #region Parameter Mocks

                    # The databases defined in the resource
                    $mockDatabaseNameParameter = @(
                        'DB*'
                        'AnotherDB'
                        '3rd*OfDatabase'
                        '4th*OfDatabase'
                    )

                    $mockDatabaseNameParameterWithNonExistingDatabases = @(
                        'NotFound*'
                        'Unknown1'
                    )

                    $mockBackupPath = 'X:\Backup'

                    $mockProcessOnlyOnActiveNode = $false

                    #endregion Parameter Mocks

                    #region mock names

                    $mockServerObjectDomainInstanceName = 'Server1'
                    $mockPrimaryServerObjectDomainInstanceName = 'Server2'
                    $mockAvailabilityGroupObjectName = 'AvailabilityGroup1'
                    $mockAvailabilityGroupWithoutDatabasesObjectName = 'AvailabilityGroupWithoutDatabases'
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName = 'AvailabilityGroup2'
                    $mockTrueLogin = 'Login1'
                    $mockDatabaseOwner = 'DatabaseOwner1'
                    $mockReplicaSeedingMode = 'Manual'
                    #endregion mock names

                    #region Availability Replica Mocks

                    $mockAvailabilityReplicaObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
                    foreach ( $mockAvailabilityReplicaName in @('Server1','Server2') )
                    {
                        $newAvailabilityReplicaObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                        $newAvailabilityReplicaObject.Name = $mockAvailabilityReplicaName
                        $newAvailabilityReplicaObject.SeedingMode = 'Manual'

                        if ( $mockServerObjectDomainInstanceName -eq $mockAvailabilityReplicaName )
                        {
                            $newAvailabilityReplicaObject.Role = 'Primary'
                        }

                        $mockAvailabilityReplicaObjects.Add($newAvailabilityReplicaObject)
                    }

                    #endregion Availability Replica Mocks

                    #region Availability Group Mocks

                    $mockAvailabilityDatabaseNames = @(
                        'DB2'
                        '3rdTypeOfDatabase'
                        'UndefinedDatabase'
                    )

                    $mockAvailabilityDatabaseAbsentResults = @(
                        'DB2'
                        '3rdTypeOfDatabase'
                    )

                    $mockAvailabilityDatabaseExactlyAddResults = @(
                        'DB1'
                    )

                    $mockAvailabilityDatabaseExactlyRemoveResults = @(
                        'UndefinedDatabase'
                    )

                    $mockAvailabilityDatabasePresentResults = @(
                        'DB1'
                    )

                    $mockAvailabilityDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
                    foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                    {
                        $newAvailabilityDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
                        $newAvailabilityDatabaseObject.Name = $mockAvailabilityDatabaseName
                        $mockAvailabilityDatabaseObjects.Add($newAvailabilityDatabaseObject)
                    }

                    $mockBadAvailabilityGroupObject = New-Object -TypeName Object

                    $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroupObject.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
                    $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupObjectName
                    $mockAvailabilityGroupObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
                    $mockAvailabilityGroupObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                    $mockAvailabilityGroupWithoutDatabasesObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroupWithoutDatabasesObject.Name = $mockAvailabilityGroupWithoutDatabasesObjectName
                    $mockAvailabilityGroupWithoutDatabasesObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
                    $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.PrimaryReplicaServerName = $mockPrimaryServerObjectDomainInstanceName
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                    #endregion Availability Group Mocks

                    #region Certificate Mocks

                    [byte[]]$mockThumbprint1 = @(
                        83
                        121
                        115
                        116
                        101
                        109
                        46
                        84
                        101
                        120
                        116
                        46
                        85
                        84
                        70
                        56
                        69
                        110
                        99
                        111
                        100
                        105
                        110
                        103
                    )

                    [byte[]]$mockThumbprint2 = @(
                        83
                        121
                        115
                        23
                        101
                        109
                        46
                        84
                        101
                        120
                        116
                        85
                        85
                        84
                        70
                        56
                        69
                        23
                        99
                        111
                        100
                        105
                        110
                        103
                    )

                    $mockCertificateObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
                    $mockCertificateObject1.Thumbprint = $mockThumbprint1

                    $mockCertificateObject2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
                    $mockCertificateObject2.Thumbprint = $mockThumbprint2

                    $mockDatabaseEncryptionKeyObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseEncryptionKey
                    $mockDatabaseEncryptionKeyObject.EncryptorName = 'TDE Cert'
                    $mockDatabaseEncryptionKeyObject.Thumbprint = $mockThumbprint1

                    #endregion Certificate Mocks

                    #region Database File Mocks

                    $mockDataFilePath = 'E:\SqlData'
                    $mockLogFilePath = 'F:\SqlLog'
                    $mockDataFilePathIncorrect = 'G:\SqlData'
                    $mockLogFilePathIncorrect = 'H:\SqlData'

                    #endregion Database File Mocks

                    #region Database Mocks

                    # The databases found on the instance
                    $mockPresentDatabaseNames = @(
                        'DB1'
                        'DB2'
                        '3rdTypeOfDatabase'
                        'UndefinedDatabase'
                    )

                    $mockMasterDatabaseName = 'master'
                    $mockMasterDatabaseObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                    $mockMasterDatabaseObject1.Name = $mockMasterDatabaseName
                    $mockMasterDatabaseObject1.ServerInstance = $mockServerObjectDomainInstanceName
                    $mockMasterDatabaseObject1.ID = 1
                    $mockMasterDatabaseObject1.Certificates = @($mockCertificateObject1)
                    $mockMasterDatabaseObject1.FileGroups = @{
                        Name = 'PRIMARY'
                        Files = @{
                            FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockMasterDatabaseName).mdf" ) )
                        }
                    }
                    $mockMasterDatabaseObject1.LogFiles = @{
                        FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockMasterDatabaseName).ldf" ) )
                    }

                    $mockDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                    foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
                    {
                        $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                        $newDatabaseObject.Name = $mockPresentDatabaseName
                        $newDatabaseObject.ServerInstance = $mockServerObjectDomainInstanceName
                        $newDatabaseObject.FileGroups = @{
                            Name = 'PRIMARY'
                            Files = @{
                                FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockPresentDatabaseName).mdf" ) )
                            }
                        }
                        $newDatabaseObject.LogFiles = @{
                            FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockPresentDatabaseName).ldf" ) )
                        }
                        $newDatabaseObject.Owner = $mockDatabaseOwner

                        # Add the database object to the database collection
                        $mockDatabaseObjects.Add($newDatabaseObject)
                    }
                    $mockDatabaseObjects.Add($mockMasterDatabaseObject1)

                    $mockDatabaseObjectsWithIncorrectFileNames = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                    foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
                    {
                        $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                        $newDatabaseObject.Name = $mockPresentDatabaseName
                        $newDatabaseObject.ServerInstance = $mockServerObjectDomainInstanceName
                        $newDatabaseObject.FileGroups = @{
                            Name = 'PRIMARY'
                            Files = @{
                                FileName = ( [IO.Path]::Combine( $mockDataFilePathIncorrect, "$($mockPresentDatabaseName).mdf" ) )
                            }
                        }
                        $newDatabaseObject.LogFiles = @{
                            FileName = ( [IO.Path]::Combine( $mockLogFilePathIncorrect, "$($mockPresentDatabaseName).ldf" ) )
                        }
                        $newDatabaseObject.Owner = $mockDatabaseOwner

                        # Add the database object to the database collection
                        $mockDatabaseObjectsWithIncorrectFileNames.Add($newDatabaseObject)
                    }

                    #endregion Database Mocks

                    #region Server mocks
                    $mockBadServerObject = New-Object -TypeName Object

                    $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockServerObject.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
                    $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
                    $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
                    $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
                    $mockServerObject.ComputerNamePhysicalNetBIOS = $mockServerObjectDomainInstanceName
                    $mockServerObject.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
                    $mockServerObject.ConnectionContext.TrueLogin = $mockTrueLogin
                    $mockServerObject.Databases = $mockDatabaseObjects
                    $mockServerObject.DomainInstanceName = $mockServerObjectDomainInstanceName
                    $mockServerObject.ServerInstance = $mockServerObjectDomainInstanceName
                    $mockServerObject.NetName = $mockServerObjectDomainInstanceName
                    $mockServerObject.ServiceName = 'MSSQLSERVER'
                    $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Primary'
                    $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Primary'
                    $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Secondary'

                    $mockServer2Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockServer2Object.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
                    $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
                    $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
                    $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
                    $mockServer2Object.ComputerNamePhysicalNetBIOS = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
                    $mockServer2Object.ConnectionContext.TrueLogin = $mockTrueLogin
                    $mockServer2Object.Databases = $mockDatabaseObjects
                    $mockServer2Object.DomainInstanceName = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.ServerInstance = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.NetName = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.ServiceName = 'MSSQLSERVER'
                    $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Secondary'
                    $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Secondary'
                    $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Primary'

                    #endregion Server mocks

                    #region Invoke Query Mock

                    $mockResultInvokeQueryFileExist = {
                        return @{
                            Tables = @{
                                Rows = @{
                                    'File is a Directory' = 1
                                }
                            }
                        }
                    }

                    $mockResultInvokeQueryFileNotExist = {
                        return @{
                            Tables = @{
                                Rows = @{
                                    'File is a Directory' = 0
                                }
                            }
                        }
                    }

                    $mockInvokeQueryParameterRestoreDatabase = {
                        $Query -like 'RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY'
                    }

                    $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs = {
                        $Query -like 'EXECUTE AS LOGIN = *
RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY*
REVERT'
                    }

                    #endregion Invoke Query Mock


                    Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Mock -CommandName Import-SqlDscPreferredModule -Verifiable
                    Mock -CommandName Invoke-SqlDscQuery -Verifiable -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Mock -CommandName Invoke-SqlDscQuery -Verifiable -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Mock -CommandName Join-Path -MockWith { [IO.Path]::Combine($databaseMembershipClass.BackupPath,"$($database.Name)_Full_$(Get-Date -Format 'yyyyMMddhhmmss').bak") } -Verifiable -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Mock -CommandName Join-Path -MockWith { [IO.Path]::Combine($databaseMembershipClass.BackupPath,"$($database.Name)_Log_$(Get-Date -Format 'yyyyMMddhhmmss').trn") } -Verifiable -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Mock -CommandName Remove-Item -Verifiable
                    Mock -CommandName Get-CurrentWindowsIdentityName -MockWith { return 'DOMAIN\TestUser' } -Verifiable
                }

                BeforeEach {
                    $mockSetTargetResourceParameters = @{
                        DatabaseName = $($mockDatabaseNameParameter)
                        ServerName = $($mockServerObject.DomainInstanceName)
                        InstanceName = $('MSSQLSERVER')
                        AvailabilityGroupName = $($mockAvailabilityGroupObjectName)
                        BackupPath = $($mockBackupPath)
                        Ensure = 'Present'
                        Force = $false
                        MatchDatabaseOwner = $false
                        ReplaceExisting = $false
                    }

                    Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Mock -CommandName Backup-SqlDatabase -Verifiable -ParameterFilter { $BackupAction -eq 'Database' }
                    Mock -CommandName Backup-SqlDatabase -Verifiable -ParameterFilter { $BackupAction -eq 'Log'}
                    Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $ServerName -eq 'Server1' }
                    Mock -CommandName Connect-SQL -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $ServerName -eq 'Server2' }
                    Mock -CommandName Invoke-SqlDscQuery -MockWith $mockResultInvokeQueryFileExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Mock -CommandName Remove-SqlAvailabilityDatabase -Verifiable
                    Mock -CommandName Test-ImpersonatePermissions -MockWith { $true } -Verifiable
                    # Add a general Connect-SQL mock to catch any calls not covered by parameter filters
                    Mock -CommandName Connect-SQL -MockWith { return $mockServerObject }
                }

                Context 'When Ensure is Present' {
                    It 'Should add the specified databases to the availability group' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should add the specified databases to the availability group when the primary replica is on another server' {
                        $mockSetTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should not do anything if no databases were found to add' {
                        $mockSetTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 0 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 0 -Scope It
                    }

                    It 'Should add the specified databases to the availability group when "MatchDatabaseOwner" is $false' {
                        $mockSetTargetResourceParameters.MatchDatabaseOwner = $false

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 0 -Scope It
                    }

                    It 'Should add the specified databases to the availability group when "ReplaceExisting" is $true' {
                        $mockSetTargetResourceParameters.DatabaseName = 'DB1'
                        $mockSetTargetResourceParameters.ReplaceExisting = $true

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should throw the correct error when "MatchDatabaseOwner" is $true and the current login does not have impersonate permissions' {
                        Mock -CommandName Test-ImpersonatePermissions -MockWith { $false } -Verifiable

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "missing impersonate any login, control server, impersonate login, or control login permissions"

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    $prerequisiteChecks = @{
                        RecoveryModel = 'Full'
                        ReadOnly = $false
                        UserAccess = 'Multiple'
                        AutoClose = $false
                        AvailabilityGroupName = ''
                        IsMirroringEnabled = $false
                    }

                    foreach ( $prerequisiteCheck in $prerequisiteChecks.GetEnumerator() )
                    {
                        It "Should throw the correct error when the database property '$($prerequisiteCheck.Key)' is not '$($prerequisiteCheck.Value)'" {
                            $originalValue = $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key)
                            $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key) = $true

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: $($prerequisiteCheck.Key) is not $($prerequisiteCheck.Value)."

                            foreach ( $databaseProperty in $prerequisiteChecks.GetEnumerator() )
                            {
                                if ( $prerequisiteCheck.Key -eq $databaseProperty.Key )
                                {
                                    $mockServerObject.Databases['DB1'].($databaseProperty.Key) | Should -Not -Be ($databaseProperty.Value)
                                }
                                else
                                {
                                    $mockServerObject.Databases['DB1'].($databaseProperty.Key) | Should -Be ($databaseProperty.Value)
                                }
                            }

                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                            Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                            Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                            Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                            Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                            Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                            Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                            Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                                Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                            $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key) = $originalValue
                        }
                    }

                    It 'Should throw the correct error when the database property "ID" is less than "4"' {
                        $mockSetTargetResourceParameters.DatabaseName = @('master')

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'master' failed with the following errors: The following prerequisite checks failed: The database cannot be a system database."

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    $filestreamProperties = @{
                        DefaultFileStreamFileGroup = ''
                        FilestreamDirectoryName = ''
                        FilestreamNonTransactedAccess = 'Off'
                    }

                    foreach ( $filestreamProperty in $filestreamProperties.GetEnumerator() )
                    {
                        It "Should throw the correct error 'AlterAvailabilityGroupDatabaseMembershipFailure' when the database property '$($filestreamProperty.Key)' is not '$($filestreamProperty.Value)'" {
                            $originalValue = $mockServerObject.Databases['DB1'].($filestreamProperty.Key)
                            $mockServerObject.Databases['DB1'].($filestreamProperty.Key) = 'On'

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: Filestream is disabled on the following instances: Server2"

                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                            Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                            Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                            Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                            Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                            Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                            Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                            Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                                Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                            $mockServerObject.Databases['DB1'].($filestreamProperty.Key) = $originalValue
                        }
                    }

                    It 'Should throw the correct error when the database property "ContainmentType" is not "Partial"' {
                        $originalValue = $mockServerObject.Databases['DB1'].ContainmentType
                        $mockServerObject.Databases['DB1'].ContainmentType = 'Partial'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: Contained Database Authentication is not enabled on the following instances: "

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        $mockServerObject.Databases['DB1'].ContainmentType = $originalValue
                    }

                    It 'Should throw the correct error when the database file path does not exist on the secondary replica' {
                        Mock -CommandName Invoke-SqlDscQuery -MockWith $mockResultInvokeQueryFileNotExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        $originalValue = $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName
                        $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName = ( [IO.Path]::Combine( 'X:\', "DB1.mdf" ) )

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: The instance 'Server2' is missing the following directories: X:\, F:\SqlLog"

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName = $originalValue
                    }

                    It 'Should throw the correct error when the log file path does not exist on the secondary replica' {
                        Mock -CommandName Invoke-SqlDscQuery -MockWith $mockResultInvokeQueryFileNotExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        $originalValue = $mockServer2Object.Databases['DB1'].LogFiles.FileName
                        $mockServer2Object.Databases['DB1'].LogFiles.FileName = ( [IO.Path]::Combine( 'Y:\', "DB1.ldf" ) )

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: The following prerequisite checks failed: The instance ''Server2'' is missing the following directories: E:\SqlData, Y:\'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        $mockServer2Object.Databases['DB1'].LogFiles.FileName = $originalValue
                    }

                    It 'Should throw the correct error when TDE is enabled on the database but the certificate is not present on the replica instances' {
                        $mockServerObject.Databases['DB1'].EncryptionEnabled = $true
                        $mockServerObject.Databases['DB1'].DatabaseEncryptionKey = $mockDatabaseEncryptionKeyObject
                        $mockServer2Object.Databases['master'].Certificates = @($mockCertificateObject2)

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: The following prerequisite checks failed: The instance ''Server2'' is missing the following certificates: TDE Cert'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        $mockServerObject.Databases['DB1'].EncryptionEnabled = $false
                        $mockServerObject.Databases['DB1'].DatabaseEncryptionKey = $null
                        $mockServer2Object.Databases['master'].Certificates = @($mockCertificateObject1)
                    }

                    It 'Should add the specified databases to the availability group when the database has not been previously backed up' {
                        $mockServerObject.Databases['DB1'].LastBackupDate = 0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should throw the correct error when it fails to perform a full backup' {
                        Mock -CommandName Backup-SqlDatabase -MockWith { throw } -Verifiable -ParameterFilter { $BackupAction -eq 'Database' }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should throw the correct error when it fails to perform a log backup' {
                        Mock -CommandName Backup-SqlDatabase -MockWith { throw } -Verifiable -ParameterFilter { $BackupAction -eq 'Log' }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should throw the correct error when it fails to add the database to the primary replica' {
                        Mock -CommandName Add-SqlAvailabilityDatabase -MockWith { throw } -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should throw the correct error when it fails to add the database to the primary replica' {
                        Mock -CommandName Add-SqlAvailabilityDatabase -MockWith { throw } -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When Ensure is Present and Force is True' {
                    BeforeEach {
                        $mockSetTargetResourceParameters.Ensure = 'Present'
                        $mockSetTargetResourceParameters.Force = $true
                    }

                    It 'Should ensure the database membership of the availability group is exactly as specified' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    # Mock current availability databases.
                    $mockAvailabilityDatabaseNames_Set = @(
                        'DB2'
                        '3rdTypeOfDatabase'
                        'UndefinedDatabase'
                    )

                    $mockAvailabilityDatabaseObjects_Set = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection'
                    foreach ($mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames_Set)
                    {
                        $newAvailabilityDatabaseObject_Set = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.AvailabilityDatabase'
                        $newAvailabilityDatabaseObject_Set.Name = $mockAvailabilityDatabaseName
                        $mockAvailabilityDatabaseObjects_Set.Add($newAvailabilityDatabaseObject_Set)
                    }

                    # Mock current replicas.
                    $mockAvailabilityReplicaObjects_Set = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection'

                    $newAvailabilityReplicaObject_Set = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.AvailabilityReplica'
                    $newAvailabilityReplicaObject_Set.Name = 'Server1'
                    $newAvailabilityReplicaObject_Set.Role = 'Primary'
                    $mockAvailabilityReplicaObjects_Set.Add($newAvailabilityReplicaObject_Set)

                    $newAvailabilityReplicaObject_Set = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.AvailabilityReplica'
                    $newAvailabilityReplicaObject_Set.Name = 'Server2'
                    $mockAvailabilityReplicaObjects_Set.Add($newAvailabilityReplicaObject_Set)

                    # Mock current Availability Group.
                    $mockAvailabilityGroupObject_Set = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.AvailabilityGroup'
                    $mockAvailabilityGroupObject_Set.AvailabilityDatabases = $mockAvailabilityDatabaseObjects_Set
                    $mockAvailabilityGroupObject_Set.Name = 'AvailabilityGroup1'
                    $mockAvailabilityGroupObject_Set.PrimaryReplicaServerName = 'Server1'
                    $mockAvailabilityGroupObject_Set.AvailabilityReplicas = $mockAvailabilityReplicaObjects_Set

                    # Mock current server settings for Connect-SQL.
                    $mockServerObject_Set = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockServerObject_Set.AvailabilityGroups = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection'
                    $mockServerObject_Set.AvailabilityGroups.Add($mockAvailabilityGroupObject_Set.Clone())
                    $mockServerObject_Set.ComputerNamePhysicalNetBIOS = 'Server1'
                    $mockServerObject_Set.ConnectionContext = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerConnection'
                    $mockServerObject_Set.ConnectionContext.TrueLogin = 'Login1'
                    $mockServerObject_Set.DomainInstanceName = 'Server1'
                    $mockServerObject_Set.NetName = 'Server1'
                    $mockServerObject_Set.ServiceName = 'MSSQLSERVER'
                    $mockServerObject_Set.AvailabilityGroups[$mockAvailabilityGroupObject_Set.Name].LocalReplicaRole = 'Primary'

                    Mock -CommandName Import-SqlDscPreferredModule

                    Mock -CommandName Connect-SQL -MockWith {
                        return $mockServerObject_Set
                    }

                    Mock -CommandName Get-PrimaryReplicaServerObject -MockWith {
                        # Return the same server object as Connect-SQL for this test.
                        return $mockServerObject_Set
                    }

                    Mock -CommandName Get-DatabasesToAddToAvailabilityGroup -MockWith {
                        return @()
                    }

                    Mock -CommandName Get-DatabasesToRemoveFromAvailabilityGroup -MockWith {
                        return @(
                            'DB2'
                        )
                    }

                    $mockSetTargetResourceParameters = @{
                        DatabaseName = @('DB2')
                        ServerName = 'Server1'
                        InstanceName = 'MSSQLSERVER'
                        AvailabilityGroupName = 'AvailabilityGroup1'
                        BackupPath = 'X:\Backup'
                        Ensure = 'Absent'
                        Force = $false
                        Verbose = $true
                    }
                }

                Context 'When a database should be absent from the availability group' {
                    BeforeAll {
                        Mock -CommandName Remove-SqlAvailabilityDatabase
                    }

                    It 'Should remove the specified database from the availability group(s)' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -ParameterFilter {
                            $InputObject.Name -eq 'DB2'
                        } -Scope It -Times 1 -Exactly
                    }
                }

                Context 'When failing to remove a database from an availability group' {
                    BeforeAll {
                        Mock -CommandName Remove-SqlAvailabilityDatabase -MockWith {
                            throw
                        }
                    }

                    It 'Should throw the correct error' {
                        $errorMessage = 'The operation on the database ''DB2'' failed with the following errors: Failed to remove the database from the availability group.'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $errorMessage

                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It
                    }
                }
            }
#        }

#        Describe 'SqlAGDatabase\Set-TargetResource' -Tag 'Set Automatic' {
            Context 'Tests that was moved into its own context block to prevent intermittent fails (see issue #1532) - workaround until proper refactor with seeding on automatic' {
                BeforeAll {
                    #region Parameter Mocks

                    # The databases defined in the resource
                    $mockDatabaseNameParameter = @(
                        'DB*'
                        'AnotherDB'
                        '3rd*OfDatabase'
                        '4th*OfDatabase'
                    )

                    $mockDatabaseNameParameterWithNonExistingDatabases = @(
                        'NotFound*'
                        'Unknown1'
                    )

                    $mockBackupPath = 'X:\Backup'

                    $mockProcessOnlyOnActiveNode = $false

                    #endregion Parameter Mocks

                    #region mock names

                    $mockServerObjectDomainInstanceName = 'Server1'
                    $mockPrimaryServerObjectDomainInstanceName = 'Server2'
                    $mockAvailabilityGroupObjectName = 'AvailabilityGroup1'
                    $mockAvailabilityGroupWithoutDatabasesObjectName = 'AvailabilityGroupWithoutDatabases'
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName = 'AvailabilityGroup2'
                    $mockTrueLogin = 'Login1'
                    $mockDatabaseOwner = 'DatabaseOwner1'
                    $mockReplicaSeedingMode = 'Automatic'
                    #endregion mock names

                    #region Availability Replica Mocks

                    $mockAvailabilityReplicaObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
                    foreach ( $mockAvailabilityReplicaName in @('Server1','Server2') )
                    {
                        $newAvailabilityReplicaObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                        $newAvailabilityReplicaObject.Name = $mockAvailabilityReplicaName
                        $newAvailabilityReplicaObject.SeedingMode = $mockReplicaSeedingMode

                        if ( $mockServerObjectDomainInstanceName -eq $mockAvailabilityReplicaName )
                        {
                            $newAvailabilityReplicaObject.Role = 'Primary'
                        }

                        $mockAvailabilityReplicaObjects.Add($newAvailabilityReplicaObject)
                    }

                    #endregion Availability Replica Mocks

                    #region Availability Group Mocks

                    $mockAvailabilityDatabaseNames = @(
                        'DB2'
                        '3rdTypeOfDatabase'
                        'UndefinedDatabase'
                    )

                    $mockAvailabilityDatabaseAbsentResults = @(
                        'DB2'
                        '3rdTypeOfDatabase'
                    )

                    $mockAvailabilityDatabaseExactlyAddResults = @(
                        'DB1'
                    )

                    $mockAvailabilityDatabaseExactlyRemoveResults = @(
                        'UndefinedDatabase'
                    )

                    $mockAvailabilityDatabasePresentResults = @(
                        'DB1'
                    )

                    $mockAvailabilityDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
                    foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                    {
                        $newAvailabilityDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
                        $newAvailabilityDatabaseObject.Name = $mockAvailabilityDatabaseName
                        $mockAvailabilityDatabaseObjects.Add($newAvailabilityDatabaseObject)
                    }

                    $mockBadAvailabilityGroupObject = New-Object -TypeName Object

                    $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroupObject.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
                    $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupObjectName
                    $mockAvailabilityGroupObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
                    $mockAvailabilityGroupObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                    $mockAvailabilityGroupWithoutDatabasesObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroupWithoutDatabasesObject.Name = $mockAvailabilityGroupWithoutDatabasesObjectName
                    $mockAvailabilityGroupWithoutDatabasesObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
                    $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.PrimaryReplicaServerName = $mockPrimaryServerObjectDomainInstanceName
                    $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                    #endregion Availability Group Mocks

                    #region Certificate Mocks

                    [byte[]]$mockThumbprint1 = @(
                        83
                        121
                        115
                        116
                        101
                        109
                        46
                        84
                        101
                        120
                        116
                        46
                        85
                        84
                        70
                        56
                        69
                        110
                        99
                        111
                        100
                        105
                        110
                        103
                    )

                    [byte[]]$mockThumbprint2 = @(
                        83
                        121
                        115
                        23
                        101
                        109
                        46
                        84
                        101
                        120
                        116
                        85
                        85
                        84
                        70
                        56
                        69
                        23
                        99
                        111
                        100
                        105
                        110
                        103
                    )

                    $mockCertificateObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
                    $mockCertificateObject1.Thumbprint = $mockThumbprint1

                    $mockCertificateObject2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
                    $mockCertificateObject2.Thumbprint = $mockThumbprint2

                    $mockDatabaseEncryptionKeyObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseEncryptionKey
                    $mockDatabaseEncryptionKeyObject.EncryptorName = 'TDE Cert'
                    $mockDatabaseEncryptionKeyObject.Thumbprint = $mockThumbprint1
                    #endregion Certificate Mocks

                    #region Database File Mocks

                    $mockDataFilePath = 'E:\SqlData'
                    $mockLogFilePath = 'F:\SqlLog'
                    $mockDataFilePathIncorrect = 'G:\SqlData'
                    $mockLogFilePathIncorrect = 'H:\SqlData'

                    #endregion Database File Mocks

                    #region Database Mocks

                    # The databases found on the instance
                    $mockPresentDatabaseNames = @(
                        'DB1'
                        'DB2'
                        '3rdTypeOfDatabase'
                        'UndefinedDatabase'
                    )

                    $mockMasterDatabaseName = 'master'
                    $mockMasterDatabaseObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                    $mockMasterDatabaseObject1.Name = $mockMasterDatabaseName
                    $mockMasterDatabaseObject1.ServerInstance = $mockServerObjectDomainInstanceName
                    $mockMasterDatabaseObject1.ID = 1
                    $mockMasterDatabaseObject1.Certificates = @($mockCertificateObject1)
                    $mockMasterDatabaseObject1.FileGroups = @{
                        Name = 'PRIMARY'
                        Files = @{
                            FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockMasterDatabaseName).mdf" ) )
                        }
                    }
                    $mockMasterDatabaseObject1.LogFiles = @{
                        FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockMasterDatabaseName).ldf" ) )
                    }

                    $mockDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                    foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
                    {
                        $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                        $newDatabaseObject.Name = $mockPresentDatabaseName
                        $newDatabaseObject.ServerInstance = $mockServerObjectDomainInstanceName
                        $newDatabaseObject.FileGroups = @{
                            Name = 'PRIMARY'
                            Files = @{
                                FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockPresentDatabaseName).mdf" ) )
                            }
                        }
                        $newDatabaseObject.LogFiles = @{
                            FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockPresentDatabaseName).ldf" ) )
                        }
                        $newDatabaseObject.Owner = $mockDatabaseOwner

                        # Add the database object to the database collection
                        $mockDatabaseObjects.Add($newDatabaseObject)
                    }
                    $mockDatabaseObjects.Add($mockMasterDatabaseObject1)

                    $mockDatabaseObjectsWithIncorrectFileNames = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                    foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
                    {
                        $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                        $newDatabaseObject.Name = $mockPresentDatabaseName
                        $newDatabaseObject.ServerInstance = $mockServerObjectDomainInstanceName
                        $newDatabaseObject.FileGroups = @{
                            Name = 'PRIMARY'
                            Files = @{
                                FileName = ( [IO.Path]::Combine( $mockDataFilePathIncorrect, "$($mockPresentDatabaseName).mdf" ) )
                            }
                        }
                        $newDatabaseObject.LogFiles = @{
                            FileName = ( [IO.Path]::Combine( $mockLogFilePathIncorrect, "$($mockPresentDatabaseName).ldf" ) )
                        }
                        $newDatabaseObject.Owner = $mockDatabaseOwner

                        # Add the database object to the database collection
                        $mockDatabaseObjectsWithIncorrectFileNames.Add($newDatabaseObject)
                    }

                    #endregion Database Mocks

                    #region Server mocks
                    $mockBadServerObject = New-Object -TypeName Object

                    $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockServerObject.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
                    $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
                    $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
                    $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
                    $mockServerObject.ComputerNamePhysicalNetBIOS = $mockServerObjectDomainInstanceName
                    $mockServerObject.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
                    $mockServerObject.ConnectionContext.TrueLogin = $mockTrueLogin
                    $mockServerObject.Databases = $mockDatabaseObjects
                    $mockServerObject.DomainInstanceName = $mockServerObjectDomainInstanceName
                    $mockServerObject.ServerInstance = $mockServerObjectDomainInstanceName
                    $mockServerObject.NetName = $mockServerObjectDomainInstanceName
                    $mockServerObject.ServiceName = 'MSSQLSERVER'
                    $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Primary'
                    $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Primary'
                    $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Secondary'

                    $mockServer2Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockServer2Object.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
                    $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
                    $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
                    $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
                    $mockServer2Object.ComputerNamePhysicalNetBIOS = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
                    $mockServer2Object.ConnectionContext.TrueLogin = $mockTrueLogin
                    $mockServer2Object.Databases = $mockDatabaseObjects
                    $mockServer2Object.DomainInstanceName = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.ServerInstance = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.NetName = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.ServiceName = 'MSSQLSERVER'
                    $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Secondary'
                    $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Secondary'
                    $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Primary'

                    #endregion Server mocks

                    #region Invoke Query Mock

                    $mockResultInvokeQueryFileExist = {
                        return @{
                            Tables = @{
                                Rows = @{
                                    'File is a Directory' = 1
                                }
                            }
                        }
                    }

                    $mockResultInvokeQueryFileNotExist = {
                        return @{
                            Tables = @{
                                Rows = @{
                                    'File is a Directory' = 0
                                }
                            }
                        }
                    }

                    $mockInvokeQueryParameterRestoreDatabase = {
                        $Query -like 'RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY'
                    }

                    $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs = {
                        $Query -like 'EXECUTE AS LOGIN = *
RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY*
REVERT'
                    }

                    #endregion Invoke Query Mock

                    Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Mock -CommandName Import-SqlDscPreferredModule -Verifiable
                    Mock -CommandName Invoke-SqlDscQuery -Verifiable -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Mock -CommandName Invoke-SqlDscQuery -Verifiable -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Mock -CommandName Join-Path -MockWith { [IO.Path]::Combine($databaseMembershipClass.BackupPath,"$($database.Name)_Full_$(Get-Date -Format 'yyyyMMddhhmmss').bak") } -Verifiable -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Mock -CommandName Join-Path -MockWith { [IO.Path]::Combine($databaseMembershipClass.BackupPath,"$($database.Name)_Log_$(Get-Date -Format 'yyyyMMddhhmmss').trn") } -Verifiable -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Mock -CommandName Remove-Item -Verifiable
                    Mock -CommandName Get-CurrentWindowsIdentityName -MockWith { return 'DOMAIN\TestUser' } -Verifiable
                }

                BeforeEach {
                    $mockSetTargetResourceParameters = @{
                        DatabaseName = $($mockDatabaseNameParameter)
                        ServerName = $($mockServerObject.DomainInstanceName)
                        InstanceName = $('MSSQLSERVER')
                        AvailabilityGroupName = $($mockAvailabilityGroupObjectName)
                        BackupPath = $($mockBackupPath)
                        Ensure = 'Present'
                        Force = $false
                        MatchDatabaseOwner = $false
                        ReplaceExisting = $false
                    }

                    Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Mock -CommandName Backup-SqlDatabase -Verifiable -ParameterFilter { $BackupAction -eq 'Database' }
                    Mock -CommandName Backup-SqlDatabase -Verifiable -ParameterFilter { $BackupAction -eq 'Log'}
                    Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $ServerName -eq 'Server1' }
                    Mock -CommandName Connect-SQL -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $ServerName -eq 'Server2' }
                    Mock -CommandName Invoke-SqlDscQuery -MockWith $mockResultInvokeQueryFileExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Mock -CommandName Remove-SqlAvailabilityDatabase -Verifiable
                    Mock -CommandName Test-ImpersonatePermissions -MockWith { $true } -Verifiable
                    # Add a general Connect-SQL mock to catch any calls not covered by parameter filters
                    Mock -CommandName Connect-SQL -MockWith { return $mockServerObject }
                }

                Context 'When Ensure is Present' {
                     It 'Should add the specified databases to the availability group.' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should add the specified databases to the availability group when the primary replica is on another server' {
                        $mockSetTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should not do anything if no databases were found to add' {
                        $mockSetTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 0 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 0 -Scope It
                    }

                    It 'Should add the specified databases to the availability group when "MatchDatabaseOwner" is $false' {
                        $mockSetTargetResourceParameters.MatchDatabaseOwner = $false

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 0 -Scope It
                    }

                    It 'Should add the specified databases to the availability group when "ReplaceExisting" is $true' {
                        $mockSetTargetResourceParameters.DatabaseName = 'DB1'
                        $mockSetTargetResourceParameters.ReplaceExisting = $true

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should throw the correct error when "MatchDatabaseOwner" is $true and the current login does not have impersonate permissions' {
                        Mock -CommandName Test-ImpersonatePermissions -MockWith { $false } -Verifiable

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "missing impersonate any login, control server, impersonate login, or control login permissions"

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    $prerequisiteChecks = @{
                        RecoveryModel = 'Full'
                        ReadOnly = $false
                        UserAccess = 'Multiple'
                        AutoClose = $false
                        AvailabilityGroupName = ''
                        IsMirroringEnabled = $false
                    }

                    foreach ( $prerequisiteCheck in $prerequisiteChecks.GetEnumerator() )
                    {
                        It "Should throw the correct error when the database property '$($prerequisiteCheck.Key)' is not '$($prerequisiteCheck.Value)'" {
                            $originalValue = $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key)
                            $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key) = $true

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: $($prerequisiteCheck.Key) is not $($prerequisiteCheck.Value)."

                            foreach ( $databaseProperty in $prerequisiteChecks.GetEnumerator() )
                            {
                                if ( $prerequisiteCheck.Key -eq $databaseProperty.Key )
                                {
                                    $mockServerObject.Databases['DB1'].($databaseProperty.Key) | Should -Not -Be ($databaseProperty.Value)
                                }
                                else
                                {
                                    $mockServerObject.Databases['DB1'].($databaseProperty.Key) | Should -Be ($databaseProperty.Value)
                                }
                            }

                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                            Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                            Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                            Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                            Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                            Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                            Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                            Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                                Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                            $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key) = $originalValue
                        }
                    }

                    It 'Should throw the correct error when the database property "ID" is less than "4"' {
                        $mockSetTargetResourceParameters.DatabaseName = @('master')

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'master' failed with the following errors: The following prerequisite checks failed: The database cannot be a system database."

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    $filestreamProperties = @{
                        DefaultFileStreamFileGroup = ''
                        FilestreamDirectoryName = ''
                        FilestreamNonTransactedAccess = 'Off'
                    }

                    foreach ( $filestreamProperty in $filestreamProperties.GetEnumerator() )
                    {
                        It "Should throw the correct error 'AlterAvailabilityGroupDatabaseMembershipFailure' when the database property '$($filestreamProperty.Key)' is not '$($filestreamProperty.Value)'" {
                            $originalValue = $mockServerObject.Databases['DB1'].($filestreamProperty.Key)
                            $mockServerObject.Databases['DB1'].($filestreamProperty.Key) = 'On'

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: Filestream is disabled on the following instances: Server2"

                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                            Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                            Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                            Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                            Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                            Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                            Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                            Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                            Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                            Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                            Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                                Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                            $mockServerObject.Databases['DB1'].($filestreamProperty.Key) = $originalValue
                        }
                    }

                    It 'Should throw the correct error when the database property "ContainmentType" is not "Partial"' {
                        $originalValue = $mockServerObject.Databases['DB1'].ContainmentType
                        $mockServerObject.Databases['DB1'].ContainmentType = 'Partial'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: Contained Database Authentication is not enabled on the following instances: "

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        $mockServerObject.Databases['DB1'].ContainmentType = $originalValue
                    }

                    It 'Should throw the correct error when the database file path does not exist on the secondary replica' {
                        Mock -CommandName Invoke-SqlDscQuery -MockWith $mockResultInvokeQueryFileNotExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        $originalValue = $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName
                        $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName = ( [IO.Path]::Combine( 'X:\', "DB1.mdf" ) )

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: The instance 'Server2' is missing the following directories: X:\, F:\SqlLog"

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName = $originalValue
                    }

                    It 'Should throw the correct error when the log file path does not exist on the secondary replica' {
                        Mock -CommandName Invoke-SqlDscQuery -MockWith $mockResultInvokeQueryFileNotExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        $originalValue = $mockServer2Object.Databases['DB1'].LogFiles.FileName
                        $mockServer2Object.Databases['DB1'].LogFiles.FileName = ( [IO.Path]::Combine( 'Y:\', "DB1.ldf" ) )

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: The following prerequisite checks failed: The instance ''Server2'' is missing the following directories: E:\SqlData, Y:\'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        $mockServer2Object.Databases['DB1'].LogFiles.FileName = $originalValue
                    }

                    It 'Should throw the correct error when TDE is enabled on the database but the certificate is not present on the replica instances' {
                        $mockServerObject.Databases['DB1'].EncryptionEnabled = $true
                        $mockServerObject.Databases['DB1'].DatabaseEncryptionKey = $mockDatabaseEncryptionKeyObject
                        $mockServer2Object.Databases['master'].Certificates = @($mockCertificateObject2)

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: The following prerequisite checks failed: The instance ''Server2'' is missing the following certificates: TDE Cert'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        $mockServerObject.Databases['DB1'].EncryptionEnabled = $false
                        $mockServerObject.Databases['DB1'].DatabaseEncryptionKey = $null
                        $mockServer2Object.Databases['master'].Certificates = @($mockCertificateObject1)
                    }

                    It 'Should add the specified databases to the availability group when the database has not been previously backed up' {
                        $mockServerObject.Databases['DB1'].CreateDate = '2020-10-20 10:00:00'
                        $mockServerObject.Databases['DB1'].LastBackupDate = '2020-10-10 10:00:00'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 1 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It

                        #reset so others will not trip. Fix for pester 5
                        $mockServerObject.Databases['DB1'].CreateDate = '2020-10-10 10:00:00'
                        $mockServerObject.Databases['DB1'].LastBackupDate = '2020-10-20 10:00:00'
                    }

                    It 'Should throw the correct error when it fails to add the database to the primary replica' {
                        Mock -CommandName Add-SqlAvailabilityDatabase -MockWith { throw } -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }

                    It 'Should throw the correct error when it fails to add the database to the primary replica' {
                        Mock -CommandName Add-SqlAvailabilityDatabase -MockWith { throw } -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When Ensure is Present and Force is True' {
                    BeforeEach {
                        $mockSetTargetResourceParameters.Ensure = 'Present'
                        $mockSetTargetResourceParameters.Force = $true
                    }

                    It 'Should ensure the database membership of the availability group is exactly as specified' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Should -Invoke -CommandName Add-SqlAvailabilityDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Database' }
                        Should -Invoke -CommandName Backup-SqlDatabase -Exactly -Times 0 -Scope It -ParameterFilter { $BackupAction -eq 'Log' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It -ParameterFilter { $ServerName -eq 'Server1' }
                        Should -Invoke -CommandName Connect-SQL -Exactly -Times 3 -Scope It -ParameterFilter { $ServerName -eq 'Server2' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 2 -Scope It -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Should -Invoke -CommandName Join-Path -Exactly -Times 0 -Scope It -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Should -Invoke -CommandName Remove-Item -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Remove-SqlAvailabilityDatabase -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Test-ImpersonatePermissions -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe 'SqlAGDatabase\Test-TargetResource' {
            BeforeAll {
                #region Parameter Mocks

                # The databases defined in the resource
                $mockDatabaseNameParameter = @(
                    'DB*'
                    'AnotherDB'
                    '3rd*OfDatabase'
                    '4th*OfDatabase'
                )

                $mockDatabaseNameParameterWithNonExistingDatabases = @(
                    'NotFound*'
                    'Unknown1'
                )

                $mockBackupPath = 'X:\Backup'

                $mockProcessOnlyOnActiveNode = $false

                #endregion Parameter Mocks

                #region mock names

                $mockServerObjectDomainInstanceName = 'Server1'
                $mockPrimaryServerObjectDomainInstanceName = 'Server2'
                $mockAvailabilityGroupObjectName = 'AvailabilityGroup1'
                $mockAvailabilityGroupWithoutDatabasesObjectName = 'AvailabilityGroupWithoutDatabases'
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName = 'AvailabilityGroup2'
                $mockTrueLogin = 'Login1'
                $mockDatabaseOwner = 'DatabaseOwner1'
                $mockReplicaSeedingMode = 'Manual'
                #endregion mock names

                #region Availability Replica Mocks

                $mockAvailabilityReplicaObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
                foreach ( $mockAvailabilityReplicaName in @('Server1','Server2') )
                {
                    $newAvailabilityReplicaObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                    $newAvailabilityReplicaObject.Name = $mockAvailabilityReplicaName
                    $newAvailabilityReplicaObject.SeedingMode = 'Manual'

                    if ( $mockServerObjectDomainInstanceName -eq $mockAvailabilityReplicaName )
                    {
                        $newAvailabilityReplicaObject.Role = 'Primary'
                    }

                    $mockAvailabilityReplicaObjects.Add($newAvailabilityReplicaObject)
                }

                #endregion Availability Replica Mocks

                #region Availability Group Mocks

                $mockAvailabilityDatabaseNames = @(
                    'DB2'
                    '3rdTypeOfDatabase'
                    'UndefinedDatabase'
                )

                $mockAvailabilityDatabaseAbsentResults = @(
                    'DB2'
                    '3rdTypeOfDatabase'
                )

                $mockAvailabilityDatabaseExactlyAddResults = @(
                    'DB1'
                )

                $mockAvailabilityDatabaseExactlyRemoveResults = @(
                    'UndefinedDatabase'
                )

                $mockAvailabilityDatabasePresentResults = @(
                    'DB1'
                )

                $mockAvailabilityDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
                foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                {
                    $newAvailabilityDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
                    $newAvailabilityDatabaseObject.Name = $mockAvailabilityDatabaseName
                    $mockAvailabilityDatabaseObjects.Add($newAvailabilityDatabaseObject)
                }

                $mockBadAvailabilityGroupObject = New-Object -TypeName Object

                $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupObject.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
                $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupObjectName
                $mockAvailabilityGroupObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
                $mockAvailabilityGroupObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                $mockAvailabilityGroupWithoutDatabasesObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupWithoutDatabasesObject.Name = $mockAvailabilityGroupWithoutDatabasesObjectName
                $mockAvailabilityGroupWithoutDatabasesObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
                $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.PrimaryReplicaServerName = $mockPrimaryServerObjectDomainInstanceName
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityReplicas = $mockAvailabilityReplicaObjects

                #endregion Availability Group Mocks

                #region Certificate Mocks

                [byte[]]$mockThumbprint1 = @(
                    83
                    121
                    115
                    116
                    101
                    109
                    46
                    84
                    101
                    120
                    116
                    46
                    85
                    84
                    70
                    56
                    69
                    110
                    99
                    111
                    100
                    105
                    110
                    103
                )

                [byte[]]$mockThumbprint2 = @(
                    83
                    121
                    115
                    23
                    101
                    109
                    46
                    84
                    101
                    120
                    116
                    85
                    85
                    84
                    70
                    56
                    69
                    23
                    99
                    111
                    100
                    105
                    110
                    103
                )

                $mockCertificateObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
                $mockCertificateObject1.Thumbprint = $mockThumbprint1

                $mockCertificateObject2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
                $mockCertificateObject2.Thumbprint = $mockThumbprint2

                $mockDatabaseEncryptionKeyObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseEncryptionKey
                $mockDatabaseEncryptionKeyObject.EncryptorName = 'TDE Cert'
                $mockDatabaseEncryptionKeyObject.Thumbprint = $mockThumbprint1

                #endregion Certificate Mocks

                #region Database File Mocks

                $mockDataFilePath = 'E:\SqlData'
                $mockLogFilePath = 'F:\SqlLog'
                $mockDataFilePathIncorrect = 'G:\SqlData'
                $mockLogFilePathIncorrect = 'H:\SqlData'

                #endregion Database File Mocks

                #region Database Mocks

                # The databases found on the instance
                $mockPresentDatabaseNames = @(
                    'DB1'
                    'DB2'
                    '3rdTypeOfDatabase'
                    'UndefinedDatabase'
                )

                $mockMasterDatabaseName = 'master'
                $mockMasterDatabaseObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                $mockMasterDatabaseObject1.Name = $mockMasterDatabaseName
                    $mockMasterDatabaseObject1.ServerInstance = $mockServerObjectDomainInstanceName
                $mockMasterDatabaseObject1.ID = 1
                $mockMasterDatabaseObject1.Certificates = @($mockCertificateObject1)
                $mockMasterDatabaseObject1.FileGroups = @{
                    Name = 'PRIMARY'
                    Files = @{
                        FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockMasterDatabaseName).mdf" ) )
                    }
                }
                $mockMasterDatabaseObject1.LogFiles = @{
                    FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockMasterDatabaseName).ldf" ) )
                }

                $mockDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
                {
                    $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                    $newDatabaseObject.Name = $mockPresentDatabaseName
                        $newDatabaseObject.ServerInstance = $mockServerObjectDomainInstanceName
                    $newDatabaseObject.FileGroups = @{
                        Name = 'PRIMARY'
                        Files = @{
                            FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockPresentDatabaseName).mdf" ) )
                        }
                    }
                    $newDatabaseObject.LogFiles = @{
                        FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockPresentDatabaseName).ldf" ) )
                    }
                    $newDatabaseObject.Owner = $mockDatabaseOwner

                    # Add the database object to the database collection
                    $mockDatabaseObjects.Add($newDatabaseObject)
                }
                $mockDatabaseObjects.Add($mockMasterDatabaseObject1)

                $mockDatabaseObjectsWithIncorrectFileNames = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
                {
                    $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                    $newDatabaseObject.Name = $mockPresentDatabaseName
                        $newDatabaseObject.ServerInstance = $mockServerObjectDomainInstanceName
                    $newDatabaseObject.FileGroups = @{
                        Name = 'PRIMARY'
                        Files = @{
                            FileName = ( [IO.Path]::Combine( $mockDataFilePathIncorrect, "$($mockPresentDatabaseName).mdf" ) )
                        }
                    }
                    $newDatabaseObject.LogFiles = @{
                        FileName = ( [IO.Path]::Combine( $mockLogFilePathIncorrect, "$($mockPresentDatabaseName).ldf" ) )
                    }
                    $newDatabaseObject.Owner = $mockDatabaseOwner

                    # Add the database object to the database collection
                    $mockDatabaseObjectsWithIncorrectFileNames.Add($newDatabaseObject)
                }

                #endregion Database Mocks

                #region Server mocks
                $mockBadServerObject = New-Object -TypeName Object

                $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServerObject.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
                $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
                $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
                $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
                $mockServerObject.ComputerNamePhysicalNetBIOS = $mockServerObjectDomainInstanceName
                $mockServerObject.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
                $mockServerObject.ConnectionContext.TrueLogin = $mockTrueLogin
                $mockServerObject.Databases = $mockDatabaseObjects
                $mockServerObject.DomainInstanceName = $mockServerObjectDomainInstanceName
                    $mockServerObject.ServerInstance = $mockServerObjectDomainInstanceName
                $mockServerObject.NetName = $mockServerObjectDomainInstanceName
                $mockServerObject.ServiceName = 'MSSQLSERVER'
                $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Primary'
                $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Primary'
                $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Secondary'

                $mockServer2Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServer2Object.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
                $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
                $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
                $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
                $mockServer2Object.ComputerNamePhysicalNetBIOS = $mockPrimaryServerObjectDomainInstanceName
                $mockServer2Object.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
                $mockServer2Object.ConnectionContext.TrueLogin = $mockTrueLogin
                $mockServer2Object.Databases = $mockDatabaseObjects
                $mockServer2Object.DomainInstanceName = $mockPrimaryServerObjectDomainInstanceName
                    $mockServer2Object.ServerInstance = $mockPrimaryServerObjectDomainInstanceName
                $mockServer2Object.NetName = $mockPrimaryServerObjectDomainInstanceName
                $mockServer2Object.ServiceName = 'MSSQLSERVER'
                $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Secondary'
                $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Secondary'
                $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Primary'

                #endregion Server mocks

                #region Invoke Query Mock

                $mockResultInvokeQueryFileExist = {
                    return @{
                        Tables = @{
                            Rows = @{
                                'File is a Directory' = 1
                            }
                        }
                    }
                }

                $mockResultInvokeQueryFileNotExist = {
                    return @{
                        Tables = @{
                            Rows = @{
                                'File is a Directory' = 0
                            }
                        }
                    }
                }

                $mockInvokeQueryParameterRestoreDatabase = {
                    $Query -like 'RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY'
                }

                $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs = {
                    $Query -like 'EXECUTE AS LOGIN = *
RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY*
REVERT'
                }

                #endregion Invoke Query Mock


                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                Mock -CommandName Test-ActiveNode -MockWith {
                    return -not $mockProcessOnlyOnActiveNode
                } -Verifiable


            }

            BeforeEach {
                $mockTestTargetResourceParameters = @{
                    DatabaseName = $mockDatabaseNameParameter
                    ServerName = $mockServerObject.DomainInstanceName
                    InstanceName = 'MSSQLSERVER'
                    AvailabilityGroupName = $mockAvailabilityGroupObject.Name
                    BackupPath = $($mockBackupPath)
                    Ensure = 'Present'
                    Force = $false
                    MatchDatabaseOwner = $false
                    ProcessOnlyOnActiveNode = $false
                }

            }

            Context 'When Ensure is Present' {
                It 'Should return $true when the configuration is in the desired state' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Should -Invoke -CommandName Test-ActiveNode -Exactly -Times 1 -Scope It
                }

                It 'Should return $false when the specified availability group is not found' {
                    $mockTestTargetResourceParameters.AvailabilityGroupName = 'NonExistentAvailabilityGroup'

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Should -Invoke -CommandName Test-ActiveNode -Exactly -Times 1 -Scope It
                }

                It 'Should return $false when no matching databases are found' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Should -Invoke -CommandName Test-ActiveNode -Exactly -Times 1 -Scope It
                }

                It 'Should return $false when databases are found to add to the availability group' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Should -Invoke -CommandName Test-ActiveNode -Exactly -Times 1 -Scope It
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames
                    $mockTestTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Should -Invoke -CommandName Test-ActiveNode -Exactly -Times 1 -Scope It
                }

                It 'Should return $true when ProcessOnlyOnActiveNode is "$true" and the current node is not actively hosting the instance' {
                    $mockProcessOnlyOnActiveNode = $true

                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames
                    $mockTestTargetResourceParameters.ProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNode

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Should -Invoke -CommandName Test-ActiveNode -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Ensure is Absent' {
                BeforeEach {
                    $mockTestTargetResourceParameters.Ensure = 'Absent'
                }

                It 'Should return $true when the configuration is in the desired state' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }

                }

                It 'Should return $true when no matching databases are found' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to remove from the availability group' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases
                    $mockTestTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }
            }

            Context 'When Ensure is Present and Force is True' {
                BeforeEach {
                    $mockTestTargetResourceParameters.Force = $true
                }

                It 'Should return $true when the configuration is in the desired state' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when no matching databases are found' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to add to the availability group' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to remove from the availability group' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames
                    $mockTestTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 0 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Exactly -Times 1 -Scope It -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }
            }
        }

        Describe 'SqlAGDatabase\Get-DatabasesToAddToAvailabilityGroup' {
            BeforeAll {
                # Setup mock variables needed for this test (reused from parent context)
                $mockDatabaseNameParameter = @(
                    'DB*'
                    'AnotherDB'
                    '3rd*OfDatabase'
                    '4th*OfDatabase'
                )

                $mockAvailabilityDatabasePresentResults = @(
                    'DB1'
                    '3rdOfDatabase'
                )

                # Create availability group object with databases
                $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupObject.Name = 'AvailabilityGroup1'
                $mockAvailabilityGroupObject.AvailabilityDatabases = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
                
                # Create availability group object without databases
                $mockAvailabilityGroupWithoutDatabasesObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupWithoutDatabasesObject.Name = 'AvailabilityGroupWithoutDatabases'
                $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityDatabases = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
                
                # Create server object
                $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            }

            BeforeEach {
                $getDatabasesToAddToAvailabilityGroup = @{
                    DatabaseName = $mockDatabaseNameParameter
                    Ensure = 'Present'
                    ServerObject = $mockServerObject
                    AvailabilityGroup = $mockAvailabilityGroupObject
                }
            }

            Context 'When Ensure is Present' {
                It 'Should return an array of database names to add when matches are found' {
                    $results = InModuleScope -Parameters @{ params = $getDatabasesToAddToAvailabilityGroup } -ScriptBlock { Get-DatabasesToAddToAvailabilityGroup @params }

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabasePresentResults -contains $result | Should -Be $true
                    }
                }

                It 'Should return an array of database names no databases are in the availability group' {
                    $getDatabasesToAddToAvailabilityGroup.AvailabilityGroup = $mockAvailabilityGroupWithoutDatabasesObject

                    $results = InModuleScope -Parameters @{ params = $getDatabasesToAddToAvailabilityGroup } -ScriptBlock { Get-DatabasesToAddToAvailabilityGroup @params }

                    foreach ( $result in $results )
                    {
                        $mockPresentDatabaseNames -contains $result | Should -Be $true
                    }
                }

                It 'Should return an empty object when no matches are found' {
                    $getDatabasesToAddToAvailabilityGroup.DatabaseName = @()

                    InModuleScope -Parameters @{ params = $getDatabasesToAddToAvailabilityGroup } -ScriptBlock { Get-DatabasesToAddToAvailabilityGroup @params } | Should -BeNullOrEmpty
                }
            }
        }

        Describe 'SqlAGDatabase\Get-DatabasesToRemoveFromAvailabilityGroup' {
            BeforeAll {
                # Setup mock variables needed for this test 
                $mockDatabaseNameParameter = @(
                    'DB*'
                    'AnotherDB'
                    '3rd*OfDatabase'
                    '4th*OfDatabase'
                )

                $mockAvailabilityDatabaseAbsentResults = @(
                    'DB2'
                    'AnotherDB'
                )

                $mockAvailabilityDatabaseNames = @(
                    'DB2'
                    'AnotherDB'
                )

                $mockAvailabilityDatabaseExactlyRemoveResults = @(
                    'DB2'
                )

                # Create availability group object with databases
                $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupObject.Name = 'AvailabilityGroup1'
                $mockAvailabilityGroupObject.AvailabilityDatabases = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
                
                # Add databases to the availability group
                foreach ($databaseName in $mockAvailabilityDatabaseNames) {
                    $availabilityDatabase = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
                    $availabilityDatabase.Name = $databaseName
                    $mockAvailabilityGroupObject.AvailabilityDatabases.Add($availabilityDatabase)
                }
                
                $mockAvailabilityGroupWithoutDatabasesObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupWithoutDatabasesObject.Name = 'AvailabilityGroup2'
                $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityDatabases = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection

                # Create server object
                $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServerObject.Databases = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                
                # Add databases to server that match the patterns
                foreach ($databaseName in $mockAvailabilityDatabaseNames) {
                    $database = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                    $database.Name = $databaseName
                    $mockServerObject.Databases.Add($database)
                }
            }

            BeforeEach {
                $getDatabasesToRemoveFromAvailabilityGroupParameters = @{
                    DatabaseName = $mockDatabaseNameParameter
                    Ensure = 'Present'
                    Force = $false
                    ServerObject = $mockServerObject
                    AvailabilityGroup = $mockAvailabilityGroupObject
                }
            }

            Context 'When Ensure is Absent' {
                BeforeEach {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.Ensure = 'Absent'
                }

                It 'Should return an array of database names to remove when matches are found' {
                    $results = InModuleScope -Parameters @{ params = $getDatabasesToRemoveFromAvailabilityGroupParameters } -ScriptBlock { Get-DatabasesToRemoveFromAvailabilityGroup @params }

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseAbsentResults -contains $result | Should -Be $true
                    }
                }

                It 'Should return an array of database names to remove when no databases are in the availability group' {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.AvailabilityGroup = $mockAvailabilityGroupWithoutDatabasesObject

                    $results = InModuleScope -Parameters @{ params = $getDatabasesToRemoveFromAvailabilityGroupParameters } -ScriptBlock { Get-DatabasesToRemoveFromAvailabilityGroup @params }

                    # When availability group has no databases, nothing should be returned to remove
                    $results | Should -BeNullOrEmpty
                }

                It 'Should return an empty object when no matches are found' {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.DatabaseName = @()

                    InModuleScope -Parameters @{ params = $getDatabasesToRemoveFromAvailabilityGroupParameters } -ScriptBlock { Get-DatabasesToRemoveFromAvailabilityGroup @params } | Should -BeNullOrEmpty
                }
            }

            Context 'When Ensure is Present and Force is True' {
                BeforeEach {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.Force = $true
                }

                It 'Should return an array of database names to remove when matches are found' {
                    $results = InModuleScope -Parameters @{ params = $getDatabasesToRemoveFromAvailabilityGroupParameters } -ScriptBlock { Get-DatabasesToRemoveFromAvailabilityGroup @params }

                    # When Force = true and Ensure = Present, databases that DON'T match the patterns should be removed
                    # Since both 'DB2' (matches 'DB*') and 'AnotherDB' (matches 'AnotherDB') are in the patterns,
                    # nothing should be returned for removal
                    $results | Should -BeNullOrEmpty
                }

                It 'Should return all of the databases in the availability group if no matches were found' {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.DatabaseName = @()

                    $results = InModuleScope -Parameters @{ params = $getDatabasesToRemoveFromAvailabilityGroupParameters } -ScriptBlock { Get-DatabasesToRemoveFromAvailabilityGroup @params }

                    # Ensure all of the results are in the Availability Databases
                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseNames -contains $result | Should -Be $true
                    }

                    # Ensure all of the Availability Databases are in the results
                    foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                    {
                        $results -contains $mockAvailabilityDatabaseName | Should -Be $true
                    }
                }
            }
        }

        Describe 'SqlAGDatabase\Get-MatchingDatabaseNames' {
            BeforeAll {
                # Setup mock variables needed for this test
                $mockDatabaseNameParameter = @(
                    'DB*'
                    'AnotherDB'
                    '3rd*OfDatabase'
                    '4th*OfDatabase'
                )

                $mockPresentDatabaseNames = @(
                    'DB1'
                    'AnotherDB'
                    '3rdOfDatabase'
                    '4thOfDatabase'
                )

                # Create a simple mock server object for testing
                $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServerObject.Databases = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
                
                # Add mock databases to the server
                foreach ($dbName in $mockPresentDatabaseNames) {
                    $mockDb = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
                    $mockDb.Name = $dbName
                    $mockDb.ServerInstance = $mockServerObjectDomainInstanceName
                    $mockServerObject.Databases.Add($mockDb)
                }

                $mockBadServerObject = New-Object -TypeName Object
            }

            BeforeEach {
                $getMatchingDatabaseNamesParameters = @{
                    DatabaseName = $mockDatabaseNameParameter
                    ServerObject = $mockServerObject
                }
            }

            Context 'When the Get-MatchingDatabaseNames function is called' {
                It 'Should throw the correct error when and invalid object type is passed to the method' {
                    { InModuleScope -Parameters @{ DatabaseName = $mockDatabaseNameParameter; ServerObject = $mockBadServerObject } -ScriptBlock { 
                        $params = @{
                            DatabaseName = $DatabaseName
                            ServerObject = $ServerObject
                        }
                        Get-MatchingDatabaseNames @params 
                    } } | Should -Throw '*ServerObject*'
                }

                It 'Should return an empty object when no matching databases are found' {
                     InModuleScope -Parameters @{ DatabaseName = @('DatabaseNotHere'); ServerObject = $mockServerObject } -ScriptBlock { 
                        $params = @{
                            DatabaseName = $DatabaseName
                            ServerObject = $ServerObject
                        }
                        Get-MatchingDatabaseNames @params 
                    } | Should -BeNullOrEmpty
                }

                It 'Should return an array of database names that match the defined databases' {
                     $results = InModuleScope -Parameters @{ params = $getMatchingDatabaseNamesParameters } -ScriptBlock { Get-MatchingDatabaseNames @params }

                     foreach ( $result in $results )
                     {
                         $mockPresentDatabaseNames -contains $result | Should -Be $true
                     }
                }

                It 'Should return an array of database names that match the defined databases when the case does not match' {
                    $getMatchingDatabaseNamesParameters.DatabaseName = $getMatchingDatabaseNamesParameters.DatabaseName | ForEach-Object -Process { $_.ToLower() }

                    $results = InModuleScope -Parameters @{ params = $getMatchingDatabaseNamesParameters } -ScriptBlock { Get-MatchingDatabaseNames @params }

                    foreach ( $result in $results )
                    {
                        $mockPresentDatabaseNames -contains $result | Should -Be $true
                    }
               }
            }
        }

        Describe 'SqlAGDatabase\Get-DatabaseNamesNotFoundOnTheInstance' {
            BeforeAll {
                # Setup mock variables needed for this test
                $mockDatabaseNameParameter = @(
                    'DB*'
                    'AnotherDB'
                    '3rd*OfDatabase'
                    '4th*OfDatabase'
                )

                # The defined databases that should be identified as missing
                $mockMissingDatabases = @(
                    'AnotherDB'
                    '4th*OfDatabase'
                )

                $mockPresentDatabaseNames = @(
                    'DB1'
                    'AnotherDB'
                    '3rdOfDatabase'
                    '4thOfDatabase'
                )
            }

            Context 'When the Get-DatabaseNamesNotFoundOnTheInstance function is called' {

                BeforeEach {
                    $getDatabaseNamesNotFoundOnTheInstanceParameters = @{
                        DatabaseName = $mockDatabaseNameParameter
                        MatchingDatabaseNames = @()
                    }
                }

                It 'Should return an empty object when no missing databases were identified' {
                    InModuleScope -Parameters @{ DatabaseName = $mockDatabaseNameParameter; MatchingDatabaseNames = $mockDatabaseNameParameter } -ScriptBlock { 
                        $params = @{
                            DatabaseName = $DatabaseName
                            MatchingDatabaseNames = $MatchingDatabaseNames
                        }
                        Get-DatabaseNamesNotFoundOnTheInstance @params 
                    } | Should -BeNullOrEmpty
                }

                It 'Should return a string array of database names when missing databases are identified' {
                    $results = InModuleScope -Parameters @{ DatabaseName = $mockDatabaseNameParameter; MatchingDatabaseNames = $mockPresentDatabaseNames } -ScriptBlock { 
                        $params = @{
                            DatabaseName = $DatabaseName
                            MatchingDatabaseNames = $MatchingDatabaseNames
                        }
                        Get-DatabaseNamesNotFoundOnTheInstance @params 
                    }

                    foreach ( $result in $results )
                    {
                        $mockMissingDatabases -contains $result | Should -Be $true
                    }
                }

                It 'Should return an empty object is supplied and no databases are defined' {
                    InModuleScope -Parameters @{ DatabaseName = @(); MatchingDatabaseNames = $mockPresentDatabaseNames } -ScriptBlock { 
                        $params = @{
                            DatabaseName = $DatabaseName
                            MatchingDatabaseNames = $MatchingDatabaseNames
                        }
                        Get-DatabaseNamesNotFoundOnTheInstance @params 
                    } | Should -BeNullOrEmpty
                }
            }
        }
