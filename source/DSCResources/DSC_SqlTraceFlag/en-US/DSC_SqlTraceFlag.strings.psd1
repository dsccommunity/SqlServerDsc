ConvertFrom-StringData @'
    GetConfiguration = Getting the current state for the instance {0}.
    SetConfiguration = Setting the desired state for the instance {0}.
    TestConfiguration = Determining the current state for the instance '{0}'.
    NotConnectedToComputerManagement = Was unable to connect to ComputerManagement '{0}'.
    NotConnectedToWMI = Was unable to connect to WMI information '{0}' in '{1}'.
    NotInDesiredState = Desired state does not match the current state. Expected the trace flags '{0}', but current state has trace flags '{1}'.
    ClearNotInDesiredState = Desired state does not match the current state. Expected no trace flags, but current state has trace flags '{0}'.
    TraceFlagPresent = Trace flag {0} is present, but should be absent.
    TraceFlagNotPresent = Trace flag {0} is absent, but should be present.
    InDesiredState = The trace flags are in the desired state.
    NoTraceFlagParameter = There were no parameters passed, there is nothing to set.
    ClearingAllTraceFlags = Removing all existing trace flags.
    DebugParsingStartupParameters = {0}: Parsing the startup parameters: {1}
    DebugFoundTraceFlags = {0}: Found the trace flags: {1}
    DebugReturningTraceFlags = {0}: Returning the trace flag values: {1}
    DebugNoTraceFlags = {0}: No trace flags were found in the startup parameters.
    DebugSetStartupParameters = {0}: Setting the startup parameters to: {1}
'@
