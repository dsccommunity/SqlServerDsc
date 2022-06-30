# $a = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlDatabasePermission -Method Get -Property @{
#     Ensure               = 'Present'
#     ServerName           = 'localhost'
#     InstanceName         = 'sql2017'
#     DatabaseName         = 'AdventureWorks2'
#     Name                 = 'SQLTEST\sqluser'
#     Permission           = [CimInstance[]]@(
#         (New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName DatabasePermission -Property @{
#             State = 'Grant'
#             Permission = @('select')
#         })
#         (New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName DatabasePermission -Property @{
#             State = 'GrantWithGrant'
#             Permission = @('update')
#         })
#     )

#     PSDscRunAsCredential = $SqlInstallCredential
# } -Verbose
