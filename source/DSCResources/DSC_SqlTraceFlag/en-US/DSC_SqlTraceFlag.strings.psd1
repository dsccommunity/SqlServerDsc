ConvertFrom-StringData @'
    GetConfiguration = Get the current TraceFlags that are set on instance {0}.
    SetConfiguration = Set the TraceFlags that are needed on instance {0}.
    TestConfiguration = Determines the current state of the TraceFlags Compared to the desired TraceFlags '{0}'.
    NotConnectedToComputerManagement = Was unable to connect to ComputerManagement '{0}'.
    NotConnectedToWMI = Was unable to connect to WMI information '{0}' in '{1}'.
    DesiredTraceFlagNotPresent = TraceFlag does not match the actual TraceFlags on the instance.
    TraceFlagPresent = traceflag {0} is present.
    TraceFlagNotPresent = traceflag {0} is not present.
'@
