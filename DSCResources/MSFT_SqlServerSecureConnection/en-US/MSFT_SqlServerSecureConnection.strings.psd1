<#
    Localized resources for MSFT_SqlServerSecureConnection
#>

ConvertFrom-StringData @'
    GetEncryptionSettings = Getting encryption settings for Instance '{0}'.
    CertificateSettings = Certificate permissions are {0}.
    EncryptedSettings = Found thumbprint of '{0}', with Force Encryption set to '{1}'.
    SetEncryptionSetting = Securing Instance '{0}' with Thumbprint: '{1}' and Force Encryption: '{2}'.
    RemoveEncryptionSetting = Removing Sql Server secure connection from Instance '{0}'.
    SetCertificatePermission = Adding read permissions to certificate '{0}' for account '{1}'.
    RestartingService = Restarting SQL Server service for Instance '{0}'.
    TestingConfiguration = Determine if the Secure Connection is in the desired state.
    ThumprintResult = Thumbprint was '{0}' but Expected '{1}'.
    ForceEncryptionResult = ForceEncryption was '{0}' but Expected '{1}'.
    CertificateResult = Certificate permissions was '{0}' but Expected 'True'.
    EncryptionOff = Sql Secure Connection is Disabled.
    InstanceNotFound = "Sql Instance '{0}' not found on Sql Server."
    PrivateKeyPath = "Certificate private is located at '{0}'.
'@
