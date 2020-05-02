ConvertFrom-StringData @'
    GetCurrentState = Getting the current state of the protocol TCP/IP address group '{0}' for the instance '{1}' on the server '{2}'. (SSPTI0001)
    MissingIpAddressGroup = The specified IP address group '{0}' does not not exist, cannot determine current state. (SSPTI0002)
    TestDesiredState = Determining the current state of the protocol TCP/IP address group '{0}' for the instance '{1}' on the server '{2}'. (SSPTI0003)
    NotInDesiredState = The protocol TCP/IP address group '{0}' for the instance '{1}' is not in desired state. (SSPTI0004)
    InDesiredState = The protocol TCP/IP address group '{0}' for the instance '{1}' is in desired state. (SSPTI0005)

    SetDesiredState = Setting the desired state for the protocol '{0}' on the instance '{1}'. (SSP0002)
    ProtocolIsInDesiredState = The protocol '{0}' on the instance '{1}' is already in desired state. (SSP0002)
    ProtocolHasBeenEnabled = The protocol '{0}' has been enabled on the SQL Server instance '{1}'. (SSP0003)
    ProtocolHasBeenDisabled = The protocol '{0}' has been disabled on the SQL Server instance '{1}'. (SSP0004)
    ParameterHasBeenSetToNewValue = The parameter '{0}' for the protocol '{1}' has been set to the value '{2}'. (SSP0005)
    RestartSuppressed = The restart was suppressed. The configuration will not be active until the node is manually restart. (SSP0006)
'@
