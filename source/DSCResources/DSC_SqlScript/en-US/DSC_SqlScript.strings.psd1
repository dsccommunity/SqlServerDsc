ConvertFrom-StringData @'
    ExecutingGetScript = Executing the Get script from the file path '{0}' on the instance '{1}' on the server '{2}'.
    SQLInstanceNotReachable = Unable to connect to SQL instance or retrieve option. Assuming resource is not in desired state. Error: {0}
    ExecutingSetScript = Executing the Set script from the file path '{0}' on the instance '{1}' on the server '{2}'.
    ExecutingTestScript = Executing the Test script from the file path '{0}' on the instance '{1}' on the server '{2}'.
    TestingConfiguration = Determines if the configuration in the Set script is in desired state.
    InDesiredState = The configuration is in desired state.
    NotInDesiredState = The configuration is not in desired state.
    GetFilePath_FileNotFound = The file specified in GetFilePath ('{0}') does not exist or is not accessible. Cannot determine resource state.
    SetFilePath_FileNotFound = The file specified in SetFilePath ('{0}') does not exist or is not accessible. Cannot apply desired state.
    TestFilePath_FileNotFound = Test script file '{0}' not found. Assuming resource is not in desired state.
'@
