ConvertFrom-StringData @'
    GetConfiguration = Get the current trace flags that are set on the instance {0}.
    SetConfiguration = Set the trace flags that are needed on the instance {0}.
    TestConfiguration = Determines the current state of the trace flags on the instance '{0}'.
    NotConnectedToComputerManagement = Was unable to connect to ComputerManagement '{0}'.
    NotConnectedToWMI = Was unable to connect to WMI information '{0}' in '{1}'.
    NotInDesiredState = Desired state does not match the current state. Expected the trace flags '{0}', but has trace flags '{1}'.
    TraceFlagPresent = Trace flag {0} is present, but should be absent.
    TraceFlagNotPresent = Trace flag {0} is absent, but should be present.
    InDesiredState = The trace flags are in the desired state.
    DebugParsingStartupParameters = Parsing the startup parameters: {0}
    DebugFoundTraceFlags = Found the trace flags: {0}
    DebugReturningTraceFlags = Returning the trace flag values: {0}
    DebugNoTraceFlags = No trace flags were found in the startup parameters.
    DebugSetStartupParameters = Setting the startup parameters to: {0}
'@
