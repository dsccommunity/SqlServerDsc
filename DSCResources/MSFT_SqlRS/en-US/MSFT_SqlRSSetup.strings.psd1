ConvertFrom-StringData @'
    TestFailedAfterSet = Test-TargetResource function returned false when Set-TargetResource function verified the desired state. This indicates that the Set-TargetResource did not correctly set set the desired state, or that the function Test-TargetResource does not correctly evaluates the desired state.
'@
