[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    # Import the function directly for testing
    . "$PSScriptRoot/../../../source/Public/Assert-SqlLogin.ps1"

    # Mock the localized data
    $script:localizedData = @{
        AssertLogin_CheckingPrincipal = 'Checking if principal ''{0}'' exists as a login on instance ''{1}''.'
        AssertLogin_PrincipalNotFound = 'The principal ''{0}'' does not exist as a login on instance ''{1}''.'
        AssertLogin_PrincipalExists = 'The principal ''{0}'' exists as a login on instance ''{1}''.'
    }

    # Define mock SMO Server class since we don't have the real assemblies
    if (-not ('Microsoft.SqlServer.Management.Smo.Server' -as [Type]))
    {
        Add-Type -TypeDefinition @"
        namespace Microsoft.SqlServer.Management.Smo {
            public class Server {
                public string InstanceName { get; set; }
                public object Logins { get; set; }
            }
        }
"@
    }
}

AfterAll {
    # Clean up
}

Describe 'Assert-SqlLogin' -Tag 'Public' {
    Context 'When the principal does not exist as a login' {
        BeforeAll {
            $mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::new()
            $mockServerObject.InstanceName = 'TESTSERVER\INSTANCE'
            $mockServerObject.Logins = @{
                'DOMAIN\ExistingLogin' = [PSCustomObject]@{ Name = 'DOMAIN\ExistingLogin' }
            }

            $mockLocalizedStringNotFound = 'The principal ''{0}'' does not exist as a login on instance ''{1}''.'
        }

        It 'Should throw a terminating error' {
            { Assert-SqlLogin -ServerObject $mockServerObject -Principal 'NonExistentLogin' } |
                Should -Throw -ExpectedMessage ($mockLocalizedStringNotFound -f 'NonExistentLogin', 'TESTSERVER\INSTANCE')
        }
    }

    Context 'When the principal exists as a login' {
        BeforeAll {
            $mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::new()
            $mockServerObject.InstanceName = 'TESTSERVER\INSTANCE'
            $mockServerObject.Logins = @{
                'DOMAIN\ExistingLogin' = [PSCustomObject]@{ Name = 'DOMAIN\ExistingLogin' }
            }
        }

        It 'Should not throw an error' {
            { Assert-SqlLogin -ServerObject $mockServerObject -Principal 'DOMAIN\ExistingLogin' } |
                Should -Not -Throw
        }

        Context 'When passing ServerObject over the pipeline' {
            It 'Should not throw an error' {
                { $mockServerObject | Assert-SqlLogin -Principal 'DOMAIN\ExistingLogin' } |
                    Should -Not -Throw
            }
        }
    }

    Context 'When testing verbose output' {
        BeforeAll {
            $mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::new()
            $mockServerObject.InstanceName = 'TESTSERVER\INSTANCE'
            $mockServerObject.Logins = @{
                'DOMAIN\ExistingLogin' = [PSCustomObject]@{ Name = 'DOMAIN\ExistingLogin' }
            }

            $mockLocalizedStringChecking = 'Checking if principal ''{0}'' exists as a login on instance ''{1}''.'
            $mockLocalizedStringExists = 'The principal ''{0}'' exists as a login on instance ''{1}''.'
        }

        It 'Should write verbose messages' {
            $verboseMessages = @()

            Assert-SqlLogin -ServerObject $mockServerObject -Principal 'DOMAIN\ExistingLogin' -Verbose 4>&1 |
                ForEach-Object { $verboseMessages += $_.Message }

            $verboseMessages | Should -Contain ($mockLocalizedStringChecking -f 'DOMAIN\ExistingLogin', 'TESTSERVER\INSTANCE')
            $verboseMessages | Should -Contain ($mockLocalizedStringExists -f 'DOMAIN\ExistingLogin', 'TESTSERVER\INSTANCE')
        }
    }

    Context 'When testing error details' {
        BeforeAll {
            $mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::new()
            $mockServerObject.InstanceName = 'TESTSERVER\INSTANCE'
            $mockServerObject.Logins = @{}
        }

        It 'Should have correct error category' {
            try
            {
                Assert-SqlLogin -ServerObject $mockServerObject -Principal 'NonExistentLogin'
            }
            catch
            {
                $_.CategoryInfo.Category | Should -Be 'ObjectNotFound'
                $_.FullyQualifiedErrorId | Should -Be 'ASL0001,Assert-SqlLogin'
                $_.TargetObject | Should -Be 'NonExistentLogin'
            }
        }
    }
}