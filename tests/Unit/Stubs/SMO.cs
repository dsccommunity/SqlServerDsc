// Stubs for the namespace Microsoft.SqlServer.Management.Smo. Used for mocking in tests.

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Security;
using System.Runtime.InteropServices;

namespace Microsoft.SqlServer.Management.Smo
{
    #region Public Enums

    // TypeName: Microsoft.SqlServer.Management.Smo.LoginCreateOptions
    // Used by:
    //  DSC_SqlLogin.Tests.ps1
    public enum LoginCreateOptions
    {
        None = 0,
        IsHashed = 1,
        MustChange = 2
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.LoginType
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by:
    //  DSC_SqlLogin
    public enum LoginType
    {
        AsymmetricKey = 4,
        Certificate = 3,
        ExternalGroup = 6,
        ExternalUser = 5,
        SqlLogin = 2,
        WindowsGroup = 1,
        WindowsUser = 0,
        Unknown = -1    // Added for verification (mock) purposes, to verify that a login type is passed
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplicaFailoverMode
    // Used by:
    //  -
    public enum AvailabilityReplicaFailoverMode
    {
        Automatic,
        Manual,
        Unknown
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplicaAvailabilityMode
    // Used by:
    //  -
    public enum AvailabilityReplicaAvailabilityMode
    {
        AsynchronousCommit,
        SynchronousCommit,
        Unknown
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplicaSeedingMode
    // Used by:
    //  SqlAGDatabase
    public enum AvailabilityReplicaSeedingMode
    {
        Automatic,
        Manual
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.EndpointType
    // Used by:
    //  SqlEndpoint
    public enum EndpointType
    {
        DatabaseMirroring,
        ServiceBroker,
        Soap,
        TSql
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ProtocolType
    // Used by:
    //  SqlEndpoint
    public enum ProtocolType
    {
        Http,
        NamedPipes,
        SharedMemory,
        Tcp,
        Via
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ServerMirroringRole
    // Used by:
    //  SqlEndpoint
    public enum ServerMirroringRole
    {
        All,
        None,
        Partner,
        Witness
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.EndpointEncryption
    // Used by:
    //  SqlEndpoint
    public enum EndpointEncryption
    {
        Disabled,
        Required,
        Supported
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.EndpointEncryptionAlgorithm
    // Used by:
    //  SqlEndpoint
    public enum EndpointEncryptionAlgorithm
    {
        Aes,
        AesRC4,
        None,
        RC4,
        RC4Aes
    }

    public enum AuditDestinationType : int
    {
        File = 0,
        SecurityLog = 1,
        ApplicationLog = 2,
        Url = 3,
        Unknown = 100,
    }

    public enum AuditFileSizeUnit : int
    {
        Mb = 0,
        Gb = 1,
        Tb = 2,
    }

    public enum OnFailureAction : int
    {
        Continue = 0,
        Shutdown = 1,
        FailOperation = 2,
    }

    public enum SqlSmoState : int
    {
        Pending = 0,
        Creating = 1,
        Existing = 2,
        ToBeDropped = 3,
        Dropped = 4,
    }

    public enum TerminationClause : int
    {
        FailOnOpenTransactions = 0,
        RollbackTransactionsImmediately = 1,
        CloseAllConnectionsImmediately = 2
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabaseUserAccess
    // Used by:
    //  New-SqlDscDatabase.Tests.ps1
    //  Set-SqlDscDatabaseProperty.Tests.ps1
    public enum DatabaseUserAccess : int
    {
        Multiple = 0,
        Single = 1,
        Restricted = 2
    }

    // Database-specific enums
    public enum CompatibilityLevel : int
    {
        Version60 = 60,
        Version65 = 65,
        Version70 = 70,
        Version80 = 80,
        Version90 = 90,
        Version100 = 100,
        Version110 = 110,
        Version120 = 120,
        Version130 = 130,
        Version140 = 140,
        Version150 = 150,
        Version160 = 160,
        Version170 = 170
    }

    public enum ContainmentType : int
    {
        None = 0,
        Partial = 1
    }

    public enum FilestreamNonTransactedAccessType : int
    {
        Off = 0,
        ReadOnly = 1,
        Full = 2
    }

    public enum PageVerify : int
    {
        None = 0,
        TornPageDetection = 1,
        Checksum = 2
    }

    public enum RecoveryModel : int
    {
        Full = 1,
        BulkLogged = 2,
        Simple = 3
    }

    public enum RetentionPeriodUnits : int
    {
        None = 0,
        Days = 1,
        Hours = 2,
        Minutes = 3
    }

    public enum AvailabilityDatabaseSynchronizationState : int
    {
        NotSynchronizing = 0,
        Synchronizing = 1,
        Synchronized = 2,
        Reverting = 3,
        Initializing = 4
    }

    public enum LogReuseWaitStatus : int
    {
        Nothing = 0,
        Checkpoint = 1,
        LogBackup = 2,
        BackupOrRestore = 3,
        Transaction = 4,
        Mirroring = 5,
        Replication = 6,
        SnapshotCreation = 7,
        LogScan = 8,
        Other = 9
    }

    public enum MirroringSafetyLevel : int
    {
        None = 0,
        Unknown = 1,
        Off = 2,
        Full = 3
    }

    public enum DelayedDurability : int
    {
        Disabled = 0,
        Allowed = 1,
        Forced = 2
    }

    public enum MirroringStatus : int
    {
        None = 0,
        Suspended = 1,
        Disconnected = 2,
        Synchronizing = 3,
        PendingFailover = 4,
        Synchronized = 5
    }

    public enum MirroringWitnessStatus : int
    {
        None = 0,
        Unknown = 1,
        Connected = 2,
        Disconnected = 3
    }

    [System.Flags]
    public enum ReplicationOptions : int
    {
        None = 0,
        Published = 1,
        Subscribed = 2,
        MergePublished = 4,
        MergeSubscribed = 8
    }

    public enum SnapshotIsolationState : int
    {
        Disabled = 0,
        Enabled = 1,
        PendingOff = 2,
        PendingOn = 3
    }

    [System.Flags]
    public enum DatabaseStatus : int
    {
        Normal = 1,
        Restoring = 2,
        RecoveryPending = 4,
        Recovering = 8,
        Suspect = 16,
        Offline = 32,
        Inaccessible = 62,
        Standby = 64,
        Shutdown = 128,
        EmergencyMode = 256,
        AutoClosed = 512
    }

    #endregion Public Enums

    #region Public Classes

    // Typename: Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionSetBase
    // Used by:
    //  SqlEndpointPermission.Tests.ps1
    public class ObjectPermissionSet
    {
        public ObjectPermissionSet(){}

        public ObjectPermissionSet(
            bool connect )
        {
            this.Connect = connect;
        }

        public bool Connect = false;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ServerPermissionSet
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionSetBase
    // Used by:
    //  SqlPermission.Tests.ps1
    public class ServerPermissionSet
    {
        public ServerPermissionSet(){}

        public ServerPermissionSet(
            bool alterAnyAvailabilityGroup,
            bool alterAnyEndpoint,
            bool connectSql,
            bool viewServerState )
        {
            this.AlterAnyAvailabilityGroup = alterAnyAvailabilityGroup;
            this.AlterAnyEndpoint = alterAnyEndpoint;
            this.ConnectSql = connectSql;
            this.ViewServerState = viewServerState;
        }

        public bool AlterAnyAvailabilityGroup = false;
        public bool AlterAnyEndpoint = false;
        public bool ConnectSql = false;
        public bool ViewServerState = false;
        public bool ControlServer = false;
        public bool CreateEndpoint = false;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ServerPermissionInfo
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionInfo
    // Used by:
    //  SqlPermission.Tests.ps1
    public class ServerPermissionInfo
    {
        public ServerPermissionInfo()
        {
            Microsoft.SqlServer.Management.Smo.ServerPermissionSet permissionSet = new Microsoft.SqlServer.Management.Smo.ServerPermissionSet();
            this.PermissionType = permissionSet;
        }

        public ServerPermissionInfo( Microsoft.SqlServer.Management.Smo.ServerPermissionSet permissionSet )
        {
            this.PermissionType = permissionSet;
        }

        public Microsoft.SqlServer.Management.Smo.ServerPermissionSet PermissionType;
        public string PermissionState;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabasePermissionSet
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionSetBase
    // Used by:
    //  SqlDatabasePermission.Tests.ps1
    //  Get-SqlDscDatabasePermission.Tests.ps1
    public class DatabasePermissionSet
    {
        public DatabasePermissionSet(){}

        public bool Connect = false;
        public bool Update = false;
        public bool Select = false;
        public bool Insert = false;
        public bool Alter = false;
        public bool CreateDatabase = false;
        public bool Delete = false;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionInfo
    // Used by:
    //  SqlDatabasePermission.Tests.ps1
    //  Get-SqlDscDatabasePermission.Tests.ps1
    public class DatabasePermissionInfo
    {
        public DatabasePermissionInfo()
        {
            Microsoft.SqlServer.Management.Smo.DatabasePermissionSet permissionSet = new Microsoft.SqlServer.Management.Smo.DatabasePermissionSet();
            this.PermissionType = permissionSet;
        }

        public DatabasePermissionInfo( Microsoft.SqlServer.Management.Smo.DatabasePermissionSet permissionSet )
        {
            this.PermissionType = permissionSet;
        }

        public Microsoft.SqlServer.Management.Smo.DatabasePermissionSet PermissionType;
        public string PermissionState;
        public string Grantee;
        public string GrantorType;
        public string ObjectClass;
        public string ObjectName;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Server
    // BaseType: Microsoft.SqlServer.Management.Smo.SqlSmoObject
    // Used by:
    //  SqlPermission
    //  DSC_SqlLogin
    public class Server
    {
        public AvailabilityGroupCollection AvailabilityGroups = new AvailabilityGroupCollection();
        public ServerConnection ConnectionContext;
        public string ComputerNamePhysicalNetBIOS;
        public DatabaseCollection Databases = new DatabaseCollection();
        public string DisplayName;
        public string DomainInstanceName;
        public EndpointCollection Endpoints = new EndpointCollection();
        public string FilestreamLevel = "Disabled";
        public string InstanceName;
        public string ServiceName;
        public string DefaultFile;
        public string DefaultLog;
        public string BackupDirectory;
        public bool IsClustered = false;
        public bool IsHadrEnabled = false;
        public bool IsMemberOfWsfcCluster = false;
        public Hashtable Logins = new Hashtable();
        public string Name;
        public string NetName;
        public Hashtable Roles = new Hashtable();
        public Hashtable Version = new Hashtable();
        public int VersionMajor;

        public Server(){}
        public Server(string name)
        {
            this.Name = name;
        }

        public Server Clone()
        {
            return new Server()
            {
                AvailabilityGroups = this.AvailabilityGroups,
                ConnectionContext = this.ConnectionContext,
                ComputerNamePhysicalNetBIOS = this.ComputerNamePhysicalNetBIOS,
                Databases = this.Databases,
                DisplayName = this.DisplayName,
                DomainInstanceName = this.DomainInstanceName,
                Endpoints = this.Endpoints,
                FilestreamLevel = this.FilestreamLevel,
                InstanceName = this.InstanceName,
                IsClustered = this.IsClustered,
                IsHadrEnabled = this.IsHadrEnabled,
                Logins = this.Logins,
                Name = this.Name,
                NetName = this.NetName,
                Roles = this.Roles,
                ServiceName = this.ServiceName,
                Version = this.Version,
                VersionMajor = this.VersionMajor
            };
        }

        public Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[] EnumServerPermissions( string principal, Microsoft.SqlServer.Management.Smo.ServerPermissionSet permissionSetQuery )
        {
            Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[] permissionInfo = null;
            List<Microsoft.SqlServer.Management.Smo.ServerPermissionInfo> listOfServerPermissionInfo = null;

            permissionInfo = listOfServerPermissionInfo.ToArray();

            return permissionInfo;
        }

        public void Grant( Microsoft.SqlServer.Management.Smo.ServerPermissionSet permission, string granteeName )
        {
        }

        public void Revoke( Microsoft.SqlServer.Management.Smo.ServerPermissionSet permission, string granteeName )
        {
        }

        // Property for SQL Agent support
        public Microsoft.SqlServer.Management.Smo.Agent.JobServer JobServer { get; set; }

        // Property for server configuration
        public Microsoft.SqlServer.Management.Smo.Configuration Configuration { get; set; }

        // Fabricated constructor
        private Server(string name, bool dummyParam)
        {
            this.Name = name;
        }

        public static Server CreateTypeInstance()
        {
            var server = new Server();

            server.JobServer = new Microsoft.SqlServer.Management.Smo.Agent.JobServer
            {
                Parent = server,
                Alerts = Microsoft.SqlServer.Management.Smo.Agent.AlertCollection.CreateTypeInstance(),
                Operators = Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection.CreateTypeInstance()
            };

            server.JobServer.Alerts.Parent = server.JobServer;
            server.JobServer.Operators.Parent = server.JobServer;

            server.Configuration = Microsoft.SqlServer.Management.Smo.Configuration.CreateTypeInstance();

            return server;
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Login
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by:
    //  DSC_SqlLogin
    public class Login
    {
        private bool _mockPasswordPassed = false;

        public string Name;
        public LoginType LoginType = LoginType.Unknown;
        public bool MockCreateCalled = false;
        public bool MustChangePassword = false;
        public bool PasswordPolicyEnforced = false;
        public bool PasswordExpirationEnabled = false;
        public bool IsDisabled = false;
        public string DefaultDatabase;
        public Server Parent;

        public Login( string name )
        {
            this.Name = name;
        }

        public Login( Server server, string name )
        {
            this.Name = name;
            this.Parent = server;
        }

        public Login( Object server, string name )
        {
            this.Name = name;
            if (server is Server)
            {
                this.Parent = (Server)server;
            }
        }

        public void Alter()
        {
        }

        public void ChangePassword( SecureString secureString )
        {
            IntPtr valuePtr = IntPtr.Zero;
            try
            {
                valuePtr = Marshal.SecureStringToGlobalAllocUnicode(secureString);
                if ( Marshal.PtrToStringUni(valuePtr) == "pw" )
                {
                    throw new FailedOperationException (
                        "FailedOperationException",
                        new SmoException (
                            "SmoException",
                            new SqlServerManagementException (
                                "SqlServerManagementException",
                                new Exception (
                                    "Password validation failed. The password does not meet Windows policy requirements because it is too short."
                                )
                            )
                        )
                    );
                }
                else if ( Marshal.PtrToStringUni(valuePtr) == "reused" )
                {
                    throw new FailedOperationException ();
                }
                else if ( Marshal.PtrToStringUni(valuePtr) == "other" )
                {
                    throw new Exception ();
                }
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(valuePtr);
            }
        }

        public void Create()
        {
            if( this.LoginType == LoginType.Unknown ) {
                throw new System.Exception( "Called Create() method without a value for LoginType." );
            }

            if( this.LoginType == LoginType.SqlLogin && _mockPasswordPassed != true ) {
                throw new System.Exception( "Called Create() method for the LoginType 'SqlLogin' but called with the wrong overloaded method. Did not pass the password with the Create() method." );
            }

            this.MockCreateCalled = true;
        }

        public void Create( SecureString secureString )
        {
            _mockPasswordPassed = true;

            this.Create();
        }

        public void Create( SecureString password, LoginCreateOptions options  )
        {
            IntPtr valuePtr = IntPtr.Zero;
            try
            {
                valuePtr = Marshal.SecureStringToGlobalAllocUnicode(password);
                if ( Marshal.PtrToStringUni(valuePtr) == "pw" )
                {
                    throw new FailedOperationException (
                        "FailedOperationException",
                        new SmoException (
                            "SmoException",
                            new SqlServerManagementException (
                                "SqlServerManagementException",
                                new Exception (
                                    "Password validation failed. The password does not meet Windows policy requirements because it is too short."
                                )
                            )
                        )
                    );
                }
                else if ( this.Name == "Existing" )
                {
                    throw new FailedOperationException ( "The login already exists" );
                }
                else if ( this.Name == "Unknown" )
                {
                    throw new Exception ();
                }
                else
                {
                    _mockPasswordPassed = true;

                    this.Create();
                }
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(valuePtr);
            }
        }

        public void Disable()
        {
            this.IsDisabled = true;
        }

        public void Enable()
        {
            this.IsDisabled = false;
        }

        public string Certificate;
        public string AsymmetricKey;
        public string Language;

        public void Drop()
        {
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ServerRole
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by:
    //  DSC_SqlRole
    public class ServerRole
    {
        public ServerRole( Server server, string name ) {
            this.Name = name;
            this.Parent = server;
        }

        public ServerRole( Object server, string name ) {
            this.Name = name;
            this.Parent = (Server)server;
        }

        public string Name;
        public Server Parent;
    }


    // TypeName: Microsoft.SqlServer.Management.Smo.Database
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by:
    //  DSC_SqlAGDatabase
    //  DSC_SqlDatabase
    //  DSC_SqlDatabasePermission
    public class Database
    {
        // Boolean Properties
        public bool AcceleratedRecoveryEnabled = true;
        public bool ActiveDirectory = false;
        public bool AnsiNullDefault = true;
        public bool AnsiNullsEnabled = true;
        public bool AnsiPaddingEnabled = true;
        public bool AnsiWarningsEnabled = true;
        public bool ArithmeticAbortEnabled = true;
        public bool AutoClose = false;
        public bool AutoCreateIncrementalStatisticsEnabled = true;
        public bool AutoCreateStatisticsEnabled = true;
        public bool AutoShrink = false;
        public bool AutoUpdateStatisticsAsync = false;
        public bool AutoUpdateStatisticsEnabled = true;
        public bool BrokerEnabled = false;
        public bool CaseSensitive = false;
        public bool ChangeTrackingAutoCleanUp = true;
        public bool ChangeTrackingEnabled = false;
        public bool CloseCursorsOnCommitEnabled = false;
        public bool ConcatenateNullYieldsNull = true;
        public bool DatabaseOwnershipChaining = false;
        public bool DataRetentionEnabled = false;
        public bool DateCorrelationOptimization = false;
        public bool DelayedDurability = false;
        public bool EncryptionEnabled = false;
        public bool HasDatabaseEncryptionKey = false;
        public bool HasFileInCloud = false;
        public bool HasMemoryOptimizedObjects = false;
        public bool HonorBrokerPriority = false;
        public bool IsAccessible = true;
        public bool IsDatabaseSnapshot = false;
        public bool IsDatabaseSnapshotBase = false;
        public bool IsDbAccessAdmin = false;
        public bool IsDbBackupOperator = false;
        public bool IsDbDatareader = false;
        public bool IsDbDatawriter = false;
        public bool IsDbDdlAdmin = false;
        public bool IsDbDenyDatareader = false;
        public bool IsDbDenyDatawriter = false;
        public bool IsDbManager = false;
        public bool IsDbOwner = true;
        public bool IsDbSecurityAdmin = false;
        public bool IsFabricDatabase = false;
        public bool IsFullTextEnabled = false;
        public bool IsLedger = false;
        public bool IsLoginManager = false;
        public bool IsMailHost = false;
        public bool IsManagementDataWarehouse = false;
        public bool IsMaxSizeApplicable = false;
        public bool IsMirroringEnabled = false;
        public bool IsParameterizationForced = false;
        public bool IsReadCommittedSnapshotOn = false;
        public bool IsSqlDw = false;
        public bool IsSqlDwEdition = false;
        public bool IsSystemObject = false;
        public bool IsVarDecimalStorageFormatEnabled = false;
        public bool IsVarDecimalStorageFormatSupported = true;
        public bool LegacyCardinalityEstimation = false;
        public bool LegacyCardinalityEstimationForSecondary = false;
        public bool LocalCursorsDefault = false;
        public bool NestedTriggersEnabled = true;
        public bool NumericRoundAbortEnabled = false;
        public bool ParameterSniffing = true;
        public bool ParameterSniffingForSecondary = true;
        public bool QueryOptimizerHotfixes = false;
        public bool QueryOptimizerHotfixesForSecondary = false;
        public bool QuotedIdentifiersEnabled = true;
        public bool ReadOnly = false;
        public bool RecursiveTriggersEnabled = false;
        public bool RemoteDataArchiveEnabled = false;
        public bool RemoteDataArchiveUseFederatedServiceAccount = false;
        public bool TemporalHistoryRetentionEnabled = true;
        public bool TransformNoiseWords = false;
        public bool Trustworthy = false;
        public bool WarnOnRename = true;

        // String Properties
        public string AvailabilityGroupName = "TestAG";
        public string AzureServiceObjective = "S1";
        public string CatalogCollation = "SQL_Latin1_General_CP1_CI_AS";
        public string Collation = "SQL_Latin1_General_CP1_CI_AS";
        public string DboLogin = "sa";
        public string DefaultFileGroup = "PRIMARY";
        public string DefaultFileStreamFileGroup = "FileStreamGroup";
        public string DefaultFullTextCatalog = "TestCatalog";
        public string DefaultSchema = "dbo";
        public string FilestreamDirectoryName = "TestDirectory";
        public string MirroringPartner = "TestPartner";
        public string MirroringPartnerInstance = "TestInstance";
        public string MirroringWitness = "TestWitness";
        public string Owner = "sa";
        public string PersistentVersionStoreFileGroup = "PRIMARY";
        public string PrimaryFilePath = "C:\\Data\\";
        public string RemoteDataArchiveCredential = "TestCredential";
        public string RemoteDataArchiveEndpoint = "https://test.endpoint.com";
        public string RemoteDataArchiveLinkedServer = "TestLinkedServer";
        public string RemoteDatabaseName = "RemoteDB";
        public string UserName = "TestUser";

        // Integer Properties
        public int ActiveConnections = 5;
        public int ChangeTrackingRetentionPeriod = 2;
        public int DefaultFullTextLanguage = 1033;
        public int DefaultLanguage = 0;
        public int ID = 5;
        public int MaxDop = 0;
        public int MaxDopForSecondary = 0;
        public int MirroringRedoQueueMaxSize = 100;
        public int MirroringRoleSequence = 1;
        public int MirroringSafetySequence = 1;
        public int MirroringTimeout = 10;
        public int TargetRecoveryTime = 60;
        public int TwoDigitYearCutoff = 2049;
        public int Version = 904;

        // Enum Properties
        public AvailabilityDatabaseSynchronizationState AvailabilityDatabaseSynchronizationState = AvailabilityDatabaseSynchronizationState.Synchronized;
        public RetentionPeriodUnits ChangeTrackingRetentionPeriodUnits = RetentionPeriodUnits.Days;
        public CompatibilityLevel CompatibilityLevel = CompatibilityLevel.Version150;
        public Microsoft.SqlServer.Management.Common.DatabaseEngineEdition DatabaseEngineEdition = Microsoft.SqlServer.Management.Common.DatabaseEngineEdition.Standard;
        public Microsoft.SqlServer.Management.Common.DatabaseEngineType DatabaseEngineType = Microsoft.SqlServer.Management.Common.DatabaseEngineType.Standalone;
        public ContainmentType ContainmentType = ContainmentType.None;
        public FilestreamNonTransactedAccessType FilestreamNonTransactedAccess = FilestreamNonTransactedAccessType.Off;
        public LogReuseWaitStatus LogReuseWaitStatus = LogReuseWaitStatus.Nothing;
        public MirroringSafetyLevel MirroringSafetyLevel = MirroringSafetyLevel.Full;
        public MirroringStatus MirroringStatus = MirroringStatus.None;
        public MirroringWitnessStatus MirroringWitnessStatus = MirroringWitnessStatus.None;
        public ReplicationOptions ReplicationOptions = ReplicationOptions.None;
        public SnapshotIsolationState SnapshotIsolationState = SnapshotIsolationState.Disabled;
        public PageVerify PageVerify = PageVerify.Checksum;
        public RecoveryModel RecoveryModel = RecoveryModel.Full;
        public DatabaseUserAccess UserAccess = DatabaseUserAccess.Multiple;
        public SqlSmoState State = SqlSmoState.Existing;
        public DatabaseStatus Status = DatabaseStatus.Normal;

        // Other existing properties
        public Certificate[] Certificates;
        public DateTime CreateDate;
        public DatabaseEncryptionKey DatabaseEncryptionKey;
        public DateTime LastBackupDate = DateTime.Now;
        public Hashtable FileGroups;
        public Hashtable LogFiles;


        public Database( Server server, string name ) {
            this.Name = name;
            this.Parent = server;
        }

        public Database( Object server, string name ) {
            this.Name = name;
            this.Parent = (Server)server;
        }

        public Database() {}

        public string Name;
        public Server Parent;

        public void Create()
        {
        }

        public void Drop()
        {
        }

        public void Alter()
        {
        }

        public void Alter(TerminationClause terminationClause)
        {
        }

        public Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[] EnumDatabasePermissions( string granteeName )
        {
            List<Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo> listOfDatabasePermissionInfo = new List<Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo>();

            Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[] permissionInfo = listOfDatabasePermissionInfo.ToArray();

            return permissionInfo;
        }

        public void Grant( Microsoft.SqlServer.Management.Smo.DatabasePermissionSet permission, string granteeName )
        {
        }

        public void Deny( Microsoft.SqlServer.Management.Smo.DatabasePermissionSet permission, string granteeName )
        {
        }

        public void SetDefaultFileGroup( string fileGroupName )
        {
            if (fileGroupName == "ThrowException")
            {
                throw new System.Exception("Failed to set default filegroup");
            }
            this.DefaultFileGroup = fileGroupName;
        }

        public void SetDefaultFileStreamFileGroup( string fileGroupName )
        {
            if (fileGroupName == "ThrowException")
            {
                throw new System.Exception("Failed to set default FILESTREAM filegroup");
            }
            this.DefaultFileStreamFileGroup = fileGroupName;
        }

        public void SetDefaultFullTextCatalog( string catalogName )
        {
            if (catalogName == "ThrowException")
            {
                throw new System.Exception("Failed to set default Full-Text catalog");
            }
            this.DefaultFullTextCatalog = catalogName;
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.User
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by:
    //  SqlDatabaseRole.Tests.ps1
    public class User
    {
        public User( Server server, string name )
        {
            this.Name = name;
        }

        public User( Object server, string name )
        {
            this.Name = name;
        }

        public string Name;
        public string Login;

        public void Create()
        {
        }

        public void Drop()
        {
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.SqlServerManagementException
    // BaseType: System.Exception
    // Used by:
    //  SqlLogin.Tests.ps1
    public class SqlServerManagementException : Exception
    {
        public SqlServerManagementException () : base () {}

        public SqlServerManagementException (string message) : base (message) {}

        public SqlServerManagementException (string message, Exception inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.SmoException
    // BaseType: Microsoft.SqlServer.Management.Smo.SqlServerManagementException
    // Used by:
    //  SqlLogin.Tests.ps1
    public class SmoException : SqlServerManagementException
    {
        public SmoException () : base () {}

        public SmoException (string message) : base (message) {}

        public SmoException (string message, SqlServerManagementException inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.FailedOperationException
    // BaseType: Microsoft.SqlServer.Management.Smo.SmoException
    // Used by:
    //  SqlLogin.Tests.ps1
    public class FailedOperationException : SmoException
    {
        public FailedOperationException () : base () {}

        public FailedOperationException (string message) : base (message) {}

        public FailedOperationException (string message, SmoException inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    // BaseType: Microsoft.SqlServer.Management.Smo.NamedSmoObject
    // Used by:
    //  SqlAG
    //  SqlAGDatabase
    public class AvailabilityGroup
    {
        public AvailabilityGroup()
        {}

        public AvailabilityGroup( Server server, string name )
        {}

        public string AutomatedBackupPreference;
        public AvailabilityDatabaseCollection AvailabilityDatabases = new AvailabilityDatabaseCollection();
        public AvailabilityReplicaCollection AvailabilityReplicas = new AvailabilityReplicaCollection();
        public bool BasicAvailabilityGroup;
        public bool DatabaseHealthTrigger;
        public bool DtcSupportEnabled;
        public string FailureConditionLevel;
        public string HealthCheckTimeout;
        public string Name;
        public string PrimaryReplicaServerName;
        public string LocalReplicaRole = "Secondary";

        public void Alter()
        {
            if ( this.Name == "AlterFailed" )
            {
                throw new System.Exception( "Alter Availability Group failed" );
            }
        }

        public AvailabilityGroup Clone()
        {
            return new AvailabilityGroup()
            {
                AutomatedBackupPreference = this.AutomatedBackupPreference,
                AvailabilityDatabases = this.AvailabilityDatabases,
                AvailabilityReplicas = this.AvailabilityReplicas,
                BasicAvailabilityGroup = this.BasicAvailabilityGroup,
                DatabaseHealthTrigger = this.DatabaseHealthTrigger,
                DtcSupportEnabled = this.DtcSupportEnabled,
                FailureConditionLevel = this.FailureConditionLevel,
                HealthCheckTimeout = this.HealthCheckTimeout,
                Name = this.Name,
                PrimaryReplicaServerName = this.PrimaryReplicaServerName,
                LocalReplicaRole = this.LocalReplicaRole
            };
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    // BaseType: Microsoft.SqlServer.Management.Smo.NamedSmoObject
    // Used by:
    //  SqlAG
    //  SqlAGDatabase
    public class AvailabilityReplica
    {
        public AvailabilityReplica()
        {}

        public AvailabilityReplica( AvailabilityGroup availabilityGroup, string name )
        {}

        public string AvailabilityMode;
        public string BackupPriority;
        public string ConnectionModeInPrimaryRole;
        public string ConnectionModeInSecondaryRole;
        public string EndpointUrl;
        public string FailoverMode;
        public string SeedingMode;
        public string Name;
        public string ReadOnlyRoutingConnectionUrl;
        public System.Collections.Specialized.StringCollection ReadOnlyRoutingList;
        public string Role = "Secondary";

        public void Alter()
        {
            if ( this.Name == "AlterFailed" )
            {
                throw new System.Exception( "Alter Availability Group Replica failed" );
            }
        }

        public void Create()
        {}
    }

    // TypeName: Microsoft.SqlServer.Management.Common.ServerConnection
    // Used by:
    //  SqlAGDatabase
    public class ServerConnection
    {
        public string TrueLogin;

        public void Create()
        {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
    // Used by:
    //  SqlAGDatabase
    public class AvailabilityDatabase
    {
        public string Name;

        public void Create() {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabaseCollection
    // Used by:
    //  SqlAGDatabase
    public class DatabaseCollection : Collection<Database>
    {
        public Database this[string name]
        {
            get
            {
                foreach ( Database database in this )
                {
                    if ( name == database.Name )
                    {
                        return database;
                    }
                }

                return null;
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
    // Used by:
    //  SqlAGDatabase
    public class AvailabilityReplicaCollection : Collection<AvailabilityReplica>
    {
        public AvailabilityReplica this[string name]
        {
            get
            {
                foreach ( AvailabilityReplica availabilityReplica in this )
                {
                    if ( name == availabilityReplica.Name )
                    {
                        return availabilityReplica;
                    }
                }

                return null;
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabaseEncryptionKey
    // Used by:
    //  SqlAGDatabase
    public class DatabaseEncryptionKey
    {
        public string EncryptorName;
        public byte[] Thumbprint;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Certificate
    // Used by:
    //  SqlAGDatabase
    public class Certificate
    {
        public byte[] Thumbprint;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
    // Used by:
    //  SqlAGDatabase
    public class AvailabilityDatabaseCollection : Collection<AvailabilityDatabase>
    {
        public AvailabilityDatabase this[string name]
        {
            get
            {
                foreach ( AvailabilityDatabase availabilityDatabase in this )
                {
                    if ( name == availabilityDatabase.Name )
                    {
                        return availabilityDatabase;
                    }
                }

                return null;
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
    // Used by:
    //  SqlAG
    public class AvailabilityGroupCollection : Collection<AvailabilityGroup>
    {
        public AvailabilityGroup this[string name]
        {
            get
            {
                foreach ( AvailabilityGroup availabilityGroup in this )
                {
                    if ( name == availabilityGroup.Name )
                    {
                        return availabilityGroup;
                    }
                }

                return null;
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
    // Used by:
    //  SqlAG
    public class Endpoint
    {
        public string Name;
        public string EndpointType;
        public Hashtable Protocol;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.EndpointCollection
    // Used by:
    //  SqlAG
    public class EndpointCollection : Collection<Endpoint>
    {
        public Endpoint this[string name]
        {
            get
            {
                foreach ( Endpoint endpoint in this )
                {
                    if ( name == endpoint.Name )
                    {
                        return endpoint;
                    }
                }

                return null;
            }
        }
    }

    public class Audit
    {
        // Constructor
        public Audit() { }
        public Audit(Microsoft.SqlServer.Management.Smo.Server server, System.String name) {
            this.Parent = server;
            this.Name = name;
        }

        // Property
        public Microsoft.SqlServer.Management.Smo.Server Parent { get; set; }
        public System.DateTime? CreateDate { get; set; }
        public System.DateTime? DateLastModified { get; set; }
        public Microsoft.SqlServer.Management.Smo.AuditDestinationType? DestinationType { get; set; }
        public System.Boolean? Enabled { get; set; }
        public System.String FileName { get; set; }
        public System.String FilePath { get; set; }
        public System.String Filter { get; set; }
        public System.Guid? Guid { get; set; }
        public System.Int32? ID { get; set; }
        public System.Int32? MaximumFiles { get; set; }
        public System.Int32? MaximumFileSize { get; set; }
        public Microsoft.SqlServer.Management.Smo.AuditFileSizeUnit? MaximumFileSizeUnit { get; set; }
        public System.Int64? MaximumRolloverFiles { get; set; }
        public Microsoft.SqlServer.Management.Smo.OnFailureAction? OnFailure { get; set; }
        public System.Int32? QueueDelay { get; set; }
        public System.Boolean? ReserveDiskSpace { get; set; }
        public System.Int32? RetentionDays { get; set; }
        public System.String Name { get; set; }
        // public Microsoft.SqlServer.Management.Smo.AbstractCollectionBase ParentCollection { get; set; }
        // public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        // public Microsoft.SqlServer.Management.Smo.SqlPropertyCollection Properties { get; set; }
        // public Microsoft.SqlServer.Management.Common.ServerVersion ServerVersion { get; set; }
        // public Microsoft.SqlServer.Management.Common.DatabaseEngineType DatabaseEngineType { get; set; }
        // public Microsoft.SqlServer.Management.Common.DatabaseEngineEdition DatabaseEngineEdition { get; set; }
        // public Microsoft.SqlServer.Management.Smo.ExecutionManager ExecutionManager { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState? State { get; set; }
    }

    public class Property
    {
        // Property
        public System.String Name { get; set; }
        public System.Object Value { get; set; }
        public System.Type Type { get; set; }
        public System.Boolean Writable { get; set; }
        public System.Boolean Readable { get; set; }
        public System.Boolean Expensive { get; set; }
        public System.Boolean Dirty { get; set; }
        public System.Boolean Retrieved { get; set; }
        public System.Boolean IsNull { get; set; }

        // Fabricated constructor
        private Property() { }
        public static Property CreateTypeInstance()
        {
            return new Property();
        }
    }

    public class PropertyCollection
    {
        // Property
        public System.Int32 Count { get; set; }
        public Microsoft.SqlServer.Management.Smo.Property Item { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

        // Fabricated constructor
        private PropertyCollection() { }
        public static PropertyCollection CreateTypeInstance()
        {
            return new PropertyCollection();
        }
    }

    public class ConfigProperty
    {
        // Property
        public System.String DisplayName { get; set; }
        public System.Int32 Number { get; set; }
        public System.Int32 Minimum { get; set; }
        public System.Int32 Maximum { get; set; }
        public System.Boolean IsDynamic { get; set; }
        public System.Boolean IsAdvanced { get; set; }
        public System.String Description { get; set; }
        public System.Int32 RunValue { get; set; }
        public System.Int32 ConfigValue { get; set; }

        // Fabricated constructor
        private ConfigProperty() { }
        public static ConfigProperty CreateTypeInstance()
        {
            return new ConfigProperty();
        }
    }

    public class ConfigPropertyCollection : IEnumerable
    {
        // Property
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }
        public Microsoft.SqlServer.Management.Smo.ConfigProperty Item { get; set; }

        // For enumeration
        private List<Microsoft.SqlServer.Management.Smo.ConfigProperty> _items = new List<Microsoft.SqlServer.Management.Smo.ConfigProperty>();

        // Implement IEnumerable
        public IEnumerator GetEnumerator()
        {
            return _items.GetEnumerator();
        }

        // Add method to add items
        public void Add(Microsoft.SqlServer.Management.Smo.ConfigProperty item)
        {
            _items.Add(item);
        }

        // Fabricated constructor
        private ConfigPropertyCollection() { }
        public static ConfigPropertyCollection CreateTypeInstance()
        {
            return new ConfigPropertyCollection();
        }
    }

    public class Configuration
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.ConfigPropertyCollection Properties { get; set; }

        // Method
        public void Alter()
        {
        }

        // Fabricated constructor
        private Configuration() { }
        public static Configuration CreateTypeInstance()
        {
            return new Configuration()
            {
                Properties = ConfigPropertyCollection.CreateTypeInstance()
            };
        }
    }

    #endregion Public Classes
}

namespace Microsoft.SqlServer.Management.Sdk.Sfc
{
    public class XPathExpression
    {
        // Constructor
        public XPathExpression(System.String strXPathExpression) { }

        // Property
        public System.Int32 Length { get; set; }
        public System.String ExpressionSkeleton { get; set; }

        // Fabricated constructor
        private XPathExpression() { }
        public static XPathExpression CreateTypeInstance()
        {
            return new XPathExpression();
        }
    }

    public class Urn
    {
        // Constructor
        public Urn() { }
        public Urn(System.String value) { }

        // Property
        public Microsoft.SqlServer.Management.Sdk.Sfc.XPathExpression XPathExpression { get; set; }
        public System.String Value { get; set; }
        public System.String DomainInstanceName { get; set; }
        public System.String Type { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Parent { get; set; }

    }

}

namespace Microsoft.SqlServer.Management.Smo.Wmi
{
    #region Public Enums

    // TypeName: Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType
    // Used by:
    //  DSC_SqlServiceAccount.Tests.ps1
    public enum ManagedServiceType : int
    {
        SqlServer = 1,
        SqlAgent = 2,
        Search = 3,
        SqlServerIntegrationService = 4,
        AnalysisServer = 5,
        ReportServer = 6,
        SqlBrowser = 7,
        NotificationServer = 8,
    }

    public enum ServiceErrorControl : int
    {
        Ignore = 0,
        Normal = 1,
        Severe = 2,
        Critical = 3,
        Unknown = 4,
    }

    public enum ServiceState : int
    {
        Stopped = 1,
        StartPending = 2,
        StopPending = 3,
        Running = 4,
        ContinuePending = 5,
        PausePending = 6,
        Paused = 7,
        Unknown = 8,
    }

    public enum ServiceStartMode : int
    {
        Boot = 0,
        System = 1,
        Auto = 2,
        Manual = 3,
        Disabled = 4,
    }

   public enum ProviderArchitecture : int
    {
        Default = 0,
        Use32bit = 32,
        Use64bit = 64,
    }

    #endregion

    #region Public Classes

    // TypeName: Microsoft.SqlServer.Management.Smo.Wmi.Service
    // Used by:
    //  Get-SqlDscManagedComputerService
    public class Service
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer Parent { get; set; }
        public System.Boolean AcceptsPause { get; set; }
        public System.Boolean AcceptsStop { get; set; }
        public System.String Description { get; set; }
        public System.String DisplayName { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ServiceErrorControl ErrorControl { get; set; }
        public System.Int32 ExitCode { get; set; }
        public System.String PathName { get; set; }
        public System.Int32 ProcessId { get; set; }
        public System.String ServiceAccount { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ServiceState ServiceState { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ServiceStartMode StartMode { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType Type { get; set; }
        public System.Boolean IsHadrEnabled { get; set; }
        public System.String StartupParameters { get; set; }
        public System.Collections.Specialized.StringCollection Dependencies { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection AdvancedProperties { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public System.String Name { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }

        // Fabricated constructor
        private Service() { }
        public static Service CreateTypeInstance()
        {
            return new Service();
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Wmi.ServiceCollection
    // Used by:
    //  Get-SqlDscManagedComputerService
    public class ServiceCollection
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.Service Item { get; set; }
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

        // Fabricated constructor
        private ServiceCollection() { }
        public static ServiceCollection CreateTypeInstance()
        {
            return new ServiceCollection();
        }
    }

    public class WmiConnectionInfo
    {
        // Property
        public System.TimeSpan Timeout { get; set; }
        public System.String MachineName { get; set; }
        public System.String Username { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ProviderArchitecture ProviderArchitecture { get; set; }

        // Fabricated constructor
        private WmiConnectionInfo() { }
        public static WmiConnectionInfo CreateTypeInstance()
        {
            return new WmiConnectionInfo();
        }
    }

    public class NetLibInfo
    {
        // Property
        public System.String FileName { get; set; }
        public System.String Version { get; set; }
        public System.DateTime Date { get; set; }
        public System.Int32 Size { get; set; }

        // Fabricated constructor
        private NetLibInfo() { }
        public static NetLibInfo CreateTypeInstance()
        {
            return new NetLibInfo();
        }
    }

    public class ProtocolProperty
    {
        // Property
        public System.String Name { get; set; }
        public System.Object Value { get; set; }
        public System.Type Type { get; set; }
        public System.Boolean Writable { get; set; }
        public System.Boolean Readable { get; set; }
        public System.Boolean Expensive { get; set; }
        public System.Boolean Dirty { get; set; }
        public System.Boolean Retrieved { get; set; }
        public System.Boolean IsNull { get; set; }

        // Fabricated constructor
        private ProtocolProperty() { }
        public static ProtocolProperty CreateTypeInstance()
        {
            return new ProtocolProperty();
        }
    }

    public class ProtocolPropertyCollection
    {
        // Property
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ProtocolProperty Item { get; set; }

        // Fabricated constructor
        private ProtocolPropertyCollection() { }
        public static ProtocolPropertyCollection CreateTypeInstance()
        {
            return new ProtocolPropertyCollection();
        }
    }

    public class ClientProtocol
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer Parent { get; set; }
        public System.String DisplayName { get; set; }
        public System.Boolean IsEnabled { get; set; }
        public System.String NetworkLibrary { get; set; }
        public System.Int32 Order { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.NetLibInfo NetLibInfo { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ProtocolPropertyCollection ProtocolProperties { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public System.String Name { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }

        // Fabricated constructor
        private ClientProtocol() { }
        public static ClientProtocol CreateTypeInstance()
        {
            return new ClientProtocol();
        }
    }

    public class ClientProtocolCollection
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ClientProtocol Item { get; set; }
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

        // Fabricated constructor
        private ClientProtocolCollection() { }
        public static ClientProtocolCollection CreateTypeInstance()
        {
            return new ClientProtocolCollection();
        }
    }

    public class IPAddressPropertyCollection
    {
        // Property
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ProtocolProperty Item { get; set; }

        // Fabricated constructor
        private IPAddressPropertyCollection() { }
        public static IPAddressPropertyCollection CreateTypeInstance()
        {
            return new IPAddressPropertyCollection();
        }
    }

    public class ServerIPAddress
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol Parent { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.IPAddressPropertyCollection IPAddressProperties { get; set; }
        public System.Net.IPAddress IPAddress { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public System.String Name { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }

        // Fabricated constructor
        private ServerIPAddress() { }
        public static ServerIPAddress CreateTypeInstance()
        {
            return new ServerIPAddress();
        }
    }

    public class ServerIPAddressCollection
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress Item { get; set; }
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

        // Fabricated constructor
        private ServerIPAddressCollection() { }
        public static ServerIPAddressCollection CreateTypeInstance()
        {
            return new ServerIPAddressCollection();
        }
    }

    public class ServerProtocol
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance Parent { get; set; }
        public System.String DisplayName { get; set; }
        public System.Boolean HasMultiIPAddresses { get; set; }
        public System.Boolean IsEnabled { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddressCollection IPAddresses { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ProtocolPropertyCollection ProtocolProperties { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public System.String Name { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }

        // Fabricated constructor
        private ServerProtocol() { }
        public static ServerProtocol CreateTypeInstance()
        {
            return new ServerProtocol();
        }
    }

    public class ServerProtocolCollection : System.Collections.IEnumerable
    {
        // Properties
        public System.Int32 Count { get { return protocols.Count; } }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

        // Collection of protocols
        private readonly System.Collections.Generic.Dictionary<string, Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol> protocols =
            new System.Collections.Generic.Dictionary<string, Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol>(System.StringComparer.OrdinalIgnoreCase);

        // Indexer
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol this[string name]
        {
            get
            {
                if (protocols.ContainsKey(name))
                {
                    return protocols[name];
                }
                return null;
            }
            set
            {
                if (value == null)
                {
                    protocols.Remove(name);
                }
                else
                {
                    protocols[name] = value;
                }
            }
        }

        // IEnumerable implementation
        public System.Collections.IEnumerator GetEnumerator()
        {
            return protocols.Values.GetEnumerator();
        }

        // Fabricated constructor
        private ServerProtocolCollection() { }
        public static ServerProtocolCollection CreateTypeInstance()
        {
            return new ServerProtocolCollection();
        }
    }

    public class ServerInstance
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer Parent { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocolCollection ServerProtocols { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public System.String Name { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }

        // Fabricated constructor
        private ServerInstance() { }
        public static ServerInstance CreateTypeInstance()
        {
            return new ServerInstance();
        }
    }

    public class ServerInstanceCollection : System.Collections.IEnumerable
    {
        // Properties
        public System.Int32 Count { get { return instances.Count; } }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

        // Collection of instances
        private System.Collections.Generic.Dictionary<string, Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance> instances = new System.Collections.Generic.Dictionary<string, Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance>(System.StringComparer.OrdinalIgnoreCase);

        // Indexer
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance this[string name]
        {
            get
            {
                if (instances.ContainsKey(name))
                {
                    return instances[name];
                }
                return null;
            }
            set
            {
                if (value == null)
                {
                    instances.Remove(name);
                }
                else
                {
                    instances[name] = value;
                }
            }
        }

        // IEnumerable implementation
        public System.Collections.IEnumerator GetEnumerator()
        {
            return instances.Values.GetEnumerator();
        }

        // Fabricated constructor
        private ServerInstanceCollection() { }
        public static ServerInstanceCollection CreateTypeInstance()
        {
            return new ServerInstanceCollection();
        }
    }

    public class ServerAlias
    {
        // Constructor
        public ServerAlias(Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer managedComputer, System.String name) { }
        public ServerAlias() { }

        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer Parent { get; set; }
        public System.String ConnectionString { get; set; }
        public System.String ProtocolName { get; set; }
        public System.String ServerName { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public System.String Name { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }
    }

    public class ServerAliasCollection
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerAlias Item { get; set; }
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

        // Fabricated constructor
        private ServerAliasCollection() { }
        public static ServerAliasCollection CreateTypeInstance()
        {
            return new ServerAliasCollection();
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
    // Used by:
    //  DSC_SqlTraceFlag.Tests.ps1
    //  Get-SqlDscManagedComputerService
    public class ManagedComputer
    {
        // Constructor
        public ManagedComputer() { }
        public ManagedComputer(System.String machineName) { }
        public ManagedComputer(System.String machineName, System.String userName, System.String password) { }
        public ManagedComputer(System.String machineName, System.String userName, System.String password, Microsoft.SqlServer.Management.Smo.Wmi.ProviderArchitecture providerArchitecture) { }

        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.WmiConnectionInfo ConnectionSettings { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ServiceCollection Services { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ClientProtocolCollection ClientProtocols { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerInstanceCollection ServerInstances { get; set; }
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerAliasCollection ServerAliases { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public System.String Name { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }
    }

    #endregion
}

namespace Microsoft.SqlServer.Management.Smo.Agent
{
    #region Public Enums

    // TypeName: Microsoft.SqlServer.Management.Smo.Agent.AlertType
    // Used by:
    //  Get-SqlDscAgentAlert.Tests.ps1
    //  New-SqlDscAgentAlert.Tests.ps1
    //  Set-SqlDscAgentAlert.Tests.ps1
    //  Remove-SqlDscAgentAlert.Tests.ps1
    //  Test-SqlDscIsAgentAlert.Tests.ps1
    //  SqlAgentAlert.Tests.ps1
    public enum AlertType
    {
        SqlServerEvent = 1,
        SqlServerPerformanceCondition = 2,
        NonSqlServerEvent = 3,
        WmiEvent = 4
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Agent.CompletionAction
    // Used by:
    //  SQL Agent Alert commands unit tests
    //  SqlAgentAlert.Tests.ps1
    public enum CompletionAction
    {
        Never = 0,
        OnSuccess = 1,
        OnFailure = 2,
        Always = 3
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Agent.WeekDays
    // Used by:
    //  SQL Agent Operator commands unit tests
    //  New-SqlDscAgentOperator.Tests.ps1
    //  Set-SqlDscAgentOperator.Tests.ps1
    public enum WeekDays
    {
        Sunday = 1,
        Monday = 2,
        Tuesday = 4,
        Wednesday = 8,
        Thursday = 16,
        Friday = 32,
        Weekdays = 62,
        Saturday = 64,
        WeekEnds = 65,
        EveryDay = 127
    }

    #endregion

    #region Public Classes

    // TypeName: Microsoft.SqlServer.Management.Smo.Agent.JobServer
    // Used by:
    //  SQL Agent Alert commands unit tests
    //  SqlAgentAlert.Tests.ps1
    //  SQL Agent Operator commands unit tests
    //  SqlAgentOperator.Tests.ps1
    public class JobServer
    {
        // Constructor
        public JobServer() { }

        // Property
        public Microsoft.SqlServer.Management.Smo.Agent.AlertCollection Alerts { get; set; }
        public Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection Operators { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public System.String Name { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }
        public Microsoft.SqlServer.Management.Smo.Server Parent { get; set; }

        // Mock property counters for tracking method calls
        public System.Int32 MockOperatorMethodCreateCalled { get; set; }
        public System.Int32 MockOperatorMethodDropCalled { get; set; }
        public System.Int32 MockOperatorMethodAlterCalled { get; set; }

        // Fabricated constructor
        private JobServer(Microsoft.SqlServer.Management.Smo.Server server) { }
        public static JobServer CreateTypeInstance()
        {
            return new JobServer();
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Agent.AlertCollection
    // Used by:
    //  SQL Agent Alert commands unit tests
    //  SqlAgentAlert.Tests.ps1
    public class AlertCollection : ICollection
    {
        private System.Collections.Generic.Dictionary<string, Microsoft.SqlServer.Management.Smo.Agent.Alert> alerts = new System.Collections.Generic.Dictionary<string, Microsoft.SqlServer.Management.Smo.Agent.Alert>();

        // Property
        public Microsoft.SqlServer.Management.Smo.Agent.Alert this[System.String name]
        {
            get { return alerts.ContainsKey(name) ? alerts[name] : null; }
            set { alerts[name] = value; }
        }
        public Microsoft.SqlServer.Management.Smo.Agent.Alert this[System.Int32 index]
        {
            get { return alerts.Values.ElementAtOrDefault(index); }
            set { /* Not implemented for stub */ }
        }
        public System.Int32 Count { get { return alerts.Count; } set { } }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }
        public Microsoft.SqlServer.Management.Smo.Agent.JobServer Parent { get; set; }

        // Method
        public void Add(Microsoft.SqlServer.Management.Smo.Agent.Alert alert) { alerts[alert.Name] = alert; }
        public void Remove(Microsoft.SqlServer.Management.Smo.Agent.Alert alert) { alerts.Remove(alert.Name); }
        public void Remove(System.String name) { alerts.Remove(name); }
        public void CopyTo(System.Array array, System.Int32 index) { }
        public IEnumerator GetEnumerator() { return alerts.Values.GetEnumerator(); }
        public void Refresh() { /* Stub implementation for refreshing alerts */ }

        // Fabricated constructor
        private AlertCollection() { }
        public static AlertCollection CreateTypeInstance()
        {
            return new AlertCollection();
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Agent.Alert
    // Used by:
    //  Get-SqlDscAgentAlert.Tests.ps1
    //  New-SqlDscAgentAlert.Tests.ps1
    //  Set-SqlDscAgentAlert.Tests.ps1
    //  Remove-SqlDscAgentAlert.Tests.ps1
    //  Test-SqlDscIsAgentAlert.Tests.ps1
    public class Alert
    {
        // Constructor
        public Alert() { }
        public Alert(Microsoft.SqlServer.Management.Smo.Agent.JobServer jobServer, System.String name)
        {
            this.Name = name;
        }

        // Property
        public System.String Name { get; set; }
        public System.Boolean IsEnabled { get; set; }
        public Microsoft.SqlServer.Management.Smo.Agent.AlertType AlertType { get; set; }
        public System.String DatabaseName { get; set; }
        public System.String DelayBetweenResponses { get; set; }
        public System.String EventDescriptionKeyword { get; set; }
        public System.String EventSource { get; set; }
        public System.Boolean HasNotification { get; set; }
        public System.Boolean IncludeEventDescription { get; set; }
        public System.Int32 MessageID { get; set; }
        public System.String NotificationMessage { get; set; }
        public System.String PerformanceCondition { get; set; }
        public System.Int32 Severity { get; set; }
        public System.String WmiEventNamespace { get; set; }
        public System.String WmiEventQuery { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }
        public Microsoft.SqlServer.Management.Smo.Agent.JobServer Parent { get; set; }

        // Method
        public void Create() { }
        public void Drop() { }
        public void Alter() { }

        // Fabricated constructor
        private Alert(Microsoft.SqlServer.Management.Smo.Agent.JobServer jobServer, System.String name, System.Boolean dummyParam) { }
        public static Alert CreateTypeInstance()
        {
            return new Alert();
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection
    // Used by:
    //  SQL Agent Operator commands unit tests
    //  SqlAgentOperator.Tests.ps1
    public class OperatorCollection : ICollection
    {
        private System.Collections.Generic.Dictionary<string, Microsoft.SqlServer.Management.Smo.Agent.Operator> operators = new System.Collections.Generic.Dictionary<string, Microsoft.SqlServer.Management.Smo.Agent.Operator>();

        // Property
        public Microsoft.SqlServer.Management.Smo.Agent.Operator this[System.String name]
        {
            get { return operators.ContainsKey(name) ? operators[name] : null; }
            set { operators[name] = value; }
        }
        public Microsoft.SqlServer.Management.Smo.Agent.Operator this[System.Int32 index]
        {
            get { return operators.Values.ElementAtOrDefault(index); }
            set { /* Not implemented for stub */ }
        }
        public System.Int32 Count { get { return operators.Count; } set { } }
        public System.Boolean IsSynchronized { get { return false; } set { } }
        public System.Object SyncRoot { get { return null; } set { } }
        public Microsoft.SqlServer.Management.Smo.Agent.JobServer Parent { get; set; }

        public void Add(Microsoft.SqlServer.Management.Smo.Agent.Operator operatorObj) { operators[operatorObj.Name] = operatorObj; }
        public void Remove(Microsoft.SqlServer.Management.Smo.Agent.Operator operatorObj) { operators.Remove(operatorObj.Name); }
        public void CopyTo(System.Array array, System.Int32 index) { /* Not implemented for stub */ }
        public System.Collections.IEnumerator GetEnumerator() { return operators.Values.GetEnumerator(); }
        public void Refresh() { /* Not implemented for stub */ }

        // Fabricated constructor
        private OperatorCollection() { }
        public static OperatorCollection CreateTypeInstance()
        {
            return new OperatorCollection();
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Agent.Operator
    // Used by:
    //  Get-SqlDscAgentOperator.Tests.ps1
    //  New-SqlDscAgentOperator.Tests.ps1
    //  Set-SqlDscAgentOperator.Tests.ps1
    //  Remove-SqlDscAgentOperator.Tests.ps1
    //  Test-SqlDscAgentOperator.Tests.ps1
    public class Operator
    {
        public Operator() { }
        public Operator(Microsoft.SqlServer.Management.Smo.Agent.JobServer jobServer, System.String name)
        {
            this.Parent = jobServer;
            this.Name = name;
        }

        // Property
        public System.String Name { get; set; }
        public System.String EmailAddress { get; set; }
        public System.String CategoryName { get; set; }
        public System.String NetSendAddress { get; set; }
        public System.String PagerAddress { get; set; }
        public Microsoft.SqlServer.Management.Smo.Agent.WeekDays PagerDays { get; set; }
        public System.TimeSpan SaturdayPagerEndTime { get; set; }
        public System.TimeSpan SaturdayPagerStartTime { get; set; }
        public System.TimeSpan SundayPagerEndTime { get; set; }
        public System.TimeSpan SundayPagerStartTime { get; set; }
        public System.TimeSpan WeekdayPagerEndTime { get; set; }
        public System.TimeSpan WeekdayPagerStartTime { get; set; }
        public System.Boolean Enabled { get; set; }
        public Microsoft.SqlServer.Management.Sdk.Sfc.Urn Urn { get; set; }
        public Microsoft.SqlServer.Management.Smo.PropertyCollection Properties { get; set; }
        public System.Object UserData { get; set; }
        public Microsoft.SqlServer.Management.Smo.SqlSmoState State { get; set; }
        public Microsoft.SqlServer.Management.Smo.Agent.JobServer Parent { get; set; }

        // Method
        public void Create()
        {
            if (this.Parent != null)
            {
                this.Parent.MockOperatorMethodCreateCalled++;
            }

            // Mock failure for specific operator name used in testing
            if (this.Name == "MockFailMethodCreateOperator")
            {
                throw new System.Exception("Simulated Create() method failure for testing purposes.");
            }
        }
        public void Drop()
        {
            if (this.Parent != null)
            {
                this.Parent.MockOperatorMethodDropCalled++;
            }
        }
        public void Alter()
        {
            if (this.Parent != null)
            {
                this.Parent.MockOperatorMethodAlterCalled++;
            }
        }

        // Fabricated constructor
        private Operator(Microsoft.SqlServer.Management.Smo.Agent.JobServer jobServer, System.String name, System.Boolean dummyParam) { }
        public static Operator CreateTypeInstance()
        {
            return new Operator();
        }
    }

    #endregion
}

namespace Microsoft.SqlServer.Management.Common
{
    #region Public Enums

    // TypeName: Microsoft.SqlServer.Management.Common.DatabaseEngineEdition
    // BaseType: System.Enum
    // Used by:
    //  Test-SqlDscDatabaseProperty
    public enum DatabaseEngineEdition : int
    {
        Unknown = 0,
        Personal = 1,
        Standard = 2,
        Enterprise = 3,
        Express = 4,
        SqlDatabase = 5,
        SqlDataWarehouse = 6,
        SqlStretchDatabase = 7,
        SqlManagedInstance = 8,
        SqlDatabaseEdge = 9,
        SqlAzureArcManagedInstance = 10,
        SqlOnDemand = 11
    }

    // TypeName: Microsoft.SqlServer.Management.Common.DatabaseEngineType
    // BaseType: System.Enum
    // Used by:
    //  Test-SqlDscDatabaseProperty
    public enum DatabaseEngineType : int
    {
        Unknown = 0,
        Standalone = 1,
        SqlAzureDatabase = 2,
    }

    #endregion
}
