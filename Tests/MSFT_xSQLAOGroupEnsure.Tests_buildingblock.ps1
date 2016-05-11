$sql = [PSCustomObject]@{
            SQLServer = 'Node01';
            SQLInstanceName = 'Prd01';
        }
$sql | Add-Member -MemberType NoteProperty -Name AvailabilityGroups -Value @{
                'AG01' = @{
                    AvailabilityGroupListeners = @{ 
                        name = 'AgList01';
                        availabilitygrouplisteneripaddresses = @{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'};
                        portnumber = 5022;};
                    AvailabilityDatabases = @(@{name='AdventureWorks'});
                };
            };
$sql.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force
$sql.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force

 
 $AvailabilityGroupName = 'AG01'
 AvailabilityGroupName = $sql.AvailabilityGroups[$AvailabilityGroupName]
    AvailabilityGroupNameListener = $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityGroupListeners.name
    AvailabilityGroupNameIP = $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityGroupListeners.availabilitygrouplisteneripaddresses.IPAddress
    AvailabilityGroupSubMask =  $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityGroupListeners.availabilitygrouplisteneripaddresses.SubnetMask
    AvailabilityGroupPort =  $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityGroupListeners.portnumber
    AvailabilityGroupNameDatabase = $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityDatabases.name