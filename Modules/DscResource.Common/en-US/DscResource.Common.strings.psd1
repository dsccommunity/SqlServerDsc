# Localized resources for helper module DscResource.Common.

ConvertFrom-StringData @'
    PropertyTypeInvalidForDesiredValues = Property 'DesiredValues' must be either a [System.Collections.Hashtable], [CimInstance] or [PSBoundParametersDictionary]. The type detected was {0}.
    PropertyTypeInvalidForValuesToCheck = If 'DesiredValues' is a CimInstance, then property 'ValuesToCheck' must contain a value.
    PropertyValidationError = Expected to find an array value for property {0} in the current values, but it was either not present or was null. This has caused the test method to return false.
    PropertiesDoesNotMatch = Found an array for property {0} in the current values, but this array does not match the desired state. Details of the changes are below.
    PropertyThatDoesNotMatch = {0} - {1}
    ValueOfTypeDoesNotMatch = {0} value for property {1} does not match. Current state is '{2}' and desired state is '{3}'.
    UnableToCompareProperty = Unable to compare property {0} as the type {1} is not handled by the Test-DscParameterState cmdlet.
    RobocopyUsingUnbufferedIo = Robocopy is using unbuffered I/O.
    RobocopyNotUsingUnbufferedIo = Unbuffered I/O cannot be used due to incompatible version of Robocopy.
    RobocopyArguments = Robocopy is started with the following arguments: {0}
    RobocopyErrorCopying = Robocopy reported errors when copying files. Error code: {0}.
    RobocopyFailuresCopying = Robocopy reported that failures occurred when copying files. Error code: {0}.
    RobocopySuccessful = Robocopy copied files successfully
    RobocopyRemovedExtraFilesAtDestination = Robocopy found files at the destination path that is not present at the source path, these extra files was remove at the destination path.
    RobocopySuccessfulAndRemovedExtraFilesAtDestination = Robocopy copied files to destination successfully. Robocopy also found files at the destination path that is not present at the source path, these extra files was remove at the destination path.
    RobocopyAllFilesPresent = Robocopy reported that all files already present.
    StartSetupProcess = Started the process with id {0} using the path '{1}', and with a timeout value of {2} seconds.
'@
