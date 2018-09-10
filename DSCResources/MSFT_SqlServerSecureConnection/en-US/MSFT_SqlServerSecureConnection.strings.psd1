<#
    Localized resources for MSFT_SqlServerSecureConnection
#>

ConvertFrom-StringData @'
    GetEncryptionSettings = Getting encryption settings for Instance '{0}'.
    EncryptedSettings = Found thumbprint of '{0}', with Force Encryption set to '{1}'.
    SetEncryptionSetting = Securing Instance '{0}' with Thumbprint: '{1}' and Force Encryption: '{2}'.
    SetCertificatePermission = Adding read permissions to certificate '{0}' for account '{1}'.
    RestartingService = Restarting SQL Server service for Instance '{0}'.
    TestingConfiguration = Determine if the Secure Connection is in the desired state.
'@
