---
Category: How-to
---

# Deploy Power BI Report Server

This guide walks you through deploying Power BI Report Server using _SqlServerDsc_
PowerShell commands. You will learn how to download the installation media,
install a dedicated SQL Server instance to host the report server database,
install and configure Power BI Report Server, and verify that everything is
working correctly.

Power BI Report Server is an on-premises report server that allows you to
create, publish, and manage Power BI reports, paginated reports, mobile
reports, and KPIs. It provides a web portal for viewing and managing reports,
similar to the Power BI service but hosted within your own infrastructure.

> [!NOTE]
> This guide uses _SqlServerDsc_ module commands to automate the entire deployment
> process. The same commands can be used in DSC configurations, scripts, or
> interactive PowerShell sessions.

## Prerequisites

Before you begin, ensure you have the following:

### System Requirements

- **Operating System**: Windows Server 2016 or later
- **PowerShell**: Windows PowerShell 5.1 or PowerShell 7+
- **Permissions**: Local Administrator privileges on the target machine
- **Disk Space**: At least 10 GB free for SQL Server and Power BI Report Server

### Required PowerShell Modules

Install the required modules before proceeding:

<!-- markdownlint-disable MD013 -->
```powershell
# Install SqlServerDsc module
Install-PSResource -Name 'SqlServerDsc' -Scope 'AllUsers' -TrustRepository

# Install SqlServer module (required for SMO assemblies)
Install-PSResource -Name 'SqlServer' -Version '22.2.0' -Scope 'AllUsers' -TrustRepository

# Install PSPKI module (required for creating self-signed certificates)
Install-PSResource -Name 'PSPKI' -Scope 'AllUsers' -TrustRepository
```
<!-- markdownlint-enable MD013 -->

### Create Service Accounts

SQL Server and its services require dedicated service accounts. Create local
user accounts for the SQL Server service and SQL Server Agent service:

<!-- markdownlint-disable MD013 -->
```powershell
# Define passwords for service accounts
# NOTE: Replace these placeholders with strong, unique passwords for production use.
#       Never commit actual passwords to source control.
$servicePassword = ConvertTo-SecureString -String '<YOUR_SERVICE_ACCOUNT_PASSWORD>' -AsPlainText -Force
$adminPassword = ConvertTo-SecureString -String '<YOUR_ADMIN_PASSWORD>' -AsPlainText -Force

# Create SQL Server service account
New-LocalUser -Name 'svc-SqlPrimary' `
    -Password $servicePassword `
    -FullName 'SQL Server Service Account' `
    -Description 'Runs the SQL Server Database Engine service.' `
    -PasswordNeverExpires

# Create SQL Server Agent service account
New-LocalUser -Name 'svc-SqlAgentPri' `
    -Password $servicePassword `
    -FullName 'SQL Server Agent Service Account' `
    -Description 'Runs the SQL Server Agent service.' `
    -PasswordNeverExpires

# Create SQL Administrator account
New-LocalUser -Name 'SqlAdmin' `
    -Password $adminPassword `
    -FullName 'SQL Administrator' `
    -Description 'SQL Server administrator account.' `
    -PasswordNeverExpires
```
<!-- markdownlint-enable MD013 -->

> [!IMPORTANT]
> This guide uses local accounts for simplicity. In production environments,
> use strong passwords and consider using Group Managed Service Accounts (gMSA)
> or domain accounts instead of local accounts.

## Phase 1: Download Installation Media

First, download the SQL Server 2022 ISO and the Power BI Report Server executable.

### Download SQL Server 2022

Use `Save-SqlDscSqlServerMediaFile` to download the SQL Server installation media:

<!-- markdownlint-disable MD013 -->
```powershell
# Define the download location
$downloadPath = 'C:\SqlServerMedia'

# Create the directory if it doesn't exist
if (-not (Test-Path -Path $downloadPath))
{
    New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null
}

# Download SQL Server 2022 Developer Edition
$sqlServerMedia = Save-SqlDscSqlServerMediaFile `
    -Url 'https://download.microsoft.com/download/c/c/9/cc9c6797-383c-4b24-8920-dc057c1de9d3/SQL2022-SSEI-Dev.exe' `
    -DestinationPath $downloadPath `
    -Force `
    -Quiet `
    -ErrorAction 'Stop'

Write-Information -MessageData "SQL Server media downloaded to: $($sqlServerMedia.FullName)" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Mount the SQL Server ISO

After downloading, mount the ISO to access the installation files:

<!-- markdownlint-disable MD013 -->
```powershell
# Mount the ISO file
$mountedImage = Mount-DiskImage -ImagePath $sqlServerMedia.FullName -PassThru
$mountedVolume = Get-Volume -DiskImage $mountedImage
$sqlMediaPath = "$($mountedVolume.DriveLetter):\"

Write-Information -MessageData "SQL Server media mounted at: $sqlMediaPath" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Download Power BI Report Server

Download the Power BI Report Server executable:

<!-- markdownlint-disable MD013 -->
```powershell
# Download Power BI Report Server (version 15.0.1117.98 - January 2025)
$pbirsMedia = Save-SqlDscSqlServerMediaFile `
    -Url 'https://download.microsoft.com/download/2/7/3/2739a88a-4769-4700-8748-1a01ddf60974/PowerBIReportServer.exe' `
    -FileName 'PowerBIReportServer.exe' `
    -DestinationPath $downloadPath `
    -SkipExecution `
    -Force `
    -Quiet `
    -ErrorAction 'Stop'

Write-Information -MessageData "Power BI Report Server downloaded to: $($pbirsMedia.FullName)" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

> [!TIP]
> The `-SkipExecution` parameter is used because the Power BI Report Server
> download is an executable installer, not an ISO that needs extraction.

### Verify Downloaded Files

You can verify the Power BI Report Server package information:

<!-- markdownlint-disable MD013 -->
```powershell
# Get package information
$packageInfo = Get-SqlDscRSPackage -FilePath $pbirsMedia.FullName
$packageInfo | Format-List
```
<!-- markdownlint-enable MD013 -->

## Phase 2: Install SQL Server Database Engine

Power BI Report Server requires a SQL Server Database Engine instance to store
its configuration and report data. Install a dedicated named instance for this
purpose.

### Install SQL Server Instance

<!-- markdownlint-disable MD013 -->
```powershell
# Define installation parameters
$installSqlServerParams = @{
    Install               = $true
    AcceptLicensingTerms  = $true
    InstanceName          = 'RSDB'
    Features              = 'SQLENGINE'
    SqlSysAdminAccounts   = @(
        "$env:COMPUTERNAME\SqlAdmin"
        'BUILTIN\Administrators'
    )
    SqlSvcAccount         = "$env:COMPUTERNAME\svc-SqlPrimary"
    SqlSvcPassword        = $servicePassword  # Use the variable defined earlier
    SqlSvcStartupType     = 'Automatic'
    AgtSvcAccount         = "$env:COMPUTERNAME\svc-SqlAgentPri"
    AgtSvcPassword        = $servicePassword  # Use the variable defined earlier
    AgtSvcStartupType     = 'Automatic'
    SecurityMode          = 'SQL'
    SAPwd                 = $adminPassword     # Use the variable defined earlier
    NpEnabled             = $true
    TcpEnabled            = $true
    MediaPath             = $sqlMediaPath
    Force                 = $true
}

# Install SQL Server
Install-SqlDscServer @installSqlServerParams -ErrorAction 'Stop'
```
<!-- markdownlint-enable MD013 -->

This installation:

- Creates a named instance called `RSDB`
- Installs only the Database Engine feature
- Configures mixed-mode authentication (Windows and SQL)
- Enables Named Pipes and TCP/IP protocols
- Sets up the service accounts created earlier

### Verify SQL Server Installation

<!-- markdownlint-disable MD013 -->
```powershell
# Check that SQL Server service is running
$sqlService = Get-Service -Name 'MSSQL$RSDB'
Write-Information -MessageData "SQL Server service status: $($sqlService.Status)" -InformationAction 'Continue'

# Check that SQL Server Agent is running
$agentService = Get-Service -Name 'SQLAgent$RSDB'
Write-Information -MessageData "SQL Server Agent service status: $($agentService.Status)" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

## Phase 3: Install Power BI Report Server

Now install Power BI Report Server using the downloaded executable.

### Run the Installation

<!-- markdownlint-disable MD013 -->
```powershell
# Define installation parameters
$installPbirsParams = @{
    AcceptLicensingTerms = $true
    MediaPath            = $pbirsMedia.FullName
    InstallFolder        = 'C:\Program Files\PBIRS'
    Edition              = 'Developer'
    LogPath              = Join-Path -Path $downloadPath -ChildPath 'PBIRS_Install.log'
    SuppressRestart      = $true
    Force                = $true
}

# Install Power BI Report Server
Install-SqlDscPowerBIReportServer @installPbirsParams -ErrorAction 'Stop'
```
<!-- markdownlint-enable MD013 -->

The available editions are:

| Edition | Description |
|---------|-------------|
| `Developer` | Full-featured free edition for development and testing |
| `Evaluation` | 180-day trial of Enterprise features |
| `ExpressAdvanced` | Free edition with limited features |

For production use, omit the `-Edition` parameter and use `-ProductKey` instead.

### Verify Installation

<!-- markdownlint-disable MD013 -->
```powershell
# Test if Power BI Report Server is installed
$isInstalled = Test-SqlDscRSInstalled -InstanceName 'PBIRS'
Write-Information -MessageData "Power BI Report Server installed: $isInstalled" -InformationAction 'Continue'

# Check the service status
$pbirsService = Get-Service -Name 'PowerBIReportServer'
Write-Information -MessageData "Power BI Report Server service status: $($pbirsService.Status)" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Get Setup Configuration

Retrieve detailed information about the installed Power BI Report Server instance
from the registry:

<!-- markdownlint-disable MD013 -->
```powershell
# Get setup configuration from registry
$setupConfig = Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

# Display installation details
Write-Information -MessageData "Instance ID: $($setupConfig.InstanceId)" -InformationAction 'Continue'
Write-Information -MessageData "Install Folder: $($setupConfig.InstallFolder)" -InformationAction 'Continue'
Write-Information -MessageData "Service Name: $($setupConfig.ServiceName)" -InformationAction 'Continue'
Write-Information -MessageData "Error Dump Directory: $($setupConfig.ErrorDumpDirectory)" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

## Phase 4: Create SSL Certificate

Before configuring the report server, create an SSL/TLS certificate for
secure HTTPS access. This guide uses a self-signed certificate for demonstration
purposes.

> [!IMPORTANT]
> **Production Certificate Recommendations:**
>
> For production environments, use a certificate issued by a trusted Certificate
> Authority (CA) instead of a self-signed certificate. Production certificates
> should meet the following requirements:
>
> - **Subject Name (CN)** or **Subject Alternative Name (SAN)**: Must match the
>   server's fully qualified domain name (FQDN) that clients will use to access
>   the report server
> - **Enhanced Key Usage (EKU)**: Must include "Server Authentication"
>   (OID: 1.3.6.1.5.5.7.3.1)
> - **Key Length**: Minimum 2048 bits for RSA keys
> - **Validity Period**: Follow your organization's certificate lifecycle policy
> - **Trusted CA**: Issued by a CA that is trusted by all client machines
>
> You can obtain production certificates from:
>
> - Your organization's internal PKI/Certificate Authority
> - Public CAs such as DigiCert, Let's Encrypt, or GlobalSign
> - Azure Key Vault (for Azure-integrated environments)

### Create a Self-Signed Certificate

For development and testing, create a self-signed certificate using the PSPKI
module:

<!-- markdownlint-disable MD013 -->
```powershell
# Import the PSPKI module for certificate creation
Import-Module -Name 'PSPKI' -ErrorAction 'Stop'

# Get the computer name for the certificate subject
$computerName = [System.Net.Dns]::GetHostName()

# Create a self-signed certificate for SSL/TLS
$newCertificateParams = @{
    Subject            = "CN=$computerName"
    EKU                = 'Server Authentication'
    KeyUsage           = 'DigitalSignature, KeyEncipherment, DataEncipherment'
    SAN                = "dns:$computerName"
    FriendlyName       = 'Power BI Report Server SSL Certificate'
    Exportable         = $true
    KeyLength          = 2048
    ProviderName       = 'Microsoft Software Key Storage Provider'
    AlgorithmName      = 'RSA'
    SignatureAlgorithm = 'SHA256'
    StoreLocation      = 'LocalMachine'
}

$sslCertificate = New-SelfSignedCertificateEx @newCertificateParams

Write-Information -MessageData "Certificate created with thumbprint: $($sslCertificate.Thumbprint)" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Add Certificate to Trusted Root (Self-Signed Only)

For self-signed certificates, add the certificate to the Trusted Root
Certification Authorities store to avoid browser trust warnings:

<!-- markdownlint-disable MD013 -->
```powershell
# Export the certificate to a temporary file
$certificatePath = Join-Path -Path $env:TEMP -ChildPath 'PBIRS_SSL_Certificate.cer'
Export-Certificate -Cert $sslCertificate -FilePath $certificatePath -ErrorAction 'Stop'

# Import into Trusted Root Certification Authorities
$null = Import-Certificate -FilePath $certificatePath -CertStoreLocation 'Cert:\LocalMachine\Root' -ErrorAction 'Stop'

# Clean up the temporary file
Remove-Item -Path $certificatePath -Force

Write-Information -MessageData 'Certificate added to Trusted Root Certification Authorities.' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

> [!NOTE]
> Adding a self-signed certificate to the Trusted Root store is only required
> for local testing. In production, your CA-issued certificate should already
> be trusted by client machines.

### Store the Certificate Thumbprint

Save the certificate thumbprint for use in later configuration steps:

<!-- markdownlint-disable MD013 -->
```powershell
# Store the certificate thumbprint for later use
$certificateThumbprint = $sslCertificate.Thumbprint

Write-Information -MessageData "Certificate thumbprint: $certificateThumbprint" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

## Phase 5: Configure Report Server Database

After installation, configure Power BI Report Server to use the SQL Server
instance for its database.

### Get the Report Server Configuration

<!-- markdownlint-disable MD013 -->
```powershell
# Get the Reporting Services configuration CIM instance
$rsConfig = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

# Display current configuration
Write-Information -MessageData "Instance Name: $($rsConfig.InstanceName)" -InformationAction 'Continue'
Write-Information -MessageData "Service Account: $($rsConfig.WindowsServiceIdentityActual)" -InformationAction 'Continue'
Write-Information -MessageData "Is Initialized: $($rsConfig.IsInitialized)" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Enable Secure Connection

Enable SSL/TLS to require secure HTTPS connections to the report server:

<!-- markdownlint-disable MD013 -->
```powershell
# Enable secure connection (require HTTPS)
$rsConfig | Enable-SqlDscRsSecureConnection -Force -ErrorAction 'Stop'

Write-Information -MessageData 'Secure connection enabled (using HTTPS).' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

This sets the `SecureConnectionLevel` to 1 or higher, which requires all
client connections to use SSL/TLS encryption.

### Set Virtual Directories

Configure the virtual directories for the Report Server web service and the
web portal. These define the URL paths used to access each application:

<!-- markdownlint-disable MD013 -->
```powershell
# Set virtual directory for the Report Server web service
$rsConfig | Set-SqlDscRSVirtualDirectory `
    -Application 'ReportServerWebService' `
    -VirtualDirectory 'ReportServer' `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'Virtual directory set for ReportServerWebService.' -InformationAction 'Continue'

# Set virtual directory for the web portal
$rsConfig | Set-SqlDscRSVirtualDirectory `
    -Application 'ReportServerWebApp' `
    -VirtualDirectory 'Reports' `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'Virtual directory set for ReportServerWebApp (web portal).' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Add URL Reservations

After setting the virtual directories, add URL reservations for HTTPS on port
443. This allows the report server to listen on secure URLs:

> [!IMPORTANT]
> URL reservations are registered for the service account. Changing the
> service account requires updating all the URL reservations.

<!-- markdownlint-disable MD013 -->
```powershell
# Add HTTPS URL reservation for the Report Server web service
$rsConfig | Add-SqlDscRSUrlReservation `
    -Application 'ReportServerWebService' `
    -UrlString 'https://+:443' `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'HTTPS URL reservation added for ReportServerWebService.' -InformationAction 'Continue'

# Add HTTPS URL reservation for the web portal
$rsConfig | Add-SqlDscRSUrlReservation `
    -Application 'ReportServerWebApp' `
    -UrlString 'https://+:443' `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'HTTPS URL reservation added for ReportServerWebApp (web portal).' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Add SSL Certificate Bindings

Bind the SSL certificate to both report server applications. This associates
the certificate with the HTTPS URL reservations:

<!-- markdownlint-disable MD013 -->
```powershell
# Add SSL certificate binding for the Report Server web service
$rsConfig | Add-SqlDscRSSslCertificateBinding `
    -Application 'ReportServerWebService' `
    -CertificateHash $certificateThumbprint `
    -IPAddress '0.0.0.0' `
    -Port 443 `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'SSL certificate bound to ReportServerWebService.' -InformationAction 'Continue'

# Add SSL certificate binding for the web portal
$rsConfig | Add-SqlDscRSSslCertificateBinding `
    -Application 'ReportServerWebApp' `
    -CertificateHash $certificateThumbprint `
    -IPAddress '0.0.0.0' `
    -Port 443 `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'SSL certificate bound to ReportServerWebApp (web portal).' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

The `-IPAddress '0.0.0.0'` binds the certificate to all available IP addresses
on the server.

### Generate Database Scripts

Power BI Report Server provides methods to generate the T-SQL scripts needed
to create and configure its database:

<!-- markdownlint-disable MD013 -->
```powershell
# Get the service account (used for database permissions)
$serviceAccount = $rsConfig.WindowsServiceIdentityActual

# Generate the database creation script
$databaseScript = $rsConfig | Request-SqlDscRSDatabaseScript `
    -DatabaseName 'ReportServer' `
    -ErrorAction 'Stop'

# Generate the database rights script
$rightsScript = $rsConfig | Request-SqlDscRSDatabaseRightsScript `
    -DatabaseName 'ReportServer' `
    -UserName $serviceAccount `
    -ErrorAction 'Stop'
```
<!-- markdownlint-enable MD013 -->

### Execute Scripts on SQL Server

Run the generated scripts against your SQL Server instance:

<!-- markdownlint-disable MD013 -->
```powershell
# Import the SqlServer module for Invoke-SqlDscQuery
Import-SqlDscPreferredModule -ErrorAction 'Stop'

# Create the report server database
Invoke-SqlDscQuery `
    -ServerName 'localhost' `
    -InstanceName 'RSDB' `
    -DatabaseName 'master' `
    -Query $databaseScript `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'Report server database created successfully.' -InformationAction 'Continue'

# Grant database permissions
Invoke-SqlDscQuery `
    -ServerName 'localhost' `
    -InstanceName 'RSDB' `
    -DatabaseName 'master' `
    -Query $rightsScript `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'Database permissions granted successfully.' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Set Database Connection

Configure Power BI Report Server to connect to the newly created database:

<!-- markdownlint-disable MD013 -->
```powershell
# Set the database connection
$rsConfig | Set-SqlDscRSDatabaseConnection `
    -ServerName 'localhost' `
    -InstanceName 'RSDB' `
    -DatabaseName 'ReportServer' `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'Database connection configured successfully.' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

## Phase 6: Initialize and Verify

Initialize the report server and verify that the web portal is accessible
over HTTPS.

### Initialize the Report Server

<!-- markdownlint-disable MD013 -->
```powershell
# Check if already initialized
$isInitialized = $rsConfig | Test-SqlDscRSInitialized -ErrorAction 'Stop'
Write-Information -MessageData "Is initialized before: $isInitialized" -InformationAction 'Continue'

if (-not $isInitialized)
{
    # Initialize the report server
    $rsConfig | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
    Write-Information -MessageData 'Report server initialized successfully.' -InformationAction 'Continue'
}

# Restart the service to complete initialization
$rsConfig | Restart-SqlDscRSService -WaitTime 30 -Force -ErrorAction 'Stop'
Write-Information -MessageData 'Report server service restarted.' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

> [!IMPORTANT]
> The service restart is essential. The web portal may not be fully functional
> until the service has been restarted after initialization.

### Verify Initialization Status

<!-- markdownlint-disable MD013 -->
```powershell
# Refresh the configuration
$rsConfig = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

# Check initialization status
$isInitialized = $rsConfig | Test-SqlDscRSInitialized -ErrorAction 'Stop'
Write-Information -MessageData "Is initialized after: $isInitialized" -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Check URL Reservations

View the configured URL reservations for the report server:

<!-- markdownlint-disable MD013 -->
```powershell
# Get URL reservations
$urlReservations = $rsConfig | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

foreach ($reservation in $urlReservations)
{
    Write-Information -MessageData "Application: $($reservation.Application)" -InformationAction 'Continue'
    Write-Information -MessageData "URL: $($reservation.UrlString)" -InformationAction 'Continue'
    Write-Information -MessageData "---" -InformationAction 'Continue'
}
```
<!-- markdownlint-enable MD013 -->

### Test Web Portal Accessibility

Verify that the report server web sites are accessible:

<!-- markdownlint-disable MD013 -->
```powershell
# Test accessibility with detailed results
$accessResults = $rsConfig | Test-SqlDscRSAccessible -Detailed -ErrorAction 'Stop'

foreach ($result in $accessResults)
{
    $status = if ($result.Accessible) { 'Accessible' } else { 'Not Accessible' }
    Write-Information -MessageData "Site: $($result.Site)" -InformationAction 'Continue'
    Write-Information -MessageData "URL: $($result.Url)" -InformationAction 'Continue'
    Write-Information -MessageData "Status: $status (HTTP $($result.StatusCode))" -InformationAction 'Continue'
    Write-Information -MessageData "---" -InformationAction 'Continue'
}
```
<!-- markdownlint-enable MD013 -->

If everything is configured correctly, you should see both the Report Server
web service and the web portal as accessible with HTTPS status code 200.

### Access the Web Portal

Open the web portal in your browser:

<!-- markdownlint-disable MD013 -->
```powershell
# Open the web portal in the default browser (using HTTPS)
Start-Process 'https://localhost/Reports'
```
<!-- markdownlint-enable MD013 -->

The default URLs are:

- **Web Portal**: `https://localhost/Reports`
- **Web Service**: `https://localhost/ReportServer`

> [!NOTE]
> If you used a self-signed certificate, your browser may display a certificate
> warning on first access. This is expected because the certificate was not
> issued by a publicly trusted Certificate Authority. You can proceed past the
> warning for testing purposes. For production deployments, use a CA-issued
> certificate to avoid these warnings.

## Cleanup

After successful installation, clean up the temporary files and dismount the ISO.

### Dismount the SQL Server ISO

<!-- markdownlint-disable MD013 -->
```powershell
# Dismount the SQL Server ISO
Dismount-DiskImage -ImagePath $sqlServerMedia.FullName
Write-Information -MessageData 'SQL Server ISO dismounted.' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Remove Downloaded Files (Optional)

If you no longer need the installation media, you can remove them:

<!-- markdownlint-disable MD013 -->
```powershell
# Remove downloaded files to free disk space
Remove-Item -Path $downloadPath -Recurse -Force
Write-Information -MessageData 'Downloaded media files removed.' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

> [!NOTE]
> Consider keeping the installation media for future use, such as adding
> features, patching, or disaster recovery scenarios.

## Troubleshooting

### Service Fails to Start After Installation

**Symptoms**: The Power BI Report Server service does not start, or stops
immediately after starting.

**Solutions**:

1. Check the service account has the "Log on as a service" right:

   <!-- markdownlint-disable MD013 -->
   ```powershell
   # View Windows event logs for service errors
   Get-EventLog -LogName 'Application' -Source 'PowerBIReportServer' -Newest 10 |
       Format-List TimeGenerated, EntryType, Message
   ```
   <!-- markdownlint-enable MD013 -->

1. Verify the service account credentials are correct.

1. Check the installation log file at the path specified in `-LogPath`.

### Database Script Generation Fails

**Symptoms**: `Request-SqlDscRSDatabaseScript` returns an error or empty script.

**Solutions**:

1. Ensure the Power BI Report Server service is running:

   <!-- markdownlint-disable MD013 -->
   ```powershell
   Start-Service -Name 'PowerBIReportServer'
   ```
   <!-- markdownlint-enable MD013 -->

2. Wait a few seconds after starting the service before generating scripts.

3. Refresh the configuration object:

   <!-- markdownlint-disable MD013 -->
   ```powershell
   $rsConfig = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
   ```
   <!-- markdownlint-enable MD013 -->

### Web Portal Not Accessible After Initialization

**Symptoms**: `Test-SqlDscRSAccessible` returns `$false` or HTTPS errors.

**Solutions**:

1. Restart the service with a longer wait time:

   <!-- markdownlint-disable MD013 -->
   ```powershell
   $rsConfig | Restart-SqlDscRSService -WaitTime 60 -Force
   ```
   <!-- markdownlint-enable MD013 -->

1. Check Windows Firewall rules allow HTTPS traffic on port 443:

   <!-- markdownlint-disable MD013 -->
   ```powershell
   # Create a firewall rule to allow HTTPS traffic on port 443
   New-NetFirewallRule -DisplayName 'Power BI Report Server HTTPS' `
       -Direction Inbound `
       -Protocol TCP `
       -LocalPort 443 `
       -Action Allow
   ```
   <!-- markdownlint-enable MD013 -->

1. Verify URL reservations are configured correctly:

   <!-- markdownlint-disable MD013 -->
   ```powershell
   $rsConfig | Get-SqlDscRSUrlReservation
   ```
   <!-- markdownlint-enable MD013 -->

1. Check if another application is using port 443:

   <!-- markdownlint-disable MD013 -->
   ```powershell
   netstat -ano | Select-String ':443 '
   ```
   <!-- markdownlint-enable MD013 -->

1. Verify SSL certificate bindings are configured:

   <!-- markdownlint-disable MD013 -->
   ```powershell
   $rsConfig | Get-SqlDscRSSslCertificateBinding
   ```
   <!-- markdownlint-enable MD013 -->

## Next Steps

After deploying Power BI Report Server, you may want to:

- Replace the self-signed certificate with a CA-issued certificate for production
- Set up email delivery for subscriptions
- Configure authentication providers
- Create and publish your first Power BI report
- Set up backup and recovery procedures

For more information, see the [Power BI Report Server documentation](https://learn.microsoft.com/power-bi/report-server/).

---

## Appendix: HTTP Configuration (Development Only)

> [!WARNING]
> The following configuration uses unencrypted HTTP connections and should
> **only be used for local development or testing**. Never use HTTP in
> production environments as it exposes sensitive data to network interception.

If you need to configure Power BI Report Server with HTTP instead of HTTPS
(for example, in an isolated development environment), follow these
alternative steps in place of the secure configuration above:

### Disable Secure Connection

<!-- markdownlint-disable MD013 -->
```powershell
# Disable secure connection (use HTTP instead of HTTPS)
$rsConfig | Disable-SqlDscRsSecureConnection -Force -ErrorAction 'Stop'

Write-Information -MessageData 'Secure connection disabled (using HTTP).' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Add HTTP URL Reservations

<!-- markdownlint-disable MD013 -->
```powershell
# Add HTTP URL reservation for the Report Server web service (port 80)
$rsConfig | Add-SqlDscRSUrlReservation `
    -Application 'ReportServerWebService' `
    -UrlString 'http://+:80' `
    -Force `
    -ErrorAction 'Stop'

# Add HTTP URL reservation for the web portal (port 80)
$rsConfig | Add-SqlDscRSUrlReservation `
    -Application 'ReportServerWebApp' `
    -UrlString 'http://+:80' `
    -Force `
    -ErrorAction 'Stop'

Write-Information -MessageData 'HTTP URL reservations added.' -InformationAction 'Continue'
```
<!-- markdownlint-enable MD013 -->

### Skip Certificate Binding

When using HTTP, skip the SSL certificate creation and binding steps entirely.
The report server will be accessible at:

- **Web Portal**: `http://localhost/Reports`
- **Web Service**: `http://localhost/ReportServer`

> [!NOTE]
> Ensure Windows Firewall allows inbound traffic on port 80 if accessing
> from remote machines.
