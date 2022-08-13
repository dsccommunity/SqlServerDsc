<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlPermission.
#>

ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class SqlDatabasePermission.
    BothFileSizePropertiesMustBeSet = Both the parameter MaximumFileSize and MaximumFileSizeUnit must be assigned. (SA0001)
    ReservDiskSpaceWithoutMaximumFiles = The parameter ReservDiskSpace can only be used together with the parameter MaximumFiles. (SA0002)
    PathInvalid = The path '{0}' does not exist. Audit file can only be created in a path that already exist and where the SQL Server instance has permission to write. (SA0003)
    EvaluateServerAudit = Evaluate the current audit '{0}' on the instance '{1}'. (SA0004)
    MaximumFileSizeValueInvalid = The maximum file size must be set to a value of 0 or a value between 2 and 2147483647. (SA0004)
    QueueDelayValueInvalid = The queue delay must be set to a value of 0 or a value between 1000 and 2147483647. (SA0005)
    CannotCreateNewAudit = Cannot create a new audit because neither of the properties LogType or Path is specified. One of those properties must be specified to create a new audit. (SA0006)
    AuditOfWrongTypeForUseWithProperty = A property that is not in desired state is not compatible with the audit type '{0}'. (SA0007)
    AuditIsWrongType = The existing audit is of wrong type to be able to update the property that is not in desired state. If the audit should be re-created set Force to $true. (SA0008)
'@
