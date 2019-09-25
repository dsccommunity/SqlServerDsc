ConvertFrom-StringData @'
    RetrievingAuditSpecificationInformation = Retrieving information about Audit specification '{0}' from the server '{1}' instance '{2}'. (SSAS0001)
    AuditSpecificationNotFound = The audit specification '{0}' does not exist. (SSAS0002)
    EvaluateAuditSpecification = Determining if the audit specification '{0}' on server '{1}' instance '{2}' is in the desired state. (SSAS0003)
    AuditSpecificationExist = The audit specification '{0}' exist in on server '{1}' instance '{2}'. (SSAS0004)
    AuditSpecificationDoesNotExist = The audit specification '{0}' does not exist on server '{1}' instance '{2}'. (SSAS0005)
    InDesiredState = The audit specification is in desired state. (SSAS0006)
    NotInDesiredState = The audit specification is not in desired state. (SSAS0007)
    DisableAuditSpecification = Disabling audit audit specification '{0}' on server '{1}' instance '{2}'. (SSAS0008)
    EnableAuditSpecification = Enabling audit audit specification '{0}' on server '{1}' instance '{2}'. (SSAS0009)
    CreateAuditSpecification = Creating the audit specification '{0}' on server '{1}' instance '{2}'. (SSAS0010)
	FailedCreateAuditSpecification = Failed creating audit specification '{0}' on server '{1}' instance '{2}'. (SSAS0011)
    AuditAlreadyInUse = Audit {0} for audit specification '{1}' on server '{2}' instance '{3}' is already in use for audit specification '{4}' (SSAS0012
    DropAuditSpecification = Removing the audit specification '{0}' from server '{1}' instance '{2}'. (SSAS0013)
	FailedDropAuditSpecification = Failed removing the audit specification '{0}' from server '{1}' instance '{2}'. (SSAS0014)
    SetAuditSpecification = Setting the audit specification '{0}' on server '{1}' instance '{2}' to the desired state. (SSAS0015)
	FailedUpdateAuditSpecification = Failed updating audit specification '{0}' on server '{1}' instance '{2}'. (SSAS0016)
    ForceNotEnabled = Unable to re-create the server audit. The server audit needs to be re-created but the configuration has not opt-in to re-create the audit. To opt-in set the parameter Force to $true.
'@
