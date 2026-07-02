[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {

}

Describe 'Get-SqlDscAudit' -Tag 'Public' {
    Context 'When getting all current audits' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockServerObject = $mockServerObject |
                Add-Member -MemberType 'ScriptProperty' -Name 'Audits' -Value {
                    return @(
                        (
                            New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                                $mockServerObject,
                                'Log1'
                            )
                        ),
                        (
                            New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                                $mockServerObject,
                                'Log2'
                            )
                        )
                    )
                } -PassThru -Force

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
            }
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscAudit @mockDefaultParameters

            # TODO: this resulted in: The script failed due to call depth overflow.
            #$result | Should-HaveType 'Microsoft.SqlServer.Management.Smo.Audit'
            $result | Should-BeCollection -Count 2
            $result.Name | Should-ContainCollection 'Log1'
            $result.Name | Should-ContainCollection 'Log2'
        }
    }
}
