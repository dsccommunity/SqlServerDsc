ConvertFrom-StringData @'
    GetClientAlias = Getting the SQL Server Client Alias '{0}'.
    OSArchitecture64Bit = Current node is a 64-bit operating system, so will get the SQL Server Client Alias '{0}' from Wow6432Node too.
    AddClientAlias64Bit = Adding the SQL Server Client Alias '{0}' (64-bit).
    AddClientAlias32Bit = Adding the SQL Server Client Alias '{0}' (32-bit).
    RemoveClientAlias64Bit = Removing the SQL Server Client Alias '{0}' (64-bit).
    RemoveClientAlias32Bit = Removing the SQL Server Client Alias '{0}' (32-bit).
    TestingConfiguration = Determines if the SQL Server Client Alias is in desired state.
    SQLInstanceNotReachable = Unable to connect to SQL instance or retrieve option. Assuming resource is not in desired state. Error: {0}
    ClientAliasMissing = The SQL Server Client Alias '{0}' is missing.
    ClientAliasPresent = The SQL Server Client Alias '{0}' exist, verifying values.
    InDesiredState = The SQL Server Client Alias '{0}' is in desired state.
    NotInDesiredState = The SQL Server Client Alias '{0}' is not in desired state.
'@
