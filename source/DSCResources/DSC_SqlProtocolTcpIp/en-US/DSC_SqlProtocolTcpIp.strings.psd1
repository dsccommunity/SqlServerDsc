ConvertFrom-StringData @'
    GetCurrentState = Getting the current state of the TCP/IP address group '{0}' for the instance '{1}' on the server '{2}'. (SSPTI0001)
    GetMissingIpAddressGroup = The specified IP address group '{0}' does not not exist, cannot determine current state. (SSPTI0002)
    TestDesiredState = Determining the current state of the TCP/IP address group '{0}' for the instance '{1}' on the server '{2}'. (SSPTI0003)
    NotInDesiredState = The TCP/IP address group '{0}' for the instance '{1}' is not in desired state. (SSPTI0004)
    InDesiredState = The TCP/IP address group '{0}' for the instance '{1}' is in desired state. (SSPTI0005)
    SetDesiredState = Setting the desired state for the TCP/IP address group '{0}' for the instance '{1}' on the server '{2}'. (SSPTI0006)
    SetMissingIpAddressGroup = The specified IP address group '{0}' does not not exist. (SSPTI0007)
    TcpPortHasBeenSet = The TCP port(s) '{0}' has been set on the TCP/IP address group '{1}'. (SSPTI0008)
    TcpDynamicPortHasBeenSet = Dynamic TCP port has been enabled on the TCP/IP address group '{0}'. (SSPTI0009)
    GroupHasBeenEnabled = The TCP/IP address group '{0}' has been enabled on the SQL Server instance '{1}'. (SSPTI0010)
    GroupHasBeenDisabled = The TCP/IP address group '{0}' has been disabled on the SQL Server instance '{1}'. (SSPTI0011)
    IpAddressHasBeenSet = The TCP/IP address for the TCP/IP address group '{0}' has been set to '{1}'. (SSPTI0012)
    GroupIsInDesiredState = The TCP/IP address group '{0}' on the instance '{1}' is already in desired state. (SSPTI0013)
    RestartSuppressed = The restart was suppressed. The configuration will not be active until the node is manually restart. (SSPTI0014)
    FailedToGetSqlServerProtocol = Failed to get the settings for the SQL Server Database Engine server protocol TCP/IP. (SSPTI0015)
    GetIpAddressGroupByIpAddress = Detect the TCP/IP address group by using the TCP/IP address '{0}'. (SSPTI0016)
    IpAddressGroupNotFoundError = The TCP/IP address group was not detected because the TCP/IP address '{0}' is not assigned to any TCP/IP address group. (SSPTI0017)
'@
