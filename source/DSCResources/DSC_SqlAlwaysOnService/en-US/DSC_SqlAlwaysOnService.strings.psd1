ConvertFrom-StringData @'
    GetAlwaysOnServiceState = Always On Availability Groups is {0} on the instance '{1}\\{2}'.
    SQLInstanceNotReachable = Unable to connect to SQL instance or retrieve option. Assuming resource is not in desired state. Error: {0}
    DisableAlwaysOnAvailabilityGroup = Disabling Always On Availability Groups for the instance '{0}\\{1}'.
    EnableAlwaysOnAvailabilityGroup = Enabling Always On Availability Groups for the instance '{0}\\{1}'.
    RestartingService = Always On Availability Groups has been {0} on the instance '{1}\\{2}'. Restarting the service.
    AlterAlwaysOnServiceFailed = Failed to change the Always On Availability Groups to {0} on the instance '{1}\\{2}'.
    TestingConfiguration = Determines if the current state of Always On Availability Groups on the instance '{0}\\{1}'.
    AlwaysOnAvailabilityGroupDisabled = Always On Availability Groups is disabled.
    AlwaysOnAvailabilityGroupEnabled = Always On Availability Groups is enabled.
    AlwaysOnAvailabilityGroupNotInDesiredStateEnabled = Always On Availability Groups is disabled, but expected it to be enabled.
    AlwaysOnAvailabilityGroupNotInDesiredStateDisabled = Always On Availability Groups is enabled, but expected it to be disabled.
'@
