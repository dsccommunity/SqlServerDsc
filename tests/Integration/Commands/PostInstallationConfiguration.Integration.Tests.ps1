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
    $script:moduleName = 'SqlServerDsc'

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

# cSpell: ignore DSCSQLTEST
Describe 'PostInstallationConfiguration' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    Context 'When configuring SSL certificate for encryption support on DSCSQLTEST instance' {
        BeforeAll {
            $script:instanceName = 'DSCSQLTEST'
            $script:computerName = Get-ComputerName
            $script:computerNameFqdn = Get-ComputerName -FullyQualifiedDomainName
            $script:serviceAccountName = 'svc-SqlPrimary'
        }

        It 'Should verify the SQL Server instance is running with the expected service account' {
            $serviceName = "MSSQL`$$script:instanceName"
            $service = Get-CimInstance -ClassName 'Win32_Service' -Filter "Name='$serviceName'" -ErrorAction 'Stop'

            $service | Should -Not -BeNullOrEmpty
            $service.State | Should -Be 'Running'
            $service.StartName | Should -BeLike "*\$script:serviceAccountName"
        }

        It 'Should create a self-signed certificate for SQL Server encryption' {
            # Create self-signed certificate with proper configuration for SQL Server
            $certificateParams = @{
                Type              = 'SSLServerAuthentication'
                Subject           = "CN=$script:computerName"
                DnsName           = @(
                    $script:computerName
                    $script:computerNameFqdn
                    'localhost'
                )
                KeyAlgorithm      = 'RSA'
                KeyLength         = 2048
                HashAlgorithm     = 'SHA256'
                TextExtension     = '2.5.29.37={text}1.3.6.1.5.5.7.3.1'
                NotAfter          = (Get-Date).AddYears(3)
                KeySpec           = 'KeyExchange'
                Provider          = 'Microsoft RSA SChannel Cryptographic Provider'
                CertStoreLocation = 'cert:\LocalMachine\My'
            }

            $script:certificate = New-SelfSignedCertificate @certificateParams -ErrorAction 'Stop'

            $script:certificate | Should -Not -BeNullOrEmpty
            $script:certificate.Thumbprint | Should -Not -BeNullOrEmpty
            $script:certificateThumbprint = $script:certificate.Thumbprint
        }

        It 'Should export the certificate to file' {
            $script:certificatePath = Join-Path -Path $env:TEMP -ChildPath 'SqlServerEncryption.cer'

            Export-Certificate -Cert $script:certificate -FilePath $script:certificatePath -ErrorAction 'Stop'

            Test-Path -Path $script:certificatePath | Should -BeTrue
        }

        It 'Should import certificate to Trusted Root Certification Authorities' {
            # Import to trusted root for self-signed certificates
            Import-Certificate -FilePath $script:certificatePath -CertStoreLocation 'Cert:\LocalMachine\Root' -ErrorAction 'Stop'

            # Verify certificate is in trusted root
            $trustedCert = Get-ChildItem -Path 'Cert:\LocalMachine\Root' | Where-Object -FilterScript { $_.Thumbprint -eq $script:certificateThumbprint }
            $trustedCert | Should -Not -BeNullOrEmpty
        }

        It 'Should grant SQL Server service account permission to certificate private key' {
            # Get the certificate from the Personal store
            $cert = Get-ChildItem -Path "Cert:\LocalMachine\My\$script:certificateThumbprint" -ErrorAction 'Stop'

            # Get the private key
            $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
            $privateKeyPath = $rsaCert.Key.UniqueName

            # Build the full path to the private key file
            $privateKeyFile = Join-Path -Path "$env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys" -ChildPath $privateKeyPath

            # Verify the private key file exists
            Test-Path -Path $privateKeyFile | Should -BeTrue

            # Grant read permission to the SQL Server service account
            $acl = Get-Acl -Path $privateKeyFile -ErrorAction 'Stop'
            $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new(
                $script:serviceAccountName,
                [System.Security.AccessControl.FileSystemRights]::Read,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $acl.AddAccessRule($accessRule)
            Set-Acl -Path $privateKeyFile -AclObject $acl -ErrorAction 'Stop'

            # Verify permission was granted
            $updatedAcl = Get-Acl -Path $privateKeyFile -ErrorAction 'Stop'
            $serviceAccountAccess = $updatedAcl.Access | Where-Object -FilterScript {
                $_.IdentityReference -like "*$script:serviceAccountName*" -and $_.FileSystemRights -match 'Read'
            }
            $serviceAccountAccess | Should -Not -BeNullOrEmpty
        }

        It 'Should configure SQL Server instance to use the certificate' {
            # Get the SQL Server instance registry key path
            # For named instance DSCSQLTEST, the registry path includes the instance name
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$script:instanceName\MSSQLServer\SuperSocketNetLib"

            # Find the actual registry path (version number varies)
            $actualRegistryPath = Get-Item -Path $registryPath -ErrorAction 'Stop' | Select-Object -First 1 -ExpandProperty Name
            $actualRegistryPath = "Registry::$actualRegistryPath"

            # Set the certificate thumbprint (without spaces)
            $thumbprintValue = $script:certificateThumbprint -replace '\s', ''
            Set-ItemProperty -Path $actualRegistryPath -Name 'Certificate' -Value $thumbprintValue -ErrorAction 'Stop'

            # Verify the certificate was set
            $setCertificate = Get-ItemProperty -Path $actualRegistryPath -Name 'Certificate' -ErrorAction 'Stop'
            $setCertificate.Certificate | Should -Be $thumbprintValue
        }

        It 'Should restart SQL Server service to apply certificate changes' {
            $serviceName = "MSSQL`$$script:instanceName"

            # Restart the SQL Server service
            Restart-Service -Name $serviceName -Force -ErrorAction 'Stop'

            # Wait for service to be running
            $maxRetries = 30
            $retryCount = 0
            do {
                Start-Sleep -Seconds 2
                $service = Get-Service -Name $serviceName -ErrorAction 'Stop'
                $retryCount++
            } while ($service.Status -ne 'Running' -and $retryCount -lt $maxRetries)

            $service.Status | Should -Be 'Running'

            Write-Verbose -Message "SQL Server instance $script:instanceName restarted with SSL certificate configuration" -Verbose
        }

        It 'Should verify SQL Server is online without using the certificate for encryption' {
            # Connect to SQL Server and verify encryption is available
            $sqlAdministratorUserName = 'SqlAdmin'
            $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            $credential = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)

            $serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:instanceName -Credential $credential -ErrorAction 'Stop'

            # The server should be online
            $serverObject.Status.ToString() | Should -Match '^Online$'

            # Clean up
            Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject -ErrorAction 'Stop'
        }

        It 'Should verify the connection is using encryption via DMV query' {
            # Connect to SQL Server with encryption enabled
            $sqlAdministratorUserName = 'SqlAdmin'
            $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            $credential = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)

            $serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:instanceName -Credential $credential -Encrypt -ErrorAction 'Stop'

            # Query sys.dm_exec_connections to verify encryption is being used
            # See: https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption?view=sql-server-ver17#verify-network-encryption
            $encryptionQuery = @"
SELECT
    session_id,
    encrypt_option,
    net_transport
FROM sys.dm_exec_connections
WHERE session_id = @@SPID
"@

            $result = Invoke-SqlDscQuery -ServerObject $serverObject -DatabaseName 'master' -Query $encryptionQuery -PassThru -Force -ErrorAction 'Stop'

            # Verify the connection is encrypted
            $result | Should -Not -BeNullOrEmpty
            $result.Tables[0].Rows.Count | Should -Be 1
            $result.Tables[0].Rows[0]['encrypt_option'] | Should -Be 'TRUE'

            # Clean up
            Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject -ErrorAction 'Stop'

            Write-Verbose -Message "Verified encrypted connection using sys.dm_exec_connections DMV" -Verbose
            Write-Verbose -Message "SSL certificate successfully configured for SQL Server instance $script:instanceName" -Verbose
        }
    }
}
