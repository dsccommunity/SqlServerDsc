using System;
using System.Collections.Generic;

namespace Microsoft.SqlServer.Management.Smo
{
    public class Globals
    {
        // Static property that is switched on or off by tests if data should be mocked (true) or not (false).
        public static bool GenerateMockData = false;
    }

    // Typename: Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionSetBase
    // Used by: 
    //  xSQLServerEndpointPermission.Tests.ps1
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
    //  xSQLServerPermission.Tests.ps1
    public class ServerPermissionSet 
    {
        public ServerPermissionSet(){}

        public ServerPermissionSet(
            bool alterAnyAvailabilityGroup, 
            bool alterAnyEndPoint,
            bool connectSql,  
            bool viewServerState )
        {
            this.AlterAnyAvailabilityGroup = alterAnyAvailabilityGroup; 
            this.AlterAnyEndPoint = alterAnyEndPoint;
            this.ConnectSql = connectSql;
            this.ViewServerState = viewServerState;
        } 
    
        public bool AlterAnyAvailabilityGroup = false;
        public bool AlterAnyEndPoint = false;
        public bool ConnectSql = false;
        public bool ViewServerState = false;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ServerPermissionInfo
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionInfo
    // Used by: 
    //  xSQLServerPermission.Tests.ps1
    public class ServerPermissionInfo 
    {
        public ServerPermissionInfo()
        {
            Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] permissionSet = { new Microsoft.SqlServer.Management.Smo.ServerPermissionSet() };
            this.PermissionType = permissionSet;
        }

        public ServerPermissionInfo( 
            Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] permissionSet )
        {
            this.PermissionType = permissionSet;
        }
        
        public Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] PermissionType;
        public string PermissionState = "Grant";
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Server
    // BaseType: Microsoft.SqlServer.Management.Smo.SqlSmoObject
    // Used by: 
    //  xSQLServerPermission.Tests.ps1
    public class Server 
    { 
        public string MockGranteeName;

        public string Name;
        public string DisplayName;
        public string InstanceName;
        public bool IsHadrEnabled = false;

        public Server(){} 

        public Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[] EnumServerPermissions( string principal, Microsoft.SqlServer.Management.Smo.ServerPermissionSet permissionSetQuery ) 
        { 
            List<Microsoft.SqlServer.Management.Smo.ServerPermissionInfo> listOfServerPermissionInfo = new List<Microsoft.SqlServer.Management.Smo.ServerPermissionInfo>();
            
            if( Globals.GenerateMockData ) {
                Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] permissionSet = { 
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( true, false, false, false ),
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( false, true, false, false ),
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( false, false, true, false ),
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( false, false, false, true ) };

                listOfServerPermissionInfo.Add( new Microsoft.SqlServer.Management.Smo.ServerPermissionInfo( permissionSet ) );
            } else {
                listOfServerPermissionInfo.Add( new Microsoft.SqlServer.Management.Smo.ServerPermissionInfo() );
            }

            Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[] permissionInfo = listOfServerPermissionInfo.ToArray();

            return permissionInfo;
        }

        public void Grant( Microsoft.SqlServer.Management.Smo.ServerPermissionSet permission, string granteeName )
        {
            if( granteeName != this.MockGranteeName ) 
            {
                string errorMessage = "Expected to get granteeName == '" + this.MockGranteeName + "'. But got '" + granteeName + "'";
                throw new System.ArgumentException(errorMessage, "granteeName");
            }
        }

        public void Revoke( Microsoft.SqlServer.Management.Smo.ServerPermissionSet permission, string granteeName )
        {
            if( granteeName != this.MockGranteeName ) 
            {
                string errorMessage = "Expected to get granteeName == '" + this.MockGranteeName + "'. But got '" + granteeName + "'";
                throw new System.ArgumentException(errorMessage, "granteeName");
            }
        }
    }
}
