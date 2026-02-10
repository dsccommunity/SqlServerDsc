ConvertFrom-StringData @'
    GetEndpointPermission = Enumerating the current permissions for the endpoint with the name '{0}' for the instance '{1}'.
    SQLInstanceNotReachable = Unable to connect to SQL instance or retrieve option. Assuming resource is not in desired state. Error: {0}
    EndpointNotFound = The endpoint with the name '{0}' does not exist.
    UnexpectedErrorFromGet = Got unexpected result from Get-TargetResource. No change is made.
    SetEndpointPermission = Changing the permissions of the endpoint with the name '{0}' for the instance '{1}'.
    GrantPermission = Grant permission to '{0}'.
    RevokePermission = Revoke permission for '{0}'.
    InDesiredState = The endpoint '{0}' is in the desired state.
    NotInDesiredState = The endpoint '{0}' is not in the desired state.
    TestingConfiguration = Determines the state of the endpoint with the name '{0}' for the instance '{1}'.
'@
