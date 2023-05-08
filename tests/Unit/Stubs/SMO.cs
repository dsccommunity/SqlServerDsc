// Stubs for the namespace Microsoft.SqlServer.Management.Smo. Used for mocking in tests.

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
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
                Version = this.Version
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
        public bool MustChangePassword = false;
        public bool PasswordPolicyEnforced = false;
        public bool PasswordExpirationEnabled = false;
        public bool IsDisabled = false;
        public string DefaultDatabase;

        public Login( string name )
        {
            this.Name = name;
        }

        public Login( Server server, string name )
        {
            this.Name = name;
        }

        public Login( Object server, string name )
        {
            this.Name = name;
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
        }

        public ServerRole( Object server, string name ) {
            this.Name = name;
        }

        public string Name;
    }


    // TypeName: Microsoft.SqlServer.Management.Smo.Database
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by:
    //  DSC_SqlAGDatabase
    //  DSC_SqlDatabase
    //  DSC_SqlDatabasePermission
    public class Database
    {
        public bool AutoClose = false;
        public string AvailabilityGroupName = "";
        public Certificate[] Certificates;
        public string ContainmentType = "None";
        public DateTime CreateDate;
        public DatabaseEncryptionKey DatabaseEncryptionKey;
        public string DefaultFileStreamFileGroup;
        public bool EncryptionEnabled = false;
        public Hashtable FileGroups;
        public string FilestreamDirectoryName;
        public string FilestreamNonTransactedAccess = "Off";
        public int ID = 6;
        public bool IsMirroringEnabled = false;
        public DateTime LastBackupDate = DateTime.Now;
        public Hashtable LogFiles;
        public string Owner = "sa";
        public bool ReadOnly = false;
        public string RecoveryModel = "Full";
        public string UserAccess = "Multiple";


        public Database( Server server, string name ) {
            this.Name = name;
        }

        public Database( Object server, string name ) {
            this.Name = name;
        }

        public Database() {}

        public string Name;

        public void Create()
        {
        }

        public void Drop()
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

    public class ConfigPropertyCollection
    {
        // Property
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }
        public Microsoft.SqlServer.Management.Smo.ConfigProperty Item { get; set; }

        // Fabricated constructor
        private ConfigPropertyCollection() { }
        public static ConfigPropertyCollection CreateTypeInstance()
        {
            return new ConfigPropertyCollection();
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

    public class ServerProtocolCollection
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol Item { get; set; }
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

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

    public class ServerInstanceCollection
    {
        // Property
        public Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance Item { get; set; }
        public System.Int32 Count { get; set; }
        public System.Boolean IsSynchronized { get; set; }
        public System.Object SyncRoot { get; set; }

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
