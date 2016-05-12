Import-Module "$PSScriptRoot\..\DSCResources\MSFT_xSQLAOGroupEnsure\MSFT_xSQLAOGroupEnsure.psm1" -Prefix Pester -Force

Describe 'Get-TargetResource'{
    Mock -ModuleName MSFT_xSQLAOGroupEnsure -CommandName Connect-SQL -MockWith {
            # build a custom object to return which is close to the real SMO object
            $smoObj = [PSCustomObject]@{
                        SQLServer = 'Node01';
                        SQLInstanceName = 'Prd01';
                        ClusterName = 'Clust01';
                    }
            $smoObj | Add-Member -MemberType NoteProperty -Name AvailabilityGroups -Value @{
                            'AG01' = @{
                                AvailabilityGroupListeners = @{ 
                                    name = 'AgList01';
                                    availabilitygrouplisteneripaddresses = @{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'};
                                    portnumber = 5022;};
                                AvailabilityDatabases = @(@{name='AdventureWorks'});
                            };
                        };
            $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force
            $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force
        return $smoObj
    }

    Context "When the configuration is already set" {
        
        $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $username = "dba" 
        $credential = New-Object System.Management.Automation.PSCredential($username,$password)

        $SqlAOGroup = Get-PesterTargetResource -Ensure 'Present' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $credential;

        It 'Should return hashtable with Ensure = $true'{
            $SqlAOGroup.Ensure | Should Be $true
        }
     }

     Context "When the configuration is not yet set or has drift" {
        
        $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $username = "dba" 
        $credential = New-Object System.Management.Automation.PSCredential($username,$password)

        $SqlAOGroup = Get-PesterTargetResource -Ensure 'Absent' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $credential;

        It 'Should return hashtable with Ensure = $false'{
            $SqlAOGroup.Ensure | Should Be $false
        }
     }
}



Describe 'Test-TargetResource'{
    Mock -ModuleName MSFT_xSQLAOGroupEnsure -CommandName Connect-SQL -MockWith {
            # build a custom object to return which is close to the real SMO object
            $smoObj = [PSCustomObject]@{
                        SQLServer = 'Node01';
                        SQLInstanceName = 'Prd01';
                        ClusterName = 'Clust01';
                    }
            $smoObj | Add-Member -MemberType NoteProperty -Name AvailabilityGroups -Value @{
                            'AG01' = @{
                                AvailabilityGroupListeners = @{ 
                                    name = 'AgList01';
                                    availabilitygrouplisteneripaddresses = @{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'};
                                    portnumber = 5022;};
                                AvailabilityDatabases = @(@{name='AdventureWorks'});
                            };
                        };
            $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force
            $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force
        return $smoObj
    }

    Context "When the configuration is valid" {
        
        $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $username = "dba" 
        $credential = New-Object System.Management.Automation.PSCredential($username,$password)

        $SqlAOGroupTest = Test-PesterTargetResource -Ensure 'Present' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $credential;

        It 'Should return $true'{
            $SqlAOGroupTest | Should Be $true
        }
     }

     Context "When the configuration has drifted" {
        
        $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $username = "dba" 
        $credential = New-Object System.Management.Automation.PSCredential($username,$password)

        $SqlAOGroupTest = Test-PesterTargetResource -Ensure 'Absent' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $credential;

        It 'Should return $false'{
            $SqlAOGroupTest | Should Be $false
        }
     }
}



Describe 'Set-TargetResource'{
    
    # create this first as we need to override the new-object cmdlet later
    $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
    $username = "dba";
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)

    Mock -ModuleName MSFT_xSQLAOGroupEnsure -CommandName Connect-SQL -MockWith {
            # build a custom object to return which is close to the real SMO object
            $smoObj = [PSCustomObject]@{
                        SQLServer = 'Node01';
                        SQLInstanceName = 'Prd01';
                        ClusterName = 'Clust01';
                    }
            $smoObj | Add-Member -MemberType NoteProperty -Name AvailabilityGroups -Value @{
                            'AG01' = @{
                                AvailabilityGroupListeners = @{ 
                                    name = 'AgList01';
                                    availabilitygrouplisteneripaddresses = @{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'};
                                    portnumber = 5022;};
                                AvailabilityDatabases = @(@{name='AdventureWorks'});
                            };
                        };
            $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force
            $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force
        return $smoObj
    }
    Mock -ModuleName MSFT_xSQLAOGroupEnsure -CommandName Grant-ServerPerms -MockWith {
        New-VerboseMessage -Message "Granted Permissions to $AuthorizedUser"
    }
    Mock -ModuleName MSFT_xSQLAOGroupEnsure -CommandName New-ListenerADObject -MockWith {
        New-VerboseMessage -Message "Created new Listener Object"
    }
    Mock -ModuleName MSFT_xSQLAOGroupEnsure -CommandName Get-ClusterNode -MockWith {
        $clusterNode = @([PSCustomObject]@{
                            Name = 'Node01';
                        };
                        , [PSCustomObject]@{
                            Name = 'Node02';
                        };
                        , [PSCustomObject]@{
                            Name = 'Node03';
                        };
                        , [PSCustomObject]@{
                            Name = 'Node04';
                        };
                    )
        return $clusterNode;
    }
    Mock -ModuleName MSFT_xSQLAOGroupEnsure -CommandName New-Object -MockWith {
        $object = [PSCustomObject]@{
                    Name = $args[0];
                }
        return $object;
    }
    Mock Get-Module -MockWith {
        return 'Module Name';
    }



    Context "Set the configuration" {
        
        # setup the params for the function using splatting method
        $Params = @{
                    Ensure = 'Present';
                    AvailabilityGroupName = 'AG01';
                    AvailabilityGroupNameListener = 'AgList01';
                    AvailabilityGroupNameIP = '192.168.0.1';
                    AvailabilityGroupSubMask = '255.255.255.0';
                    AvailabilityGroupPort = 1433;
                    ReadableSecondary = 'ReadOnly';
                    AutoBackupPrefernce = 'Primary';
                    SQLServer = 'localhost';
                    SQLInstanceName = 'MSSQLSERVER';
                    SetupCredential = $credential;
                }

        $SqlAOGroup = Set-PesterTargetResource @Params;
        
        #this shouldn't have generated any errors which they are caught by pester without further checks
     }
    
}
